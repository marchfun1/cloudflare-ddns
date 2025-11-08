# CloudFlare DDNS script/Raspberry pi IPv4/IPv6 DDNS Solution 

English | [中文](/README.md)

### Overview
This script is adapted from [https://github.com/wherelse/cloudflare-ddns-script](https://github.com/wherelse/cloudflare-ddns-script). The original project used a Global API Key and is no longer functional.
This revised version is based on the Cloudflare API Token and serves as a DDNS update script. It supports both IPv4 and IPv6, and can retrieve the IP address of the host either via network-based or local methods. In theory, it is compatible with all Linux-based systems, and has been tested successfully on Debian and Ubuntu.

### What to do before using a script
1. A liunx device that can be connected to the Internet.
2. Have a domain name.
3. Register a CloudFlare account ( www.cloudflare.com ), add the domain to the account. After the configuration is complete, add an AAAA resolution to the IPV6 address of the service device as required, and set it to perform DNS resolution only.
4. Query the Globe API Key of CloudFlare account and record it for subsequent configuration.

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
This program is capable of simultaneously updating two domains. If you only wish to update one domain, please leave the second set of domain settings empty.

Find and modify the content below:

```shell

# First Domain Settings
apitoken1="Enter_API_TOKEN_1" # Your API Token xxxxxxxxxxxxxxxxxxxxxxxxxxxx
zonename1="example.com"       # Root domain
recordname1="www"             # Subdomain (hostname). Can be left empty when updating the root domain.
recordtype1="A"               # A (IPv4) or AAAA (IPv6) record
proxied1="false"              # Do not use proxy; set to DNS resolution only

# Second Domain Settings (Can be left completely empty if only updating one domain)
apitoken2=""
zonename2=""
recordname2=""
recordtype2="A"
proxied2="false"
```
Taking any domain as an example, for the domain www.google.com, zonename1 would be google.com and recordname1 would be www. After making the modifications, save and exit.

Enter the following at the terminal to run the script:
```shell
bash /home/username/cloudflare-ddns.sh
```
If it says `IP changed to: xxxxx` or` IP has not changed.`, the configuration is successful.

#### Schedule script
In order to achieve dynamic domain name resolution, the script must be kept running to obtain the IP status. Here the system crontab is used for timing.
Enter the `crontab -e` at the terminal,Add the following at the end of the file:
```shell
*/5 * * * *  /home/username/cloudflare-ddns.sh >/dev/null 2>&1
```
Save and exit after making changes.Set the script here to execute the `cloudflare-ddns.sh` script every five minutes to achieve dynamic domain name resolution.
