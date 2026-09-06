#!/bin/bash
echo "Mods directory: ${SRB2KART_MODS_DIRECTORY}"
MOD_LAYERS=$(ls ${SRB2KART_MODS_DIRECTORY})
UNSORTED_MODS=$(ls ${SRB2KART_MODS_DIRECTORY} | egrep '\.pk3$|\.wad$|\.lua$' | shuf)

echo "Mod quota: $TOTAL_SERVER_MOD_QUOTA"

if [[ ! -z "$TOTAL_SERVER_MOD_QUOTA" ]]; then
    TOTAL_SERVER_MOD_QUOTA_IEC=$(numfmt --from=iec ${TOTAL_SERVER_MOD_QUOTA:-0G})
    ACTIVE_MOD_QUOTA=0
    echo "Mods restricted from exceeding current quota of: $TOTAL_SERVER_MOD_QUOTA_IEC"
fi

MODS=$UNSORTED_MODS

for layer in ${MOD_LAYERS}; do
    LAYER_FILES=$(ls ${SRB2KART_MODS_DIRECTORY}/${layer} |  egrep '\.pk3$|\.wad$|\.lua$' | shuf)
    for mod in $LAYER_FILES; do
        MOD_DISK_USAGE=$(du -h ${SRB2KART_MODS_DIRECTORY}/${layer}/${mod} | cut -f -1 | numfmt --from=iec)
        if [[ ! -z "$TOTAL_SERVER_MOD_QUOTA" ]]; then
            NEXT_MOD_USAGE=$((MOD_DISK_USAGE + ACTIVE_MOD_QUOTA))
            echo "Attempting filter.. $NEXT_MOD_USAGE > $TOTAL_SERVER_MOD_QUOTA_IEC"
            if [[ $NEXT_MOD_USAGE -gt $TOTAL_SERVER_MOD_QUOTA_IEC ]]; then
                echo "Skipping ${mod}.."
                break
            fi
        fi
        ACTIVE_MOD_QUOTA=$((MOD_DISK_USAGE + ACTIVE_MOD_QUOTA))
        MODS="${MODS}\
        ${layer}/${mod}"

        echo $ACTIVE_MOD_QUOTA
    done
done


echo "Mods active:\
$MODS"

set -ex && srb2kart $@ -room 33 ${EXTRA_RUN_ARGS} -file ${MODS}

