# my Fedora installation and configuration

## install minimal fedora (F36)

To install a minimal Fedora, download the Fedora Server netinst ISO from the official [Fedora Server download page](https://getfedora.org/en/server/download/).

From the "Software Selection" page, select "Minimal Install" as Base Environment, and select only "Standard". Optionally you can select "Sound and Video" and "Guest Agents" if you are running it in QEMU (I did not test it with other Hypervisors)

run `sudo bash install.sh` from this repository in the freshly installed Fedora
