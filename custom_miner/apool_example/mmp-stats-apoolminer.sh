#!/usr/bin/env bash
# This is mmp-stat.sh for apoolminer QUBIC miner.
# It uses its internal API to fetch hashrate and sharerate.
DEVICE_COUNT=$1
LOG_FILE=$2
cd "$(dirname "$0")"
[[ -r mmp-external.conf ]] && . mmp-external.conf

MINER_API_PORT=${MINER_API_PORT:-5001}
API_URL="http://127.0.0.1:${MINER_API_PORT}/gpu"

stats_json=$(curl --silent --insecure --header 'Accept: application/json' "$API_URL")
if [[ $? -ne 0 || -z $stats_json ]]; then
    echo "Miner API connection failed"
    exit 1
fi

get_cards_busid() {
    echo "$stats_json" | jq -c '[.data.gpus[] | if .bus == 0 then "cpu" else .bus end | select(. != null)]'
}

get_miner_shares() {
    for ((i = 0; i < DEVICE_COUNT; i++)); do
        local stats=$(echo "$stats_json" | jq ".data.gpus[] | select(.id == $i)")
        accepted[$i]=$(echo "$stats" | jq -r '.valid // 0')
        rejected[$i]=$(echo "$stats" | jq -r '.statle // 0')
        invalid[$i]=$(echo "$stats" | jq -r '.inval // 0')
    done
}

get_latest_version() {
    TARGET_DIR="."
    URL="https://github.com/apool-io/apoolminer/releases/latest"
    VERSION=$(curl -sL "$URL" | grep -oP 'v[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)

    if [[ -n "$VERSION" && "$VERSION" != "v${EXTERNAL_VERSION}" ]]; then
        FILE_URL="https://github.com/ddobreff/mmpos/releases/download/$VERSION/apoolminer-$VERSION.tar.gz"
        if curl --head --silent --fail "$FILE_URL" > /dev/null; then
            echo "Updating to $VERSION..."
            curl -L -o "apoolminer-$VERSION.tar.gz" "$FILE_URL"
            tar --strip-components=1 -xzf "apoolminer-$VERSION.tar.gz" -C "$TARGET_DIR"
            rm "apoolminer-$VERSION.tar.gz"
            echo "Update complete. Restarting service..."
            sudo systemctl restart mmp-agent.service
        else
            echo "Update file not found: $FILE_URL"
        fi
    fi
}

get_miner_stats() {
    get_miner_shares

    ac=$(IFS=+; echo "$((${accepted[*]:-0}))")
    rj=$(IFS=+; echo "$((${rejected[*]:-0}))")
    inv=$(IFS=+; echo "$((${invalid[*]:-0}))")

    shares=$(jq -n \
            --argjson accepted "$(printf '%s\n' "${accepted[@]}" | jq -R 'tonumber' | jq -s .)" \
            --argjson rejected "$(printf '%s\n' "${rejected[@]}" | jq -R 'tonumber' | jq -s .)" \
            --argjson invalid "$(printf '%s\n' "${invalid[@]}" | jq -R 'tonumber' | jq -s .)" \
        '{accepted: $accepted, rejected: $rejected, invalid: $invalid}')

    busid=$(get_cards_busid)
    hash=$(echo "$stats_json" | jq '[.data.gpus[] | if .bus == 0 then .proof else empty end] + [.data.gpus[] | select(.bus != 0) | .proof]')
    units="hs"

    jq -nc \
        --argjson hash "$hash" \
        --argjson busid "$busid" \
        --argjson shares "$shares" \
        --arg units "$units" \
        --arg ac "$ac" --arg inv "$inv" --arg rj "$rj" \
        --arg miner_version "$EXTERNAL_VERSION" \
        --arg miner_name "$EXTERNAL_NAME" \
        '{busid: $busid, hash: $hash, units: $units, shares: $shares, air: [$ac, $inv, $rj], miner_name: $miner_name, miner_version: $miner_version}'
}

get_miner_stats $DEVICE_COUNT $LOG_FILE
get_latest_version
