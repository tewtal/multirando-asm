macro ReplaceRefillRoom(name, direction, orig_room_header, orig_door_out, header_addr, door_addr)
pushpc
org <door_addr>
<name>DoorData:
if <direction> == 0 ; Original door on the left
	.in
		dw <orig_room_header>&$ffff : db $40, $05, $0E, $06, $00, $00 : dw $8000, $0000
	.out
		dw <orig_room_header>&$ffff : db $40, $04, $0E, $06, $00, $00 : dw $8000, $0000
else
	.in
		dw <orig_room_header>&$ffff : db $40, $04, $01, $06, $00, $00 : dw $8000, $0000
	.out
		dw <orig_room_header>&$ffff : db $40, $05, $01, $06, $00, $00 : dw $8000, $0000
endif

org <orig_room_header>+9
	dw .doors
org <orig_room_header>+13
	dl $CE8FA6
org <orig_room_header>+33
	dw .plms

org <header_addr>
.doors
if <direction> == 0 ; Original door on the left
	dw (<orig_door_out>&$ffff) : dw <name>DoorData_out
else
	dw <name>DoorData_out : dw (<orig_door_out>&$ffff)
endif
	dw $0000
.plms
	dw $B6DF
	db $07, $0A
	dw $0048, $0000

pullpc
endmacro

; Repoint/modify existing save room to have double doors
macro ReplaceSaveRoom(name, direction, orig_room_header, orig_door_out, header_addr, door_addr)
pushpc
org <door_addr>
<name>DoorData:
if <direction> == 0 ; Original door on the left
	.in
		dw <orig_room_header>&$ffff : db $40, $05, $0E, $06, $00, $00 : dw $8000, $0000
	.out
		dw <orig_room_header>&$ffff : db $40, $04, $0E, $06, $00, $00 : dw $8000, $0000
else
	.in
		dw <orig_room_header>&$ffff : db $40, $04, $01, $06, $00, $00 : dw $8000, $0000
	.out
		dw <orig_room_header>&$ffff : db $40, $05, $01, $06, $00, $00 : dw $8000, $0000
endif

org <orig_room_header>+9
	dw .doors
org <orig_room_header>+13
	dl $CE9EF6
org <orig_room_header>+33
	dw .plms

org <header_addr>
.doors
if <direction> == 0 ; Original door on the left
	dw <name>DoorData_out : dw (<orig_door_out>&$ffff)
else
	dw (<orig_door_out>&$ffff) : dw <name>DoorData_out
endif
	dw $0000
.plms
	dw $B76F
	db $07, $0B
	dw $0001, $0000

pullpc
endmacro

; Repoint/modify existing map room to have double doors
macro ReplaceMapRoom(name, direction, orig_room_header, orig_door_out, header_addr, door_addr)
pushpc
org <door_addr>
<name>DoorData:
if <direction> == 0 ; Original door on the left
	.in
		dw <orig_room_header>&$ffff : db $40, $05, $0E, $06, $00, $00 : dw $8000, $0000	
	.out
		dw <orig_room_header>&$ffff : db $40, $04, $0E, $06, $00, $00 : dw $8000, $0000		
else
	.in
		dw <orig_room_header>&$ffff : db $40, $04, $01, $06, $00, $00 : dw $8000, $0000
	.out
		dw <orig_room_header>&$ffff : db $40, $05, $01, $06, $00, $00 : dw $8000, $0000
endif

org <orig_room_header>+9
	dw .doors
org <orig_room_header>+13
	dl NewMapRoomLevelData+$F8000
org <orig_room_header>+33
	dw .plms

org <header_addr>
.doors
if <direction> == 0 ; Original door on the left
	dw (<orig_door_out>&$ffff) : dw <name>DoorData_out
else
	dw <name>DoorData_out : dw (<orig_door_out>&$ffff)
endif
	dw $0000
.plms
	dw $B6D3
	db $08, $0A
	dw $8000, $0000

pullpc
endmacro


; Replace and link up new double-door rooms
; Direction (0 = original door on the left, 1 = original door on the right)

; Crateria
;%ReplaceSaveRoom("CrateriaParlorSave", 1,   $8F93D5, $8389BE, $8FED00, $83AE00)

%ReplaceMapRoom("CrateriaMap", 0,           $8F9994, $838C2E, $8FED00, $83AE00)

%ReplaceMapRoom("NorfairMap", 1,            $8FB0B4, $8397C2, $8FEE00, $83AF00)

%ReplaceRefillRoom("MaridiaMissile", 0,     $8FD845, $83A894, $8FEE80, $83AF80)

%ReplaceRefillRoom("LNRefill", 0,           $8FB305, $8398A6, $8FEF00, $83B000)
