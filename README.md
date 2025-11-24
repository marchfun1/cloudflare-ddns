# CloudFlare DDNS script/Raspberry pi IPv4/IPv6 動態 DNS 更新方案

#### cloudflare ddns 指令碼/樹莓派 IPv6/IPv4 DDNS

中文 | [English](/README-EN.md)

### 概述
本指令碼修改自 https://github.com/wherelse/cloudflare-ddns-script 原專案使用 Global API Key，並且程式碼已失效。
本專案修改成基於 cloudflare API Token 的 DDNS 指令碼，支援 IPv4 和 IPv6，可透過網路方式和本地方式取得指令碼安裝主機的 IP 位址，理論支援所有使用 linux 系統的主機，已在 debian 和 ubuntu 上測試可用。

### 使用指令碼前需要做的
1. 一台可上網的 liunx 裝置
2. 擁有一個域名，免費的或者收費的都可以
3. 註冊一個 CloudFlare 帳號 ( www.cloudflare.com )，並將需要使用的域名新增到帳號上，完成設定後根據需要加入服務裝置的 A 或 AAAA 紀錄，並設為僅進行 DNS 解析
4. 在 CloudFlare 帳號中建立 API Token (權杖) 並記錄下來，用於後續設定

### 使用方法
開啟指令視窗，執行以下程式：
```shell
wget https://raw.githubusercontent.com/marchfun1/cloudflare-ddns/master/cloudflare-ddns.sh
sudo chmod +x /home/username/cloudflare-ddns.sh #目錄根據實際使用者等進行變更
```
需要對指令碼內的網域資訊進行設定
```shell
sudo nano /home/username/cloudflare-ddns.sh
#或
sudo vi /home/username/cloudflare-ddns.sh
```
本程式設計可同時更新兩個網域。若只想更新一個網域，第二組網域設定請留空。
找到如下內容進行變更：

```shell
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
```
以任意一個域名為例，www.google.com 這個域名，zonename1 為 `google.com` 和 recordname1 則為 `www` ，recordname1 為空的話則會更新根域名 `google.com` 記錄。修改完成後，儲存並離開。

在指令行中輸入以下內容執行指令碼：
```shell
bash /home/username/cloudflare-ddns.sh
```
如果提示 `IP 更新成功: xxxxx` 或 `IP 未變更: xxxxx` 則說明設定成功了

**定時執行指令碼**
為了實現動態域名解析，必須讓指令碼保持執行以取得 IP 狀態，這裡使用系統 crontab 定時
在指令行輸入：`sudo crontab -e` 後在檔案最後加入以下內容
```shell
*/10 * * * *  /home/username/cloudflare-ddns.sh >/dev/null 2>&1
```
變更完成後儲存並離開。
在這裡將指令碼設定為每十分鐘執行一次 `cloudflare-ddns.sh` 指令碼，就可以實現動態域名解析了。

### 結語
該指令碼不僅適用於樹莓派，在其他 Linux 伺服器上也適用，使用時都需要根據自己的實際情況變更以上設定時使用的路徑

