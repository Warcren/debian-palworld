#!/bin/bash

## check for sudo/root
if ! [ $(id -u) = 0 ]; then
  echo "This script must run with sudo, try again..."
  exit 1
fi

# Get the username of the user who invoked sudo
if [ "$SUDO_USER" ]; then
  username="$SUDO_USER"
else
  username="$(whoami)"
fi

# Get the home directory of the user
homedir=$(getent passwd "$username" | cut -d: -f6)

# This function runs the 'sudo apt-get install -y nala' command and install nala on the OS
run_nala_install() {
	
    sudo apt update && sudo apt upgrade
    sudo apt-get install -y nala
}

# This function runs the 'sudo nala fetch' command and sends the response '1 2 3 y' when prompted for input
run_nala_fetch() {
    echo "Running 'sudo nala fetch' command..."
    { echo "1 2 3"; echo "y"; } | sudo nala fetch
}

# This function runs the 'nala' command and installs several needed packages:
run_nala_installPackages() {

	sudo nala install -y \
	xz-utils \
	curl \
	nano \
	debconf \
	ufw \
	fail2ban \
	net-tools \
	iptables \
	unzip \
	dbus-x11 \
	neofetch \
	htop \
	psmisc \
	jq \
	sed \
	gawk \
	iw
}

#This function applies a security baseline.
setup_security() {
    # Setup UFW rules
    sudo ufw limit 22/tcp  
    sudo ufw allow 80/tcp  
    sudo ufw allow 443/tcp
    sudo ufw default deny incoming  
    sudo ufw default allow outgoing
    sudo ufw enable

    # Harden /etc/sysctl.conf
    sudo sysctl kernel.modules_disabled=1
    sudo sysctl -a
    sudo sysctl -A
    sudo sysctl mib
    sudo sysctl net.ipv4.conf.all.rp_filter
    sudo sysctl -a --pattern 'net.ipv4.conf.(eth|wlan)0.arp'

    # PREVENT IP SPOOFS
    sudo bash -c 'echo -e "order bind,hosts\nmulti on" > /etc/host.conf'

    # Enable fail2ban
    sudo cp jail.local /etc/fail2ban/
    sudo touch /var/log/auth.log
    echo "logpath = /var/log/auth.log" | sudo tee -a /etc/fail2ban/jail.d/defaults-debian.conf

    sudo systemctl enable fail2ban
    sudo systemctl daemon-reload
    sudo systemctl start fail2ban

    echo "listening ports"
    sudo netstat -tunlp 
}

run_bash_install() {
	cd "$homedir/"
	git clone https://github.com/Warcren/mybash.git
 	cd mybash
  	mv setup.sh "$homedir/"
   	mv starship.toml "$homedir/"
    	cd "$homedir/"
  	chmod +x setup.sh
   	sudo ./setup.sh
    	cd "$homedir/debian-desktop"
}

# Main script
echo "Starting script..."

#Install Nala and Fetch best mirrors
run_nala_install
run_nala_fetch

#Install Additional Packages
run_nala_installPackages

#Hardens Server
setup_security

#Setup Custom Bash
run_bash_install

echo "Script finished."

