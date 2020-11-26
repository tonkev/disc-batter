IF !DEF(SFX)
SFX SET 1

INCLUDE "src/updates.asm"

SECTION "SFX Code", ROM0

SFXSetup:
	
	ld a, $FF
	ld [rNR50], a
	ld [rNR51], a
	
	ld a, $8F
	ld [rNR52], a
	
	ret
	
PlayDeath:
	ld a, $3A
	ld [rNR41], a
	ld a, $A3
	ld [rNR42], a
	ld a, $27
	ld [rNR43], a
	ld a, $80
	ld [rNR44], a
	ret

PlayBonk:
	ld a, $14
	ld [rNR10], a
	ld a, $82
	ld [rNR11], a
	ld a, $64
	ld [rNR12], a
	ld a, $4C
	ld [rNR13], a
	ld a, $84
	ld [rNR14], a
	ret
	
PlayCharge:
	ld a, $3A
	ld [rNR41], a
	ld a, $75
	ld [rNR42], a
	ld a, $7A
	ld [rNR43], a
	ld a, $80
	ld [rNR44], a
	ret


ENDC