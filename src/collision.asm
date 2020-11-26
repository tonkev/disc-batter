IF !DEF(COLLISION)
COLLISION SET 1

INCLUDE "inc/hardware.inc"
INCLUDE "src/utilities.asm"
INCLUDE "src/map.asm"

SECTION "Resolve AABB against Map", ROM0

ResolveXMovementAgainstMap:

;parameters
; hl  - size 
; bc  - target position (top left corner)
; e   - x direction

;returns
; bc - new position
; f  - nz if collision

;wrecks
; all

    ld d, c
	ld a, c

	bit 7, e
    jr nz, .xLeft

.xRight:
    add l
    ld c, a
	and $F8
	sub l
	jr .xRightRet

.xLeft:
    and $F8
    add $08

.xRightRet:	
    ld e, a
    push de
    ld l, b
    ld a, b
    add h
	dec a
    ld b, a

.xLoop:
    push hl
    call GetOverlappingTile
    pop hl
	cp $00
    jr nz, .xCollision

    ld a, h
    cp $00
    jr z, .xNoCollision
    sub $08
    jr nc, .xNotLast
    xor a
.xNotLast:
    ld h, a
    add l
	inc a
    ld b, a
    jr .xLoop

.xCollision:
    pop de
    ld c, e
	ld b, l
	or $01
    jr .xCollided

.xNoCollision:
    pop de
	ld c, d
	ld b, l
	xor a

.xCollided:
	
	ret
	
ResolveYMovementAgainstMap:

;parameters
; hl  - size 
; bc  - target position (top left corner)
; e   - y direction

;returns
; bc - new position
; a  - 0 if no collision
	
	ld d, b
	ld a, b
	
	bit 7, e
    jr nz, .yUp
	
.yDown:
	add h
	ld b, a
	and $F8
	sub h
	jr .yDownRet

.yUp:
	and $F8
	add $08
	
.yDownRet:
	ld e, a
	push de
	ld h, c
	ld a, c
	add l
	dec a
	ld c, a
	
.yLoop:
	push hl
	call GetOverlappingTile
	pop hl
	cp $00
	jr nz, .yCollision
	
	ld a, l
	cp $00
	jr z, .yNoCollision
	sub $08
	jr nc, .yNotLast
	xor a
.yNotLast:
	ld l, a
	add h
	inc a
	ld c, a
	jr .yLoop

.yCollision:
	pop de
	ld b, e
	ld c, h
	or $01
	jr .yCollided
	
.yNoCollision:
	pop de
	ld b, d
	ld c, h
	xor a
	
.yCollided:
	
	ret

GetOverlappingTile:

;parameters
; bc - yx position

;returns
; a - tile

;preserves
; bc

	ld hl, Map

	ld a, b
	and $F8
	sub $10
	rlc a
	rlc a
	ld d, a
	
	and $FC
	ld e, c
	srl e
	srl e
	srl e
	add e
	dec a
	add l
	ld l, a
	
	ld a, d
	adc $00
	and $07
	add h
	ld h, a
	
	ld a, [hl]
	ret

ENDC