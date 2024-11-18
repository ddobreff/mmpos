#!/usr/bin/env bash
# Below example adds miner stats for zkminer by apool.io
# get_bus_ids function fetches bus_ids from either MMPOS devicetool or using lspci command if previous is unavailable.
# get_miner_data function fetches hashrate and solution rate information per device based on bus_id count.
# This example is based on log file.
DEVICE_COUNT=$1
LOG_FILE=$2

[[ -r mmp-external.conf ]] && . mmp-external.conf

get_bus_ids() {
    local vendor_id="$1"
    local gpu_info_json="/run/gpuinfo.json"
    local busids=()

    if [[ -f "$gpu_info_json" ]]; then
        local vendor
        vendor_id=$(echo "$vendor_id" | tr -d '[:space:]')
        case "$vendor_id" in
            10de) vendor="nvidia" ;;
            1002) vendor="amd_sysfs" ;;
            *)    vendor="intel_sysfs" ;;
        esac

        local bus_ids
        bus_ids=$(jq -r ".device.GPU.${vendor}_details.busid[]" "$gpu_info_json" 2>/dev/null)

        if [[ -z "$bus_ids" ]]; then
            exit 1
        fi

        while read -r bus_id; do
            local hex=${bus_id:5:2}
            busids+=($((16#$hex)))
        done <<< "$bus_ids"

    else
        local bus_ids
        bus_ids=$(/bin/lspci -n | awk '$2 ~ /^030[02]:/ && $3 ~ /^'"$vendor_id"':/ {print $1}')

        if [[ -z "$bus_ids" ]]; then
            exit 1
        fi

        while read -r bus_id; do
            local decimal_bus_id=$((16#${bus_id%%:*}))
            busids+=("$decimal_bus_id")
        done <<< "$bus_ids"
    fi

    echo "${busids[*]}"
}

get_miner_data() {
    local busids=($(get_bus_ids "10de"))
    local hash=() accepted=() rejected=() invalid=()

    for (( i = 0; i < ${#busids[@]}; i++ )); do
        local line=$(grep -P "^\|\s+$i\s+\|" "$LOG_FILE" | tail -n 1)
        hash+=($(echo "$line" | awk -F '|' '{gsub(/ /, "", $3); print $3}' || echo "0"))
        accepted+=($(echo "$line" | awk -F '|' '{gsub(/ /, "", $4); print $4}' || echo "0"))
        rejected+=("0")
        invalid+=("0")
    done
}

get_miner_stats() {
    get_miner_data
    local busids=($(get_bus_ids "10de"))
    ac=$(IFS=+; echo "$((${accepted[*]:-0}))")
    local shares=$(jq -n \
            --argjson accepted "$(printf '%s\n' "${accepted[@]}" | jq -R '. | tonumber' | jq -s .)" \
            --argjson rejected "$(printf '%s\n' "${rejected[@]}" | jq -R '. | tonumber' | jq -s .)" \
            --argjson invalid "$(printf '%s\n' "${invalid[@]}" | jq -R '. | tonumber' | jq -s .)" \
        '{accepted: $accepted, rejected: $rejected, invalid: $invalid}')

    jq -nc \
        --argjson busid "$(printf '%s\n' "${busids[@]}" | jq -cs '.')" \
        --argjson hash "$(printf '%s\n' "${hash[@]}" | jq -cs '.')" \
        --argjson shares "$shares" \
        --arg units "hs" \
        --arg ac "$ac" --arg inv "0" --arg rj "0" \
        --arg miner_version "${EXTERNAL_VERSION:-unknown}" \
        --arg miner_name "${EXTERNAL_NAME:-unknown}" \
        '{$busid, $hash, shares: $shares, $units, air: [$ac, $inv, $rj], miner_name: $miner_name, miner_version: $miner_version}'
}

get_miner_stats $DEVICE_COUNT $LOG_FILE
