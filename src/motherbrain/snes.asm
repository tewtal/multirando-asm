; This is the first code to run on the SNES, it'll prepare a basic Mode 0 screen and clear all PPU regs
; It will then wait for the SA-1 to issue commands that it'll execute during NMI (or force-blank)
print "snes main = ", pc

SNES_CMD_QUEUE = $3600
SNES_CMD_PTR = $37e0

snes_main:
	rep #$30
	
	; Update the SA-1 I-RAM NMI handler to point to our NMI handler
	lda.w #$5c5c
	sta.l !IRAM_NMI
	lda.w #snes_nmi_handler
	sta.l !IRAM_NMI+1
	lda.w #(snes_nmi_handler>>8)
	sta.l !IRAM_NMI+2

	; Initialize the CMD Pointer and queue
	lda.w #$0000
	ldx.w #$0000
-
	sta SNES_CMD_QUEUE, x
	inx #2
	cpx.w #(SNES_CMD_PTR-SNES_CMD_QUEUE)
	bne -

	lda.w #SNES_CMD_QUEUE
	sta SNES_CMD_PTR
	
    jsr snes_init
	
	lda.w #$0081	; Enable NMI and joypad polling
	sta.w $4200

	lda.w #$CAFE
	sta.w $37fe		; Tell the SA-1 we're ready to process commands

-   
	lda.w $37e6	    ; Check if we got a JML command
	beq -

	stz.w $37e6
	jmp [$37e2]

snes_nmi_handler:
	pha : phx : phy : php
	rep #$30
	
	lda.w SNES_CMD_PTR
	cmp.w #SNES_CMD_QUEUE
	beq .end
	ldx #SNES_CMD_QUEUE
.loop
	cpx.w SNES_CMD_PTR
	beq .end

	lda.w $0000, x
	cmp.w #$0000
	beq .end
	cmp.w #$0001
	beq .vram_dma
	cmp.w #$0002
	beq .vram_write
	cmp.w #$0003
	beq .wram_dma
	cmp.w #$0004
	beq .bus_write
	cmp.w #$0005
	beq .bus_write_long
	cmp.w #$0006
	beq .bus_write_byte
	cmp.w #$0007
	beq .cgram_dma
	cmp.w #$0008
	beq .jml_target
	bra .end

.vram_dma:
	inx #2
	jsr snes_vram_dma
	bra .loop
.vram_write:
	inx #2
	jsr snes_vram_write
	bra .loop
.wram_dma:
	inx #2
	jsr snes_wram_dma
	bra .loop
.bus_write:
	inx #2
	jsr snes_bus_write
	bra .loop
.bus_write_long:
	inx #2
	jsr snes_bus_write_long
	bra .loop
.bus_write_byte
	inx #2
	jsr snes_bus_write_byte
	bra .loop
.cgram_dma:
	inx #2
	jsr snes_cgram_dma
	bra .loop
.jml_target
	inx #2
	jsr snes_jml_target
	bra .loop

.end
	lda.w #SNES_CMD_QUEUE
	sta SNES_CMD_PTR

	sep #$20
-
	lda $4212
	and.b #$01
	bne -
	
	rep #$20
	lda $4218
	sta $37e8
	eor $37ea
	and $37e8
	sta $37ec
	lda $37e8
	sta $37ea
	stz $37fa

	plp : ply : plx : pla
    rti

; <source addr>, <source bank>, <dest addr>, <size>
snes_vram_dma:
	lda.w $0000, x
	sta $4302
	lda.w $0002, x
	sta $4304
	lda.w $0004, x
	sta $2116
	lda.w $0006, x
	sta $4305

	sep #$20
	lda.b #$80
	sta $2115
	lda.b #$18
	sta $4301
	lda.b #$01
	sta $4300
	sta $420b

	rep #$30
	txa : clc : adc.w #$0008 : tax
	rts

; <value>, <dest addr>
snes_vram_write:
	lda.w $0002, x
	sta $2116
	lda.w $0000, x
	sta $2118
	inx #4
	rts

; <source addr>, <source bank>, <dest addr>, <dest bank>, <size>
snes_wram_dma:
	lda.w $0000, x
	sta $4302
	lda.w $0002, x
	sta $4304
	lda.w $0004, x
	sta $2181
	lda.w $0006, x
	sta $2183
	lda.w $0008, x
	sta $4305

	sep #$20
	stz $4300
	lda.b #$80
	sta $4301
	lda.b #$01
	sta $420b

	rep #$30
	txa : clc : adc.w #$000A : tax
	rts

; <value>, <dest addr>
snes_bus_write:
	lda.w $0000, x
	ldy.w $0002, x
	sta.w $0000, y
	inx #4
	rts

; <value>, <dest addr>
snes_bus_write_byte:
	lda.w $0000, x
	ldy.w $0002, x
	sep #$20
	sta.w $0000, y
	rep #$20
	inx #4
	rts

; <value>, <dest addr>, <bank>
snes_bus_write_long:
	phb
	lda.w $0004, x
	pha : plb	; Stack off by one
	lda.w $0000, x
	ldy.w $0002, x
	sta.w $0000, y
	plb : plb ; Fix stack and restore bank
	inx #6
	rts

; <source addr>, <source bank>, <size>
snes_cgram_dma:
	lda.w $0000, x
	sta $4302
	lda.w $0002, x
	sta $4304
	lda.w $0004, x
	sta $4305

	sep #$20

	lda.b #$00
	sta $2121

	stz $4300
	lda.b #$22
	sta $4301

	lda.b #$01
	sta $420b

	rep #$30
	txa : clc : adc.w #$0006 : tax
	rts

; <target addr>
snes_jml_target:
	lda.w $0000, x
	sta.w $37e2
	lda.w $0002, x
	sta.w $37e4
	lda.w #$0002
	sta.w $37e6
	inx #4
	rts

snes_init:
  	sep 	#$30    ; X,Y,A are 8 bit numbers
 	lda 	#$8F    ; screen off, full brightness
 	sta 	$2100   ; brightness + screen enable register 
 	stz 	$2101   ; Sprite register (size + address in VRAM) 
 	stz 	$2102   ; Sprite registers (address of sprite memory [OAM])
 	stz 	$2103   ;    ""                       ""
 	stz 	$2105   ; Mode 0, = Graphic mode register
 	stz 	$2106   ; noplanes, no mosaic, = Mosaic register
 	stz 	$2107   ; Plane 0 map VRAM location
 	stz 	$2108   ; Plane 1 map VRAM location
 	stz 	$2109   ; Plane 2 map VRAM location
 	stz 	$210A   ; Plane 3 map VRAM location
 	stz 	$210B   ; Plane 0+1 Tile data location
 	stz 	$210C   ; Plane 2+3 Tile data location
 	stz 	$210D   ; Plane 0 scroll x (first 8 bits)
 	stz 	$210D   ; Plane 0 scroll x (last 3 bits) #$0 - #$07ff
 	lda 	#$FF    ; The top pixel drawn on the screen isn't the top one in the tilemap, it's the one above that.
 	sta 	$210E   ; Plane 0 scroll y (first 8 bits)
 	sta 	$2110   ; Plane 1 scroll y (first 8 bits)
 	sta 	$2112   ; Plane 2 scroll y (first 8 bits)
 	sta 	$2114   ; Plane 3 scroll y (first 8 bits)
 	lda 	#$07    ; Since this could get quite annoying, it's better to edit the scrolling registers to fix this.
 	sta 	$210E   ; Plane 0 scroll y (last 3 bits) #$0 - #$07ff
 	sta 	$2110   ; Plane 1 scroll y (last 3 bits) #$0 - #$07ff
 	sta 	$2112   ; Plane 2 scroll y (last 3 bits) #$0 - #$07ff
 	sta 	$2114   ; Plane 3 scroll y (last 3 bits) #$0 - #$07ff
 	stz 	$210F   ; Plane 1 scroll x (first 8 bits)
 	stz 	$210F   ; Plane 1 scroll x (last 3 bits) #$0 - #$07ff
 	stz 	$2111   ; Plane 2 scroll x (first 8 bits)
 	stz 	$2111   ; Plane 2 scroll x (last 3 bits) #$0 - #$07ff
 	stz 	$2113   ; Plane 3 scroll x (first 8 bits)
 	stz 	$2113   ; Plane 3 scroll x (last 3 bits) #$0 - #$07ff
 	lda 	#$80    ; increase VRAM address after writing to $2119
 	sta 	$2115   ; VRAM address increment register
 	stz 	$2116   ; VRAM address low
 	stz 	$2117   ; VRAM address high
 	stz 	$211A   ; Initial Mode 7 setting register
 	stz 	$211B   ; Mode 7 matrix parameter A register (low)
 	lda 	#$01
 	sta 	$211B   ; Mode 7 matrix parameter A register (high)
 	stz 	$211C   ; Mode 7 matrix parameter B register (low)
 	stz 	$211C   ; Mode 7 matrix parameter B register (high)
 	stz 	$211D   ; Mode 7 matrix parameter C register (low)
 	stz 	$211D   ; Mode 7 matrix parameter C register (high)
 	stz 	$211E   ; Mode 7 matrix parameter D register (low)
 	sta 	$211E   ; Mode 7 matrix parameter D register (high)
 	stz 	$211F   ; Mode 7 center position X register (low)
 	stz 	$211F   ; Mode 7 center position X register (high)
 	stz 	$2120   ; Mode 7 center position Y register (low)
 	stz 	$2120   ; Mode 7 center position Y register (high)
 	stz 	$2121   ; Color number register ($0-ff)
 	stz 	$2123   ; BG1 & BG2 Window mask setting register
 	stz 	$2124   ; BG3 & BG4 Window mask setting register
 	stz 	$2125   ; OBJ & Color Window mask setting register
 	stz 	$2126   ; Window 1 left position register
 	stz 	$2127   ; Window 2 left position register
 	stz 	$2128   ; Window 3 left position register
 	stz 	$2129   ; Window 4 left position register
 	stz 	$212A   ; BG1, BG2, BG3, BG4 Window Logic register
 	stz 	$212B   ; OBJ, Color Window Logic Register (or,and,xor,xnor)
 	sta 	$212C   ; Main Screen designation (planes, sprites enable)
 	stz 	$212D   ; Sub Screen designation
 	stz 	$212E   ; Window mask for Main Screen
 	stz 	$212F   ; Window mask for Sub Screen
 	lda 	#$30
 	sta 	$2130   ; Color addition & screen addition init setting
 	stz 	$2131   ; Add/Sub sub designation for screen, sprite, color
 	lda 	#$E0
 	sta 	$2132   ; color data for addition/subtraction
 	stz 	$2133   ; Screen setting (interlace x,y/enable SFX data)
 	stz 	$4200   ; Enable V-blank, interrupt, Joypad register
 	lda 	#$FF
 	sta 	$4201   ; Programmable I/O port
 	stz 	$4202   ; Multiplicand A
 	stz 	$4203   ; Multiplier B
 	stz 	$4204   ; Multiplier C
 	stz 	$4205   ; Multiplicand C
 	stz 	$4206   ; Divisor B
 	stz 	$4207   ; Horizontal Count Timer
 	stz 	$4208   ; Horizontal Count Timer MSB (most significant bit)
 	stz 	$4209   ; Vertical Count Timer
 	stz 	$420A   ; Vertical Count Timer MSB
 	stz 	$420B   ; General DMA enable (bits 0-7)
 	stz 	$420C   ; Horizontal DMA (HDMA) enable (bits 0-7)
 	stz 	$420D	; Access cycle designation (slow/fast rom)
 	cli 	 	; Enable interrupts
	rep		#$30
 	rts   

snes_run_z1:
    sep #$20

	lda #$00
	sta.l $004200

	lda #$80
	sta.l $002100    

    lda #$86
    sta $2222   ; Swap Z1 bank into $80-9F

    lda #$03
    sta $2224

    ; Set stack to be NES-compatible
    rep #$30
    ldx #$01FF
    txs

    ; Write Z1 NMI to I-RAM
    lda #$105c
    sta.l !IRAM_NMI

    lda #$0008
    sta.l !IRAM_NMI+2

	; Ack NMI/IRQs
	lda.l $004210

    ; Jump to zelda 1 init code
    sep #$30
    jml z1_SnesBoot

snes_run_m1:
    sep #$20

	lda #$00
	sta.l $004200

	lda #$80
	sta.l $002100

    lda #$87
    sta.l $002222   ; Swap M1 bank into $80-9F

    lda #$04
    sta.l $002224

    ; Set stack to be NES-compatible
    rep #$30
    ldx #$01FF
    txs

    ; Write Z1 NMI to I-RAM
    lda #$105c
    sta.l !IRAM_NMI

    lda #$0008
    sta.l !IRAM_NMI+2

	; Ack NMI/IRQs
	lda.l $004210

    ; Jump to metroid 1 init code
    sep #$30
    jml m1_SnesBoot	

snes_run_z3:
    sep #$20
    
	lda #$00
	sta.l $004200

	lda #$80
	sta.l $002100

    lda #$84
    sta.l $002220
    sta.l $002222

    lda #$85
    sta.l $002221
    sta.l $002223

    lda #$01
    sta.l $002224

	; Ack NMI/IRQs
	lda.l $004210

	; Set WRIO.7 to 1
	lda #$80
	sta.l $004201

    rep #$30
    ldx #$1fff
    txs

    ; Write Z3 NMI to I-RAM
    lda #$c95c
    sta.l !IRAM_NMI
    lda #$0080
    sta.l !IRAM_NMI+2  

    ; Write Z3 IRQ to I-RAM
    lda #$d85c
    sta.l !IRAM_IRQ
    lda #$0082
    sta.l !IRAM_IRQ+2

    sep #$30
    jml $008000

snes_run_m3:
    sep #$20
    
	lda #$00
	sta.l $004200

	lda #$80
	sta.l $002100
		
    lda #$02
    sta $2220
    lda #$03
    sta $2221

    lda #$80
    sta $2222
    lda #$81
    sta $2223

    lda #$00
    sta $2224

    rep #$30
    ldx #$1fff
    txs

    ; Write SM NMI to I-RAM
    lda #$835c
    sta.l !IRAM_NMI
    lda #$0095
    sta.l !IRAM_NMI+2

    ; Write SM IRQ to I-RAM
    lda #$6a5c
    sta.l !IRAM_IRQ
    lda #$0098
    sta.l !IRAM_IRQ+2

    sep #$30
    jml $80841C

snes_run_credits:
    %a16()
    lda #$0011 : sta !SRAM_CURRENT_GAME
    %a8()
    lda #$07 : sta $2223

    ; Set credits NMI vector
    
    ; Write Credits NMI to I-RAM
    lda #$5c
    sta !IRAM_NMI
    %a16()
    lda #(credits_nmi&$FFFF)
    sta !IRAM_NMI+1
    lda #((credits_nmi>>8)&$FFFF)
    sta !IRAM_NMI+2

    jml credits_init