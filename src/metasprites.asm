IF !DEF(METASPRITES)
METASPRITES SET 1

INCLUDE "inc/hardware.inc"
INCLUDE "src/utilities.asm"
INCLUDE "src/updates.asm"

OAM_BUFFER_HI SET $C1
MS_TABLE_HI SET $C2

SECTION "OAM Buffer", WRAM0[$C100]

OAMBuffer:
	DS 4*40
OAMBufferEnd:

SECTION "Metasprite Table", WRAM0[$C200]

;MetaspriteTableEntry - Each Metasprite a LinkedList
;--------------------
;AnimationState
;OffsetY
;OffsetX
;Next(Lo Byte) -- FF means end

;MetaspriteEntrys linked 1 to 1 to sprites

MetaspriteTable:
	DS 4*40
MetaspriteTableEnd:

SECTION "Metasprite Vars", WRAM0

PreviousDIV:
	DS 1

SECTION "Metasprites Setup", ROM0

MetaspritesSetup:

	xor a
	ld [PreviousDIV], a

	ld de, FlushOAMBuffer
	ld bc, DMARoutineEnd - DMARoutine
	call CopyFollowingData

DMARoutine:
	ld a, OAM_BUFFER_HI
	ldh [rDMA], a
	ld a, $28; wait 160 ms for DMA transfer to finish
.loop:
	dec a
	jr nz, .loop
	ret
DMARoutineEnd:

	ld hl, OAMBuffer
	ld bc, OAMBufferEnd-OAMBuffer
	xor a
	call ClearMemory
	
	ld hl, MetaspriteTable
	ld bc, MetaspriteTableEnd-MetaspriteTable
	xor a
	call ClearMemory
	
	ld hl, MetaspritesUpdate
	call RegisterUpdateCall
	
	ret

SECTION "Flush OAM Buffer", HRAM[$FF80]

FlushOAMBuffer:
	DS DMARoutineEnd - DMARoutine
	
SECTION "Metasprites Update", ROM0

MetaspritesUpdate:
	
	ld a, [rDIV]
	and $80
	ld b, a
	ld a, [PreviousDIV]
	cp b
	ret z
	
	ld a, b
	ld [PreviousDIV], a
	ld hl, $C2FC
	
.loop:
	ld a, $04
	add l
	cp $A0
	ret z
	ld l, a
	ld a, [hl]
	cp $00
	jr z, .loop
	
	ld b, a
	and $F0
	swap a
	ld c, a
	ld a, b
	and $0F
	inc a
	cp c
	jr nz, .notMax
	
	xor a
	
.notMax
	swap c
	or c
	ld [hl], a
	
	jr .loop

SECTION "NewMetasprite", ROM0
	
NewMetasprite:

;parameters
; c  - no of sprites

;returns
; b - MetaspriteID
	
	ld hl, $C2FC
	ld d, MS_TABLE_HI
	ld b, $FF

.loopNotEmpty:
	inc l
	inc l
	inc l
.loop:
	inc l
	
	ld a, [hl]
	cp $00
	jr nz, .loopNotEmpty
	
	ld a, $FF
	cp b
	jr nz, .skipSaveMSID
	
	ld b, l
	jr .skipUpdatePrevNext
	
.skipSaveMSID:
	
	ld a, l
	ld [de], a
	
.skipUpdatePrevNext:

	ld a, $01
	ld [hli], a ;Set MS flag	
	inc l		;Skip MS offsets
	inc l
	
	dec c
	jr z, .loopBreak
	
	ld e, l	;Save MS next ptr to write later
	
	jr .loop
	
.loopBreak:
	ld a, $FF
	ld [hl], a	;Set MS next to terminator
	
	ret


SECTION "RemoveMetasprite", ROM0
	
RemoveMetasprite:

;parameters
; e - MetaspriteID

;preserves
; bc
	
	ld h, OAM_BUFFER_HI
	ld d, MS_TABLE_HI
	
.loop:
	xor a
	ld [de], a
	ld l, e
	ld [hl], a
	
	inc e	
	inc e
	inc e
	
	ld a, [de]
	cp $FF
	ret z
	
	ld e, a
	jr .loop

SECTION "Set Metasprite Animation State", ROM0

;parameters
; a(Hi) - Animation Size
; a(Lo) - Starting Index
; e     - metaspriteID

;wrecks
; d

;preserves
; abcefhl

SetMetaspriteAnimationState:

	ld d, MS_TABLE_HI
	ld [de], a
	ret 

SECTION "Get Metasprite Animation Frame", ROM0

;parameters
; e - metaspriteID

;returns
; a - animation frame

;wrecks
; ad

;preserves
; bcefhl

GetMetaspriteAnimationFrame:

	ld d, MS_TABLE_HI
	ld a, [de]
	and $0F
	ret

SECTION "Set Metasprite Offsets", ROM0

SetMetaspriteOffsets:

;parameters
; hl - address to offset pairs
; e  - metaspriteID

;preserves
; bc

	ld d, MS_TABLE_HI

.loop:
	inc e
	
	ld a, [hli]
	ld [de], a	;Set OffsetY
	inc e
	ld a, [hli]
	ld [de], a	;Set OffsetX
	inc e
	ld a, [de]	;Get Next MS
	ld e, a
	
	cp $FF
	jr nz, .loop
	
	ret
	
SECTION "Set Metasprite Tile", ROM0

SetMetaspriteTile:

;parameters
; a - tile
; e  - metaspriteID

;wrecks
; de

	ld d, OAM_BUFFER_HI
	inc e
	inc e
	ld [de], a	
	ret

SECTION "Set Metasprite Tiles", ROM0

SetMetaspriteTiles:

;parameters
; hl - address to sprite list
; e  - metaspriteID

;preserves
; bc

.loop:
	ld d, OAM_BUFFER_HI
	inc e
	inc e
	ld a, [hli]
	ld [de], a
	
	ld d, MS_TABLE_HI
	inc e
	ld a, [de]
	ld e, a
	
	cp $FF
	jr nz, .loop
	
	ret
	
SECTION "Set Metasprite OAM Flag", ROM0

SetMetaspriteOAMFlag:

;parameters
; h  - flag
; e  - metaspriteID

;preserves
; bchl

.loop:
	ld d, OAM_BUFFER_HI
	inc e
	inc e
	inc e
	ld a, h
	ld [de], a
	
	ld d, MS_TABLE_HI
	ld a, [de]
	ld e, a
	
	cp $FF
	jr nz, .loop
	
	ret

SECTION "Set Metasprite OAM Flags", ROM0

SetMetaspriteOAMFlags:

;parameters
; hl - address to flags
; e  - metaspriteID

;preserves
; bc

.loop:
	ld d, OAM_BUFFER_HI
	inc e
	inc e
	inc e
	ld a, [hli]
	ld [de], a
	
	ld d, MS_TABLE_HI
	ld a, [de]
	ld e, a
	
	cp $FF
	jr nz, .loop
	
	ret

	
SECTION "Move Metasprite", ROM0

MoveMetasprite:

;parameters
; bc - YX
; l  - metaspriteID

	ld h, MS_TABLE_HI
	ld d, OAM_BUFFER_HI

.loop:
	ld e, l
	
	inc l	
	ld a, [hli]
	add b
	ld [de], a	;Set SpriteY
	inc e
	ld a, [hli]
	add c
	ld [de], a	;Set SpriteX
	
	ld a, [hl]
	ld l, a
	
	cp $FF
	jr nz, .loop

	ret

SECTION "Flip Animate Metasprite", ROM0

FlipAnimateMetasprite:

;parameters
; b - metaspriteID

	ld a, [rDIV]
	and $80
	jr z, .even
	
	ld hl, Standard2x2Flags
	push hl
	ld hl, Standard2x2Offsets
	
	jr .odd
	
.even:

	ld hl, Flipped2x2Flags
	push hl
	ld hl, Flipped2x2Offsets

.odd:

	ld e, b
	call SetMetaspriteOffsets
	pop hl
	ld e, b
	jp SetMetaspriteOAMFlags

SECTION "Metasprite Defaults", ROM0
	
Standard2x2Offsets:
DB $00, $00, $00, $08, $08, $00, $08, $08
	
Flipped2x2Offsets:
DB $00, $08, $00, $00, $08, $08, $08, $00

Standard2x2Flags:
DB $00, $00, $00, $00
	
Flipped2x2Flags:
DB $20, $20, $20, $20
	
ENDC