#!/bin/bash
CFG_DIR="/home/miner" # Change this if you plan to post config.txt and rigs.txt somewhere else
SW_CNF_FILE="${CFG_DIR}/config.txt"
LOCKFILE="/tmp/get_seed.lock"
SEED_FILE="/tmp/seed.txt"
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
            done
        else
            for (( i = 0; i < ${#rig[@]} ; i++ )); do
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
            done
        fi
    fi

    echo "$SEED_RESULT" > "$SEED_FILE"
}

switch_profiles

