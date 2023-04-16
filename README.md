# Pi-hole + PiVPN

This work was largely based on a tutorial put out by Scaleway. Link here:
<https://www.scaleway.com/en/docs/tutorials/pihole-vpn/>. For posterity, I've
downloaded the doc and saved it to a PDF at
[`scaleway-pihole.pdf`](./scaleway-pihole.pdf).

## Setup AWS Spot

[Instance comparison](https://instances.vantage.sh/?region=us-west-1&selected=t4g.small,t4g.medium,t4g.micro):

t4g.micro - 1GB, 2vCPU, 5Gbit network, $0.0034 hourly Spot cost  
t4g.small - 2GB, 2vCPU, 5Gbit network, $0.0060 hourly Spot cost  
t4g.medium - 4GB, 2vCPU, 5Gbit network, $0.0120 hourly Spot cost  

For an automated setup, use the Terraform script

```tf
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
http://<your-ip>/admin

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

# Copy the client's .ovpn config file to your desktop
scp -i <certificate> ubuntu@<ip>:/home/openvpn/ovpns/*.ovpn
```

Download the OpenVPN app on your devices (laptop, phone). Then to configure the
OpenVPN app by passing it your `*.ovpn` file.

