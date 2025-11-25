# CloudFlare DDNS 脚本 / Raspberry Pi IPv4/IPv6 动态 DNS 更新方案

#### cloudflare ddns 脚本 / 树莓派 IPv6/IPv4 DDNS

中文 | [English](/README-EN.md)

### 概述
本脚本改自 https://github.com/wherelse/cloudflare-ddns-script，原项目使用 Global API Key，代码已失效。
本项目将其改为基于 Cloudflare API Token 的 DDNS 脚本，支持 IPv4 和 IPv6，可通过网络方式获取运行主机的 IP 地址，理论上支持所有使用 Linux 系统的主机，已在 Debian 和 Ubuntu 上测试可用。

### 功能特色
- ✅ 支持 IPv4 (A 记录) 和 IPv6 (AAAA 记录)
- ✅ 可同时更新两个域名，支持不同记录类型（例如：一个 IPv4，一个 IPv6）
- ✅ 自动检查必要依赖（curl 和 jq）
- ✅ 完善的错误处理和日志记录
- ✅ 使用绝对路径，避免在不同目录执行时产生问题

### 使用脚本前需要做的准备
1. 一台可以上网的 Linux 设备
2. 拥有一个域名，免费或付费均可
3. 注册一个 Cloudflare 账户 (www.cloudflare.com)，并将需要使用的域名添加到账户中，完成设置后根据需要在服务设备上添加 A 或 AAAA 记录，并设置为仅进行 DNS 解析
4. 在 Cloudflare 账户中创建 API Token（令牌），并记录下来，用于后续配置
5. 确保系统已安装 `curl` 和 `jq`（脚本会自动检查并提示安装方法）

### 使用方法
打开终端，执行以下命令：
```shell
wget https://raw.githubusercontent.com/marchfun1/cloudflare-ddns/master/cloudflare-ddns.sh
sudo chmod +x /home/username/cloudflare-ddns.sh  # 根据实际用户路径调整目录
```
需要对脚本内的域名信息进行设置：
```shell
sudo nano /home/username/cloudflare-ddns.sh
# 或
sudo vi /home/username/cloudflare-ddns.sh
```

### 配置说明
本程序可同时更新两个域名。若只想更新一个域名，第二组域名设置请留空。
找到如下内容进行修改：
```shell
# 第一组域名设置
apitoken1="填入API_TOKEN_1" # 你的 API Token xxxxxxxxxxxxxxxxxxxxxxxxxxxx
zonename1="example.com"     # 根域名
recordname1="www"           # 子域名（主机名），更新根域名时可留空
recordtype1="A"             # A (IPv4) 或 AAAA (IPv6) 记录
proxied1="false"            # 不使用代理，设为仅进行 DNS 解析

# 第二组域名设置（只更新一组域名时可以留空）
apitoken2=""
zonename2=""
recordname2=""              # 同样可以留空以更新根域名
recordtype2="A"
proxied2="false"
```

**配置示例：**
- 以 `www.google.com` 为例：`zonename1` 为 `google.com`，`recordname1` 为 `www`
- 若要更新根域名 `google.com`：`zonename1` 为 `google.com`，`recordname1` 留空
- 同时更新 IPv4 和 IPv6：第一组设置 `recordtype1="A"`，第二组设置 `recordtype2="AAAA"`（脚本会自动获取对应的 IP）

修改完成后，保存并退出。

在终端中输入以下内容执行脚本：
```shell
bash /home/username/cloudflare-ddns.sh
```
如果提示 `IP 更新成功: xxxxx` 或 `IP 未变更: xxxxx` 则说明设置成功。

**定时执行脚本**
为了实现动态域名解析，需要让脚本定期运行以获取 IP 状态，这里使用系统 crontab 定时。
在终端输入：`sudo crontab -e`，在文件末尾加入以下内容：
```shell
*/10 * * * *  /home/username/cloudflare-ddns.sh > /dev/null 2>&1
```
保存并退出。这样脚本每十分钟执行一次，即可实现动态域名解析。

### 结语
该脚本不仅适用于树莓派，也适用于其他 Linux 服务器，使用时需要根据自己的实际情况修改上述路径和配置。
