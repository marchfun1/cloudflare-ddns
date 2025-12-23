#!/usr/bin/env bash
set -euo pipefail
# --------------------------------------------------
# Updated: 2025-11-25 23:24:03 (UTC+8)
# Version: 2.0
# Author: March Fun
# URL: https://www.suma.tw
# --------------------------------------------------
# --------------------------------------------------
# 說明: 使用 Cloudflare API Token 的 DDNS 更新腳本，支援 IPv4 與 IPv6
# 授權: MIT License
# 依賴: curl, jq (可使用 apt/yum/brew 安裝)
# 使用方式: 設定腳本內的 apitoken、zonename、recordname 等變數後執行
# --------------------------------------------------

# 第一組網域設定  # First group domain settings
apitoken1="填入API_TOKEN_1" # 你的 API Token xxxxxxxxxxxxxxxxxxxxxxxxxxxx  # Your API Token
zonename1="example.com"     # 根域名  # Root domain
recordname1="www"           # 子域名 (主機名) 更新根域名時可留空  # Subdomain (hostname); leave empty to update root domain
recordtype1="A"             # A (IPv4) 或 AAAA (IPv6) 紀錄  # Record type: A (IPv4) or AAAA (IPv6)
proxied1="false"            # 不使用代理，設為僅進行 DNS 解析  # Do not use proxy; DNS-only mode

# 第二組網域設定（只更新一組網域時可以不設定全部留空）  # Second group domain settings (can be left empty if only updating one domain)
apitoken2=""
zonename2=""
recordname2=""
recordtype2="A"
proxied2="false"

# 使用腳本目錄作為檔案路徑  # Use script directory for file paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ipfile="${SCRIPT_DIR}/ip.txt"
logfile="${SCRIPT_DIR}/cloudflare-ddns.log"

# 檢查必要的依賴  # Check required dependencies
check_dependencies() {
    local missing_deps=()
    
    if ! command -v curl &>/dev/null; then
        missing_deps+=("curl")
    fi
    
    if ! command -v jq &>/dev/null; then
        missing_deps+=("jq")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "錯誤: 缺少必要的依賴程式: ${missing_deps[*]}"  # Error: Missing required tools
        echo "請使用以下命令安裝:"  # Please install with:
        echo "  Debian/Ubuntu: sudo apt-get install ${missing_deps[*]}"
        echo "  CentOS/RHEL: sudo yum install ${missing_deps[*]}"
        exit 1
    fi
}

log() {
    echo -e "$(date '+%F %T') $@" >> "$logfile"
}

fetch_ip() {
    local rt="$1"
    local ip=""
    if [[ "$rt" == "AAAA" ]]; then
        ip=$(curl -6 -s --max-time 10 ip.sb 2>/dev/null)
    else
        ip=$(curl -4 -s --max-time 10 ip.sb 2>/dev/null)
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

    # 取得 Zone ID  # Retrieve Zone ID
    local zoneid=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${zonename}" \
      -H "Authorization: Bearer ${apitoken}" -H "Content-Type: application/json" | jq -r '.result[0].id // empty')
    if [[ -z "$zoneid" || "$zoneid" == "null" ]]; then 
        log "[$zonename] 取得 ZoneID 失敗,請檢查域名和 API Token"  # Failed to obtain Zone ID, check domain and API token
        return 1
    fi

    # 組合完整記錄名稱  # Construct full record name
    local rec_name
    if [[ -z "$recordname" ]]; then
        rec_name="$zonename"
    else
        rec_name="${recordname}.${zonename}"
    fi

    # 取得 Record ID  # Retrieve Record ID
    local recid=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${zoneid}/dns_records?type=${recordtype}&name=${rec_name}" \
      -H "Authorization: Bearer ${apitoken}" -H "Content-Type: application/json" | jq -r '.result[0].id // empty')
    if [[ -z "$recid" || "$recid" == "null" ]]; then 
        log "[$zonename] 取得紀錄 ID 失敗,請確認 DNS 記錄 ${rec_name} (${recordtype}) 已存在"  # Failed to obtain Record ID, ensure DNS record exists
        return 1
    fi

    # 更新 DNS 記錄  # Update DNS record
    local update_json="{\"type\":\"${recordtype}\",\"name\":\"${rec_name}\",\"content\":\"${ip}\",\"ttl\":1,\"proxied\":${proxied}}"
    local resp=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${zoneid}/dns_records/${recid}" \
      -H "Authorization: Bearer ${apitoken}" -H "Content-Type: application/json" --data "$update_json")
    local success=$(echo "$resp" | jq -r '.success // false')
    if [[ "$success" == "true" ]]; then
        log "[$zonename] IP 更新成功: $ip"  # IP update successful
    else
        local errors=$(echo "$resp" | jq -r '.errors[]?.message' 2>/dev/null)
        log "[$zonename] IP 更新失敗: ${errors:-未知錯誤}"  # IP update failed
        return 1
    fi
}

check_dependencies
# ---- 取得最新外部 IP ----  # Fetch the latest external IP
ip1=$(fetch_ip "$recordtype1")
if [[ -z "$ip1" ]]; then 
    log "取得 IP 失敗,請檢查網路連線"  # Failed to obtain IP, check network connection
    exit 1
fi

# 檢查 IP 是否變動  # Check if IP has changed
if [[ -f "$ipfile" ]]; then
    oldip=$(cat "$ipfile" 2>/dev/null)
else
    oldip=""
fi

if [[ "$ip1" == "$oldip" ]]; then
    log "IP 未變更: $ip1"  # IP unchanged
    exit 0
fi

# ---- 執行第一組 ----  # Execute first domain group
if [[ -n "$zonename1" && -n "$apitoken1" ]]; then
    update_dns "$apitoken1" "$zonename1" "$recordname1" "$recordtype1" "$ip1" "$proxied1"
fi

# ---- 執行第二組（只有參數設定才執行） ----  # Execute second domain group if configured
if [[ -n "$zonename2" && -n "$apitoken2" ]]; then
    if [[ "$recordtype2" != "$recordtype1" ]]; then
        ip2=$(fetch_ip "$recordtype2")
        if [[ -n "$ip2" ]]; then
            update_dns "$apitoken2" "$zonename2" "$recordname2" "$recordtype2" "$ip2" "$proxied2"
        else
            log "取得第二組 IP 失敗"  # Failed to obtain IP for second group
        fi
    else
        update_dns "$apitoken2" "$zonename2" "$recordname2" "$recordtype2" "$ip1" "$proxied2"
    fi
fi

# 儲存當前 IP  # Save current IP
echo "$ip1" > "$ipfile"
