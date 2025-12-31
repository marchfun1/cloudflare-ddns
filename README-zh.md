# Cloudflare DDNS 脚本 (V3.0)

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Bash](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/marchfun1/cloudflare-ddns)

这是一个基于 **Cloudflare API Token** 的轻量级 DDNS 更新脚本，特别针对树莓派 (Raspberry Pi) 与 Linux 服务器优化，支持 IPv4 与 IPv6 双栈更新。

[繁體中文](/README.md) | [简体中文] | [English](/README-EN.md)

---

### 🌟 功能特色

- **双栈支持**：完整支持 IPv4 (A 记录) 与 IPv6 (AAAA 记录)。
- **多组更新**：可同时管理两组以上的域名设置。
- **多供应商备援 (Multi-Provider)**：内置 4 组 IP 获取来源，避免单点故障。
- **配置分离**：代码与 `ddns.conf` 分离，升级脚本不需要重新配置。
- **自动日志管理**：支持日志滚动 (Rotation)，防止 .log 文件无限增长。
- **高鲁棒性**：自动检查依赖 (curl, jq)，具备完善的错误处理机制。
- **缓存判定**：针对不同记录类型独立缓存 IP，减少对 CF API 的无谓请求。

---

### 🛠️ 准备工作

1. **环境**：一台可联网的 Linux 设备（如 Debian, Ubuntu, Raspbian）。
2. **域名**：已托管于 Cloudflare。
3. **API Token**：
   - 登录 Cloudflare 账户。
   - 前往 [My Profile > API Tokens](https://dash.cloudflare.com/profile/api-tokens)。
   - 创建一个具有 `Zone.DNS` 编辑权限的令牌 (Token)。
4. **DNS 记录**：请先手动在 Cloudflare 面板建立好对应的 A 或 AAAA 记录。

---

### 🚀 快速开始

#### 1. 下载项目

```bash
git clone https://github.com/marchfun1/cloudflare-ddns.git
cd cloudflare-ddns
chmod +x cloudflare-ddns.sh
```

#### 2. 配置参数

编辑 `ddns.conf` 填入您的令牌与域名信息：

```bash
nano ddns.conf
```

#### 3. 手动测试

运行脚本确认是否更新成功：

```bash
./cloudflare-ddns.sh
```

若看到 `IP 成功更新为: xxx` 或 `日志中显示 IP 未变更` 即表示配置正确。

---

### 📅 自动化运行 (Crontab)

建议设置每 10 分钟检查一次 IP 变动：

1. 输入 `crontab -e`。
2. 在文件末尾加入以下内容（请修改为您的实际路径）：

```bash
*/10 * * * * /path/to/cloudflare-ddns/cloudflare-ddns.sh >/dev/null 2>&1
```

---

### ⚙️ 配置档详解 (ddns.conf)

| 参数 | 说明 | 示例 |
| :--- | :--- | :--- |
| `apitoken1` | Cloudflare API Token | `xxxxxx...` |
| `zonename1` | 根域名 (Root Domain) | `example.com` |
| `recordname1` | 子域名 (Subdomain) | `www` (更新根域名请留空) |
| `recordtype1` | 记录类型 | `A` (IPv4) 或 `AAAA` (IPv6) |
| `proxied1` | 是否开启 CF 代理 (小橘云) | `true` 或 `false` |

---

### 📄 授权条款

本项目基于 **GPL-3.0 License** 开源。欢迎提交 Issue 或 Pull Request 协助改进。

---
**原作者**: March Fun  
**官方网站**: [www.suma.tw](https://www.suma.tw)
