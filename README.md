# Pi-hole + PiVPN

Set up your own ad-blocking + VPN server! Features include:

- connecting to your VPN server from any device (laptop, mobile)
- greater control of your network traffic data (obfuscated from your local
  network and ISP)
- granular control over which hostnames to block/allow
- automation to teardown & setup a new server (~30min)

This work was largely based on a [tutorial put out by
Scaleway](https://www.scaleway.com/en/docs/tutorials/pihole-vpn/). For
posterity, I've downloaded the doc and saved it to
[`scaleway-pihole.pdf`](./scaleway-pihole.pdf).

## Set up compute instance

```bash
# Uninstall a previous installation
terraform destroy

# Start a new installation
terraform init
terraform plan 
terraform apply
```

## Installing Pi-hole

```bash
sudo su
apt update && apt upgrade -y

# Run the installer 
# - OpenDNS
# - StevenBlack's Unified Hosts List
# - Web admin interface: ON
# - Install web server: ON
# - Log queries: ON
# - Privacy mode: 0 Show everything
curl -sSL https://install.pi-hole.net | bash

# Do not expose the admin interface to public internet
pihole -a -i local

# Customize password of pihole
pihole -a -p
```

Now you should be able to visit the Pi-hole web interface via
http://YOUR_INSTANCE_PUBLIC_IP/admin

If you are using this Pi-hole as just a DNS server and not a VPN, you will need
to ensure you configure the Pi-hole to accept non-local requests. Use caution to
ensure your DNS server is not
[abused](https://www.cloudflare.com/learning/ddos/dns-amplification-ddos-attack/).

## Installing PiVPN

```bash
sudo su

# Add non-root user for OpenVPN
adduser openvpn

# Run the installer
# - User: openvpn
# - Customize: Yes
# - UDP port 1194
# - Pi-hole: Yes
# - Custom search domain: No
# - Elliptic Curve Crypto, 256-bit certificate
# - Unattended upgrades: Yes
curl -L https://install.pivpn.io | bash

# Add users to the VPN server (one user per client)
pivpn add
cp /home/openvpn/ovpns/*.ovpn /home/ubuntu
chmod 666 /home/ubuntu/*.ovpn
```

Next, run the following command on your laptop to copy the `.ovpn` config file
from the server to local.

```bash
scp -i "<certificate>" "ubuntu@<ip>:/home/ubuntu/*.ovpn" .
```

Download the OpenVPN app on your devices (laptop, phone). Then to configure the
OpenVPN app by passing it your `*.ovpn` file.

<!--
TODO:
- Gifs for logging onto the OpenVPN server. And for visiting the Pi-hole admin page
-->
