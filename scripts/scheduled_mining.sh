#!/usr/bin/env bash
# ----------------------------------------------------------------
# In memory of Ovalbore
# The script was intended for him, sadly he didn't live to use it.
# ----------------------------------------------------------------
# Fill in the names of your rigs in rigs.txt
# ex:
# rig1
# rig2
# rig3
# Since agent version 4.0.11 we now post mac_address field to API.
# Next step is to use tags instead of rig names for full automation.
CFG="/etc"
i=0
while read rigids
do
    rigs[$i]="$rigids"
    i=$((i+1))
done < ${CFG}/rigs.txt

TCHATID="Your-telegram-chatid-here"
TBOTID="Your-telegram-botid-here-with-api-key"
API_TOKEN="MMPOS-API-KEY"
FARMID="YOUR-MMPOS-FARM-ID"
LIMIT="100" # Change this if you have more than 100 rigs or profiles.
# For local setup where you use wakeonlan use the following crontab addition:
# crontab addition to start at 9am and poweroff at 6pm your local time(make sure your linux system has correct timezone)
# 0 9 * * * /path/to/script.sh poweron >/dev/null 2>&1
# 0 18 * * * /path/to/script.sh poweroff >/dev/null 2>&1
# For remote use this one:
# 0 18 * * * /path/to/script.sh schedule_wakeup >/dev/null 2>&1
# end crontab addition
# Make sure to edit wakeup time below, its statically set to 9am your local time.
SCHD=$(date -d "tomorrow 09:30:00" +'%Y-%m-%d %T %Z')
SCHD_TS=$(date -d "$SCHD" -u +"%s")
NOW=$(date +'%Y-%m-%d %T %Z')

function send_notification() {
    curl -X POST \
        -H 'Content-Type: application/json' \
        -d '{"chat_id": "'"${TCHATID}"'", "text": "'"$1"'", "disable_notification": true}' \
        https://api.telegram.org/${TBOTID}/sendMessage
}

rigUUID=()
macAddrs=()
for (( i=0; i<${#rigs[@]}; i++ )); do
    rig="${rigs[i]}"
    resp=$(curl -s -X GET -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" \
            "https://api.mmpos.eu/api/v1/${FARMID}/rigs?limit=$LIMIT" | \
        jq -r --arg name "$rig" '.[] | select(.name == $name) | {id: .id, mac_address: .mac_address}')

    rigUUID[i]="$(echo "$resp" | jq -r '.id')"
    macAddrs[i]="$(echo "$resp" | jq -r '.mac_address')"
done

case "$1" in
    poweroff)
        for (( i = 0; i < ${#rigs[@]} ; i++ )); do
            RIG_STATUS=$(curl -s -X GET -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" "https://api.mmpos.eu/api/v1/${FARMID}/rigs/${rigUUID[$i]}?limit=$LIMIT" | jq -r .status)
            if [[ "$RIG_STATUS" != "rig_down" ]]; then
                curl -s -X POST -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" -d '{"control": "poweroff"}' https://api.mmpos.eu/api/v1/${FARMID}/rigs/${rigUUID[$i]}/control
            else
                echo "Rig ${rig[$i]} is down, skipping shutdown."
            fi
        done
        send_notification "Rigs have been shut at: [ $NOW ]"
        ;;
    schedule_wakeup)
        for (( i = 0; i < ${#rigs[@]} ; i++ )); do
            curl -s -s -X POST -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" -d '{"control": "poweroff_wake '"${SCHD_TS}"'"}' https://api.mmpos.eu/api/v1/${FARMID}/rigs/${rigUUID[$i]}/control
        done
        send_notification "Rigs have been shut at: [ $NOW ], but will be powered back up at [ $SCHD ]"
        ;;
    poweron)
        for (( i = 0; i < ${#macAddrs[@]} ; i++ )); do
            wakeonlan ${macAddrs[$i]}
        done
        send_notification "Rigs have been manually powered up at: [ $NOW ]"
        ;;
    *)
        echo -e "You have to choose an option"
        exit
        ;;
esac
