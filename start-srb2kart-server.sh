#!/bin/sh
echo "Mods directory: ${SRB2KART_MODS_DIRECTORY}"
MODS=$(ls ${SRB2KART_MODS_DIRECTORY} | egrep '\.pk3$|\.wad$|\.lua$')
set -ex && srb2kart $@ -file ${MODS}
