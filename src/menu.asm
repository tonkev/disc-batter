IF !DEF(MENU)
MENU SET 1

INCLUDE "src/utilities.asm"
INCLUDE "src/updates.asm"
INCLUDE "src/input.asm"
INCLUDE "src/ui.asm"
INCLUDE "src/main.asm"
INCLUDE "src/sfx.asm"

SECTION "Menu Strings", ROM0

DiscBatter:
DB "DISC  BATTER", 0
Best:
DB "BEST", 0
Last:
DB "LAST", 0
Time:
DB "  :  :  ", 0
Instructions0:
DB "DOWN : OPTIONS", 0
Instructions1:
DB "A : START", 0
NoOfDiscs:
DB "NO OF DISCS : ", 0
DiscsSpeed:
DB "DISC SPEED : ", 0
EnabledBigDisc:
DB "BIG DISC ENABLED : ", 0
EnabledBat:
DB "BAT ENABLED : ", 0

SECTION "Menu Vars", WRAM0

MenuState:
DS 1

SECTION "Menu Setup", ROM0

MenuSetup:
	xor a
	ld [MenuState], a
	
	ld hl, Time
	ld de, _SCRN1 + (32 * 0) + 1
	call DrawText
	
	ld hl, Time
	ld de, _SCRN1 + (32 * 0) + 11
	call DrawText
	
	ld hl, Last
	ld de, _SCRN1 + (32 * 1) + 3
	call DrawText
	
	ld hl, Best
	ld de, _SCRN1 + (32 * 1) + 13
	call DrawText
	
	ld hl, DiscBatter
	ld de, _SCRN1 + (32 * 2) + 4
	call DrawText
	
	ld hl, NoOfDiscs
	ld de, _SCRN1 + (32 * 4) + 2
	call DrawText
	
	ld hl, DiscsSpeed
	ld de, _SCRN1 + (32 * 5) + 3
	call DrawText
	
	ld a, 7
	ld [rWX], a
	
	ld hl, MenuUpdate
	call RegisterUpdateCall
	
	ret

SECTION "Menu Update", ROM0

MenuUpdate:

	ld a, [Paused]
	cp $00
	ld a, 136
	jp z, .unpaused
	
	ld a, [JustPressed]
	ld b, a
	and $09
	jr z, .stillPaused
	
	call PlayBonk
	
	ld a, [Dead]
	cp $00
	jr z, .notDead
	
	jp Restart
	
.stillPaused:
	
	ld a, [MenuState]
	ld c, a
	
	ld a, $84
	and b
	jr z, .notDown
	inc c
.notDown:
	ld a, $40
	and b
	jr z, .notUp
	dec c
.notUp:
	ld a, $FF
	cp c
	jr nz, .notFF
	ld c, $02
.notFF:
	ld a, $03
	cp c
	jr nz, .not03
	ld c, $00
.not03
	ld a, c
	ld [MenuState], a
	
	cp $00
	jr z, .defState
	cp $01
	jr z, .noState
	
	ld a, [DiscSpeed]
	ld c, a
	ld a, $20
	and b
	jr z, .notLeft1
	dec c
.notLeft1:
	ld a, $10
	and b
	jr z, .notRight1
	inc c
.notRight1:
	
	ld a, $01
	cp c
	jr nz, .notSmall1
	ld c, $02
.notSmall1
	ld a, $09
	cp c
	jr nz, .notLarge1
	ld c, $08
.notLarge1
	ld a, c
	ld [DiscSpeed], a
	jr .retState
	
.noState:
	ld a, [DiscCount]
	ld c, a
	ld a, $20
	and b
	jr z, .notLeft2
	dec c
.notLeft2:
	ld a, $10
	and b
	jr z, .notRight2
	inc c
.notRight2:
	
	ld a, $02
	cp c
	jr nz, .notSmall2
	ld c, $03
.notSmall2
	ld a, $08
	cp c
	jr nz, .notLarge2
	ld c, $07
.notLarge2
	ld a, c
	ld [DiscCount], a
	jr .retState
	
.notDead:
	xor a
	ld [Paused], a
	
.retState:
	ld a, $30
	and b
	jr z, .defState
	
.defState:
	ld a, 96;120;112
.unpaused:
	ld [rWY], a

	ret
	
ENDC