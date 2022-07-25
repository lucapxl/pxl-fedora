#!/bin/bash

# Author lucapxl 
# Date  2022-07-17

######################
# Edit these variables to customize your installation
# packages that will be installed additionally to sway and QmlGreet
PACKAGES="firefox thefuck tldr blueman"
######################


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

######################
# Output function
######################
function logMe {
    echo ""
    echo ""
    echo "============================================================"
    echo "============================================================"
    echo "==="
    echo "===" $1
    echo "==="
    echo "============================================================"
    echo "============================================================"
    sleep 3
}

# creating necessary folders
mkdir -p $TOOLSDIR
mkdir -p $USERDIR/.config
cd $TOOLSDIR

######################
# Enabling RPM Fusion
######################
logMe "Enabling RPM Fusion"
dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

######################
# Optimize DNF
######################
logMe "Optimizing DNF"
dnf upgrade --refresh -y
echo "max_parallel_downloads=10" >> /etc/dnf/dnf.conf
echo "fastestmirror=True" >> /etc/dnf/dnf.conf
dnf upgrade --refresh -y

######################
# Installing necessary packages
######################
# Dunst - popup notification tool
# Light - display brightness tool
# rofi - application starter - menu
# wdisplay - display manager for wayland
# kanshi - profile manager for display settings
# gammastep - change gamma day/night
# nemo - file manager
logMe "Installing sway and other prerequisites"
dnf install -y sway waybar swaylock polkit neofetch golang-go pam-devel libX11-devel gcc appstream-data wofi wdisplays dunst light kanshi alacritty gammastep nemo nextcloud-client-nemo wlogout
dnf groupupdate -y multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
dnf groupupdate -y sound-and-video

######################
# If running in qemu then set the correct variables to run sway
######################
if hostnamectl | grep -q "Virtualization: kvm"; then
    logMe "[INFO] Running on QEMU VM. configuring settings to run sway correctly"
    echo "export LIBGL_ALWAYS_SOFTWARE=true" >> $USERDIR/.bashrc
    echo "export WLR_NO_HARDWARE_CURSORS=1" >> $USERDIR/.bashrc
fi

######################
# Install emptty
######################
logMe "[INFO] Installing emptty"
cd $TOOLSDIR
git clone https://github.com/tvrzna/emptty.git
cd emptty
make build
make install
make install-pam-fedora
make install-config
make install-systemd

######################
# customizing emptty
######################
sed -ir "s/^[#]*\s*PRINT_ISSUE=.*/PRINT_ISSUE=false/" /etc/emptty/conf
sed -ir "s/^[#]*\s*DYNAMIC_MOTD=.*/DYNAMIC_MOTD=true/" /etc/emptty/conf
sed -ir "s/^[#]*\s*DYNAMIC_MOTD_PATH=.*/DYNAMIC_MOTD_PATH=\/etc\/emptty\/dynamic-motd.sh/" /etc/emptty/conf
cat > /etc/emptty/dynamic-motd.sh <<EOL
#!/bin/bash
neofetch --logo
echo ""
echo ""
echo "PXL Fedora"
EOL

chmod 744 /etc/emptty/dynamic-motd.sh

######################
# enabling emptty at start and switching target to graphical
######################
systemctl enable emptty
systemctl set-default graphical.target
# to revert to the tty login
# systemctl set-default multi-user.target

logMe "[INFO] Configuring emptty"
cat > $USERDIR/.config/emptty <<EOL
#!/bin/bash
Environment=wayland
. /etc/profile
. ~/.bashrc
/usr/bin/sway
EOL

chmod +x $USERDIR/.config/emptty

######################
# Install some packages
######################
logMe "[INFO] Installing some more packages"
dnf install -y $PACKAGES

######################
# if running on a laptop, install the CPU frequency tool
######################
if hostnamectl | grep -q "Chassis: laptop"; then
    logMe "[INFO] Running on laptop, installing cpufreq tool"
    dnf install -y python-devel dmidecode
    cd $TOOLSDIR
    git clone https://github.com/AdnanHodzic/auto-cpufreq.git
    cd auto-cpufreq && ./auto-cpufreq-installer --install
fi

######################
# Download and apply config files
######################
logMe "[INFO] applying config files"
cd $TOOLSDIR
git clone https://github.com/lucapxl/dotconfig.git
cd dotconfig/files
cp -R  $TOOLSDIR/dotconfig/files/* ~/.config/

######################
# recursively fix ownership for .config directory
######################
chown -R $SUDO_USER:$SUDO_USER $USERDIR

######################
# all done, rebooting
######################
logMe "[INFO] Installation completed! press any key to reboot"
read -p ""
systemctl reboot