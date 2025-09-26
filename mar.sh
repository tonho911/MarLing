#!/bin/bash
colorized_echo() {
    local color=$1
    local text=$2
    
    case $color in
        "red")
        printf "\e[91m${text}\e[0m\n";;
        "green")
        printf "\e[92m${text}\e[0m\n";;
        "yellow")
        printf "\e[93m${text}\e[0m\n";;
        "blue")
        printf "\e[94m${text}\e[0m\n";;
        "magenta")
        printf "\e[95m${text}\e[0m\n";;
        "cyan")
        printf "\e[96m${text}\e[0m\n";;
        *)
            echo "${text}"
        ;;
    esac
}

# Check if the script is run as root
if [ "$(id -u)" != "0" ]; then
    colorized_echo red "Error: Skrip ini harus dijalankan sebagai root."
    exit 1
fi

# Check supported operating system
supported_os=false

if [ -f /etc/os-release ]; then
    os_name=$(grep -E '^ID=' /etc/os-release | cut -d= -f2)
    os_version=$(grep -E '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '"')

    if [ "$os_name" == "debian" ] && [ "$os_version" == "12" ]; then
        supported_os=true
    elif [ "$os_name" == "debian" ] && [ "$os_version" == "11" ]; then
        supported_os=true
    fi
fi

if [ "$supported_os" != true ]; then
    colorized_echo red "Error: Skrip ini hanya support di Debian 12 dan Ubuntu 22.04. Mohon gunakan OS yang di support."
    exit 1
fi
apt install sudo curl -y
# Fungsi untuk menambahkan repo Debian 12
addDebian12Repo() {
    echo "#mirror_kambing-sysadmind deb12
deb http://kartolo.sby.datautama.net.id/debian/ bookworm contrib main non-free non-free-firmware
deb http://kartolo.sby.datautama.net.id/debian/ bookworm-updates contrib main non-free non-free-firmware
deb http://kartolo.sby.datautama.net.id/debian/ bookworm-proposed-updates contrib main non-free non-free-firmware
deb http://kartolo.sby.datautama.net.id/debian/ bookworm-backports contrib main non-free non-free-firmware
deb http://kartolo.sby.datautama.net.id/debian-security/ bookworm-security contrib main non-free non-free-firmware" | sudo tee /etc/apt/sources.list > /dev/null
}

# Fungsi untuk menambahkan repo Ubuntu 22.04
addUbuntu2004Repo() {
    echo "#mirror buaya klas 22.04
deb http://kebo.pens.ac.id/ubuntu/ jammy main restricted universe multiverse
deb http://kebo.pens.ac.id/ubuntu/ jammy-updates main restricted universe multiverse
deb http://kebo.pens.ac.id/ubuntu/ jammy-security main restricted universe multiverse
deb http://kebo.pens.ac.id/ubuntu/ jammy-backports main restricted universe multiverse
deb http://kebo.pens.ac.id/ubuntu/ jammy-proposed main restricted universe multiverse" | sudo tee /etc/apt/sources.list > /dev/null
}

# Mendapatkan informasi kode negara dan OS
COUNTRY_CODE=$(curl -s https://ipinfo.io/country)
OS=$(lsb_release -si)

# Pemeriksaan IP Indonesia
if [[ "$COUNTRY_CODE" == "ID" ]]; then
    colorized_echo green "IP Indonesia terdeteksi, menggunakan repositories lokal Indonesia"

    # Menanyakan kepada pengguna apakah ingin menggunakan repo lokal atau repo default
    read -p "Apakah Anda ingin menggunakan repo lokal Indonesia? (y/n): " use_local_repo

    if [[ "$use_local_repo" == "y" || "$use_local_repo" == "Y" ]]; then
        # Pemeriksaan OS untuk menambahkan repo yang sesuai
        case "$OS" in
            Debian)
                VERSION=$(lsb_release -sr)
                if [ "$VERSION" == "12" ]; then
                    addDebian12Repo
                else
                    colorized_echo red "Versi Debian ini tidak didukung."
                fi
                ;;
            Ubuntu)
                VERSION=$(lsb_release -sr)
                if [ "$VERSION" == "20.04" ]; then
                    addUbuntu2004Repo
                else
                    colorized_echo red "Versi Ubuntu ini tidak didukung."
                fi
                ;;
            *)
                colorized_echo red "Sistem Operasi ini tidak didukung."
                ;;
        esac
    else
        colorized_echo yellow "Menggunakan repo bawaan VM."
        # Tidak melakukan apa-apa, sehingga repo bawaan VM tetap digunakan
    fi
else
    colorized_echo yellow "IP di luar Indonesia."
    # Lanjutkan dengan repo bawaan OS
fi
mkdir -p /etc/data

#domain
read -rp "Masukkan Domain: " domain
echo "$domain" > /etc/data/domain
domain=$(cat /etc/data/domain)

#email
read -rp "Masukkan Email anda: " email

#username
while true; do
    read -rp "Masukkan UsernamePanel (hanya huruf dan angka): " userpanel

    # Memeriksa apakah userpanel hanya mengandung huruf dan angka
    if [[ ! "$userpanel" =~ ^[A-Za-z0-9]+$ ]]; then
        echo "UsernamePanel hanya boleh berisi huruf dan angka. Silakan masukkan kembali."
    elif [[ "$userpanel" =~ [Aa][Dd][Mm][Ii][Nn] ]]; then
        echo "UsernamePanel tidak boleh mengandung kata 'admin'. Silakan masukkan kembali."
    else
        echo "$userpanel" > /etc/data/userpanel
        break
    fi
done

read -rp "Masukkan Password Panel: " passpanel
echo "$passpanel" > /etc/data/passpanel

#Preparation
clear
cd;
apt-get update;

#Remove unused Module
apt-get -y --purge remove samba*;
apt-get -y --purge remove apache2*;
apt-get -y --purge remove sendmail*;
apt-get -y --purge remove bind9*;

#install bbr
echo 'fs.file-max = 500000
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 4096
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mem = 25600 51200 102400
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.core.rmem_max = 4000000
net.ipv4.tcp_mtu_probing = 1
net.ipv4.ip_forward = 1
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.conf
sysctl -p;

#install toolkit
apt-get install git cron libio-socket-inet6-perl libsocket6-perl libcrypt-ssleay-perl libnet-libidn-perl perl libio-socket-ssl-perl libwww-perl libpcre3 libpcre3-dev zlib1g-dev dbus iftop zip unzip wget net-tools curl nano sed screen gnupg gnupg1 bc apt-transport-https build-essential dirmngr dnsutils sudo at htop iptables bsdmainutils cron lsof lnav -y

#Install lolcat
apt-get install -y ruby;
gem install lolcat;

#Set Timezone GMT+7
timedatectl set-timezone Asia/Jakarta;

#Install Marzban
sudo bash -c "$(curl -sL https://github.com/tonho911/Marzban-scripts/raw/master/marzban.sh)" @ install

#Install Subs
wget -N -P /var/lib/marzban/templates/subscription/  https://raw.githubusercontent.com/tonho911/MarLing/main/index.html

#install env
wget -O /opt/marzban/.env "https://raw.githubusercontent.com/tonho911/MarLing/main/env"

#install Assets folder
mkdir -p /var/lib/marzban/assets
cd

#profile
echo -e 'profile' >> /root/.profile
wget -O /usr/bin/profile "https://raw.githubusercontent.com/tonho911/MarLing/main/profile";
chmod +x /usr/bin/profile
apt install neofetch -y
wget -O /usr/bin/cekservice "https://raw.githubusercontent.com/tonho911/MarLing/main/cekservice.sh"
chmod +x /usr/bin/cekservice

#install compose
wget -O /opt/marzban/docker-compose.yml "https://raw.githubusercontent.com/tonho911/MarLing/main/docker-compose.yml"

#Install VNSTAT
apt -y install vnstat
/etc/init.d/vnstat restart
apt -y install libsqlite3-dev
wget https://github.com/tonho911/MarLing/raw/main/vnstat-2.6.tar.gz
tar zxvf vnstat-2.6.tar.gz
cd vnstat-2.6
./configure --prefix=/usr --sysconfdir=/etc && make && make install 
cd
chown vnstat:vnstat /var/lib/vnstat -R
systemctl enable vnstat
/etc/init.d/vnstat restart
rm -f /root/vnstat-2.6.tar.gz 
rm -rf /root/vnstat-2.6

# Swap RAM 1GB
wget https://raw.githubusercontent.com/tonho911/MarLing/refs/heads/main/swap.sh -O swap
sh swap 1G
rm swap

#Install Speedtest
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
sudo apt-get install speedtest -y


