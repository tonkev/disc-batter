IF !DEF(SCROLL)
SCROLL SET 1

INCLUDE "src/updates.asm"
INCLUDE "src/map.asm"
INCLUDE "src/player.asm"

SECTION "Scroll Vars", WRAM0

Shake:
DS 1
ScrollY:
DS 1
ScrollX:
DS 1

SECTION "Scroll Setup", ROM0

ScrollSetup:
	
	xor a
	ld [Shake], a
	
	
	ld hl, ScrollUpdate
	call RegisterUpdateCall
	
	ret

SECTION "Scroll Update", ROM0

ScrollUpdate:

	ld a, [PlayerY]
	sub 72
	jr c, .scySmallerThanMin
	cp MAP_YA - 24
	jr nc, .scyLargerThanMin
.scySmallerThanMin:
	ld a, MAP_YA - 24
.scyLargerThanMin:
	cp MAP_YB + 24 - 144
	jr c, .scySmallerThanMax
	ld a, MAP_YB + 24 - 144
.scySmallerThanMax:
	ld b, a
	
	ld a, [PlayerX]
	sub 80
	jr c, .scxSmallerThanMin
	cp MAP_XA - 24
	jr nc, .scxLargerThanMin
.scxSmallerThanMin:
	ld a, MAP_XA - 24
.scxLargerThanMin:
	cp MAP_XB + 24 - 160
	jr c, .scxSmallerThanMax
	ld a, MAP_XB + 24 - 160
.scxSmallerThanMax:
	ld c, a
	
	ld hl, $0000
	ld a, [Shake]
	cp $00
	jr z, .noShake
	dec a
	ld [Shake], a
	ld h, a
	ld l, a
	
	ld a, [rDIV]
	ld d, a
	and $01
	jr nz, .skipFlipY
	ld a, h
	xor $FF
	ld h, a
.skipFlipY:

	ld a, $02
	and d
	jr nz, .skipFlipX
	ld a, l
	xor $FF
	ld l, a
.skipFlipX:
.noShake:
	
	ld a, b
	add h
	ld [ScrollY], a
	ld a, c
	add l
	ld [ScrollX], a

	ret
	
SECTION "Add Shake", ROM0

AddShake:
; a - shake

	ld b, a
	ld a, [Shake]
	cp b
	jr nc, .smaller
	ld a, b
	ld [Shake], a
.smaller:
	ret
	
ENDC