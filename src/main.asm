IF !DEF(MAIN)
MAIN SET 1

INCLUDE "inc/hardware.inc"
INCLUDE "src/utilities.asm"
INCLUDE "src/metasprites.asm"
INCLUDE "src/updates.asm"
INCLUDE "src/input.asm"
INCLUDE "src/map.asm"
INCLUDE "src/player.asm"
INCLUDE "src/discs.asm"
INCLUDE "src/bat.asm"
INCLUDE "src/boss.asm"
INCLUDE "src/ui.asm"
INCLUDE "src/menu.asm"
INCLUDE "src/scroll.asm"
INCLUDE "src/sfx.asm"

SECTION "V-Blank Interrupt", ROM0[$40]
	jp VBlank

SECTION "LCDC Interrupt", ROM0[$48]

	reti

SECTION "Timer Interrupt", ROM0[$50]
	
	reti

SECTION "Serial Interrupt", ROM0[$58]

	reti

SECTION "P10-P13 Interrupt", ROM0[$60]

	reti
	
SECTION "VBlank", ROM0

VBlank:
	push bc
	push de
	push hl
	push af
	ld a, [SkipFrames]
	cp $00
	jr nz, .skip
	call UpdateTimes
	call DrawSettingValues
.skip:
	ld a, [ScrollY]
	ld [rSCY], a
	ld a, [ScrollX]
	ld [rSCX], a
	call FlushOAMBuffer
	pop af
	pop hl
	pop de
	pop bc
	reti
 
SECTION "Header", ROM0[$100]
 
EntryPoint:
	di
	jp Start


REPT $150 - $104
    db 0
ENDR

SaveHighscoresHI SET $A0
SECTION "Save", SRAM

SaveHighscores:
DS 4*5*6
SaveHighscoresEnd:

SaveValid:
DS 1

SaveDiscCount:
DS 1
SaveDiscSpeed:
DS 1
SaveEnableBigDisc:
DS 1
SaveEnableBat:
DS 1


SaveMS:
DS 1
SaveS:
DS 1
SaveM:
DS 1

SECTION "Game Vars", WRAM0

Paused:
DS 1
Dead:
DS 1

LastMS:
DS 1
LastS:
DS 1
LastM:
DS 1

BestMS:
DS 1
BestS:
DS 1
BestM:
DS 1

DiscCount:
DS 1
DiscSpeed:
DS 1
EnableBigDisc:
DS 1
EnableBat:
DS 1

SkipFrames:
DS 1

OddFrame:
DS 1

HighscoresHI SET $C4
SECTION "Highscores", WRAM0[$C400]

Highscores:
DS 4*5*6
HighscoresEnd:

SECTION "Game Code", ROM0

GetHighScoreLocation:
	ld a, [DiscCount]
	sub 2
	ld b, a
	ld a, [DiscSpeed]
	dec a
	ld c, a
	
	xor a
.loop1:
	dec b
	jr z, .loop2
	add 20
	jr .loop1
	
.loop2:
	dec c
	ret z
	add 4
	jr .loop2

UpdateTimes:
	
	ld b, $00
	ld a, [Paused]
	cp $00
	jr nz, .paused
	ld b, $01
.paused:

	ld a, [LastMS]
	add b
	daa
	ld e, a
	ld [LastMS], a
	
	ld a, [LastS]
	adc 0
	daa
	cp $60
	jr c, .ncS
	ld a, $00
.ncS:
	ld d, a
	ld [LastS], a
	ccf
	
	ld a, [LastM]
	adc 0
	daa
	ld [LastM], a
	
	ld b, a
	and $F0
	swap a
	add $15
	ld hl, _SCRN1 + (32 * 0) + 1
	ld [hli], a
	ld a, $0F
	and b
	add $15
	ld [hli], a
	
	inc hl
	ld a, $F0
	and d
	swap a
	add $15
	ld [hli], a
	ld a, $0F
	and d
	add $15
	ld [hli], a
	
	inc hl
	ld a, $F0
	and e
	swap a
	add $15
	ld [hli], a
	ld a, $0F
	and e
	add $15
	ld [hli], a
	
	inc hl
	inc hl
	
	ld d, HighscoresHI
	call GetHighScoreLocation
	add 2
	ld e, a
	
	ld a, [de]
	dec de
	ld b, a
	ld a, $F0
	and b
	swap a
	add $15
	ld [hli], a
	ld a, $0F
	and b
	add $15
	ld [hli], a
	
	inc hl
	ld a, [de]
	dec de
	ld b, a
	ld a, $F0
	and b
	swap a
	add $15
	ld [hli], a
	ld a, $0F
	and b
	add $15
	ld [hli], a
	
	inc hl
	ld a, [de]
	ld b, a
	ld a, $F0
	and b
	swap a
	add $15
	ld [hli], a
	ld a, $0F
	and b
	add $15
	ld [hli], a
	
	ret
	
DrawSettingValues:
	ld a, [DiscCount]
	ld b, a
	ld a, [DiscSpeed]
	ld c, a
	
	ld a, [MenuState]
	cp $00
	jr z, .ms0
	cp $01
	ld a, [OddFrame]
	jr nz, .ms2
	xor $FF
	cp $00
	jr z, .ms1
	ld b, $EB
	jr .ms1
.ms2:
	xor $FF
	cp $00
	jr z, .ms1
	ld c, $EB
.ms1:
	ld [OddFrame], a
.ms0:
	ld a, b
	add $15
	ld hl, _SCRN1 + (32 * 4) + 16
	ld [hl], a
	
	
	ld a, c
	add $14
	ld hl, _SCRN1 + (32 * 5) + 16
	ld [hl], a

	ret
	
AddSkipFrames:
; a - frames

	ld b, a
	ld a, [SkipFrames]
	cp b
	jr nc, .smaller
	ld a, b
	ld [SkipFrames], a
.smaller:
	ret

SaveBest:
	ld d, SaveHighscoresHI
	ld h, HighscoresHI
	call GetHighScoreLocation
	ld e, a
	add 2
	ld l, a

	ld a, [hld]
	ld b, a
	ld a, [LastM]
	cp b
	jr c, .smaller
	jr nz, .larger
	
	ld a, [hld]
	ld b, a
	ld a, [LastS]
	cp b
	jr c, .smaller
	jr nz, .larger
	
	ld a, [hli]
	ld b, a
	ld a, [LastMS]
	cp b
	jr c, .smaller
	
	inc l
	

	jr .larger
.smaller:
	ld a, $0A
	ld [$0000], a
	
	jr .smaller2
	
.larger:

	ld a, e
	add 2
	ld l, a

	ld a, [LastM]
	ld [hld], a
	ld a, [LastS]
	ld [hld], a
	ld a, [LastMS]
	ld [hl], a	

	ld a, $0A
	ld [$0000], a
	
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hl]
	ld [de], a
	
.smaller2:
	
	ld a, [DiscCount]
	ld [SaveDiscCount], a
	ld a, [DiscSpeed]
	ld [SaveDiscSpeed], a
	ld a, [EnableBigDisc]
	ld [SaveEnableBigDisc], a
	ld a, [EnableBat]
	ld [SaveEnableBat], a
	
	ld a, $0A
	ld [SaveValid], a
	
	ld a, $00
	ld [$0000], a
	
	ret
	
Restart:
	di
	
	ld hl, $FFFE
	ld sp, hl
	
	call TurnOffLCD
	
	call UpdatesSetup
	call MetaspritesSetup
	call InputSetup
	call MapSetup
	call PlayerSetup
	call BatSetup
	call DiscsSetup
	call BossSetup
	call UISetup
	call MenuSetup
	call ScrollSetup
	call SFXSetup
	
	xor a
	ld [Paused], a
	ld [Dead], a
	ld [LastMS], a
	ld [LastS], a
	ld [LastM], a
	
	jp restartReturn

Start:
	call TurnOffLCD
	
	call UpdatesSetup
	call MetaspritesSetup
	call InputSetup
	call MapSetup
	call PlayerSetup
	call BatSetup
	call DiscsSetup
	call BossSetup
	call UISetup
	call MenuSetup
	call ScrollSetup
	call SFXSetup
	
	ld a, $01
	ld [Paused], a
	xor a
	ld [Dead], a
	ld [LastMS], a
	ld [LastS], a
	ld [LastM], a
	ld [BestMS], a
	ld [BestS], a
	ld [BestM], a
	ld [SkipFrames], a
	ld [OddFrame], a
	
	ld a, $05
	ld [DiscCount], a
	ld [DiscSpeed], a
	ld a, $01
	ld [EnableBigDisc], a
	ld [EnableBat], a
	
	ld hl, Highscores
	ld bc, HighscoresEnd-Highscores
	xor a
	call ClearMemory
	
	ld a, $0A
	ld [$0000], a
	
	ld a, [SaveValid]
	cp $0A
	jr nz, .invalidSave
	
	ld hl, Highscores
	ld de, SaveHighscores
	ld bc, SaveHighscoresEnd - SaveHighscores
	call CopyMemory
	
	ld a, [SaveMS]
	ld [BestMS], a
	ld a, [SaveS]
	ld [BestS], a
	ld a, [SaveM]
	ld [BestM], a
	
	ld a, [SaveDiscCount]
	ld [DiscCount], a
	ld a, [SaveDiscSpeed]
	ld [DiscSpeed], a
	
	jr .validSave
	
.invalidSave:

	ld hl, SaveHighscores
	ld bc, SaveHighscoresEnd-SaveHighscores
	xor a
	call ClearMemory
	
	ld a, [DiscCount]
	ld [SaveDiscCount], a
	ld a, [DiscSpeed]
	ld [SaveDiscSpeed], a
	
	ld a, $0A
	ld [SaveValid], a
	
.validSave:
	
	ld a, $00
	ld [$0000], a
	
	ld a, %11100100
	ld [rBGP], a
	ld [rOBP0], a
	ld a, %10010000
	ld [rOBP1], a
	
	xor a
	ld [rSCY], a
	ld [rSCX], a

	ld [rIF], a
	; Enable Vblank interrupt
	ld a, %00000001
	ld [rIE], a

restartReturn:
	
	ld a, %11100011
	ld [rLCDC], a
	
	ei

.main
	halt
	ld a, [SkipFrames]
	cp $00
	jr z, .noskip
	dec a
	ld [SkipFrames], a
	jr .main
.noskip:
	call UpdateAll
	jr .main

ENDC