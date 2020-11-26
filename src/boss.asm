IF !DEF(BOSS)
BOSS SET 1

INCLUDE "src/utilities.asm"
INCLUDE "src/metasprites.asm"
INCLUDE "src/updates.asm"
INCLUDE "src/player.asm"
INCLUDE "src/input.asm"
INCLUDE "src/main.asm"
INCLUDE "src/scroll.asm"
INCLUDE "src/sfx.asm"

BOSS_WAIT_COOLDOWN SET $10
BOSS_ATTACK_COOLDOWN SET $FF
BOSS_ROAM_SPEED SET 2
BOSS_ATTACK_SPEED SET 4

SECTION "Boss Tiles", ROM0

BossTiles:
INCLUDE "spr/boss.z80"
BossTilesEnd:

BossTilesMap:
INCLUDE "spr/boss_map.z80"
BossTilesMapEnd:

BossMSOffsets:
DB -12, -12, -12, -4, -12, 4
DB  -4, -12,  -4, -4,  -4, 4
DB   4, -12,   4, -4,   4, 4

SECTION "Boss Tiles RAM", VRAM[$8160]

BossTilesVRAM:
DS BossTilesEnd - BossTiles

SECTION "Boss Vars", WRAM0

BossState: ;0 - sleeping 1 - awake 2 - waiting 3 - angry
DS 1
BossTimer:
DS 1
BossY:
DS 1
BossX:
DS 1
BossVY:
DS 1
BossVX:
DS 1

SECTION "Boss Setup", ROM0

BossSetup:
	
	ld hl, BossTilesVRAM
	ld de, BossTiles
	ld bc, BossTilesEnd - BossTiles
	call CopyMemory
	
	xor a
	ld [BossState], a
	
	ld a, BOSS_ATTACK_COOLDOWN
	ld [BossTimer], a
	
	ld a, MAP_YA - 16
	ld [BossY], a
	ld a, $80
	ld [BossX], a
	
	xor a
	ld [BossVY], a
	ld a, -BOSS_ROAM_SPEED
	ld [BossVX], a
	
	ld c, 9
	call NewMetasprite
	
	ld e, b
	ld a, $10
	call SetMetaspriteAnimationState	
	
	ld b, e
	ld hl, BossMSOffsets
	call SetMetaspriteOffsets
	
	ld e, b
	ld h, $00
	call SetMetaspriteOAMFlag
	
	ld e, b
	ld hl, BossTilesMap
	call SetMetaspriteTiles
	
	ld e, b
	ld hl, BossUpdate
	call RegisterUpdateCall
	
	ret

SECTION "Boss Update", ROM0

;e - MetaspriteID

BossUpdate:

	ld l, e
	
	ld a, [BossTimer]
	sub 1
	jr c, .timerZero
	ld [BossTimer], a
	jr .timerNZ
.timerZero:
	ld a, [BossState]
	cp $00
	jr nz, .timerNZ
	ld a, $01
	ld [BossState], a
.timerNZ:
	
	ld a, [BossState]
	cp $02
	jp z, .bossWaiting
	
	ld a, [BossVY]
	ld d, a	
	ld a, [BossY]
	add d
	ld b, a
	
	ld a, [BossVX]
	ld e, a	
	ld a, [BossX]
	add e
	ld c, a
	
	ld a, b
	cp MAP_YA - 16
	jr nc, .yLargerThanMinWH	
	ld b, MAP_YA - 16 + 1
	ld d, 0
	ld e, -BOSS_ROAM_SPEED
	jr .clamped
.yLargerThanMinWH:
	cp MAP_YB + 16
	jr c, .ySmallerThanMaxWH
	ld b, MAP_YB + 16 - 1
	ld d, 0
	ld e, BOSS_ROAM_SPEED
	jr .clamped
.ySmallerThanMaxWH:
	
	ld a, c
	cp MAP_XA - 16
	jr nc, .xLargerThanMinWH
	ld c, MAP_XA - 16 + 1
	ld d, BOSS_ROAM_SPEED
	ld e, 0
	jr .clamped
.xLargerThanMinWH:
	cp MAP_XB + 16
	jr c, .xSmallerThanMaxWH
	ld c, MAP_XB + 16 - 1
	ld d, -BOSS_ROAM_SPEED
	ld e, 0
	
.clamped:
	ld a, [BossTimer]
	cp $00
	ld a, $01
	jr z, .clampedAwake
	xor a
.clampedAwake:
	ld [BossState], a	
	
.xSmallerThanMaxWH:

	ld a, b
	ld [BossY], a
	ld a, c
	ld [BossX], a
	ld a, d
	ld [BossVY], a
	ld a, e
	ld [BossVX], a
	
	ld a, [Paused]
	cp $00
	jp nz, .paused
	
	ld a, [PlayerY]
	sub b
	jr c, .belowPlayer
	cp 14
	jr nc, .notHittingPlayer
	jr .hittingPlayerY
.belowPlayer:
	cp -11
	jr c, .notHittingPlayer
	
.hittingPlayerY:
	ld a, [PlayerX]
	sub c
	jr c, .rightOfPlayer
	cp 10
	jr nc, .notHittingPlayer
	jr .hittingPlayer
.rightOfPlayer:
	cp -9
	jr c, .notHittingPlayer
	
.hittingPlayer:
	call PlayDeath
	
	call SaveBest
	
	ld a, $01
	ld [Paused], a
	ld [Dead], a
	ld a, $08
	call AddSkipFrames
	ld a, $08
	call AddShake
	ret
	
.notHittingPlayer:

	ld a, [BossTimer]
	cp $00
	jr nz, .attackOnCooldown
	
	ld a, d
	cp $00
	jr z, .yStationary
	
	ld d, $00
	ld e, 4
	ld a, [PlayerX]
	sub c
	jr nc, .atkXLeftOfPlayer
	ld e, -4
.atkXLeftOfPlayer:

	ld a, [PlayerY]
	sub b
	jr c, .atkXBelowPlayer
	cp 5
	jr nc, .notHittingPlayerPossible
	jr .hittingPlayerPossible
.atkXBelowPlayer:
	cp -4
	jr c, .notHittingPlayerPossible
	jr .hittingPlayerPossible
	
.yStationary:

	ld e, $00
	ld d, 4
	ld a, [PlayerY]
	sub b
	jr nc, .atkYAbovePlayer
	ld d, -4
.atkYAbovePlayer:

	ld a, [PlayerX]
	sub c
	jr c, .atkYBelowPlayer
	cp 5
	jr nc, .notHittingPlayerPossible
	jr .hittingPlayerPossible
.atkYBelowPlayer:
	cp -4
	jr c, .notHittingPlayerPossible
	
.hittingPlayerPossible:
	call PlayCharge
	
	ld a, d
	ld [BossVY], a
	ld a, e
	ld [BossVX], a
	ld a, BOSS_WAIT_COOLDOWN
	ld [BossTimer], a
	ld a, $02
	ld [BossState], a
	
.notHittingPlayerPossible
.attackOnCooldown:
.waitingReturn:
.paused:
	
	ld a, [ScrollY]
	ld d, a
	ld a, [ScrollX]
	ld e, a
	
	ld a, b
	sub d
	jr nc, .largerThanSCY
	xor a
.largerThanSCY:
	cp 144
	jr c, .smallerThanSCY2
	ld a, 144
.smallerThanSCY2:
	add $10
	ld b, a
	
	ld a, c
	sub e
	jr nc, .largerThanSCX
	xor a
.largerThanSCX:
	cp 160
	jr c, .smallerThanSCX2
	ld a, 160
.smallerThanSCX2:
	add $08
	ld c, a
	
	ld e, l
	push hl
	ld hl, BossTilesMap + 18
	ld a, [BossState]
	cp $00
	jr z, .sleep
	ld hl, BossTilesMap
	cp $01
	jr z, .awake
	ld hl, BossTilesMap + 9
	cp $02
	jr z, .waiting
	push bc
	ld a, $01
	call AddShake
	pop bc
.sleep:
.awake:
.waiting:
	call SetMetaspriteTiles
	pop hl
	
	call MoveMetasprite

	ret
	
.bossWaiting:

	ld a, [BossY]
	ld b, a
	ld a, [BossX]
	ld c, a
	
	ld a, [BossTimer]
	cp $00
	jr z, .waitCooldownOver
	
	jp .waitingReturn
	
.waitCooldownOver:
	ld a, $03
	ld [BossState], a
	ld a, BOSS_ATTACK_COOLDOWN
	ld [BossTimer], a
	
	jp .waitingReturn
	
ENDC