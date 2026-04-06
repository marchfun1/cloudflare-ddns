# Cloudflare DDNS 腳本 (V3.0.2)

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Bash](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/marchfun1/cloudflare-ddns)

這是一個基於 **Cloudflare API Token** 的輕量級 DDNS 更新腳本，特別針對樹莓派 (Raspberry Pi) 與 Linux 伺服器優化，支援 IPv4 與 IPv6 雙棧更新。

[繁體中文] | [简体中文](/README-zh.md) | [English](/README-EN.md)

---

### 🌟 功能特色

- **雙棧支援**：完整支援 IPv4 (A 記錄) 與 IPv6 (AAAA 記錄)。
- **多組更新**：可同時管理兩組以上的網域設定。
- **多供應商備援 (Multi-Provider)**：內建 4 組 IP 取得來源，避免單點故障。
- **設定分離**：程式碼與 `ddns.conf` 分離，升級腳本不需重新設定。
- **自動日誌管理**：支援日誌滾動 (Rotation)，防止 .log 檔案無限增長。
- **高強健性**：自動檢查依賴 (curl, jq)，具備完整的錯誤處理機制。
- **快取判定**：針對不同記錄類型獨立快取 IP，減少對 CF API 的無謂請求。

---

### 🛠️ 準備工作

1. **環境**：一台可連網的 Linux 裝置（如 Debian, Ubuntu, Raspbian）。
2. **域名**：已託管於 Cloudflare。
3. **API Token**：
   - 登入 Cloudflare 帳戶。
   - 前往 [我的設定檔 > API 權杖](https://dash.cloudflare.com/profile/api-tokens)。
   - 建立一個具有 `Zone.DNS` 編輯權限的權杖 (Token)。
4. **DNS 記錄**：請先手動在 Cloudflare 面板建立好對應的 A 或 AAAA 記錄。

---

### 🚀 快速開始

#### 1. 下載專案

```bash
git clone https://github.com/marchfun1/cloudflare-ddns.git
cd cloudflare-ddns
chmod +x cloudflare-ddns.sh
```

#### 2. 設定參數

複製範例設定檔並填入您的權仗與域名資訊：

```bash
cp ddns.conf.example ddns.conf
nano ddns.conf
```

#### 3. 手動測試

執行腳本確認是否更新成功：

```bash
./cloudflare-ddns.sh
```

若看到 `IP 成功更新為: xxx` 或 `日誌中顯示 IP 未變更` 即表示設定正確。

---

### 📅 自動化執行 (Crontab)

建議設定每 10 分鐘檢查一次 IP 變動：

1. 輸入 `crontab -e`。
2. 在檔案末尾加入以下內容（請修正為您的實際路徑）：

```bash
*/10 * * * * /path/to/cloudflare-ddns/cloudflare-ddns.sh
```

---

### 🔄 如何更新

若要更新至最新版本，請在專案目錄執行：

```bash
git pull
chmod +x cloudflare-ddns.sh
```

**手動更新：**  
若您不是透過 `git clone` 安裝，可以直接從 GitHub 下載最新的 `cloudflare-ddns.sh` 覆蓋舊檔。請注意，更新後必須再次檢查檔案權限，確保腳本具備可執行權限：`chmod +x cloudflare-ddns.sh`。

---

### ⚙️ 設定檔詳解 (ddns.conf)

| 參數 | 說明 | 範例 |
| :--- | :--- | :--- |
| `apitoken1` | Cloudflare API Token | `xxxxxx...` |
| `zonename1` | 根域名 (Root Domain) | `example.com` |
| `recordname1` | 子域名 (Subdomain) | `www` (更新根域名請留空) |
| `recordtype1` | 紀錄類型 | `A` (IPv4) 或 `AAAA` (IPv6) |
| `proxied1` | 是否開啟 CF 代理 (小橘雲) | `true` 或 `false` |

---

### 📄 授權條款

本專案基於 **GPL-3.0 License** 開源。歡迎提交 Issue 或 Pull Request 協助改進。

---
**原作者**: 域創數位工作室 (LOCALSOFT Digital Studio)  
**官方網站**: [suma.tw](https://suma.tw)
