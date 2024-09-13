#!/bin/bash
SW_CNF_FILE=$1

if [[ -f "$SW_CNF_FILE" && -r "$SW_CNF_FILE" ]]; then
    . "$SW_CNF_FILE"

    case "$2" in
        active)
            curl -X POST -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" \
                -d '{"miner_profiles": ["'"${PRIMARY_PROFILE}"'"]}' \
                https://api.mmpos.eu/api/v1/${FID}/rigs/${RID}/miner_profiles
            ;;
        inactive)
            curl -X POST -H "X-API-Key: ${API_TOKEN}" -H "Content-Type: application/json" \
                -d '{"miner_profiles": ["'"${PRIMARY_PROFILE}"'", "'"${SECONDARY_PROFILE}"'"]}' \
                https://api.mmpos.eu/api/v1/${FID}/rigs/${RID}/miner_profiles
            ;;
        *)
            echo "You have to choose an option"
            exit 1
            ;;
    esac
else
    exit 1
fi
