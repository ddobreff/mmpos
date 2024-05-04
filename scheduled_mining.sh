#!/usr/bin/env bash
# Fill in the names of your rigs in rigs.txt
# ex:
# rig1
# rig2
# rig3
# For mac addresses use your rig mac addresses, obtain them from your dhcp server or using arp.
# ex:
# 00:01:02:03:04:05
# 00:02:03:04:05:06
CFG="/etc"
i=0
while read macs
do
    mac[$i]="$macs"
    i=$((i+1))
done < ${CFG}/macs.txt
k=0
while read rigids
do
    rig[$k]="$rigids"
    k=$((k+1))
done < ${CFG}/rigs.txt

TCHATID="Your-telegram-chatid-here"
TBOTID="Your-telegram-botid-here-with-api-key"
API_TOKEN="MMPOS-API-KEY"
FARMID="YOUR-MMPOS-FARM-ID"
# For local setup where you use wakeonlan use the following crontab addition:
# crontab addition to start at 9am and poweroff at 6pm your local time(make sure your linux system has correct timezone)
# 0 9 * * * /path/to/script.sh poweron >/dev/null 2>&1
# 0 18 * * * /path/to/script.sh poweroff >/dev/null 2>&1
# For remote use this one:
# 0 18 * * * /path/to/script.sh schedule_wakeup >/dev/null 2>&1
# end crontab addition
# Make sure to edit wakeup time below, its statically set to 9am your local time.
SCHD=$(date -d "tomorrow 09:00:00" +'%Y-%m-%d %T %Z')
SCHD_TS=$(date -d "$SCHD" -u +"%s")
NOW=$(date +'%Y-%m-%d %T %Z')

function send_notification() {
    curl -X POST \
        -H 'Content-Type: application/json' \
        -d '{"chat_id": "'"${TCHATID}"'", "text": "'"$1"'", "disable_notification": true}' \
        https://api.telegram.org/${TBOTID}/sendMessage
}

rigUUID=()
for (( i = 0; i <${#rig[@]} ; i++ )); do
    rigUUID+=( "$(curl -s -X GET  -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" https://api.mmpos.eu/api/v1/${FID}/rigs?limit=100 |jq -r '.[] | select(.name == "'"${rig[$i]}"'") | .id')" )
done

case "$1" in
    poweroff)
        for (( i = 0; i < ${#rig[@]} ; i++ )); do
            curl -s -X POST -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" -d '{"control": "poweroff"}' https://api.mmpos.eu/api/v1/${FID}/rigs/${rigUUID[$i]}/control
        done
        send_notification "Rigs have been shut at: [ $NOW ]"
        ;;
    schedule_wakeup)
        for (( i = 0; i < ${#rig[@]} ; i++ )); do
            curl -s -s -X POST -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" -d '{"control": "poweroff_wake '"${SCHD_TS}"'"}' https://api.mmpos.eu/api/v1/${FID}/rigs/${rigUUID[$i]}/control
        done
        send_notification "Rigs have been shut at: [ $NOW ], but will be powered back up at [ $SCHD ]"
        ;;
    poweron)
        for (( i = 0; i < ${#mac[@]} ; i++ )); do
            wakeonlan ${mac[$i]}
        done
        send_notification "Rigs have been manually powered up at: [ $NOW ]"
        ;;
    *)
        echo -e "You have to choose an option"
        exit
        ;;
esac
