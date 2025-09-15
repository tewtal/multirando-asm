import os
import argparse
import struct

# Constants
NES_TILE_SIZE = 16  # Bytes per 8x8 2bpp NES tile
SNES_INTERLEAVED_TILE_SIZE = 16 # Bytes per 8x8 interleaved P0/P1 tile
CHUNK_SIZE = 32 * 1024  # 32 KB
INES_HEADER_SIZE = 16
PRG_BANK_SIZE = 16 * 1024 # 16 KB
CHR_BANK_SIZE = 8 * 1024  # 8 KB
TRAINER_SIZE = 512

# --- Conversion Function (unchanged) ---
def convert_nes_to_interleaved(nes_data: bytes) -> bytes:
    """
    Converts a block of NES 2bpp tile data (P0..P0, P1..P1) to
    SNES-ready interleaved format (P0R0, P1R0, P0R1, P1R1, ...).

    Args:
        nes_data: Bytes object containing NES 2bpp tile data.
                  Length must be a multiple of 16 bytes.

    Returns:
        Bytes object containing the converted interleaved data (same length).
        Returns None if input data length is invalid.
    """
    if len(nes_data) == 0:
        return b''
    if len(nes_data) % NES_TILE_SIZE != 0:
        print(f"\nError: Data length for conversion ({len(nes_data)}) is not a multiple of {NES_TILE_SIZE}")
        return None

    num_tiles = len(nes_data) // NES_TILE_SIZE
    interleaved_data = bytearray(len(nes_data))

    for i in range(num_tiles):
        nes_tile_offset = i * NES_TILE_SIZE
        interleaved_tile_offset = i * SNES_INTERLEAVED_TILE_SIZE

        for row in range(8):
            nes_plane0_byte = nes_data[nes_tile_offset + row]
            nes_plane1_byte = nes_data[nes_tile_offset + 8 + row]
            interleaved_data[interleaved_tile_offset + row * 2] = nes_plane0_byte
            interleaved_data[interleaved_tile_offset + row * 2 + 1] = nes_plane1_byte

    return bytes(interleaved_data)

# --- iNES Header Parsing Function ---
def parse_ines_header(rom_path):
    """
    Parses the iNES header to find CHR ROM offset and size.

    Args:
        rom_path: Path to the NES ROM file.

    Returns:
        A dictionary {'offset': int, 'length': int} for the CHR ROM data,
        or None if no CHR ROM is present or header is invalid.
    """
    try:
        with open(rom_path, 'rb') as f:
            header = f.read(INES_HEADER_SIZE)

        if len(header) < INES_HEADER_SIZE:
            print(f"Error: File '{rom_path}' is too small to contain an iNES header.")
            return None

        # Check magic number "NES\x1A"
        if header[0:4] != b'NES\x1a':
            print(f"Error: File '{rom_path}' does not have a valid iNES magic number.")
            return None

        prg_rom_units = header[4]
        chr_rom_units = header[5]
        flags6 = header[6]
        # flags7 = header[7] # Not used for basic CHR location

        # Check for CHR RAM (indicated by 0 units of CHR ROM)
        if chr_rom_units == 0:
            print("iNES header indicates CHR RAM is used. No CHR ROM data found in the file.")
            return {'offset': 0, 'length': 0} # Signal no CHR ROM data

        # Calculate sizes
        prg_rom_size = prg_rom_units * PRG_BANK_SIZE
        chr_rom_size = chr_rom_units * CHR_BANK_SIZE

        # Check for trainer (Flags 6, bit 2)
        has_trainer = (flags6 & 0x04) != 0
        trainer_offset = TRAINER_SIZE if has_trainer else 0

        # Calculate CHR ROM offset
        chr_offset = INES_HEADER_SIZE + trainer_offset + prg_rom_size

        print("--- iNES Header Info ---")
        print(f"PRG ROM Banks: {prg_rom_units} ({prg_rom_size} bytes)")
        print(f"CHR ROM Banks: {chr_rom_units} ({chr_rom_size} bytes)")
        print(f"Trainer Present: {'Yes' if has_trainer else 'No'}")
        print(f"Calculated CHR ROM Offset: {chr_offset} (0x{chr_offset:X})")
        print(f"Calculated CHR ROM Length: {chr_rom_size}")
        print("------------------------")

        # Optional: Sanity check against file size
        try:
            file_size = os.path.getsize(rom_path)
            if chr_offset + chr_rom_size > file_size:
                print(f"Warning: Calculated CHR ROM end ({chr_offset + chr_rom_size}) exceeds file size ({file_size}). File may be truncated.")
                # Adjust length if needed, or let the read operation fail later
                chr_rom_size = max(0, file_size - chr_offset)
                print(f"Adjusted CHR ROM Length: {chr_rom_size}")
        except OSError:
             print("Warning: Could not get file size for validation.")


        return {'offset': chr_offset, 'length': chr_rom_size}

    except IOError as e:
        print(f"Error reading header from file {rom_path}: {e}")
        return None
    except Exception as e:
        print(f"An unexpected error occurred during header parsing: {e}")
        return None


# --- ROM Processing Function (now uses determined offset/length) ---
def process_rom_segment(input_rom_path, output_dir, output_prefix, start_offset, segment_length):
    """
    Reads a specific segment (e.g., CHR ROM) of an input ROM, processes it in chunks,
    converts each chunk to interleaved format, and writes to output files.
    """
    if segment_length == 0:
        print("Segment length is zero. Nothing to process.")
        return

    if not os.path.exists(output_dir):
        try:
            os.makedirs(output_dir)
            print(f"Created output directory: {output_dir}")
        except OSError as e:
            print(f"Error creating output directory {output_dir}: {e}")
            return

    chunk_index = 0
    bytes_processed_in_segment = 0
    total_bytes_written = 0

    print(f"\nProcessing segment: Offset={start_offset}, Length={segment_length}")

    try:
        with open(input_rom_path, 'rb') as infile:
            # Move to the starting offset of the segment
            try:
                infile.seek(start_offset)
            except OSError as e:
                 print(f"Error seeking to offset {start_offset}: {e}")
                 return

            while bytes_processed_in_segment < segment_length:
                bytes_remaining_in_segment = segment_length - bytes_processed_in_segment
                read_size = min(CHUNK_SIZE, bytes_remaining_in_segment)

                chunk_data = infile.read(read_size)

                if not chunk_data:
                    print("Warning: Reached end of file unexpectedly before processing full segment length.")
                    break

                current_chunk_size = len(chunk_data)
                bytes_processed_in_segment += current_chunk_size

                # --- Validate and Convert ---
                # We expect CHR ROM to be perfectly tile aligned
                if current_chunk_size % NES_TILE_SIZE != 0:
                     print(f"\nWarning: Chunk {chunk_index} (or final part of segment) has size {current_chunk_size}, which is not a multiple of {NES_TILE_SIZE}.")
                     print("         This is unusual for CHR ROM data.")

                converted_chunk = convert_nes_to_interleaved(chunk_data)

                if converted_chunk is None:
                    print(f"Skipping chunk {chunk_index} due to conversion error (likely size non-multiple of {NES_TILE_SIZE}).")
                    # This might indicate a problem with the ROM or header interpretation
                    chunk_index += 1
                    continue

                # --- Write Output File ---
                output_filename = f"{output_prefix}_{chunk_index}.bin"
                output_filepath = os.path.join(output_dir, output_filename)

                try:
                    with open(output_filepath, 'wb') as outfile:
                        outfile.write(converted_chunk)
                    total_bytes_written += len(converted_chunk)
                except IOError as e:
                    print(f"Error writing output file {output_filepath}: {e}")
                    break

                chunk_index += 1

    except IOError as e:
        print(f"Error reading input file {input_rom_path}: {e}")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")

    print("\n--- Processing Summary ---")
    print(f"Source segment offset: {start_offset} (0x{start_offset:X})")
    print(f"Source segment length: {segment_length}")
    print(f"Bytes processed from segment: {bytes_processed_in_segment}")
    print(f"Total bytes written (converted): {total_bytes_written}")
    print(f"Number of output chunk files generated: {chunk_index}")
    print("-------------------------")


# --- Main Execution ---
if __name__ == "__main__":
    # Note: Removed --offset and --length arguments
    parser = argparse.ArgumentParser(description="Automatically finds NES CHR ROM data using the iNES header and converts it in chunks to interleaved format (16 bytes/tile) for SNES DMA.")
    parser.add_argument("input_rom", help="Path to the input NES ROM file.")
    parser.add_argument("-o", "--output_dir", default=".", help="Directory to save the output chunk files (default: current directory).")
    parser.add_argument("-p", "--prefix", default="chr_interleaved_chunk", help="Prefix for the output filenames (default: chr_interleaved_chunk).")

    args = parser.parse_args()

    # Parse the header first to get CHR info
    chr_info = parse_ines_header(args.input_rom)

    if chr_info is None:
        print("Could not parse iNES header or file invalid. Exiting.")
    elif chr_info['length'] == 0:
         print("ROM uses CHR RAM, no CHR ROM data to extract. Exiting.")
    else:
        # If header parsed and CHR ROM exists, process the segment
        process_rom_segment(
            args.input_rom,
            args.output_dir,
            args.prefix,
            chr_info['offset'],
            chr_info['length']
        )