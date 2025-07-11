# CloudFlare DDNS script/Raspberry pi IPV6 DDNS Solution 

#### cloudflare ddns 指令碼/樹莓派 IPv6/IPv4 DDNS

中文 | [English](/README-EN.md)

### 概述
本指令碼修改自 https://github.com/wherelse/cloudflare-ddns-script 原專案使用 Global API Key，並且程式碼已失效。
本專案修改成基於 cloudflare API Token 的 DDNS 指令碼，支援 IPv4 和 IPv6，可透過網路方式和本地方式取得指令碼安裝主機的 IP 位址，理論支援所有使用 linux 系統的主機，已在 debian 和 ubuntu 上測試可用。

### 使用指令碼前需要做的
1. 一台可上網的 liunx 裝置
2. 擁有一個域名，免費的或者收費的都可以
3. 註冊一個 CloudFlare 帳號 ( www.cloudflare.com )，並將需要使用的域名新增到帳號上，完成設定後根據需要加入服務裝置的 IPv6 位址加入一個 AAAA 解析，並設為僅進行 DNS 解析
4. 在 CloudFlare 帳號中建立 API Token (權杖) 並記錄下來，用於後續設定

### 使用方法
開啟指令視窗，執行以下程式：
```shell
wget https://raw.githubusercontent.com/marchfun1/cloudflare-ddns/master/cloudflare-ddns.sh
sudo chmod +x /home/username/cloudflare-ddns.sh #目錄根據實際使用者等進行變更
```
需要對指令碼內的個人設定資訊進行變更，目錄和上一筆指令保持一致
```shell
sudo nano /home/username/cloudflare-ddns.sh
#或
sudo vi /home/username/cloudflare-ddns.sh
```
找到如下內容進行變更
```shell
api_token="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" # 你的 API Token
zone_name="Your main Domain"           		     # 根域名
record_name="Your full Domain"                 # 完整子域名
record_type="A"                                # A (IPv4) 或 AAAA (IPv6) 紀錄

ip_index="internet"                       # local 或 internet 使用本地方式還是網路方式取得位址
eth_card="eth0"                           # 使用本地取得方式時繫結的網卡，使用網路方式可不變更
```
以任意一個域名為例，ipv6.google.com 這個域名，zone_name為 `google.com` 和 record_name 則為 `ipv6.google.com` ，修改完成後，儲存並離開。

在指令行中輸入以下內容執行指令碼：
```shell
bash /home/username/cloudflare-ddns.sh
```
如果提示 `IP changed to: xxxxx` 或 `IP has not changed.` 則說明設定成功了

**定時執行指令碼**
為了實現動態域名解析，必須讓指令碼保持執行以取得IP狀態，這裡使用系統crontab定時
在指令行輸入：`crontab -e` 後在檔案最後加入以下內容
```shell
*/5 * * * *  /home/username/cloudflare-ddns.sh >/dev/null 2>&1
```
變更完成後儲存並離開。
在這裡將指令碼設定為每五分鐘執行一次 `cloudflare-ddns.sh` 指令碼，就可以實現動態域名解析了。

### 結束
該指令碼不僅適用於樹莓派，在其他 Linux 伺服器上也適用，使用時都需要根據自己的實際情況變更以上設定時使用的路徑

### FAQ
錯誤記錄為以下內容時：
`API UPDATE FAILED. DUMPING RESULTS:`
`{"success":false,"errors":[{"code":7001,"message":"Method PUT not available for that URI."}],"messages":[],"result":null}`
刪除指令碼執行目錄下的`cloudflare.ids`檔案，然後再次嘗試執行。
