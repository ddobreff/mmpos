#!/bin/bash
# -- Use below helper to install switcher on one of your rigs.
# SWITCH_SCRIPT_URL="https://raw.githubusercontent.com/ddobreff/mmpos/refs/heads/main/scripts/qubic-switch.sh"
# SWITCH_SCRIPT_PATH="/home/miner/qubic/qubic-switch.sh"
# CONFIG_FILE="/home/miner/qubic/config.txt"
# RIGS_FILE="/home/miner/qubic/rigs.txt"
# CRONTAB_ENTRY="* * * * * $SWITCH_SCRIPT_PATH >/dev/null 2>&1"

# curl --fail --insecure -A "Debian APT-HTTP/1.3 (1.6.12)" -kL -o "$SWITCH_SCRIPT_PATH" "$SWITCH_SCRIPT_URL"
# chmod +x "$SWITCH_SCRIPT_PATH"

# -- !!! EDIT BELOW !!!
# cat <<EOL > "$CONFIG_FILE"
# API_TOKEN="YOUR-API-TOKEN"  # You can get this if you're at least supporter tier from profile.
# FID="YOUR-FARM-ID" # Go to farms on dashboard and copy uuid link of your farm.
# QUBIC_GPU_PROFILE="YOUR-QUBIC-GPU-PROFILE" # UUID of primary qubic miner.
# QUBIC_GPU_PROFILE="YOUR-QUBIC-CPU-PROFILE"
# MAIN_GPU_PROFILE="YOUR-MAIN-GPU-PROFILE" # UUID of secondary miner.
# MAIN_CPU_PROFILE="YOUR-MAIN-CPU-PROFILE" # Add it in case you use cpu profile
# QUBIC_ACCESSTOKEN="Your qubic.li accesstoken" # This is not your QUBIC WALLET!!!
# EOL
#
# -- !!! PLACE YOUR RIGS WHICH WILL SWITCH TO QUBIC
# cat <<EOL > "$RIGS_FILE"
# rig1 # default without extension means only GPU mining
# rig2
# rig3+cpu # means this rig is both CPU and GPU mining only
# rig4-cpu # means the rig is CPU mining only
# rig5
# EOL

# -- Add script to crontab
# (echo "$CRONTAB_ENTRY"; crontab -l | grep -v "$SWITCH_SCRIPT_PATH") | crontab -
#
# -- End helper

CFG_DIR="/home/miner/qubic" # Change this if you plan to post config.txt and rigs.txt somewhere else
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
profile_type=()

while read -r names; do
    if [[ "$names" == *"+cpu" ]]; then
        rig[$k]="${names%+cpu}"
        profile_type[$k]="both"
    elif [[ "$names" == *"-cpu" ]]; then
        rig[$k]="${names%-cpu}"
        profile_type[$k]="cpu"
    else
        rig[$k]="$names"
        profile_type[$k]="gpu"
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
                    if [[ "${profile_type[$i]}" == "both" ]]; then
                        if [[ "${MAIN_CPU_PROFILE}" == "${MAIN_GPU_PROFILE}" ]]; then
                            echo "Switching to inactive profile $MAIN_GPU_PROFILE (same for CPU and GPU) on Rig ID: ${rigUUID[$i]}"
                            curl -X POST -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" \
                                -d '{"miner_profiles": ["'"${MAIN_GPU_PROFILE}"'"]}' \
                                https://api.mmpos.eu/api/v1/${FID}/rigs/${rigUUID[$i]}/miner_profiles
                        else
                            echo "Switching to inactive profile $MAIN_GPU_PROFILE + $MAIN_CPU_PROFILE on Rig ID: ${rigUUID[$i]}"
                            curl -X POST -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" \
                                -d '{"miner_profiles": ["'"${MAIN_CPU_PROFILE}"'", "'"${MAIN_GPU_PROFILE}"'"]}' \
                                https://api.mmpos.eu/api/v1/${FID}/rigs/${rigUUID[$i]}/miner_profiles
                        fi
                    elif [[ "${profile_type[$i]}" == "gpu" ]]; then
                        echo "Switching to inactive profile $MAIN_GPU_PROFILE on Rig ID: ${rigUUID[$i]}"
                        curl -X POST -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" \
                            -d '{"miner_profiles": ["'"${MAIN_GPU_PROFILE}"'"]}' \
                            https://api.mmpos.eu/api/v1/${FID}/rigs/${rigUUID[$i]}/miner_profiles
                    else
                        echo "Switching to inactive profile $MAIN_GPU_PROFILE on Rig ID: ${rigUUID[$i]}"
                        curl -X POST -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" \
                            -d '{"miner_profiles": ["'"${MAIN_CPU_PROFILE}"'"]}' \
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
                    if [[ "${profile_type[$i]}" == "both" ]]; then
                        if [[ "${QUBIC_CPU_PROFILE}" == "${QUBIC_GPU_PROFILE}" ]]; then
                            echo "Switching to active profile $QUBIC_GPU_PROFILE (same for CPU and GPU) on Rig ID: ${rigUUID[$i]}"
                            curl -X POST -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" \
                                -d '{"miner_profiles": ["'"${QUBIC_GPU_PROFILE}"'"]}' \
                                https://api.mmpos.eu/api/v1/${FID}/rigs/${rigUUID[$i]}/miner_profiles
                        else
                            echo "Switching to active profile $QUBIC_GPU_PROFILE + $QUBIC_CPU_PROFILE on Rig ID: ${rigUUID[$i]}"
                            curl -X POST -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" \
                                -d '{"miner_profiles": ["'"${QUBIC_CPU_PROFILE}"'", "'"${QUBIC_GPU_PROFILE}"'"]}' \
                                https://api.mmpos.eu/api/v1/${FID}/rigs/${rigUUID[$i]}/miner_profiles
                        fi
                    elif [[ "${profile_type[$i]}" == "gpu" ]]; then
                        echo "Switching to active profile $QUBIC_GPU_PROFILE on Rig ID: ${rigUUID[$i]}"
                        curl -X POST -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" \
                            -d '{"miner_profiles": ["'"${QUBIC_GPU_PROFILE}"'"]}' \
                            https://api.mmpos.eu/api/v1/${FID}/rigs/${rigUUID[$i]}/miner_profiles
                    else
                        echo "Switching to active profile $QUBIC_GPU_PROFILE on Rig ID: ${rigUUID[$i]}"
                        curl -X POST -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" \
                            -d '{"miner_profiles": ["'"${QUBIC_CPU_PROFILE}"'"]}' \
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

