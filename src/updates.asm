IF !DEF(UPDATES)
UPDATES SET 1

INCLUDE "inc/hardware.inc"
INCLUDE "src/utilities.asm"
INCLUDE "src/updates.asm"

SECTION "Update Table", WRAM0[$C000]

UpdateTable:
	DS 4*64
UpdateTableEnd:

SECTION "Updates Setup", ROM0

UpdatesSetup:

.clearUpdateTable:
	ld hl, UpdateTable
	ld bc, UpdateTableEnd - UpdateTable
	ld a, $E0; inaccessible area -> signifies free row
	call ClearMemory

	ret

SECTION "Register Update Call", ROM0

RegisterUpdateCall:

;parameters
;hl - address to be called per frame
;de - data for context

	push de
	push hl

	ld hl, UpdateTable
	ld bc, $0400
	ld d, $E0
	call SearchMemory
	
	pop de
	ld a, d
	ld [hli], a
	ld a, e
	ld [hli], a
	pop de
	ld a, d
	ld [hli], a
	ld a, e
	ld [hl], a
	
	ret

SECTION "Remove This Update Call", ROM0

RemoveThisUpdateCall:

;To be called only from update routine - no deeper levels

	ld hl, sp+4
	ld a, [hl]
	sub $04
	
	ld h, $C0
	ld l, a
	
	ld a, $E0
	ld [hl], a
	ret

SECTION "Update All", ROM0

UpdateAll:

	ld hl, UpdateTable
.loop:
	ld a, h
	cp $C1;ASSUMING UpdateTable ends at C100
	ret z

	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld e, a
	
	ld a, b
	cp $E0
	jr z, .loop
	
	push hl
	ld hl, .return
	push hl
	ld h, b
	ld l, c
	jp hl
	
.return:
	pop hl
	jr .loop

ENDC