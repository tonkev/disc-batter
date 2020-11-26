IF !DEF(UTILITIES)
UTILITIES SET 1

INCLUDE "inc/hardware.inc"

SECTION "Wait V-Blank", ROM0

WaitVBlank:
	ld a, [rLY]
	cp 144
	jr nz, WaitVBlank
	ret

SECTION "Turn Off LCD", ROM0

TurnOffLCD:
	call WaitVBlank
	
	ld a, [rLCDC]
	and $7F
	ld [rLCDC], a
	
	ret

SECTION "Turn On LCD", ROM0
	
TurnOnLCD:	
	ld a, [rLCDC]
	or $80
	ld [rLCDC], a
	
	ret

SECTION "Copy Following Data", ROM0

CopyFollowingData:
	pop hl
	
.loop
	
	ld a, [hli]
	ld [de], a
	
	inc de
	dec bc
	
	ld a, b
	or c
	jr nz, .loop
	
	jp hl
	ret

SECTION "Copy Memory", ROM0

;parameter
;hl - destination
;de - source
;bc - size

CopyMemory:

.loop:
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or c
	jr nz, .loop
	
	ret
	

SECTION "Clear Memory", ROM0

ClearMemory:

;parameters
;a  clear value
;bc range
;hl starting address

;preserves
;e

	ld d, a
	
.loop
	ld a, d
	ld [hli], a
	dec bc
	
	ld a, b
	or c	
	jr nz, .loop
	
	ret

SECTION "Bounded Search Memory", ROM0

BoundedSearchMemory:

;parameters
;hl start address
;b  stride
;c  index start
;d	search term
;e  size

;returns
;hl address
;c  index

;preserves
;b

.loop:
	ld a, [hl]
	cp d
	ret z
	ld a, l
	add b
	ld l, a
	xor a
	adc a, h
	inc c
	dec e
	ret z
	jr .loop
	
SECTION "Search Memory", ROM0

SearchMemory:
;UNBOUNDED SEARCH - EXPECTS TO FIND SEARCH TERM

;parameters
;hl start address
;b  stride
;c  index start
;d	search term

;returns
;hl address
;c  index

;preserves
;be

.loop:
	ld a, [hl]
	cp d
	ret z
	ld a, l
	add b
	ld l, a
	xor a
	adc a, h
	inc c
	jr .loop

SECTION "Search Memory Zero", ROM0

SearchMemoryZero:
;UNBOUNDED SEARCH - EXPECTS TO FIND SEARCH TERM

;parameters
;hl start address
;b  stride
;c  index start

;returns
;hl address
;c  index

;preserves
;bde

.loop:
	ld a, [hl]
	cp $00
	ret z
	ld a, l
	add b
	ld l, a
	xor a
	adc a, h
	inc c
	jr .loop

SECTION "Multiply", ROM0

Multiply:

;parameters
;hl term a
;a  term b

;returns
;hl result

;preserves
;bcde

	cp $00
	jr z, .zero

.loop:
	dec a
	ret z
	add hl, hl
	jr .loop

.zero:
	ld hl, $00
	ret
	
ENDC