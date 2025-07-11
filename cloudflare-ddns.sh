#!/bin/bash

# 使用者設定
api_token="xxxxxxxxxxxxxxxxxxxxxxxxxxxxx" # 你的 API Token
zone_name="Your main Domain"           	  # 根域名
record_name="Your sub Domain"             # 完整子域名
record_type="A"                           # A (IPv4) 或 AAAA (IPv6) 紀錄
ip_index="internet"                       # local 或 internet 使用本地方式還是網路方式取得 IP 位址
eth_card="eth0"                           # 使用本地取得方式時繫結的網卡，使用網路方式時此項設定無效
proxied=false                             # 不使用代理，設為僅進行 DNS 解析

# 檔案設定 (產生的檔案位置與 cloudflare-ddns.sh 相同)
ip_file="ip.txt"
id_file="cloudflare.ids"
log_file="cloudflare.log"

# 紀錄函式
log() {
    echo -e "[$(date)] $1" >> "$log_file"
}

# 擷取 IP
fetch_ip() {
    if [ "$record_type" = "AAAA" ]; then
        [ "$ip_index" = "internet" ] && ip=$(curl -6 -s ip.sb)
        [ "$ip_index" = "local" ] && ip=$(ip -6 addr show "$eth_card" | grep 'inet6' | awk '{print $2}' | grep -v 'fe80' | grep -v '^::1' | cut -d/ -f1 | head -1)
    elif [ "$record_type" = "A" ]; then
        [ "$ip_index" = "internet" ] && ip=$(curl -4 -s ip.sb)
        [ "$ip_index" = "local" ] && ip=$(ip -4 addr show "$eth_card" | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 | head -1)
    else
        log "❌ Unsupported DNS types: $record_type"
        exit 1
    fi

    if [ -z "$ip" ]; then
        log "❌ Unable to retrieve IP, please confirm the network card settings: $eth_card"
        exit 1
    fi
}

# 自動查詢 zone_id 和 record_id
get_ids() {
    zone_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone_name" \
        -H "Authorization: Bearer $api_token" \
        -H "Content-Type: application/json" | jq -r '.result[0].id')

    if [ -z "$zone_identifier" ]; then
        log "❌ Unable to obtain zone ID, please check whether zone_name exists: $zone_name"
        exit 1
    fi

    record_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?type=$record_type&name=$record_name" \
        -H "Authorization: Bearer $api_token" \
        -H "Content-Type: application/json" | jq -r '.result[0].id')

    if [ -z "$record_identifier" ]; then
        log "❌ Unable to obtain DNS record ID, please confirm whether record_name exists: $record_name"
        exit 1
    fi
}

# 檢查是否需要更新
log "🔍 Start checking if the IP has changed"
fetch_ip

if [ -f "$ip_file" ] && [ "$ip" = "$(cat $ip_file)" ]; then
    log "📌 IP unchanged: $ip, no need to update"
    echo "IP unchanged: $ip"
    exit 0
fi

# 查詢 DNS 記錄資訊
get_ids

# 執行更新
response=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" \
    -H "Authorization: Bearer $api_token" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"$record_type\",\"name\":\"$record_name\",\"content\":\"$ip\",\"ttl\":1,\"proxied\":$proxied}")

success=$(echo "$response" | jq -r '.success')

if [ "$success" = "true" ]; then
    echo "$ip" > "$ip_file"
    log "✅ IP update successful: $ip"
    echo "IP updated: $ip"
else
    log "❌ The update failed, and the API response is as follows: \n$response"
    echo -e "Update failed:\n$response"
    exit 1
fi
