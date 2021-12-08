#!/bin/bash

#font colors

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"

clear

#add users

echo -ne "${YELLOW}Enter the username : "; read username
while true; do
    read -p "Do you want to genarate a random password ? (Y/N) " yn
    case $yn in
        [Yy]* ) password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-9};echo;); break;;
        [Nn]* ) echo -ne "Enter password (please use a strong password) : "; read password; break;;
        * ) echo "Please answer yes or no.";;
    esac
done
echo -ne "Enter No. of Days till expiration : ";read nod
exd=$(date +%F  -d "$nod days")
useradd -e $exd -M -N -s /bin/false $username && echo "$username:$password" | chpasswd &&
clear &&
echo -e "${GREEN} ✅ SUCCESSFULLY CREATED ✅" &&
echo -e "${RED}-----------------------------" &&
echo -e "${GREEN}\n✅ IP ADDRESS :${YELLOW} $pub_ip" &&
echo -e "${GREEN}\n✅ Username :${YELLOW} $username" &&
echo -e "${GREEN}\n✅ Password :${YELLOW} $password" &&
echo -e "${GREEN}\n✅ Expire Date :${YELLOW} $exd ${ENDCOLOR}" ||
echo -e "${RED}\nFailed to add user $username please try again.${ENDCOLOR}"
echo -e "\033[1;32m======================="
echo -e "\033[1;32m=❌NO SPAM"
echo -e "\033[1;32m=❌NO DDOS "
echo -e "\033[1;32m=❌NO HACKING "
echo -e "\033[1;32m=❌NO CARDING   "
echo -e "\033[1;32m=❌NO TORRENT   "
echo -e "\033[1;32m=❌NO OVER DOWNLOAD"
echo -e "\033[1;32m=❌NO MULTILOGIN "
echo -e "\033[1;32m======================="
echo -e "\033[1;32m࿂ SSH •  22"
echo -e "\033[1;32m࿂ SSL •  443"
echo -e "\033[1;32m࿂ Squid  •  8080"
echo -e "\033[1;32m࿂ Dropbear •  80"
echo -e "\033[1;32m [-] ═───────◇───────═"
echo -e "\033[1;32m࿂ Badvpn •  7300"
echo -e "\033[1;32m [-] ═───────◇───────═"
echo -e "\033[1;32m›☬[•] SCRIPTS ═◇ ⚡️⚡️  BY DATAKINGDOM  ⚡️⚡️ ◇═ [•]☬"
#return to panel

echo -e "\nPress Enter key to return to main menu"; read
menu
