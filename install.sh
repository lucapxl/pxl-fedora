#!/bin/bash

# Author lucapxl 
# Date  2025-08-08

######################
# Edit these variables to customize your installation
# packages that will be installed additionally to labwc 
PACKAGES="firefox thefuck tldr blueman bash-completion"
######################

######################
# Defining some variables needed during the installation
######################
USERDIR=$(echo "/home/$SUDO_USER")
TOOLSDIR=$(echo "$USERDIR/_tools")

######################
# Other Packages required
######################
PACKAGES=" $PACKAGES labwc waybar swaylock wlogout wlop sfwbar xorg-x11-server-Xwayland"          # labwc and labwc related (bar, lock, logou menu)
PAKCAGES=" $PACKAGES gnome-keyring"            # polkit and qtkeychain for 1password and nextcloud
PACKAGES=" $PACKAGES rofi-wayland"                                  # Menu for labwc
PACKAGES=" $PACKAGES wdisplays kanshi"                      # Graphical monitor manager and profile manager
PACKAGES=" $PACKAGES dunst"                                 # Graphical Notification manager
PACKAGES=" $PACKAGES brightnessctl gammastep"               # Brightness manager and gamma changer
PACKAGES=" $PACKAGES playerctl"                             # Player buttons manager
PACKAGES=" $PACKAGES pavucontrol"                           # audio devices manager
PACKAGES=" $PACKAGES nmtui"                # network manager
PACKAGES=" $PACKAGES grim slurp swaybg"                            # screenshot and region selection tools
PACKAGES=" $PACKAGES papirus-icon-theme"                    # icon package
PACKAGES=" $PACKAGES tuigreet greetd"                       # login manager
PACKAGES=" $PACKAGES foot nautilus nextcloud-client nextcloud-client-nautilus flatpak"  # terminal, file manager, nextcloud and file manager plugin for nextcloud
PACKAGES=" $PACKAGES pam-devel libX11-devel gcc appstream-data python-devel dmidecode make tar mozilla-fira-sans-fonts fira-code-fonts galculator google-noto-fonts-all" # prerequisites for installation of packages later

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
# Installing necessary packages
######################
logMe "Installing labwc and other prerequisites"
dnf install -y $PACKAGES --skip-unavailable
dnf update -y @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
sudo dnf install -y gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel
sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing

######################
# If running in qemu then set the correct variables to run sway
######################
# if hostnamectl | grep -q "Virtualization: kvm"; then
#     logMe "[INFO] Running on QEMU VM. configuring settings to run sway correctly"
#     echo "export LIBGL_ALWAYS_SOFTWARE=true" >> $USERDIR/.bashrc
#     echo "export WLR_NO_HARDWARE_CURSORS=1" >> $USERDIR/.bashrc
# fi

######################
# Installing flathub and flatpaks
######################
logMe "[INFO] Installing Flathub"
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install flathub org.keepassxc.KeePassXC -y
flatpak install flathub io.github.flattool.Warehouse -y
flatpak install flathub org.dupot.easyflatpak -y
flatpak install flathub com.visualstudio.code -y
flatpak install flathub org.xfce.mousepad -y

######################
# enabling greetk at start and switching target to graphical
######################
systemctl set-default graphical.target
systemctl enable greetd
# to revert to the tty login
# systemctl set-default multi-user.target
sed -i 's/^command.*/command = "tuigreet --cmd labwc"/' /etc/greetd/config.toml

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
