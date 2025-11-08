#!/bin/bash

# 第一組網域設定
apitoken1="填入API_TOKEN_1" # 你的 API Token xxxxxxxxxxxxxxxxxxxxxxxxxxxx
zonename1="example.com"     # 根域名
recordname1="www"           # 子域名 (主機名) 更新根域名時可留空
recordtype1="A"             # A (IPv4) 或 AAAA (IPv6) 紀錄
proxied1="false"            # 不使用代理，設為僅進行 DNS 解析

# 第二組網域設定（只更新一組網域時可以不設定全部留空）
apitoken2=""
zonename2=""
recordname2=""
recordtype2="A"
proxied2="false"

ipfile="ip.txt"
logfile="cloudflare-ddns.log"

log() {
    echo -e "$(date '+%F %T') $@" >> "$logfile"
}

fetch_ip() {
    local rt="$1"
    local ip=""
    if [[ "$rt" == "AAAA" ]]; then
        ip=$(curl -6 -s ip.sb)
    else
        ip=$(curl -4 -s ip.sb)
    fi
    echo "$ip"
}

update_dns() {
    local apitoken="$1"
    local zonename="$2"
    local recordname="$3"
    local recordtype="$4"
    local ip="$5"
    local proxied="$6"

    local zoneid=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${zonename}" \
      -H "Authorization: Bearer ${apitoken}" -H "Content-Type: application/json" | jq -r '.result[0].id')
    if [[ -z "$zoneid" ]]; then log "[$zonename] 取得 ZoneID 失敗"; return 1; fi

    local rec_name
    if [[ -z "$recordname" ]]; then
        rec_name="$zonename"
    else
        rec_name="${recordname}.${zonename}"
    fi

    local recid=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${zoneid}/dns_records?type=${recordtype}&name=${rec_name}" \
      -H "Authorization: Bearer ${apitoken}" -H "Content-Type: application/json" | jq -r '.result[0].id')
    if [[ -z "$recid" ]]; then log "[$zonename] 取得紀錄 ID 失敗"; return 1; fi

    local update_json="{\"type\":\"${recordtype}\",\"name\":\"${rec_name}\",\"content\":\"${ip}\",\"ttl\":1,\"proxied\":${proxied}}"
    local resp=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${zoneid}/dns_records/${recid}" \
      -H "Authorization: Bearer ${apitoken}" -H "Content-Type: application/json" --data "$update_json")
    local success=$(echo $resp | jq -r '.success')
    if [[ "$success" == "true" ]]; then
        log "[$zonename] IP 更新成功: $ip"
    else
        log "[$zonename] IP 更新失敗: $resp"
    fi
}

# ---- 取得最新外部 IP ----
ip1=$(fetch_ip "$recordtype1")
if [[ -z "$ip1" ]]; then 
    log "取得 IP 失敗"
    exit 1
fi

# 檢查IP是否變動
if [[ -f "$ipfile" ]]; then
    oldip=$(cat "$ipfile")
else
    oldip=""
fi

if [[ "$ip1" == "$oldip" ]]; then
    log "IP 未變更: $ip1"
    exit 0
fi

# ---- 執行第一組 ----
if [[ -n "$zonename1" && -n "$apitoken1" ]]; then
    update_dns "$apitoken1" "$zonename1" "$recordname1" "$recordtype1" "$ip1" "$proxied1"
fi

# ---- 執行第二組（只有參數設定才執行） ----
if [[ -n "$zonename2" && -n "$recordname2" && -n "$apitoken2" ]]; then
    update_dns "$apitoken2" "$zonename2" "$recordname2" "$recordtype2" "$ip1" "$proxied2"
fi

echo "$ip1" > "$ipfile"
