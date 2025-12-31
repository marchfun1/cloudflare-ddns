# Cloudflare DDNS Script (V3.0)

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Bash](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/marchfun1/cloudflare-ddns)

A lightweight DDNS update script based on **Cloudflare API Token**. Optimized for Raspberry Pi and Linux servers, supporting IPv4 and IPv6 dual-stack updates.

[繁體中文](README.md) | [简体中文](README-zh.md) | [English]

---

### 🌟 Features

- **Dual-Stack Support**: Full support for IPv4 (A records) and IPv6 (AAAA records).
- **Multiple Domain Sets**: Manage more than two domain configurations simultaneously.
- **Multi-Provider Redundancy**: Built-in 4 IP fetch sources to avoid single points of failure.
- **Config Separation**: Logic is separated from `ddns.conf`, making updates hassle-free.
- **Automatic Log Management**: Supports log rotation to prevent `.log` files from growing indefinitely.
- **High Robustness**: Auto-checks dependencies (curl, jq) with comprehensive error handling.
- **Cache Mechanism**: Independently caches IP for different record types, reducing unnecessary API calls to Cloudflare.

---

### 🛠️ Prerequisites

1. **Environment**: A Linux device with internet access (e.g., Debian, Ubuntu, Raspbian).
2. **Domain**: Already managed by Cloudflare.
3. **API Token**:
   - Log in to your Cloudflare account.
   - Go to [My Profile > API Tokens](https://dash.cloudflare.com/profile/api-tokens).
   - Create a token with `Zone.DNS` edit permissions.
4. **DNS Records**: Manually create corresponding A or AAAA records in the Cloudflare dashboard first.

---

### 🚀 Quick Start

#### 1. Download Project

```bash
git clone https://github.com/marchfun1/cloudflare-ddns.git
cd cloudflare-ddns
chmod +x cloudflare-ddns.sh
```

#### 2. Configure Parameters

Edit `ddns.conf` and fill in your token and domain info:

```bash
nano ddns.conf
```

#### 3. Manual Test

Run the script to verify if it works:

```bash
./cloudflare-ddns.sh
```

If you see `IP successfully updated to: xxx` or `IP unchanged` in the log, the setup is correct.

---

### 📅 Automation (Crontab)

It is recommended to check for IP changes every 10 minutes:

1. Type `crontab -e`.
2. Add the following line at the end (adjust the path to your actual location):

```bash
*/10 * * * * /path/to/cloudflare-ddns/cloudflare-ddns.sh >/dev/null 2>&1
```

---

### ⚙️ Config Details (ddns.conf)

| Parameter | Description | Example |
| :--- | :--- | :--- |
| `apitoken1` | Cloudflare API Token | `xxxxxx...` |
| `zonename1` | Root Domain | `example.com` |
| `recordname1` | Subdomain | `www` (Leave empty for root domain) |
| `recordtype1` | Record Type | `A` (IPv4) or `AAAA` (IPv6) |
| `proxied1` | Enable CF Proxy (Orange Cloud) | `true` or `false` |

---

### 📄 License

This project is open-sourced under the **GPL-3.0 License**. Contributions via Issues or Pull Requests are welcome.

---
**Author**: March Fun  
**Website**: [www.suma.tw](https://www.suma.tw)
