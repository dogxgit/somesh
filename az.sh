#!/bin/bash

# Change SSH port to 48192
sudo sed -i 's/^#Port 22/Port 48192/g' /etc/ssh/sshd_config

# Restart SSH service to apply changes
sudo service ssh restart

# Setup iptables rules
sudo iptables -F

# Allow established connections
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow localhost connections
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A OUTPUT -o lo -j ACCEPT

# Allow incoming connections on 80, 443, and 48192
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 48192 -j ACCEPT

# Now set the default rules to DROP
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT

# Save iptables rules
sudo iptables-save > /etc/iptables.rules

# Setup iptables rules to be loaded on boot
echo '#!/bin/sh' | sudo tee /etc/network/if-pre-up.d/iptables
echo '/sbin/iptables-restore < /etc/iptables.rules' | sudo tee -a /etc/network/if-pre-up.d/iptables
sudo chmod +x /etc/network/if-pre-up.d/iptables
