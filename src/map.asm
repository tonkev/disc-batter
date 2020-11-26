IF !DEF(MAP)
MAP SET 1

MAP_XA SET 72 - 16
MAP_YA SET 64 - 8
MAP_XB SET 184 + 24
MAP_YB SET 192 + 8

SECTION "Map", ROM0

MapTiles:
INCLUDE "spr/bg.z80"
MapTilesEnd:

Map:
INCLUDE "map/room.z80"
MapEnd:

SECTION "Map Tiles VRAM", VRAM[$9000]

MapTilesVRAM:
DS MapTilesEnd - MapTiles

SECTION "Map VRAM", VRAM[$9800]

MapVRAM:
DS MapEnd - Map



SECTION "MapSetup", ROM0

MapSetup:

	ld hl, MapTilesVRAM
	ld de, MapTiles
	ld bc, MapTilesEnd - MapTiles
	call CopyMemory
	
	ld hl, MapVRAM
	ld de, Map
	ld bc, MapEnd - Map
	call CopyMemory

	ret
	
ENDC