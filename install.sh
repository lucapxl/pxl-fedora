#!/bin/bash

# optimize DNF
echo "[INFO] Optimizing DNF"
sudo dnf upgrade --refresh -y
echo "max_parallel_downloads=10" >> /etc/dnf/dnf.conf
echo "fastestmirror=True" >> /etc/dnf/dnf.conf
sudo dnf upgrade --refresh -y

# install sway
echo "[INFO] Installing sway and other prerequisites"
sudo dnf install -y sway waybar swaylock polkit

# if running in qemu then set the correct variables to run sway
if hostnamectl | grep -q "Hardware Vendor: QEMU"; then
    echo "[INFO] Running on QEMU VM. configuring settings to run sway correctly"
    echo "export LIBGL_ALWAYS_SOFTWARE=true" >> .bashrc
    echo "export WLR_NO_HARDWARE_CURSORS=1" >> .bashrc
fi

# install some packages
sudo dnf install -y firefox thefuck tldr blueman-manager

# if running on a laptop, install the CPU frequency tool
if hostnamectl | grep -q "Chassis: laptop"; then
    echo "[INFO] Running on laptop, installing cpufreq tool"
    mkdir tools
    cd tools
    git clone https://github.com/AdnanHodzic/auto-cpufreq.git
    cd auto-cpufreq && sudo ./auto-cpufreq-installer
fi


# copy the file .local/share/applications/mimeapps.list that contains to automatically open citrix


