INCLUDE "src/utilities.asm"
INCLUDE "src/metasprites.asm"
INCLUDE "src/updates.asm"
INCLUDE "src/player.asm"
INCLUDE "src/bat.asm"
INCLUDE "src/map.asm"
INCLUDE "src/main.asm"
INCLUDE "src/scroll.asm"
INCLUDE "src/sfx.asm"

DISC_SPAWN_TIME SET $40
DISC_SPEED SET 8
DISC_RADIUS SET 8

SECTION "Disc Tiles", ROM0

DiscTiles:
INCLUDE "spr/disc1.z80"
DiscTilesEnd:

DiscTilesMap:
INCLUDE "spr/disc1_map.z80"
DiscTilesMapEnd:

DiscTileOffsets:
DB $F9, $F9, $F9, $01, $01, $F9, $01, $01

SECTION "Disc Table", WRAM0[$C300]

;DiscTableEntry - Each Metasprite a LinkedList
;--------------------
;DiscState	0 - empty 1 - standard 2 - wallhugger 3 - projectile
;DiscTimer
;DiscVY
;DiscY
;DiscY2
;DiscVX
;DiscX
;DiscX2
;DiscMS

DiscTable:
	DS 9*8
DiscTableEnd:

SECTION "Disc Tiles RAM", VRAM[$8060]

DiscTilesVRAM:
DS DiscTilesEnd - DiscTiles

SECTION "Disc Vars", WRAM0

DiscTimerEncountered:
	DS 1

SECTION "Discs Setup", ROM0

DiscsSetup:
	
	ld hl, DiscTilesVRAM
	ld de, DiscTiles
	ld bc, DiscTilesEnd - DiscTiles
	call CopyMemory
	
	ld hl, DiscTable
	ld bc, DiscTableEnd-DiscTable
	xor a
	call ClearMemory
	
	ld hl, DiscsUpdate
	call RegisterUpdateCall
	
	ret

SECTION "Discs Update", ROM0

DiscsUpdate:
	
	ld hl, DiscTable
	
	xor a
	ld [DiscTimerEncountered], a
	
.loop:
	ld a, [DiscCount]
	ld c, a
	xor a
.multiLoop:
	add 9
	dec c
	jr nz, .multiLoop
	
	cp l
	ret z
	ret c

	ld a, [hl]
	cp $00
	jp z, .discEmpty
	ld b, a
	
	inc hl
	ld a, [hl]
	cp $00
	jp nz, .timerNotZero
	inc hl
	
	ld a, b
	cp $02
	jp z, .wallHugger
	
	cp $03
	jp z, .projectile
	
	ld a, [hli]
	ld d, a
	
	push de	
	and $FD
	sra a
	sra a
	ld b, a
	
	ld a, d
	and $03
	rrca
	rrca
	ld d, a
    
	ld a, [hl]
	add d
	ld [hli], a
	
	ld a, [hld]
	adc b
	ld b, a	
	pop de
    dec hl 
	
	cp MAP_YA
	jr nc, .yLargerThanMin
	xor a
	sub d
	ld d, a
	ld a, MAP_YA
.yLargerThanMin:
	cp MAP_YB
	jr c, .ySmallerThanMax
	xor a
	sub d
	ld d, a
	ld a, MAP_YB
.ySmallerThanMax:
	ld b, a
	ld a, d
	ld [hli], a
	inc hl
	ld a, b
	ld [hli], a
	
	ld a, [hli]
	ld e, a
	
	push de	
	and $FD
	sra a
	sra a
	ld c, a
	
	ld a, e
	and $03
	rrca
	rrca
	ld e, a
    
	ld a, [hl]
	add e
	ld [hli], a
	
	ld a, [hld]
	adc c
	ld c, a	
	pop de
	dec hl
	
	cp MAP_XA
	jr nc, .xLargerThanMin
	xor a
	sub e
	ld e, a
	ld a, MAP_XA
.xLargerThanMin:
	cp MAP_XB
	jr c, .xSmallerThanMax
	xor a
	sub e
	ld e, a
	ld a, MAP_XB
.xSmallerThanMax:
	ld c, a
	ld a, e
	ld [hli], a
	inc hl
	ld a, c
	ld [hli], a
	
.wallHuggerReturn:

	ld a, [Paused]
	cp $00
	jp nz, .paused
	
	ld a, [PlayerY]
	sub b
	jr c, .belowPlayer
	cp 9
	jr nc, .notHittingPlayer
	jr .hittingPlayerY
.belowPlayer:
	cp -6
	jr c, .notHittingPlayer
	
.hittingPlayerY:
	ld a, [PlayerX]
	sub c
	jr c, .rightOfPlayer
	cp 5
	jr nc, .notHittingPlayer
	jr .hittingPlayer
.rightOfPlayer:
	cp -4
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

	ld a, [BatActive]
	cp $00
	jr z, .batInactive

	ld a, [PlayerY]
	sub b
	jr c, .belowBat
	cp 18
	jr nc, .notHittingBat
	jr .hittingBatY
.belowBat:
	cp -15
	jr c, .notHittingBat
	
.hittingBatY:
	ld a, [PlayerX]
	sub c
	jr c, .rightOfBat
	cp 14
	jr nc, .notHittingBat
	jr .hittingBat
.rightOfBat:
	cp -13
	jr c, .notHittingBat
	
.hittingBat:
	call PlayBonk
	
	push bc
	ld a, $04
	call AddSkipFrames
	ld a, $08
	call AddShake
	pop bc
	
	push hl
	ld a, [hl]
	ld e, a
	ld h, $10
	call SetMetaspriteOAMFlag
	pop hl

	ld a, l
	sub 8
	ld l, a
	
	ld a, $03
	ld [hli], a
	inc hl
	
	ld a, [PlayerVY]
	sla a
	ld d, a
	ld a, [PlayerVX]
	sla a
	ld e, a
	
	jr nz, .playerVNZ
	ld a, d
	cp $00
	jr nz, .playerVNZ
	
	ld a, [hl]
	ld d, a
	sub d
	sub d
	sla a
	ld [hli], a
	inc l
	inc l
	ld a, [hl]
	sla a
	ld e, a
	ld a, d
	cp $00
	jr nz, .syZ
	xor a
	sub e
	ld e, a
.syZ
	ld a, e
	ld [hli], a
	inc l
	inc l
	jr .playerVZ
	
.playerVNZ:
	ld a, d
	ld [hli], a
	inc hl
	inc hl
	ld a, e
	ld [hli], a
	inc hl
	inc hl
	
.playerVZ:
	
.notHittingBat:
.batInactive:
	

.timerReturn:

.projectileReturn:

.paused:

	ld a, b
	add $10
	ld b, a
	ld a, [ScrollY]
	ld d, a
	ld a, b
	sub d
	ld b, a
	
	ld a, c
	add $08
	ld c, a
	ld a, [ScrollX]
	ld e, a
	ld a, c
	sub e
	ld c, a
	
	ld a, [hli]
	push hl
	push bc
	ld b, a
	
	ld e, a
	call GetMetaspriteAnimationFrame
	sla a
	sla a
	ld hl, DiscTilesMap
	add l
	ld l, a
	ld a, h
	adc 0
	ld h, a
	call SetMetaspriteTiles
	
	ld l, b
	pop bc
	call MoveMetasprite
	
	pop hl
	
	jp .loop
	
.timerNotZero:

	ld d, $00
	ld b, a
	ld a, [DiscTimerEncountered]
	cp $00
	jr nz, .timerEncountered
	dec b
	jr nz, .timerNotZero2
	ld d, $01
.timerNotZero2
	ld a, $01
	ld [DiscTimerEncountered], a
.timerEncountered
	
	ld a, b
	ld [hli], a
	inc hl
	inc hl
	ld a, [hli]
	ld b, a
	inc hl
	inc hl
	ld a, [hli]
	ld c, a
	
	ld a, d
	cp $00
	jr z, .timerReturn
	
	ld a, [hl]
	ld e, a
	push hl
	ld h, $00
	call SetMetaspriteOAMFlag
	pop hl
	
	jr .timerReturn

.discEmpty:
	push hl
	call FillDisc
	pop hl
	ld a, $09
	add l
	ld l, a
	jp .loop

.wallHugger:
	ld a, [hli]
	ld d, a
	
	push de
	
	and $FD
	sra a
	sra a
	ld b, a
	
	ld a, d
	and $03
	rrca
	rrca
	ld d, a
    
	ld a, [hl]
	add d
	ld [hli], a
	
	ld a, [hli]
	adc b
	ld b, a
	
	pop de
	
	cp MAP_YA
	jr nc, .yLargerThanMinWH	
	ld b, MAP_YA
	ld d, 0
	ld a, [DiscSpeed]
	ld e, a
	jr .exitWH1
.yLargerThanMinWH:
	cp MAP_YB
	jr c, .ySmallerThanMaxWH
	ld b, MAP_YB - 1
	ld d, 0
	ld a, [DiscSpeed]
	ld e, a
	sub e
	sub e
	ld e, a
	jr .exitWH1
.ySmallerThanMaxWH:
	
	ld a, [hli]
	ld e, a
	
	push de
	
	and $FD
	sra a
	sra a
	ld c, a
	
	ld a, e
	and $03
	rrca
	rrca
	ld e, a
    
	ld a, [hl]
	add e
	ld [hli], a
	
	ld a, [hl]
	adc c
	ld c, a
	
	pop de
	
	cp MAP_XA
	jr nc, .xLargerThanMinWH
	ld c, MAP_XA
	ld a, [DiscSpeed]
	ld d, a
	sub d
	sub d
	ld d, a
	ld e, 0
	jr .exitWH2
.xLargerThanMinWH:
	cp MAP_XB
	jr c, .xSmallerThanMaxWH
	ld c, MAP_XB - 1
	ld a, [DiscSpeed]
	ld d, a
	ld e, 0
.xSmallerThanMaxWH:
	jr .exitWH2

.exitWH1:
	inc hl
	inc hl
	ld a, [hl]
	ld c, a
	ld a, e
	and $FD
	sra a
	sra a
	add c
	ld c, a

.exitWH2:
	ld a, c
	ld [hld], a
	dec hl
	ld a, e
	ld [hld], a
	ld a, b
	ld [hld], a
	dec hl
	ld a, d
	ld [hl], a
	
	ld a, 6
	add l
	ld l, a
	
	jp .wallHuggerReturn
	
.projectile

	ld a, [hli]
	ld d, a
	
	push de	
	and $FD
	sra a
	sra a
	ld b, a
	
	ld a, d
	and $03
	rrca
	rrca
	ld d, a
    
	ld a, [hl]
	add d
	ld [hli], a
	
	ld a, [hl]
	adc b
	ld b, a	
	ld [hli], a
	pop de
	
	bit 7, d
	jr z, .dPositive
	jr nc, .projectileYBorder
	jr .dNegative
.dPositive:
	jr c, .projectileYBorder
.dNegative:
	
	ld a, [hli]
	ld e, a
	
	push de	
	and $FD
	sra a
	sra a
	ld c, a
	
	ld a, e
	and $03
	rrca
	rrca
	ld e, a
    
	ld a, [hl]
	add e
	ld [hli], a
	
	ld a, [hl]
	adc c
	ld c, a	
	pop de
	ld [hli], a
	
	bit 7, e
	jr z, .ePositive
	jr nc, .projectileXBorder
	jr .projectileContinue
.ePositive:
	jr c, .projectileXBorder
	
.projectileContinue:
	jp .projectileReturn
	
.projectileYBorder:
	inc l
	inc l
	inc l

.projectileXBorder:
	ld a, [hl]
	ld e, a
	push hl
	call RemoveMetasprite
	pop hl
	
	ld a, l
	sub 8
	ld l, a
	xor a
	ld [hl], a
	
	ld a, l
	add 9
	ld l, a
	
	jp .loop
	
	
SECTION "New Disc", ROM0

NewDisc:

	ld hl, DiscTable
	
.loop:
	ld a, l
	cp $3B
	ret nc

	ld a, [hl]
	cp $00
	jr z, FillDisc
	
	ld a, $07
	add l
	ld l, a 
	jr .loop
	
FillDisc:
	ld b, $01
    ld a, l
    cp $00
    jr nz, .notWallhugger
    ld b, $02
.notWallhugger:
    ld a, b
	ld [hli], a
	
	ld a, DISC_SPAWN_TIME
	ld [hli], a
	
	ld a, [DiscSpeed]
	ld d, a
	ld e, a
	
    ld a, [rDIV]
    ld c, a
    and $01
    jr z, .positiveVY
	xor a
	sub d
	ld d, a
.positiveVY:

    ld a, $04
    and c
    jr z, .notHalfVY
    sra d
.notHalfVY:

    ld a, d
	ld [hli], a
	
	xor a
	ld [hli], a
	ld a, 128
	ld [hli], a
	
    ld a, $02
    and c
    jr z, .positiveVX
	xor a
	sub e
	ld e, a
.positiveVX:

    ld a, $08
    and c
    jr z, .notHalfVX
    sra e
.notHalfVX:

	ld a, e
	ld [hli], a
	
	xor a
	ld [hli], a
	ld a, 128
	ld [hli], a
	
	push hl
	
	ld c, 4
	call NewMetasprite
	
	ld e, b
	ld a, $30
	call SetMetaspriteAnimationState	
	
	ld e, b
	ld hl, DiscTileOffsets
	call SetMetaspriteOffsets
	
	ld e, b
	ld h, $10
	call SetMetaspriteOAMFlag
	
	ld a, b
	pop hl
	ld [hl], a
	
	ret