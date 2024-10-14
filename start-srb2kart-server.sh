#!/bin/sh
echo "Mods directory: ${SRB2KART_MODS_DIRECTORY}"
MODS=$(ls ${SRB2KART_MODS_DIRECTORY} | egrep '\.pk3$|\.wad$|\.lua$')

echo "Starting NGINX"
nginx

set -ex && srb2kart $@ -room 33 ${EXTRA_RUN_ARGS} -file ${MODS}
