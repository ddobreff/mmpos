#!/bin/bash
# Quickpod mmpOS switching script
API_TOKEN="mmpOS API Token"
FID="Your Farm UUID"
Q_API_KEY="Quickpod API token"
Q_MID="Quickpod Rig ID"
RIG_ID="mmpOS Rig ID"

# create temp file to compare rental results
temp_file="/tmp/quickpod_rental"

# Fetch machines from quickpod.io
stats=$(curl -sS --location --request GET "https://api.quickpod.io/api:KoOk0R5J/mymachines" \
        --header "Accept: application/json" \
    --header "Authorization: ${Q_API_KEY}")

# match rental results
if [ -e "$temp_file" ]; then
    prev_rental_status=$(cat "$temp_file")
else
    prev_rental_status=false
fi

# Check if we are listed
listed_status=$(echo "$stats" |jq '.[] |.listed')
if [ "$listed_status" = "true" ]; then
    # fetch clients, if false = machine is not rented, else if true, its rented
    rental_status=$(echo "$stats" | jq '.[]._machines[] | select(.id == '"$Q_MID"') | .occupied')

    echo "$rental_status" > "$temp_file"

    if [ "$rental_status" = "true" ]; then
        if [ "$rental_status" -ne "$prev_rental_status" ]; then
            curl -X POST -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" -d '{"control": "disable"}' "https://api.mmpos.eu/api/v1/${FID}/rigs/${RIG_ID}/control"
            sleep 2
            nvidia-smi -rmc
            nvidia-smi -rgc
            nvidia-smi -pl 200
        else
            echo "Rig: [ ${Q_MID} ] is rented, not doing anything"
        fi
    else
        if [ "$prev_rental_status" = "false" ]; then
            echo "Rig: [ ${Q_MID} ] is not rented and was not rented in the previous iteration, not doing anything"
        else
            curl -X POST -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" -d '{"control": "enable"}' "https://api.mmpos.eu/api/v1/${FID}/rigs/${RIG_ID}/control"
        fi
    fi
else
    echo "Rig:  [ ${Q_MID} ] is not listed!"
fi
exit 0
