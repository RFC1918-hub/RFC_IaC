#! /bin/bash

# Override existing DNS Settings using netplan, but don't do it for Terraform AWS builds
if ! curl -s 169.254.169.254 --connect-timeout 2 >/dev/null; then
  echo -e "    eth1:\n      dhcp4: true\n      nameservers:\n        addresses: [8.8.8.8,8.8.4.4]" >>/etc/netplan/01-netcfg.yaml
  netplan apply
fi

# Kill systemd-resolvd, just use plain ol' /etc/resolv.conf
systemctl disable systemd-resolved
systemctl stop systemd-resolved
rm /etc/resolv.conf
echo 'nameserver 8.8.8.8' >> /etc/resolv.conf
echo 'nameserver 8.8.4.4' >> /etc/resolv.conf
echo 'nameserver 192.168.56.102' >> /etc/resolv.conf

# Download and install Splunk
LATEST_SPLUNK=$(curl https://www.splunk.com/en_us/download/splunk-enterprise.html | grep -i deb | grep -Eo "data-link=\"................................................................................................................................" | cut -d '"' -f 2)
wget --progress=bar:force -O /opt/splunk.deb $LATEST_SPLUNK
dpkg -i /opt/splunk*.deb >/dev/null

# Configure Splunk 
/opt/splunk/bin/splunk start --accept-license --answer-yes --no-prompt --seed-passwd changeme!
/opt/splunk/bin/splunk add index wineventlog -auth 'admin:changeme!'
/opt/splunk/bin/splunk add index sysmon -auth 'admin:changeme!'
/opt/splunk/bin/splunk add index powershell -auth 'admin:changeme!'

# Install Splunk Apps
/opt/splunk/bin/splunk install app '/vagrant/tools/splunk_forwarder/Splunk Add-on for Microsoft Windows.tgz' -auth 'admin:changeme!'
/opt/splunk/bin/splunk install app '/vagrant/tools/splunk_forwarder/Splunk Add-on for Sysmon.tgz' -auth 'admin:changeme!'


# Configure Splunk listening port
/opt/splunk/bin/splunk enable listen 9997 -auth 'admin:changeme!'
/opt/splunk/bin/splunk restart
/opt/splunk/bin/splunk enable boot-start