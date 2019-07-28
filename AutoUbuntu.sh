
# extract ip address
IPADDRESS=$(wget -qO- ipv4.icanhazip.com);
IPADD="s/ipaddresxxx/$IPADDRESS/g";

# set time GMT +8
echo \> Changing Server Time Zone...
ln -fs /usr/share/zoneinfo/Asia/Manila /etc/localtime

# System Update
apt update
apt upgrade -y
# Install Openvpn
apt-get -y install openvpn 
# Install Firewall
apt-get -y install ufw
#Installing Easy-RSA...
apt-get -y install easy-rsa
Installing Apache2 Web Server...
apt-get -y install apache2
#Install Squid
apt-get -y install squid
#Install Zip
apt-get -y install zip
#Install Privoxy
apt-get -y install privoxy
#Configure OpenVPN Certificate
cp -r /usr/share/easy-rsa/ /etc/openvpn
mkdir /etc/openvpn/easy-rsa/keys
sed -i 's|export KEY_COUNTRY="US"|export KEY_COUNTRY="PH"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_PROVINCE="CA"|export KEY_PROVINCE="BTG"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_CITY="SanFrancisco"|export KEY_CITY="Batangas City"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_ORG="Fort-Funston"|export KEY_ORG="GROME"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_EMAIL="me@myhost.mydomain"|export KEY_EMAIL="jeromelaliag@yahoo.com"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_OU="MyOrganizationalUnit"|export KEY_OU="jeromelaliag"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_NAME="EasyRSA"|export KEY_NAME="jeromelaliag"|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_OU=changeme|export KEY_OU=jeromelaliag|' /etc/openvpn/easy-rsa/vars
sed -i 's|export KEY_SIZE=2048|export KEY_SIZE=1024|' /etc/openvpn/easy-rsa/vars

# create diffie-helman pem
openssl dhparam -out /etc/openvpn/dh1024.pem 1024

# create pki
cd /etc/openvpn/easy-rsa
. ./vars
./clean-all
export EASY_RSA="${EASY_RSA:-.}"
"$EASY_RSA/pkitool" --initca $*
# create key server
export EASY_RSA="${EASY_RSA:-.}"
"$EASY_RSA/pkitool" --server server
# setting key cn
export EASY_RSA="${EASY_RSA:-.}"
"$EASY_RSA/pkitool" client
cd
# copy /etc/openvpn/easy-rsa/keys/{server.crt,server.key,ca.crt} /etc/openvpn
cp /etc/openvpn/easy-rsa/keys/server.crt /etc/openvpn/server.crt
cp /etc/openvpn/easy-rsa/keys/server.key /etc/openvpn/server.key
cp /etc/openvpn/easy-rsa/keys/ca.crt /etc/openvpn/ca.crt

# setting server
cat > /etc/openvpn/server.conf <<-END
port 110
proto tcp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh1024.pem
client-cert-not-required
username-as-common-name
plugin /usr/lib/openvpn/openvpn-plugin-auth-pam.so login
server 192.168.100.0 255.255.255.0
ifconfig-pool-persist ipp.txt
persist-key
persist-tun
status openvpn-status.log
log openvpn.log
verb 0
cipher none
auth none
keepalive 1 10
reneg-sec 0
tcp-nodelay
push "dhcp-option DNS 1.1.1.1"
push "dhcp-option DNS 1.0.0.1"
END
# create SUN-NOLOAD openvpn config
echo \> Generating OpenVPN Client Configuration...
cat > /root/SUN-NOLOAD.ovpn <<-END
client
dev tun
proto tcp-client
remote $IPADDRESS 110
persist-key
persist-tun
bind
float
remote-cert-tls server
verb 0
auth-user-pass
redirect-gateway def1
cipher none
auth none
auth-nocache
auth-retry interact
connect-retry 0 1
nice -20
reneg-sec 0

END
echo '<ca>' >> /root/SUN-NOLOAD.ovpn
cat /etc/openvpn/ca.crt >> /root/SUN-NOLOAD.ovpn
echo>> /root/SUN-NOLOAD.ovpn
echo '</ca>' >> /root/SUN-NOLOAD.ovpn
# create SUN-TU200 openvpn config
cat > /root/SUN-TU200.ovpn <<-END
client
dev tun
proto tcp-client
remote $IPADDRESS 110
persist-key
persist-tun
remote-cert-tls server
verb 3
auth-user-pass
redirect-gateway def1
cipher none
auth none
auth-nocache
auth-retry interact
connect-retry 0 1
nice -20
reneg-sec 0
http-proxy $IPADDRESS 8080
http-proxy-option CUSTOM-HEADER CONNECT HTTP/1.0
http-proxy-option CUSTOM-HEADER Host line.telegram.me
http-proxy-option CUSTOM-HEADER X-Online-Host line.telegram.me
http-proxy-option CUSTOM-HEADER X-Forward-Host line.telegram.me
http-proxy-option CUSTOM-HEADER Connection keep-alive
http-proxy-option CUSTOM-HEADER Proxy-Connection keep-alive

END
echo '<ca>' >> /root/SUN-TU200.ovpn
cat /etc/openvpn/ca.crt >> /root/SUN-TU200.ovpn
echo>> /root/SUN-TU200.ovpn
echo '</ca>' >> /root/SUN-TU200.ovpn
# create DEFAULT-NO-PROXY openvpn config
cat > /root/DEFAULT-NO-PROXY.ovpn <<-END
client
dev tun
proto tcp-client
remote $IPADDRESS 110
persist-key
persist-tun
remote-cert-tls server
verb 3
auth-user-pass
redirect-gateway def1
cipher none
auth none
auth-nocache
auth-retry interact
connect-retry 0 1
nice -20
reneg-sec 0

END
echo '<ca>' >> /root/DEFAULT-NO-PROXY.ovpn
cat /etc/openvpn/ca.crt >> /root/DEFAULT-NO-PROXY.ovpn
echo>> /root/DEFAULT-NO-PROXY.ovpn
echo '</ca>' >> /root/DEFAULT-NO-PROXY.ovpn
# create DEFAULT-WITH-PROXY openvpn config
cat > /root/DEFAULT-WITH-PROXY.ovpn <<-END
client
dev tun
proto tcp-client
remote $IPADDRESS 110
persist-key
persist-tun
remote-cert-tls server
verb 3
auth-user-pass
redirect-gateway def1
cipher none
auth none
auth-nocache
auth-retry interact
connect-retry 0 1
nice -20
reneg-sec 0
http-proxy $IPADDRESS 8080

END
echo '<ca>' >> /root/DEFAULT-WITH-PROXY.ovpn
cat /etc/openvpn/ca.crt >> /root/DEFAULT-WITH-PROXY.ovpn
echo>> /root/DEFAULT-WITH-PROXY.ovpn
echo '</ca>' >> /root/DEFAULT-WITH-PROXY.ovpn
# create SUN-CTC-TU50 openvpn config
cat > /root/SUN-CTC-TU50.ovpn <<-END
client
dev tun
proto tcp-client
remote $IPADDRESS 110
persist-key
persist-tun
remote-cert-tls server
verb 3
auth-user-pass
redirect-gateway def1
cipher none
auth none
auth-nocache
auth-retry interact
connect-retry 0 1
nice -20
reneg-sec 0
http-proxy $IPADDRESS 8118
http-proxy-option CUSTOM-HEADER ""
http-proxy-option CUSTOM-HEADER "POST https://viber.com HTTP/1.0"

END
echo '<ca>' >> /root/SUN-CTC-TU50.ovpn
cat /etc/openvpn/ca.crt >> /root/SUN-CTC-TU50.ovpn
echo>> /root/SUN-CTC-TU50.ovpn
echo '</ca>' >> /root/SUN-CTC-TU50.ovpn
# create SUN-FLP openvpn config
cat > /root/SUN-FLP.ovpn <<-END
client
dev tun
proto tcp-client
remote $IPADDRESS 110
persist-key
persist-tun
remote-cert-tls server
verb 3
auth-user-pass
redirect-gateway def1
cipher none
auth none
auth-nocache
auth-retry interact
connect-retry 0 1
nice -20
reneg-sec 0
http-proxy $IPADDRESS 8118
http-proxy-option CUSTOM-HEADER ""
http-proxy-option CUSTOM-HEADER "POST https://viber.com HTTP/1.1"
http-proxy-option CUSTOM-HEADER "Proxy-Connection: Keep-Alive"

END
echo '<ca>' >> /root/SUN-FLP.ovpn
cat /etc/openvpn/ca.crt >> /root/SUN-FLP.ovpn
echo>> /root/SUN-FLP.ovpn
echo '</ca>' >> /root/SUN-FLP.ovpn
# create GLOBE-GOWATCHANDPLAY openvpn config
cat > /root/GLOBE-GOWATCHANDPLAY.ovpn <<-END
client
dev tun
proto tcp-client
remote $IPADDRESS 110
persist-key
persist-tun
remote-cert-tls server
verb 3
auth-user-pass
redirect-gateway def1
cipher none
auth none
auth-nocache
auth-retry interact
connect-retry 0 1
nice -20
reneg-sec 0
http-proxy $IPADDRESS 8080
http-proxy-option CUSTOM-HEADER CONNECT HTTP/1.0
http-proxy-option CUSTOM-HEADER Host i.ytimg.com
http-proxy-option CUSTOM-HEADER X-Online-Host i.ytimg.com
http-proxy-option CUSTOM-HEADER X-Forward-Host i.ytimg.com
http-proxy-option CUSTOM-HEADER Connection keep-alive
http-proxy-option CUSTOM-HEADER Proxy-Connection keep-alive

END
echo '<ca>' >> /root/GLOBE-GOWATCHANDPLAY.ovpn
cat /etc/openvpn/ca.crt >> /root/GLOBE-GOWATCHANDPLAY.ovpn
echo>> /root/GLOBE-GOWATCHANDPLAY.ovpn
echo '</ca>' >> /root/GLOBE-GOWATCHANDPLAY.ovpn
# create GLOBE-GOWATCHANDPLAY2 openvpn config
cat > /root/GLOBE-GOWATCHANDPLAY2.ovpn <<-END
client
dev tun
proto tcp-client
remote $IPADDRESS 110
persist-key
persist-tun
remote-cert-tls server
verb 3
auth-user-pass
redirect-gateway def1
cipher none
auth none
auth-nocache
auth-retry interact
connect-retry 0 1
nice -20
reneg-sec 0
http-proxy $IPADDRESS 8080
http-proxy-option CUSTOM-HEADER CONNECT HTTP/1.0
http-proxy-option CUSTOM-HEADER Host www.googleapis.com
http-proxy-option CUSTOM-HEADER X-Online-Host www.googleapis.com
http-proxy-option CUSTOM-HEADER X-Forward-Host www.googleapis.com
http-proxy-option CUSTOM-HEADER Connection keep-alive
http-proxy-option CUSTOM-HEADER Proxy-Connection keep-alive

END
echo '<ca>' >> /root/GLOBE-GOWATCHANDPLAY2.ovpn
cat /etc/openvpn/ca.crt >> /root/GLOBE-GOWATCHANDPLAY2.ovpn
echo>> /root/GLOBE-GOWATCHANDPLAY.ovpn
echo '</ca>' >> /root/GLOBE-GOWATCHANDPLAY2.ovpn

# setting iptables
echo \> Configuring IPTables Rules...
cat > /etc/iptables.up.rules <<-END
*nat
:PREROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -j SNAT --to-source ipaddresxxx
-A POSTROUTING -o eth0 -j MASQUERADE
-A POSTROUTING -s 192.168.100.0/24 -o eth0 -j MASQUERADE
-A POSTROUTING -s 10.1.0.0/24 -o eth0 -j MASQUERADE
COMMIT

*filter
:INPUT ACCEPT [19406:27313311]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [9393:434129]
-A FORWARD -i eth0 -o ppp0 -m state --state RELATED,ESTABLISHED -j ACCEPT
-A FORWARD -i ppp0 -o eth0 -j ACCEPT
-A INPUT -p ICMP --icmp-type 8 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 53 -j ACCEPT
-A INPUT -p tcp --dport 22  -m state --state NEW -j ACCEPT
-A INPUT -p tcp --dport 110  -m state --state NEW -j ACCEPT
-A INPUT -p udp --dport 110  -m state --state NEW -j ACCEPT
-A INPUT -p tcp --dport 8080  -m state --state NEW -j ACCEPT
-A INPUT -p udp --dport 8080  -m state --state NEW -j ACCEPT
-A INPUT -p tcp --dport 8118  -m state --state NEW -j ACCEPT
-A INPUT -p udp --dport 8118  -m state --state NEW -j ACCEPT
COMMIT

*raw
:PREROUTING ACCEPT [158575:227800758]
:OUTPUT ACCEPT [46145:2312668]
COMMIT

*mangle
:PREROUTING ACCEPT [158575:227800758]
:INPUT ACCEPT [158575:227800758]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [46145:2312668]
:POSTROUTING ACCEPT [46145:2312668]
COMMIT
END
sed -i '$ i\iptables-restore < /etc/iptables.up.rules' /etc/rc.local
sed -i $IPADD /etc/iptables.up.rules;
iptables-restore < /etc/iptables.up.rules

# disable ipv6
echo \> Disabling IPv6...
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local
# add dns server ipv4
echo \> Changing DNS to CloudFlare DNS...
echo "nameserver 1.1.1.1" > /etc/resolv.conf
echo "nameserver 1.0.0.1" >> /etc/resolv.conf
sed -i '$ i\echo "nameserver 1.1.1.1" > /etc/resolv.conf' /etc/rc.local
sed -i '$ i\echo "nameserver 1.0.0.1" >> /etc/resolv.conf' /etc/rc.local
sed -i '$ i\sleep 10' /etc/rc.local
sed -i '$ i\for p in $(pgrep openvpn); do renice -n -20 -p $p; done' /etc/rc.local
sed -i '$ i\for p in $(pgrep privoxy); do renice -n -20 -p $p; done' /etc/rc.local
sed -i '$ i\for p in $(pgrep squid); do renice -n -20 -p $p; done' /etc/rc.local

# setting ufw
echo \> Configuring Uncomplicated Firewall...
ufw allow ssh > /dev/null
ufw allow 110/tcp > /dev/null
ufw allow 8080/tcp > /dev/null
ufw allow 8118/tcp > /dev/null
ufw allow 110/udp > /dev/null
ufw allow 8080/udp > /dev/null
ufw allow 8118/udp > /dev/null
sed -i 's|DEFAULT_INPUT_POLICY="DROP"|DEFAULT_INPUT_POLICY="ACCEPT"|' /etc/default/ufw
sed -i 's|DEFAULT_FORWARD_POLICY="DROP"|DEFAULT_FORWARD_POLICY="ACCEPT"|' /etc/default/ufw
cat > /etc/ufw/before.rules <<-END
# START OPENVPN RULES
# NAT table rules
*nat
:POSTROUTING ACCEPT [0:0]
# Allow traffic from OpenVPN client to eth0
-A POSTROUTING -s 10.8.0.0/8 -o eth0 -j MASQUERADE
COMMIT
# END OPENVPN RULES
END
echo "y" | ufw enable > /dev/null
# set ipv4 forward
echo \> Configuring IPv4 Forward...
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i 's|#net.ipv4.ip_forward=1|net.ipv4.ip_forward=1|' /etc/sysctl.conf

# configure privoxy
echo \> Configuring Privoxy...
cat > /etc/privoxy/config <<-END
user-manual /usr/share/doc/privoxy/user-manual
confdir /etc/privoxy
logdir /var/log/privoxy
filterfile default.filter
logfile logfile
listen-address 0.0.0.0:8118
toggle 1
enable-remote-toggle 0
enable-remote-http-toggle 0
enable-edit-actions 0
enforce-blocks 0
buffer-limit 4096
enable-proxy-authentication-forwarding 1
forwarded-connect-retries 1
accept-intercepted-requests 1
allow-cgi-request-crunching 1
split-large-forms 0
keep-alive-timeout 5
tolerate-pipelining 1
socket-timeout 300
permit-access 0.0.0.0/0 $IPADDRESS

END

# configure squid
echo \> Configuring Squid Proxy Server...
cat > /etc/squid/squid.conf <<-END
acl localhost src 127.0.0.1/32 ::1
acl to_localhost dst 127.0.0.0/8 0.0.0.0/32 ::1
acl SSL_ports port 443
acl Safe_ports port 80
acl Safe_ports port 21
acl Safe_ports port 443
acl Safe_ports port 70
acl Safe_ports port 210
acl Safe_ports port 1025-65535
acl Safe_ports port 280
acl Safe_ports port 488
acl Safe_ports port 591
acl Safe_ports port 777
acl CONNECT method CONNECT
acl SSH dst ipaddresxxx-ipaddresxxx/32
http_access allow SSH
http_access allow manager localhost
http_access deny manager
http_access allow localhost
http_access deny all
http_port 8080
coredump_dir /var/spool/squid
refresh_pattern ^ftp: 1440 20% 10080
refresh_pattern ^gopher: 1440 0% 1440
refresh_pattern -i (/cgi-bin/|\?) 0 0% 0
refresh_pattern . 0 20% 4320
visible_hostname jeromelaliag

END
sed -i $IPADD /etc/squid/squid.conf;

echo \> Compressing OpenVPN Configuration to Zip File...
cd /root/
zip /var/www/html/config.zip SUN-TU200.ovpn SUN-CTC-TU50.ovpn SUN-NOLOAD.ovpn GLOBE-GOWATCHANDPLAY.ovpn GLOBE-GOWATCHANDPLAY2.ovpn SUN-FLP.ovpn DEFAULT-NO-PROXY.ovpn DEFAULT-WITH-PROXY.ovpn > /dev/null


# Add openvpn user
echo \> Adding default OpenVPN User...
useradd adminko
echo "adminko:adminko" | chpasswd
clear
echo \> Install finish!
echo
echo \> VPS Open Ports
echo SSH Port: 22
echo OpenVPN Port: 110
echo Squid Port: 8080
echo Privoxy Port: 8118
echo
sleep 1
echo \> Download your openvpn config here.
echo http://$IPADDRESS/config.zip

echo \> Please Reboot your VPS!!