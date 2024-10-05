#/bin/bash
MODS=$(ls ${SRB2_KART_MODS_DIRECTORY}/*.{wad,pk3,lua))
srb2kart $@ -file $MODS
