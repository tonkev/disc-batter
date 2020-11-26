IF !DEF(PLAYER)
PLAYER SET 1

INCLUDE "src/utilities.asm"
INCLUDE "src/metasprites.asm"
INCLUDE "src/updates.asm"
INCLUDE "src/input.asm"
INCLUDE "src/map.asm"
INCLUDE "src/main.asm"

PLAYER_ACC SET $02
PLAYER_MAX_SPEED SET $08
PLAYER_MAX_NEG_SPEED SET $F8
PLAYER_MAX_DIAG_SPEED SET $06
PLAYER_MAX_NEG_DIAG_SPEED SET $FA

PLAYER_W SET 5
PLAYER_H SET 8

SECTION "Player Tiles", ROM0

PlayerTiles:
INCLUDE "spr/player.z80"
PlayerTilesEnd:

PlayerTilesMap:
INCLUDE "spr/player_map.z80"
PlayerTilesMapEnd:

PlayerMSOffset1:
DB -5, -4
PlayerMSOffset2:
DB -6, -4

SECTION "Player Tiles RAM", VRAM[$8010]

PlayerTilesVRAM:
DS PlayerTilesEnd - PlayerTiles

SECTION "Player Vars", WRAM0

PlayerVY:
DS 1
PlayerVX:
DS 1
PlayerY:
DS 1
PlayerX:
DS 1
PlayerY2:
DS 1
PlayerX2:
DS 1

SECTION "Player Setup", ROM0

PlayerSetup:
	
	ld hl, PlayerTilesVRAM
	ld de, PlayerTiles
	ld bc, PlayerTilesEnd - PlayerTiles
	call CopyMemory
	
	xor a
	ld [PlayerVY], a
	ld [PlayerVX], a
	ld [PlayerY2], a
	ld [PlayerX2], a
	
	ld a, 128 - 32
	ld [PlayerY], a
	ld a, 128
	ld [PlayerX], a
	
	ld c, 1
	call NewMetasprite
	
	ld e, b
	ld a, $40
	call SetMetaspriteAnimationState	
	
	ld e, b
	ld hl, PlayerMSOffset1
	call SetMetaspriteOffsets
	
	ld hl, PlayerUpdate
	ld e, b
	call RegisterUpdateCall
	
	ret

SECTION "Player Update", ROM0

;e - MetaspriteID

PlayerUpdate:

	push de

	ld a, [Dead]
	cp $00
	ld a, $04
	jr nz, .dead	
	call GetMetaspriteAnimationFrame
.dead
	ld b, e
	ld c, a
	
	ld hl, PlayerMSOffset1
	bit 0, a
	jr z, .animEven
	ld hl, PlayerMSOffset2
.animEven
	call SetMetaspriteOffsets
	
	ld e, b
	ld hl, PlayerTilesMap
	ld a, c
	add l
	ld l, a
	ld a, h
	adc 0
	ld h, a
	call SetMetaspriteTiles
	
	ld b, PLAYER_ACC
	ld c, PLAYER_MAX_SPEED
	ld l, PLAYER_MAX_NEG_SPEED
	
	ld a, [Paused]
	cp $00
	ld a, $00
	jr nz, .paused 
	
	ld a, [IsPressed]
.paused:
	
	ld h, a
	and $30
	jr z, .notPressingHorizontal
	
	ld a, $C0
	and h
	jr z, .notPressingVertical
	
	;sra b
	ld c, PLAYER_MAX_DIAG_SPEED
	ld l, PLAYER_MAX_NEG_DIAG_SPEED
	
.notPressingHorizontal:
.notPressingVertical:
	
	ld a, [PlayerVY]
	ld d, a
	ld a, [PlayerVX]
	ld e, a
	
	ld a, h ;IsPressed
	bit 5, a
	jr z, .notPressingLeft
	
	ld a, e
	sub b
	cp l
	jr nc, .dontClampVX
	
	ld a, l
	
	jr .pressedLeft
	
.notPressingLeft:

	bit 4, a
	jr z, .notPressingRight
	
	ld a, e
	add b
	cp c
	jr c, .dontClampVX
	
	ld a, c
	
	jr .pressedRight
	
.notPressingRight:

	ld a, e
	bit 7, a
	jr nz, .positiveVX
	
	add b
	bit 7, a
	jr nz, .dontZeroVX
	
	jr .zeroVX
	
.positiveVX:

	sub b
	bit 7, a
	jr z, .dontZeroVX
	
.zeroVX:
	
	xor a
	
.dontClampVX:
.pressedLeft:
.pressedRight:
.dontZeroVX:

	ld e, a
	
	ld a, h ;IsPressed
	bit 6, a
	jr z, .notPressingUp
	
	ld a, d
	sub b
	cp l
	jr nc, .dontClampVY
	
	ld a, l
	
	jr .pressedUp
	
.notPressingUp:

	bit 7, a
	jr z, .notPressingDown
	
	ld a, d
	add b
	cp c
	jr c, .dontClampVY
	
	ld a, c
	
	jr .pressedDown
	
.notPressingDown:

	ld a, d
	bit 7, a
	jr nz, .positiveVY
	
	add b
	bit 7, a
	jr nz, .dontZeroVY
	
	jr .zeroVY
	
.positiveVY:

	sub b
	bit 7, a
	jr z, .dontZeroVY
	
.zeroVY:
	
	xor a
	
.dontClampVY:
.pressedUp:
.pressedDown:
.dontZeroVY:

	ld d, a
	
	;ld a, d
	ld [PlayerVY], a
	ld a, e
	ld [PlayerVX], a
	
	ld b, d
	ld c, e
	
	sra d
	sra d
	sra e
	sra e
	
	ld a, $03
	and b
	rrc a
	rrc a
	ld b, a
	
	ld a, $03
	and c
	rrc a
	rrc a
	ld c, a
	
	ld a, [PlayerY2]
	add b
	ld [PlayerY2], a
	
	ld a, [PlayerY]
	adc d
	ld b, a
	
	ld a, [PlayerX2]
	add c
	ld [PlayerX2], a
	
	ld a, [PlayerX]
	adc e
	ld c, a
	
	ld a, b
	cp MAP_YA
	jr nc, .yLargerThanMin
	ld a, MAP_YA
.yLargerThanMin:
	cp MAP_YB - 3
	jr c, .ySmallerThanMax
	ld a, MAP_YB - 3 
.ySmallerThanMax:
	ld b, a
	ld [PlayerY], a
	
	ld a, [ScrollY]
	ld d, a
	ld a, b
	sub d
	add $10
	ld b, a
	
	ld a, c	
	cp MAP_XA
	jr nc, .xLargerThanMin
	ld a, MAP_XA
.xLargerThanMin:
	cp MAP_XB
	jr c, .xSmallerThanMax
	ld a, MAP_XB
.xSmallerThanMax:
	ld c, a
	ld [PlayerX], a
	
	ld a, [ScrollX]
	ld e, a
	ld a, c
	sub e
	add $08
	ld c, a
	
	ld a, [Dead]
	cp $00
	jr nz, .unpaused
	ld a, [Paused]
	cp $00
	jr z, .unpaused
	ld bc, $0000
.unpaused:

	pop hl
	call MoveMetasprite

	ret
	
ENDC