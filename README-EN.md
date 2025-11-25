# CloudFlare DDNS script/Raspberry pi IPv4/IPv6 DDNS Solution 

English | [中文](/README.md)

### Overview
This script is adapted from [https://github.com/wherelse/cloudflare-ddns-script](https://github.com/wherelse/cloudflare-ddns-script). The original project used a Global API Key and is no longer functional.
This revised version is based on the Cloudflare API Token and serves as a DDNS update script. It supports both IPv4 and IPv6, and can retrieve the IP address of the host via network-based methods. In theory, it is compatible with all Linux-based systems, and has been tested successfully on Debian and Ubuntu.

### Features
- ✅ Supports IPv4 (A records) and IPv6 (AAAA records)
- ✅ Can update two domains simultaneously with different record types (e.g., one IPv4 and one IPv6)
- ✅ Automatic dependency checking (curl and jq)
- ✅ Comprehensive error handling and logging
- ✅ Uses absolute paths to avoid issues when running from different directories

### Prerequisites
1. A Linux device with internet connectivity
2. A domain name (free or paid)
3. A Cloudflare account (www.cloudflare.com) with your domain added. After setup, add A or AAAA records for your device and set them to DNS-only mode
4. Create an API Token in your Cloudflare account and save it for configuration
5. Ensure `curl` and `jq` are installed (the script will check and provide installation instructions)

### Instructions
Open a terminal window and execute the following procedure:
```shell
wget https://raw.githubusercontent.com/marchfun1/cloudflare-ddns/master/cloudflare-ddns.sh
sudo chmod +x /home/username/cloudflare-ddns.sh #Directory changes based on actual users, you should change the username.
```
The personal configuration information in the script needs to be changed, and the directory is consistent with the previous command
```shell
sudo nano /home/username/cloudflare-ddns.sh
#or
sudo vi /home/username/cloudflare-ddns.sh
```
### Configuration
This program can update two domains simultaneously. If you only want to update one domain, leave the second set of settings empty.

Find and modify the following:

```shell
# First Domain Settings
apitoken1="Enter_API_TOKEN_1" # Your API Token xxxxxxxxxxxxxxxxxxxxxxxxxxxx
zonename1="example.com"       # Root domain
recordname1="www"             # Subdomain (hostname). Can be left empty when updating the root domain
recordtype1="A"               # A (IPv4) or AAAA (IPv6) record
proxied1="false"              # Do not use proxy; set to DNS resolution only

# Second Domain Settings (Can be left empty if only updating one domain)
apitoken2=""
zonename2=""
recordname2=""                # Can also be left empty to update root domain
recordtype2="A"
proxied2="false"
```

**Configuration Examples:**
- For `www.google.com`: set `zonename1` to `google.com` and `recordname1` to `www`
- To update root domain `google.com`: set `zonename1` to `google.com` and leave `recordname1` empty
- To update both IPv4 and IPv6: set `recordtype1="A"` for the first domain and `recordtype2="AAAA"` for the second (the script will automatically fetch the corresponding IP)

After making the modifications, save and exit.

Enter the following at the terminal to run the script:
```shell
bash /home/username/cloudflare-ddns.sh
```
If it says `IP changed to: xxxxx` or` IP has not changed.`, the configuration is successful.

#### Schedule script
In order to achieve dynamic domain name resolution, the script must be kept running to obtain the IP status. Here the system crontab is used for timing.
Enter the `sudo crontab -e` at the terminal,Add the following at the end of the file:
```shell
*/10 * * * *  /home/username/cloudflare-ddns.sh >/dev/null 2>&1
```
Save and exit after making changes.Set the script here to execute the `cloudflare-ddns.sh` script every five minutes to achieve dynamic domain name resolution.
