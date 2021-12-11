#!/bin/bash

#Font Colors

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
ENDCOLOR="\e[0m"

clear

#public ip

pub_ip=$(wget -qO- https://ipecho.net/plain ; echo)

#root check

if ! [ $(id -u) = 0 ]; then
   echo -e "${RED}Plese run the script with root privilages!${ENDCOLOR}"
   exit 1
fi

spinner()
{
    #Loading spinner
    local pid=$!
    local delay=0.75
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}
pre_req()
{
        #installing pre-requirements and adding port rules to ubuntu firewall
		
	apt update -y && apt upgrade -y

        apt-get install -y dropbear && apt-get install -y stunnel4 && apt-get install -y squid && apt-get install -y cmake && apt-get install -y python3 && apt-get install -y screenfetch && apt-get install -y openssl
        ufw allow 443/tcp
	ufw allow 444/tcp
        ufw allow 22/tcp
        ufw allow 80/tcp
        ufw allow 110/tcp
        ufw allow 8080/tcp
        ufw allow 7300/tcp
        ufw allow 7300/udp
}
mid_conf()
{

#configuring openssh

sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#Banner none/Banner \/etc\/banner/' /etc/ssh/sshd_config

#configuring dropbear

mv /etc/default/dropbear /etc/default/dropbear.backup
cat << EOF > /etc/default/dropbear
NO_START=0
DROPBEAR_PORT=80
DROPBEAR_EXTRA_ARGS="-p 110"
DROPBEAR_BANNER="/etc/banner"
DROPBEAR_RSAKEY="/etc/dropbear/dropbear_rsa_host_key"
DROPBEAR_DSSKEY="/etc/dropbear/dropbear_dss_host_key"
DROPBEAR_ECDSAKEY="/etc/dropbear/dropbear_ecdsa_host_key"
DROPBEAR_RECEIVE_WINDOW=65536
EOF

#Adding the banner

cat << EOF > /etc/banner
<strong>🛑 𝐃𝐊-𝐒𝐒𝐇-𝐒𝐂𝐑𝐈𝐏𝐓𝐒 🛑</strong> <h><fontcolor='blue'><html><body><center><h2><font color="#FF0000">⛅𝘗𝘈𝘐𝘋 𝘚𝘌𝘙𝘝𝘌𝘙⛅ </font></h2><br></center><font color="#ff8c00">: : ★ Happy Browsing!</font><br> <font color="#ffe100">: : ★ STRICTLY NO ACCOUNT SHARING</font><br> <font color="#d9ff00">: : ★ STRICTLY NO MULTI-LOGIN</font><br> <font color="#77ff00">: : ★ STRICTLY NO TORRENT<font><br><br><br><strong><p><strong><strong><span style="color: #ff0000; background-color:#c0c0c0;">💢•ᴅᴀᴛᴀᴋɪɴɢᴅᴏᴍ-ᴘʀᴏᴊᴇᴄᴛ•💢</span></strong></strong></p><h2><fontcolor="#339966"> 
🌀𝘒𝘌𝘌𝘗𝘓𝘐𝘔𝘐𝘛 🌀 <br><br><center><br>====================================</body></html><br>EOF

#Configuring stunnel
mkdir /etc/stunnel
cat << EOF > /etc/stunnel/stunnel.conf
cert = /etc/stunnel/stunnel.pem
client = no
sslVersion = all
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[dropbear]
accept = 443
connect = 110

[openssh]
accept = 444
connect = 22
EOF

#Genarating a self signed certificate for stunnel

openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com" \
    -out stunnel.pem  -keyout stunnel.pem

cp stunnel.pem /etc/stunnel/stunnel.pem
chmod 644 /etc/stunnel/stunnel.pem

#Enable overide stunnel default

cp /etc/default/stunnel4 /etc/default/stunnel4.backup
sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/stunnel4

# Configuring squid

mv /etc/squid/squid.conf /etc/squid/squid.conf.backup
cat << EOF > /etc/squid/squid.conf
acl url1 dstdomain -i 127.0.0.1
acl url2 dstdomain -i localhost
acl url3 dstdomain -i $pub_ip
acl url4 dstdomain -i /ELHSSHv2?
acl payload url_regex -i "/etc/squid/payload.txt"

http_access allow url1
http_access allow url2
http_access allow url3
http_access allow url4
http_access allow payload
http_access deny all

http_port 8080
visible_hostname ELHSSHv2
via off
forwarded_for off
pipeline_prefetch off
EOF
cat << EOF > /etc/squid/payload.txt
.whatsapp.net/
.facebook.net/
.twitter.com/
.speedtest.net/
EOF
}
fun_udpgw()
{
#build and install badvpn-udpgw

git clone https://github.com/ambrop72/badvpn
cd badvpn
cmake -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1
make install

#creating badvpn systemd service unit

cat << EOF > /etc/systemd/system/udpgw.service
[Unit]
Description=UDP forwarding for badvpn-tun2socks
After=nss-lookup.target

[Service]
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 10000 --max-connections-for-client 10 --client-socket-sndbuf 10000
User=udpgw

[Install]
WantedBy=multi-user.target
EOF
}
fun_panel()
{
mkdir /etc/elhssh-v2
wget https://raw.githubusercontent.com/heshan3030/DK-SSH-AUTO-SCRIPT/main/etc/ChangeUser.sh
wget https://raw.githubusercontent.com/heshan3030/DK-SSH-AUTO-SCRIPT/main/etc/ChangePorts.sh
wget https://raw.githubusercontent.com/heshan3030/DK-SSH-AUTO-SCRIPT/main/etc/UserManager.sh
wget https://raw.githubusercontent.com/heshan3030/DK-SSH-AUTO-SCRIPT/main/etc/Banner.sh
wget https://raw.githubusercontent.com/heshan3030/DK-SSH-AUTO-SCRIPT/main/etc/DelUser.sh
wget https://raw.githubusercontent.com/heshan3030/DK-SSH-AUTO-SCRIPT/main/etc/ListUsers.sh
wget https://raw.githubusercontent.com/heshan3030/DK-SSH-AUTO-SCRIPT/main/etc/RemoveScript.sh
wget -O speedtest-cli https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py
wget https://raw.githubusercontent.com/heshan3030/DK-SSH-AUTO-SCRIPT/main/menu
mv ChangeUser.sh /etc/elhssh-v2/ChangeUser.sh
mv ChangePorts.sh /etc/elhssh-v2/ChangePorts.sh
mv UserManager.sh /etc/elhssh-v2/UserManager.sh
mv Banner.sh /etc/elhssh-v2/Banner.sh
mv DelUser.sh /etc/elhssh-v2/DelUser.sh
mv ListUsers.sh /etc/elhssh-v2/ListUsers.sh
mv RemoveScript.sh /etc/elhssh-v2/RemoveScript.sh
mv speedtest-cli /etc/elhssh-v2/speedtest-cli
mv menu /usr/local/bin/menu
chmod +x /etc/elhssh-v2/ChangeUser.sh
chmod +x /etc/elhssh-v2/ChangePorts.sh
chmod +x /etc/elhssh-v2/UserManager.sh
chmod +x /etc/elhssh-v2/Banner.sh
chmod +x /etc/elhssh-v2/DelUser.sh
chmod +x /etc/elhssh-v2/ListUsers.sh
chmod +x /etc/elhssh-v2/RemoveScript.sh
chmod +x /etc/elhssh-v2/speedtest-cli
chmod +x /usr/local/bin/menu
}
fun_service_start()
{
#enabling and starting all services

useradd -m udpgw

systemctl restart sshd
systemctl enable dropbear
systemctl restart dropbear
systemctl enable stunnel4
systemctl restart stunnel4
systemctl enable squid
systemctl restart squid
sudo systemctl enable udpgw
sudo systemctl restart udpgw
}
echo -ne "${GREEN}DK-SSH-AUTO-SCRIPT Installing required packages ............."
pre_req >/dev/null 2>&1 &
spinner
echo -ne "\tdone"
echo -ne "\n${BLUE}Configuring Stunnel, Openssh, Dropbear and Squid ............."
mid_conf >/dev/null 2>&1 &
spinner
echo -ne "\tdone"
echo -ne "\n${YELLOW}Compiling and installing Badvpn UDP Gateway ............."
fun_udpgw >/dev/null 2>&1 &
spinner
echo -ne "\tdone"
echo -ne "\n${CYAN}DK-SSH-AUTO-SCRIPT Installing Panel ............."
fun_panel >/dev/null 2>&1 &
spinner
echo -ne "\tdone"
echo -ne "\n${RED}DK-SSH-AUTO-SCRIPT Starting All the services ............."
fun_service_start >/dev/null 2>&1 &
spinner
echo -ne "\tdone"
echo -e "${ENDCOLOR}"

#configure user shell to /bin/false
echo /bin/false >> /etc/shells
clear
echo -e "  \033[1;33m     • \033[1;32m████████ DK-SSH AUTO SCRIPT INSTALLATION COMPLETED ████████\033[1;33m • \033[0m"
echo ""
echo -e  "                     \033[1;31m    █▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█
                         █░░╦─╦╔╗╦─╔╗╔╗╔╦╗╔╗░░█
                         █░░║║║╠─║─║─║║║║║╠─░░█
                         █░░╚╩╝╚╝╚╝╚╝╚╝╩─╩╚╝░░█
                         █▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█ \033[0m" 
echo -e " \033[1;31m═─────────────────────────────◇──◇──◇─────────────────────────────═
\033[0m"
echo -e "  \033[1;33m  ⭐️...☁️☁️🔸•DK-SSH PROJECT•🔸☁️☁️...\033[1;31m
\033[1;36m    ⭐️...🔸🔹 NEW Version ; 1 🔸🔹...  \033[1;31m 
\033[1;37m    ⭐️...🙏😘ThankYOU FOR SELECTING OUR SCRIPT🙏😘...
             ⭐️...😷STAY SAFE😷...\033[0m"
echo -e "\033[1;33m    ⭐️...⚠️THIS IS FREE AND NOT FOR SALE⚠️...\033[1;31m
\033[1;36m    ⭐️...🛑VIOLATORS WILL BE REPORTED AND BANED🛑...\033[1;37m
    ⭐️...🌍HAPPY BROWSING🌍... \033[0m"
echo -e " \033[1;31m═─────────────────────────────◇──◇──◇─────────────────────────────═
\033[0m"
echo -e "\033[1;33m  📊 MORE INFORMATION CONTACT TELEGRAM \033[1;31m\033[1;36m
  🌐TELEGRAM🌐\033[1;31m:\033[1;37m @Dk_king_offcial \033[0m"
echo -e "\033[1;33m  📊 MORE INFORMATION CONTACT whatsapp \033[1;31m \033[1;36m
  🌐whatsapp🌐\033[1;31m:\033[1;37m 0768100942\033[0m"
echo -e " \033[1;31m═══════════════════════•ᴅᴀᴛᴀᴋɪɴɢᴅᴏᴍ ᴘʀᴏᴊᴇᴄᴛ•═══════════════════════\033[0m"
#Adding the default user
echo -ne "${GREEN}🛑Enter the default username🛑 : "; read username
while true; do
    read -p "Do you want to genarate a random password😁 ? (Y/N) " yn
    case $yn in
        [Yy]* ) password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-9};echo;); break;;
        [Nn]* ) echo -ne "Enter password (please use a strong password) : "; read password; break;;
        * ) echo "Please answer yes or no.";;
    esac
done
echo -ne "⚠️Enter No. of Days till expiration⚠️ : ";read nod
exd=$(date +%F  -d "$nod days")
useradd -e $exd -M -N -s /bin/false $username && echo "$username:$password" | chpasswd &&
clear &&
echo -e "${GREEN}🛑Default User Details🛑" &&
echo -e "${RED}--------------------" &&
echo -e "${GREEN}\n🛑Username :${YELLOW} $username" &&
echo -e "${GREEN}\n🛑Password :${YELLOW} $password" &&
echo -e "${GREEN}\n🛑Expire Date :${YELLOW} $exd ${ENDCOLOR}" ||
echo -e "${RED}\nFailed to add default user $username please try again.${ENDCOLOR}"

#exit script
echo -e "\n${CYAN}Script installed. You can access the panel using 'menu' command. ${ENDCOLOR}\n"
echo -e "\nPress Enter key to exit"; read
