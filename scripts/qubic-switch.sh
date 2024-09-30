#!/bin/bash
# -- Use below helper to install switcher on one of your rigs.
# SWITCH_SCRIPT_URL="https://raw.githubusercontent.com/ddobreff/mmpos/refs/heads/main/scripts/qubic-switch.sh"
# SWITCH_SCRIPT_PATH="/home/miner/qubic-switch.sh"
# CONFIG_FILE="/home/miner/config.txt"
# RIGS_FILE="/home/miner/rigs.txt"
# CRONTAB_ENTRY="* * * * * $SWITCH_SCRIPT_PATH >/dev/null 2>&1"

# curl --fail --insecure -A "Debian APT-HTTP/1.3 (1.6.12)" -kL -o "$SWITCH_SCRIPT_PATH" "$SWITCH_SCRIPT_URL"
# chmod +x "$SWITCH_SCRIPT_PATH"

# -- !!! EDIT BELOW !!!
# cat <<EOL > "$CONFIG_FILE"
# API_TOKEN="YOUR-API-TOKEN"  # You can get this if you're at least supporter tier from profile.
# FID="YOUR-FARM-ID" # Go to farms on dashboard and copy uuid link of your farm.
# PRIMARY_PROFILE="YOUR-PRIMARY-QUBIC-PROFILE" # UUID of primary qubic miner.
# SECONDARY_PROFILE="YOUR-IDLE-PROFILE" # UUID of secondary miner.
# CPU_PROFILE="YOUR-CPU-PROFILE" # Add it in case you use cpu profile
# QUBIC_ACCESSTOKEN="Your qubic.li accesstoken" # This is not your QUBIC WALLET!!!
# EOL
#
# -- !!! PLACE YOUR RIGS WHICH WILL SWITCH TO QUBIC
# cat <<EOL > "$RIGS_FILE"
# rig1
# rig2
# rig3+cpu # means this rig has cpu profile too
# rig4+cpu # same as above
# rig5
# EOL

# -- Add script to crontab
# (echo "$CRONTAB_ENTRY"; crontab -l | grep -v "$SWITCH_SCRIPT_PATH") | crontab -
#
# -- End helper

CFG_DIR="/home/miner" # Change this if you plan to post config.txt and rigs.txt somewhere else
SW_CNF_FILE="${CFG_DIR}/config.txt"
LOCKFILE="${CFG_DIR}/get_seed.lock"
SEED_FILE="${CFG_DIR}/seed.txt"
IDLE_SEED="0000000000000000000000000000000000000000000000000000000000000000"
DEFAULT_SEED="0000000000000000000000000000000000000000000000000000000000000001"

if [[ -f "$SW_CNF_FILE" && -r "$SW_CNF_FILE" ]]; then
    . "$SW_CNF_FILE"
else
    exit 1
fi

k=0
rig=()
cpu_profiles=()

while read -r names; do
    if [[ "$names" == *"+cpu" ]]; then
        rig[$k]="${names%+cpu}"
        cpu_profile[$k]="$CPU_PROFILE"
    else
        rig[$k]="$names"
        cpu_profile[$k]=""
    fi
    k=$((k + 1))
done < "${CFG_DIR}/rigs.txt"

rigUUID=()
for (( i = 0; i <${#rig[@]} ; i++ )); do
    rigUUID+=( "$(curl -s -X GET  -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" https://api.mmpos.eu/api/v1/${FID}/rigs?limit=100 |jq -r '.[] | select(.name == "'"${rig[$i]}"'") | .id')" )
done

if [[ -f "$LOCKFILE" ]]; then
    echo "Switcher is already running."
    exit 1
fi
trap "rm -f $LOCKFILE" EXIT
touch "$LOCKFILE"

switch_profiles() {

    GET_SEED=$(curl --fail --insecure -A "Debian APT-HTTP/1.3 (1.6.12)" --silent -L -g -H "Content-Type: application/json" \
            -X GET "https://mine.qubic.li/Training/RandomSeed" \
        -H "Authorization: Bearer ${QUBIC_ACCESSTOKEN}" | jq -r .seed)

    if [[ -z "$GET_SEED" || "$GET_SEED" == "null" ]]; then
        # Failover: if qubic.li api fails, go for qubicmine.pro.
        GET_SEED=$(curl --fail --insecure -A "Debian APT-HTTP/1.3 (1.6.12)" --silent -L -g -H "Content-Type: application/json" \
            -X GET "https://wss.qubicmine.pro/currentSeed" | jq -r .seed)
    fi

    SEED_RESULT="${GET_SEED:-$IDLE_SEED}"

    if [[ -f "$SEED_FILE" ]]; then
        LAST_SEED=$(cat "$SEED_FILE")
    else
        LAST_SEED="${DEFAULT_SEED}"
    fi

    if [[ "$SEED_RESULT" != "$LAST_SEED" ]]; then
        if [[ "$SEED_RESULT" == "$IDLE_SEED" ]]; then
            for (( i = 0; i < ${#rig[@]} ; i++ )); do
                RIG_STATUS=$(curl -s -X GET -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" \
                    "https://api.mmpos.eu/api/v1/${FID}/rigs/${rigUUID[$i]}?limit=100" | jq -r .status)

                if [[ "$RIG_STATUS" != "rig_down" ]]; then
                    if [[ -n "${cpu_profile[$i]}" ]]; then
                        echo "Switching to inactive profile $SECONDARY_PROFILE + $CPU_PROFILE on RID: ${rigUUID[$i]}"
                        curl -X POST -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" \
                            -d '{"miner_profiles": ["'"${CPU_PROFILE}"'", "'"${SECONDARY_PROFILE}"'"]}' \
                            https://api.mmpos.eu/api/v1/${FID}/rigs/${rigUUID[$i]}/miner_profiles
                    else
                        echo "Switching to inactive profile $SECONDARY_PROFILE on RID: ${rigUUID[$i]}"
                        curl -X POST -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" \
                            -d '{"miner_profiles": ["'"${SECONDARY_PROFILE}"'"]}' \
                            https://api.mmpos.eu/api/v1/${FID}/rigs/${rigUUID[$i]}/miner_profiles
                    fi
                else
                    echo "Rig ${rig[$i]} is down, skipping profile switch."
                fi

            done
        else
            for (( i = 0; i < ${#rig[@]} ; i++ )); do
                RIG_STATUS=$(curl -s -X GET -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" \
                    "https://api.mmpos.eu/api/v1/${FID}/rigs/${rigUUID[$i]}?limit=100" | jq -r .status)

                if [[ "$RIG_STATUS" != "rig_down" ]]; then
                    if [[ -n "${cpu_profile[$i]}" ]]; then
                        echo "Switching to active profile $PRIMARY_PROFILE + $CPU_PROFILE on RID: ${rigUUID[$i]}"
                        curl -X POST -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" \
                            -d '{"miner_profiles": ["'"${CPU_PROFILE}"'", "'"${PRIMARY_PROFILE}"'"]}' \
                            https://api.mmpos.eu/api/v1/${FID}/rigs/${rigUUID[$i]}/miner_profiles
                    else
                        echo "Switching to active profile $PRIMARY_PROFILE on RID: ${rigUUID[$i]}"
                        curl -X POST -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" \
                            -d '{"miner_profiles": ["'"${PRIMARY_PROFILE}"'"]}' \
                            https://api.mmpos.eu/api/v1/${FID}/rigs/${rigUUID[$i]}/miner_profiles
                    fi
                else
                    echo "Rig ${rig[$i]} is down, skipping profile switch."
                fi
            done
        fi
    fi

    echo "$SEED_RESULT" > "$SEED_FILE"
}

switch_profiles

