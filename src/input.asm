IF !DEF(INPUT)
INPUT SET 1

INCLUDE "inc/hardware.inc"
INCLUDE "src/updates.asm"

SECTION "Input Vars", WRAM0

; d u l r start select b a

IsPressed:
	DS 1
JustPressed:
	DS 1
JustReleased:
	DS 1

SECTION "Input Setup", ROM0

InputSetup:
	
	xor a
	ld [IsPressed], a
	ld [JustPressed], a
	ld [JustReleased], a
	
	ld hl, UpdateInput
	call RegisterUpdateCall
	
	ret

SECTION "Update Input", ROM0

UpdateInput:
	
	ld a, $20
	ld [rP1], a
	ld a, [rP1]
	ld a, [rP1]
	
	and $0F
	ld d, a
	swap d
	
	ld a, $10
	ld [rP1], a
	ld a, [rP1]
	ld a, [rP1]
	
	and $0F
	or d
	xor $FF
	ld d, a
	
	ld a, [IsPressed]
	ld e, a
	
	xor d	
	and d	
	ld [JustPressed], a
	
	ld a, e
	xor d
	and e
	ld [JustReleased], a
	
	ld a, d
	ld [IsPressed], a
	
	ret

ENDC