IF !DEF(BAT)
BAT SET 1

INCLUDE "src/utilities.asm"
INCLUDE "src/metasprites.asm"
INCLUDE "src/updates.asm"
INCLUDE "src/player.asm"
INCLUDE "src/input.asm"
INCLUDE "src/scroll.asm"

BAT_COOLDOWN SET $40

SECTION "Bat Tiles", ROM0

BatTiles:
INCLUDE "spr/bat.z80"
BatTilesEnd:

BatMSOffset:
DB -7, -8

SECTION "Bat Tiles RAM", VRAM[$8120]

BatTilesVRAM:
DS BatTilesEnd - BatTiles

SECTION "Bat Vars", WRAM0

BatActive:
DS 1
BatTimer:
DS 1

SECTION "Bat Setup", ROM0

BatSetup:
	
	ld hl, BatTilesVRAM
	ld de, BatTiles
	ld bc, BatTilesEnd - BatTiles
	call CopyMemory
	
	xor a
	ld [BatActive], a
	
	ld a, BAT_COOLDOWN
	ld [BatTimer], a
	
	ld c, 1
	call NewMetasprite
	
	ld e, b
	ld a, $10
	call SetMetaspriteAnimationState	
	
	ld e, b
	ld hl, BatMSOffset
	call SetMetaspriteOffsets
	
	ld e, b
	ld h, $20
	call SetMetaspriteOAMFlag
	
	ld hl, BatUpdate
	ld e, b
	call RegisterUpdateCall
	
	ret

SECTION "Bat Update", ROM0

;e - MetaspriteID

BatUpdate:

	push de

	ld a, [BatActive]
	cp $00
	jr nz, .batActive
	
	ld a, [BatTimer]
	dec a
	jr z, .notOnCooldown
	
	ld [BatTimer], a
	pop de
	ret
	
.batActive:
	call GetMetaspriteAnimationFrame
	cp $00
	jr nz, .stillActive
	
	ld [BatActive], a
	
	ld a, BAT_COOLDOWN
	ld [BatTimer], a
	
	pop hl
	ld bc, $0000
	call MoveMetasprite
	ret

.notOnCooldown:
	ld a, [Paused]
	cp $00
	jr nz, .stillNotOnCooldown
	ld a, [JustPressed]
	and $01
	jr z, .stillNotOnCooldown
	
	ld a, $02
	call AddShake

	ld [BatActive], a
	ld a, $31
	call SetMetaspriteAnimationState
	ld a, $01
	
.stillNotOnCooldown:
.stillActive:
	add $12
	call SetMetaspriteTile
	
	ld a, [ScrollY]
	ld b, a
	ld a, [ScrollX]
	ld c, a
	
	ld a, [PlayerY]
	sub b
	add $10
	ld b, a
	ld a, [PlayerX]
	sub c
	add $08
	ld c, a
	
	ld a, [Paused]
	cp $00
	jr z, .unpaused
	ld bc, $0000
.unpaused:
	
	pop hl
	call MoveMetasprite

	ret
	
ENDC