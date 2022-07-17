#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# optimize DNF
echo -e "\n\n\n\n\n[INFO] Optimizing DNF\n\n\n\n\n" ; sleep 2
sudo dnf upgrade --refresh -y
echo "max_parallel_downloads=10" >> /etc/dnf/dnf.conf
echo "fastestmirror=True" >> /etc/dnf/dnf.conf
sudo dnf upgrade --refresh -y

# install sway
echo -e "\n\n\n\n\n[INFO] Installing sway and other prerequisites\n\n\n\n\n" ; sleep 2
sudo dnf install -y sway waybar swaylock polkit

# if running in qemu then set the correct variables to run sway
if hostnamectl | grep -q "Virtualization: kvm"; then
    echo -e "\n\n\n\n\n[INFO] Running on QEMU VM. configuring settings to run sway correctly\n\n\n\n\n" ; sleep 2
    echo "export LIBGL_ALWAYS_SOFTWARE=true" >> /home/$SUDO_USER/.bashrc
    echo "export WLR_NO_HARDWARE_CURSORS=1" >> /home/$SUDO_USER/.bashrc
fi

# install some packages
echo -e "\n\n\n\n\n[INFO] Installing some more packets\n\n\n\n\n" ; sleep 2
sudo dnf install -y firefox thefuck tldr blueman

# if running on a laptop, install the CPU frequency tool
#if hostnamectl | grep -q "Chassis: laptop"; then
    echo -e "\n\n\n\n\n[INFO] Running on laptop, installing cpufreq tool\n\n\n\n\n" ; sleep 2
    mkdir tools
    cd tools
    git clone https://github.com/AdnanHodzic/auto-cpufreq.git
    cd auto-cpufreq && sudo ./auto-cpufreq-installer
#fi


# copy the file .local/share/applications/mimeapps.list that contains to automatically open citrix


echo -e "\n\n\n\n\n[INFO] rebooting\n\n\n\n\n" ; sleep 2
systemctl reboot