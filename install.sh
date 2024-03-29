#!/bin/bash

# Author lucapxl 
# Date  2022-07-17

######################
# Edit these variables to customize your installation
# packages that will be installed additionally to sway and QmlGreet
PACKAGES="firefox thefuck tldr blueman neofetch bash-completion"
######################

######################
# Defining some variables needed during the installation
######################
USERDIR=$(echo "/home/$SUDO_USER")
TOOLSDIR=$(echo "$USERDIR/_tools")

######################
# Other Packages required
######################
PACKAGES=" $PACKAGES sway waybar swaylock wlogout"          # sway and sway related (bar, lock, logou menu)
PAKCAGES=" $PACKAGES polkit lxpolkit qtkeychain gnome-keyring gnome-keyring-pam seahorse"            # polkit and qtkeychain for 1password and nextcloud
PACKAGES=" $PACKAGES rofi"                                  # Menu for sway
PACKAGES=" $PACKAGES wdisplays kanshi"                      # Graphical monitor manager and profile manager
PACKAGES=" $PACKAGES dunst"                                 # Graphical Notification manager
PACKAGES=" $PACKAGES light gammastep"                       # Brightness manager and gamma changer
PACKAGES=" $PACKAGES pavucontrol"                           # audio devices manager
PACKAGES=" $PACKAGES network-manager-applet"                # network manager
PACKAGES=" $PACKAGES grim slurp"                            # screenshot and region selection tools
PACKAGES=" $PACKAGES papirus-icon-theme"                    # icon package
#PACKAGES=" $PACKAGES sddm"                                  # login manager
PACKAGES=" $PACKAGES alacritty nautilus nextcloud-client nextcloud-client-nautilus"  # terminal, file manager, nextcloud and file manager plugin for nextcloud
PACKAGES=" $PACKAGES golang-go pam-devel libX11-devel gcc appstream-data python-devel dmidecode make tar" # prerequisites for installation of packages later

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
echo "max_parallel_downloads=10" >> /etc/dnf/dnf.conf
echo "fastestmirror=True" >> /etc/dnf/dnf.conf
dnf upgrade --refresh -y

######################
# Add additional repositories
######################
# 1password
logMe "Adding repositories"
rpm --import https://downloads.1password.com/linux/keys/1password.asc
sh -c 'echo -e "[1password]\nname=1Password Stable Channel\nbaseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=\"https://downloads.1password.com/linux/keys/1password.asc\"" > /etc/yum.repos.d/1password.repo'
PACKAGES=" $PACKAGES 1password"  # Adding 1password to packages to install

# IVPN
dnf config-manager --add-repo https://repo.ivpn.net/stable/fedora/generic/ivpn.repo
PACKAGES=" $PACKAGES ivpn ivpn-ui"  # Adding IVPN to packages to install

# Microsoft Edge, Teams and VS Code
rpm --import https://packages.microsoft.com/keys/microsoft.asc
dnf config-manager --add-repo https://packages.microsoft.com/yumrepos/edge
dnf config-manager --add-repo https://packages.microsoft.com/yumrepos/ms-teams
dnf config-manager --add-repo https://packages.microsoft.com/yumrepos/vscode
PACKAGES=" $PACKAGES microsoft-edge-stable teams code"  # Adding Microosft Edge and Teams to packages to install

######################
# Installing necessary packages
######################
logMe "Installing sway and other prerequisites"
dnf install -y $PACKAGES
sudo dnf groupupdate -y multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
sudo dnf groupupdate -y sound-and-video
sudo dnf install -y gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel
sudo dnf install -y lame\* --exclude=lame-devel
sudo dnf group upgrade -y --with-optional Multimedia

######################
# If running in qemu then set the correct variables to run sway
######################
if hostnamectl | grep -q "Virtualization: kvm"; then
    logMe "[INFO] Running on QEMU VM. configuring settings to run sway correctly"
    echo "export LIBGL_ALWAYS_SOFTWARE=true" >> $USERDIR/.bashrc
    echo "export WLR_NO_HARDWARE_CURSORS=1" >> $USERDIR/.bashrc
fi

######################
# enabling gdm at start and switching target to graphical
######################
# systemctl enable sddm
# systemctl set-default graphical.target
# to revert to the tty login
# systemctl set-default multi-user.target

#####################
# Downloading SDDM theme
#####################

######################
# if running on a laptop, install the CPU frequency tool
######################
if hostnamectl | grep -q "Chassis: laptop"; then
    logMe "[INFO] Running on laptop, installing cpufreq tool"
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
cp -R  $TOOLSDIR/dotconfig/files/* $USERDIR/.config/

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
