#!/usr/bin/env bash
set -euo pipefail
# --------------------------------------------------
# Updated: 2025-12-31 12:45:00 (UTC+8)
# Version: 3.0
# Author: March Fun
# URL: https://suma.tw
# --------------------------------------------------
# 說明: 使用 Cloudflare API Token 的 DDNS 更新腳本，支援 IPv4 與 IPv6
# 授權: GPL-3.0 License
# 依賴: curl, jq
# --------------------------------------------------

# 腳本目錄
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 載入設定檔
CONFIG_FILE="${SCRIPT_DIR}/ddns.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
else
    echo "錯誤: 找不到設定檔 $CONFIG_FILE"
    exit 1
fi

# 預設值與檔案路徑
logfile="${logfile:-${SCRIPT_DIR}/cloudflare-ddns.log}"
max_log_size="${max_log_size:-1048576}" # 預設 1MB

# 檢查必要的依賴
check_dependencies() {
    local missing_deps=()
    for dep in curl jq; do
        if ! command -v "$dep" &>/dev/null; then
            missing_deps+=("$dep")
        fi
    done
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "錯誤: 缺少必要的依賴程式: ${missing_deps[*]}"
        exit 1
    fi
}

log() {
    local message="$@"
    echo -e "$(date '+%F %T') $message" >> "$logfile"
    
    # 日誌滾動檢查
    if [[ -f "$logfile" ]]; then
        local current_size=$(stat -c%s "$logfile" 2>/dev/null || stat -f%z "$logfile" 2>/dev/null || echo 0)
        if (( current_size > max_log_size )); then
            tail -n 100 "$logfile" > "${logfile}.tmp" && mv "${logfile}.tmp" "$logfile"
            log "[System] 日誌超過限制，已清理舊紀錄"
        fi
    fi
}

fetch_ip() {
    local rt="$1"
    local ip=""
    local providers=()
    if [[ "$rt" == "AAAA" ]]; then
        providers=(
            "https://v6.ident.me"
            "https://api6.ipify.org"
            "https://v6.ip.sb"
            "https://ipv6.icanhazip.com"
        )
        for url in "${providers[@]}"; do
            ip=$(curl -6 -s --max-time 5 "$url" 2>/dev/null | grep -E '^([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])' | tr -d '[:space:]' || true)
            [[ -n "$ip" ]] && break
        done
    else
        providers=(
            "https://v4.ident.me"
            "https://api.ipify.org"
            "https://v4.ip.sb"
            "https://ipv4.icanhazip.com"
        )
        for url in "${providers[@]}"; do
            ip=$(curl -4 -s --max-time 5 "$url" 2>/dev/null | grep -E '([0-9]{1,3}\.){3}[0-9]{1,3}' | tr -d '[:space:]' || true)
            [[ -n "$ip" ]] && break
        done
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

    # 取得 Zone ID
    local zoneid=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${zonename}" \
      -H "Authorization: Bearer ${apitoken}" -H "Content-Type: application/json" | jq -r '.result[0].id // empty')
    
    if [[ -z "$zoneid" || "$zoneid" == "null" ]]; then 
        log "[$zonename] 取得 ZoneID 失敗，請檢查域名和 API Token"
        return 1
    fi

    # 組合完整記錄名稱
    local rec_name=$([[ -z "$recordname" ]] && echo "$zonename" || echo "${recordname}.${zonename}")

    # 取得 Record ID
    local recid=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${zoneid}/dns_records?type=${recordtype}&name=${rec_name}" \
      -H "Authorization: Bearer ${apitoken}" -H "Content-Type: application/json" | jq -r '.result[0].id // empty')
    
    if [[ -z "$recid" || "$recid" == "null" ]]; then 
        log "[$zonename] 取得紀錄 ID 失敗，請確認 ${rec_name} (${recordtype}) 已存在於 CF 中"
        return 1
    fi

    # 更新 DNS 記錄
    local update_json="{\"type\":\"${recordtype}\",\"name\":\"${rec_name}\",\"content\":\"${ip}\",\"ttl\":1,\"proxied\":${proxied}}"
    local resp=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${zoneid}/dns_records/${recid}" \
      -H "Authorization: Bearer ${apitoken}" -H "Content-Type: application/json" --data "$update_json")
    
    local success=$(echo "$resp" | jq -r '.success // false')
    if [[ "$success" == "true" ]]; then
        log "[$rec_name] IP 成功更新為: $ip"
    else
        local errors=$(echo "$resp" | jq -r '.errors[]?.message' 2>/dev/null)
        log "[$rec_name] IP 更新失敗: ${errors:-未知錯誤}"
        return 1
    fi
}

process_group() {
    local token="$1" zone="$2" record="$3" type="$4" proxied="$5"
    [[ -z "$token" || -z "$zone" ]] && return 0

    local current_ip=$(fetch_ip "$type")
    if [[ -z "$current_ip" ]]; then
        log "[$zone] 取得 $type IP 失敗，跳過此組"
        return 1
    fi

    local ip_cache_file="${SCRIPT_DIR}/.ip_${type}_${zone}_${record:-root}.txt"
    local old_ip=""
    [[ -f "$ip_cache_file" ]] && old_ip=$(cat "$ip_cache_file")

    if [[ "$current_ip" == "$old_ip" ]]; then
        # 為了保持日誌整潔，IP 未變更時可選擇是否記錄
        # log "[$zone] IP 未變更 ($current_ip)"
        return 0
    fi

    if update_dns "$token" "$zone" "$record" "$type" "$current_ip" "$proxied"; then
        echo "$current_ip" > "$ip_cache_file"
    fi
}

# 主執行邏輯
main() {
    check_dependencies
    
    # 處理第一組
    process_group "${apitoken1:-}" "${zonename1:-}" "${recordname1:-}" "${recordtype1:-A}" "${proxied1:-false}"
    
    # 處理第二組
    process_group "${apitoken2:-}" "${zonename2:-}" "${recordname2:-}" "${recordtype2:-A}" "${proxied2:-false}"
}

main "$@"
