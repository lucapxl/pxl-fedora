#!/bin/bash
######################
# Edit these variables to customize your installation
# packages that will be installed additionally to sway and QmlGreet
PACKAGES="firefox thefuck tldr blueman"

##################################################################

######################
# Defining some variables needed during the installation
######################
USERDIR=$(echo "/home/$SUDO_USER")
TOOLSDIR=$(echo "$USERDIR/_tools")

######################
# Making sure the user running has root privileges
######################
if [ "$EUID" -ne 0 ]
  then echo "Please run with sudo"
  exit
fi

if [[ -z "$SUDO_USER" ]]; then
  echo "Please run with sudo from your user, not from the root user directly"
  exit
fi

# creating necessary folders
mkdir -p $TOOLSDIR
mkdir -p $USERDIR/.config
cd $TOOLSDIR

######################
# Optimize DNF
######################
echo -e "[INFO] Optimizing DNF" ; sleep 2
dnf upgrade --refresh -y
echo "max_parallel_downloads=10" >> /etc/dnf/dnf.conf
echo "fastestmirror=True" >> /etc/dnf/dnf.conf
dnf upgrade --refresh -y

######################
# Install sway
######################
echo -e "[INFO] Installing sway and other prerequisites" ; sleep 2
dnf install -y sway waybar swaylock polkit

######################
# If running in qemu then set the correct variables to run sway
######################
if hostnamectl | grep -q "Virtualization: kvm"; then
    echo -e "[INFO] Running on QEMU VM. configuring settings to run sway correctly" ; sleep 2
    echo "export LIBGL_ALWAYS_SOFTWARE=true" >> $USERDIR/.bashrc
    echo "export WLR_NO_HARDWARE_CURSORS=1" >> $USERDIR/.bashrc
fi

######################
# Install emptty
######################
echo -e "[INFO] Installing emptty" ; sleep 2
dnf install golang-go pam-devel libX11-devel gcc gcc-c++ cmake
cd $TOOLSDIR
git clone https://github.com/tvrzna/emptty.git
cd emptty
make build
make install
make install-pam-fedora
make install-config
make install-systemd

systemctl enable emptty.service

echo -e "[INFO] Configuring emptty" ; sleep 2
cat > $USERDIR/.config/emptty <<EOL
#!/bin/bash
Environment=wayland
. /etc/profile
. ~/.bashrc
/usr/bin/sway
EOL

chmod +x $USERDIR/.config/runsway.sh
chown -r $SUDO_USER:$SUDO_USER $USERDIR/.config


######################
# Install some packages
######################
echo -e "[INFO] Installing some more packages" ; sleep 2
dnf install -y $PACKAGES

# if running on a laptop, install the CPU frequency tool
if hostnamectl | grep -q "Chassis: laptop"; then
    echo -e "[INFO] Running on laptop, installing cpufreq tool" ; sleep 2
    dnf install -y python-devel dmidecode
    cd $TOOLSDIR
    git clone https://github.com/AdnanHodzic/auto-cpufreq.git
    cd auto-cpufreq && ./auto-cpufreq-installer --install
fi


echo -e "[INFO] Installation completed! rebooting" ; sleep 2
systemctl reboot