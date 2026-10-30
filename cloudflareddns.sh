#!/bin/bash

ZONE_ID="CF_ZONE_ID_HERE"
CF_TOKEN="CF_API_TOKEN_HERE"

DOMAINS=(
    "yourdomain.com"
    "www.yourdomain.com"
    "ftp.yourdomain.com"
)

CURRENT_IP=$(curl -s https://api.ipify.org)

echo "Current IP: $CURRENT_IP"

for DOMAIN in "${DOMAINS[@]}"; do

    echo
    echo "Checking $DOMAIN..."

    RECORD_INFO=$(curl -s \
        -H "Authorization: Bearer ${CF_TOKEN}" \
        -H "Content-Type: application/json" \
        "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?type=A&name=${DOMAIN}")

    RECORD_ID=$(echo "$RECORD_INFO" | jq -r '.result[0].id')
    EXISTING_IP=$(echo "$RECORD_INFO" | jq -r '.result[0].content')
    PROXIED=$(echo "$RECORD_INFO" | jq -r '.result[0].proxied')

    if [[ "$RECORD_ID" == "null" ]]; then
        echo "Record not found"
        continue
    fi

    if [[ "$CURRENT_IP" == "$EXISTING_IP" ]]; then
        echo "Already up to date ($CURRENT_IP)"
        continue
    fi

    echo "Updating $DOMAIN from $EXISTING_IP to $CURRENT_IP"

    curl -s -X PUT \
        "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${RECORD_ID}" \
        -H "Authorization: Bearer ${CF_TOKEN}" \
        -H "Content-Type: application/json" \
        --data "{
            \"type\":\"A\",
            \"name\":\"${DOMAIN}\",
            \"content\":\"${CURRENT_IP}\",
            \"ttl\":1,
            \"proxied\":${PROXIED}
        }" | jq .

done
