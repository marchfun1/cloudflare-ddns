#!/bin/bash

# 使用者設定
api_token="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" # 你的 API Token
zone_name="Your main Domain"           		   # 根域名
record_name="Your full Domain"                 # 完整子域名
record_type="A"                                # A (IPv4) 或 AAAA (IPv6) 紀錄
ip_index="internet"                       # local 或 internet 使用本地方式還是網路方式取得位址
eth_card="eth0"                           # 使用本地取得方式時繫結的網卡，使用網路方式可不變更
proxied=false                             # 不使用代理，設為僅進行 DNS 解析

# 檔案設定
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
        log "❌ 不支援的 DNS 類型：$record_type"
        exit 1
    fi

    if [ -z "$ip" ]; then
        log "❌ 無法擷取 IP，請確認網卡設定：$eth_card"
        exit 1
    fi
}

# 自動查詢 zone_id 和 record_id
get_ids() {
    zone_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone_name" \
        -H "Authorization: Bearer $api_token" \
        -H "Content-Type: application/json" | jq -r '.result[0].id')

    if [ -z "$zone_identifier" ]; then
        log "❌ 無法取得 zone ID，請檢查 zone_name 是否存在：$zone_name"
        exit 1
    fi

    record_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?type=$record_type&name=$record_name" \
        -H "Authorization: Bearer $api_token" \
        -H "Content-Type: application/json" | jq -r '.result[0].id')

    if [ -z "$record_identifier" ]; then
        log "❌ 無法取得 DNS 記錄 ID，請確認 record_name 是否存在：$record_name"
        exit 1
    fi
}

# 檢查是否需要更新
log "🔍 開始檢查 IP 是否有變動"
fetch_ip

if [ -f "$ip_file" ] && [ "$ip" = "$(cat $ip_file)" ]; then
    log "📌 IP 無變化：$ip，不需更新"
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
    log "✅ IP 更新成功：$ip"
    echo "IP updated: $ip"
else
    log "❌ 更新失敗，API 回傳如下：\n$response"
    echo -e "Update failed:\n$response"
    exit 1
fi
