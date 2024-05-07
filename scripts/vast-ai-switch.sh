#!/bin/bash
API_TOKEN="mmpOS-API-Token"
FID="mmpOS-Farm-ID"
VAST_API_KEY="Vast.ai API key"
VAST_MID="your-vast-ai-machine-id"
RIG_ID="mmpOS-Rig-ID"


# create temp file to compare rental results
temp_file="/tmp/vast_rental"

# Fetch machines from vast.ai
stats=$(curl -sS --location --request GET "https://console.vast.ai/api/v0/machines" \
        --header "Accept: application/json" \
        --header "Authorization: Bearer ${VAST_API_KEY}")

# match rental results
if [ -e "$temp_file" ]; then
    prev_rental_status=$(cat "$temp_file")
else
    prev_rental_status=0
fi

# fetch clients, if 0 = machine is not rented, > 0 its rented
rental_status=$(echo "$stats" | jq '.machines[] | select(.machine_id == '"$VAST_MID"') | .clients | length')

echo "$rental_status" > "$temp_file"

if [ "$rental_status" -gt 0 ]; then
    if [ "$rental_status" -ne "$prev_rental_status" ]; then
        curl -X POST -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" -d '{"control": "disable"}' "https://api.mmpos.eu/api/v1/${FID}/rigs/${RIG_ID}/control"
  sleep 2
  nvidia-smi -rmc
  nvidia-smi -rgc
  nvidia-smi -pl 200
    else
        echo "Rig: [ ${VAST_MID} ] is rented, not doing anything"
    fi
else
    if [ "$prev_rental_status" -eq 0 ]; then
        echo "Rig: [ ${VAST_MID} ] is not rented and was not rented in the previous iteration, not doing anything"
    else
        curl -X POST -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" -d '{"control": "enable"}' "https://api.mmpos.eu/api/v1/${FID}/rigs/${RIG_ID}/control"
    fi
fi
exit 0
