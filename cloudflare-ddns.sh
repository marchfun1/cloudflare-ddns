#!/usr/bin/env bash
set -euo pipefail
# --------------------------------------------------
# Updated: 2026-06-11 23:20:00 (UTC+8)
# Version: 3.0.3
# Author: 域創數位工作室 (LOCALSOFT Digital Studio)
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
    # 檢查設定檔權限，若其他使用者有讀寫權限則發出警告 (避免 API Token 洩漏)
    if command -v stat &>/dev/null; then
        perms=$(stat -c "%a" "$CONFIG_FILE" 2>/dev/null || true)
        if [[ -n "$perms" && "${perms: -1}" != "0" ]]; then
            echo "Warning: Config file $CONFIG_FILE permissions are too open (permissions $perms), which may leak the API Token. Recommended action: chmod 600 $CONFIG_FILE" >&2
        fi
    fi
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
else
    echo "Error: Configuration file $CONFIG_FILE not found"
    exit 1
fi

# 預設值與檔案路徑
# 確保日誌路徑為絕對路徑 (處理相對路徑設定)
if [[ -n "${logfile:-}" && "$logfile" != /* && "$logfile" != *:* ]]; then
    logfile="${SCRIPT_DIR}/${logfile}"
fi
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
        echo "Error: Missing required dependencies: ${missing_deps[*]}"
        exit 1
    fi
}

log() {
    local message="$@"
    local timestamp=$(date '+%F %T')
    # 輸出到 Log 檔案，使用 printf 避免 echo -e 造成跳脫字元被解析的風險
    printf "%s %s\n" "$timestamp" "$message" >> "$logfile"
    # 如果是在終端機執行，也同時輸出到 stderr 以便觀察
    if [ -t 2 ]; then
        printf "%s %s\n" "$timestamp" "$message" >&2
    fi
    
    # 日誌滾動檢查
    if [[ -f "$logfile" ]]; then
        local current_size=$(stat -c%s "$logfile" 2>/dev/null || stat -f%z "$logfile" 2>/dev/null || echo 0)
        if (( current_size > max_log_size )); then
            if tail -n 100 "$logfile" > "${logfile}.tmp" 2>/dev/null && mv "${logfile}.tmp" "$logfile" 2>/dev/null; then
                log "[System] Log size exceeded limit, cleared old entries"
            else
                rm -f "${logfile}.tmp" 2>/dev/null || true
            fi
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

    # 驗證域名與記錄名稱格式安全 (僅允許英數、點、減號)，防止非預期字元破壞 URL 結構
    if [[ ! "$zonename" =~ ^[a-zA-Z0-9.-]+$ ]]; then
        log "Error: Domain '$zonename' format is incorrect, only alphanumeric characters, dots, and hyphens are allowed"
        return 1
    fi
    if [[ -n "$recordname" && ! "$recordname" =~ ^[a-zA-Z0-9.-]+$ ]]; then
        log "Error: Record name '$recordname' format is incorrect, only alphanumeric characters, dots, and hyphens are allowed"
        return 1
    fi

    # 取得 Zone ID (安全地使用 || echo "" 確保網路或 API 異常時不致令 set -e 中斷腳本)
    local zoneid
    zoneid=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${zonename}" \
      -H "Authorization: Bearer ${apitoken}" -H "Content-Type: application/json" 2>/dev/null | jq -r '.result[0].id // empty' 2>/dev/null || echo "")
    
    if [[ -z "$zoneid" || "$zoneid" == "null" ]]; then 
        log "[$zonename] Error: Failed to retrieve ZoneID. Please check network connection, domain, and API Token"
        return 1
    fi

    # 組合完整記錄名稱
    local rec_name=$([[ -z "$recordname" ]] && echo "$zonename" || echo "${recordname}.${zonename}")

    # 取得 Record ID (安全地使用 || echo "" 確保網路或 API 異常時不致令 set -e 中斷腳本)
    local recid
    recid=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${zoneid}/dns_records?type=${recordtype}&name=${rec_name}" \
      -H "Authorization: Bearer ${apitoken}" -H "Content-Type: application/json" 2>/dev/null | jq -r '.result[0].id // empty' 2>/dev/null || echo "")
    
    if [[ -z "$recid" || "$recid" == "null" ]]; then 
        log "[$zonename] Error: Failed to retrieve record ID. Please make sure ${rec_name} (${recordtype}) exists in Cloudflare"
        return 1
    fi

    # 安全地組合 JSON 資料，防止 JSON 注入攻擊
    local proxied_bool="false"
    [[ "$proxied" == "true" ]] && proxied_bool="true"
    
    local update_json
    update_json=$(jq -n \
        --arg type "$recordtype" \
        --arg name "$rec_name" \
        --arg content "$ip" \
        --argjson proxied "$proxied_bool" \
        '{type: $type, name: $name, content: $content, ttl: 1, proxied: $proxied}')

    # 安全地使用 || echo "" 確保網路或 API 異常時不致令 set -e 中斷腳本
    local resp
    resp=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${zoneid}/dns_records/${recid}" \
      -H "Authorization: Bearer ${apitoken}" -H "Content-Type: application/json" --data "$update_json" 2>/dev/null || echo "")
    
    local success
    success=$(echo "$resp" | jq -r '.success // false' 2>/dev/null || echo "false")
    if [[ "$success" == "true" ]]; then
        log "[$rec_name] IP successfully updated to: $ip"
    else
        local errors
        errors=$(echo "$resp" | jq -r '.errors[]?.message' 2>/dev/null || echo "")
        log "[$rec_name] Error: IP update failed: ${errors:-Unknown error/Network connection failed}"
        return 1
    fi
}

process_group() {
    local token="$1" zone="$2" record="$3" type="$4" proxied="$5"
    [[ -z "$token" || -z "$zone" ]] && return 0

    local current_ip=$(fetch_ip "$type")
    if [[ -z "$current_ip" ]]; then
        log "[$zone] Error: Failed to retrieve $type IP, skipping this group"
        return 1
    fi

    # 清理變數中的特殊字元，避免路徑穿越 (Path Traversal) 漏洞
    local safe_zone="${zone//[^a-zA-Z0-9.-]/_}"
    local safe_record="${record//[^a-zA-Z0-9.-]/_}"
    local ip_cache_file="${SCRIPT_DIR}/ip_${type}_${safe_zone}_${safe_record:-root}.txt"
    
    # 檢查目錄寫入權限 (僅在首次需要建立檔案時檢查，避免重複)
    if [[ ! -f "$ip_cache_file" && ! -w "$SCRIPT_DIR" ]]; then
        log "[$zone] Critical Error: Unable to write to directory $SCRIPT_DIR, cannot create cache file"
        return 1
    fi

    local old_ip=""
    [[ -f "$ip_cache_file" ]] && old_ip=$(cat "$ip_cache_file")

    if [[ "$current_ip" == "$old_ip" ]]; then
        # IP 未變更，安靜離開
        return 0
    fi

    # 嘗試更新
    if update_dns "$token" "$zone" "$record" "$type" "$current_ip" "$proxied"; then
        # 只有在更新成功後，才寫入快取
        if echo "$current_ip" > "$ip_cache_file"; then
            log "[$zone] Cache file updated: $ip_cache_file"
        else
             log "[$zone] Warning: API update successful, but failed to write to cache file (insufficient permissions?)"
        fi
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
