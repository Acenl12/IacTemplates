sudo /sbin/iptables -N sshguard

# Include log whenever you like

sudo /sbin/iptables -A sshguard -m state --state NEW -m recent --name SSH --rcheck --seconds 60 --hitcount 2 -j LOG --log-prefix "SSH-shield:"

sudo /sbin/iptables -A sshguard -m state --state NEW -m recent --name SSH --update --seconds 60 --hitcount 2 -j DROP

sudo /sbin/iptables -A sshguard -m state --state NEW -m recent --name SSH --set -j ACCEPT

sudo /sbin/iptables -A sshguard -j ACCEPT
sudo /sbin/iptables -A INPUT -p tcp --dport 22 -j sshguard

sudo iptables -A INPUT -i lo -j ACCEPT

sudo iptables -A OUTPUT -o lo -j ACCEPT
