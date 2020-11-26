IF !DEF(UI)
UI SET 1

INCLUDE "inc/hardware.inc"

SECTION "Font Tiles", ROM0

FontTiles:
INCLUDE "spr/font.z80"
FontTilesEnd:

SECTION "Font Tiles VRAM", VRAM[$9140]

FontTilesVRAM:
DS FontTilesEnd - FontTiles

SECTION "UI Setup", ROM0

UISetup:
	
	ld hl, FontTilesVRAM
	ld de, FontTiles
	ld bc, FontTilesEnd - FontTiles
	call CopyMemory

SECTION "Clear Screen", ROM0

ClearScreen:

	ld hl, _SCRN0
	ld bc, _SCRN1 - _SCRN0
	xor a
	call ClearMemory
	
	ret

SECTION "Draw Character", ROM0

;parameters
;a char
;de destination

DrawChar:
	cp $40
	jr nz, .notAt
	ld a, $3A
	jr .at
.notAt:
	sub $20
	jr z, .space
	cp $21
	jr nc, .alpha
	add 5
	cp $1F
	jr nz, .numeric
	ld a, $3B
.alpha:
	sub 2
.space:
.numeric:
.at:
	ld [de], a
	
	ret

SECTION "Draw Text", ROM0

;parameters
;hl address to 0 terminated string
;de destination

DrawText:

.loop:
	ld a, [hli]
	cp 0
	ret z
	cp $40
	jr nz, .notAt
	ld a, $3A
	jr .at
.notAt:
	sub $20
	jr z, .space
	cp $21
	jr nc, .alpha
	add 5
	cp $1F
	jr nz, .numeric
	ld a, $3B
.alpha:
	sub 2
.space:
.numeric:
.at:
	ld [de], a
	inc de
	jr .loop

SECTION "Clear Text", ROM0

;parameters
;hl address to 0 terminated string
;de destination

ClearText:

.loop:
	ld a, [hli]
	cp 0
	ret z
	xor a
	ld [de], a
	inc de
	jr .loop

ENDC