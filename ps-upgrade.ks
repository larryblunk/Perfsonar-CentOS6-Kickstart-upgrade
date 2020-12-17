##############################
# ps-upgrade.ks
#
# This kickstart file can be used to remotely install CentOS 7 over an
# existing CentOS 6 Perfsonar installation. It does a full re-install, so
# you will need to follow  https://docs.perfsonar.net/install_migrate_centos7.html
# if you wish to migrate existing Perfsonar configuration and data.
# Note that you will likely need to replace the Postgres8.4 pg_dump
# binary in /usr/bin to run the ps_migrate_backup.sh script. For example,
# cd /usr/bin; mv pg_dump pg_dump.orig; ln -s /usr/pgsql-9.5/bin/pg_dump
#
# It is based on the Perfsonar net-install kickstart located at
# https://github.com/perfsonar/toolkit-building/blob/master/kickstarts/centos7-netinstall.cfg
# with several modifications and is current as of 10Dec2020.
# Please see README sections below and update where indicated.
#
# This kickstart file can be placed on the local disk. In most cases, it can be
# placed in the /boot directory mounted as /dev/sda1.  You will also
# need to download the CentOS 7 vmlinuz and initrd.img files from
# http://linux.mirrors.es.net/centos/7/os/x86_64/isolinux and place them
# in the /boot directory.
# Finally, add an entry to your /boot/grub/grub.conf file as the first
# entry in order to boot this kickstart and install CentOS 7 on reboot. The
# below assumes ps-upgrade.ks is in /boot directory mounted on /dev/sda1. sshd=1 is
# optional and starts the sshd server. The password is defined in this kickstart file.
#
# title Install CentOS 7 Perfsonar
#	  kernel /vmlinuz ks=hd:/dev/sda1:/ps-upgrade.ks sshd=1
#	  initrd /initrd.img
##############################

install
url --url=http://linux.mirrors.es.net/centos/7/os/x86_64

##############################
# README
# The following sets the root password and forces a reboot
# after installation for automatic installation.  You will need to fill
# in the encrypted root password from your existing system (or optionally
# use --plaintext option with a plaintext password for root).
# You may also wish to uncomment and enable remote ssh and vnc support
# to follow installation progress and possibly rescue a stuck installation.
##############################
rootpw --iscrypted <encrypted root password>
reboot
#vnc --password=<vnc password>
#sshpw --username=root <root password>

##############################
# README
# preset timezone/keyboard/language for automatic installation
# These can be copied from original install Kickstart at /root/anaconda-ks.cfg
##############################
timezone America/New_York
keyboard --vckeymap=us --xlayouts='us'
lang en_US.UTF-8

##############################
# System Configuration
##############################
auth --enableshadow --enablemd5
firstboot --disabled
selinux --disabled
skipx

##############################
# README
# Disk partitioning and installation drive selection
# This assumes /dev/sda is the install disk.
# autopart tells the installation to automatically create LVM volumes
# and the --nohome directive tells it not to create a separate home volume.
# The root volume will still be 50GB even though no home volume is created.
# The post install lvextend command below will extend the root volume to
# use all available space.
##############################
ignoredisk --only-use=sda
zerombr
clearpart --all --initlabel --drives=sda
bootloader --location=mbr --boot-drive=sda
autopart --type=lvm --nohome

##############################
# README
# Network configuration
# This assumes you are using a statically configured IP address and
# you will need to fill in the appropriate values. The MAC address can be found
# with ifconfig command. While the interface name can be used for the device
# as well, be aware that interface naming conventions changed between CentOS 6
# and 7, and thus using the MAC address will likely be more straightforward.
##############################
network --bootproto=static --device=<MAC Address> --ip=<device IP> --netmask=<Netmask> --gateway=<Gateway IP> --hostname=<Hostname> --nameserver=<Nameserver IP> activate

##############################
# Repository Configuration
##############################
repo --name=a-base      --baseurl=http://linux.mirrors.es.net/centos/7/os/x86_64
repo --name=a-extras    --baseurl=http://linux.mirrors.es.net/centos/7/extras/x86_64
repo --name=a-updates   --mirrorlist=http://software.internet2.edu/rpms/el7/mirrors-Toolkit-CentOS-Updates-x86_64
repo --name=a-EPEL      --mirrorlist=http://software.internet2.edu/rpms/el7/mirrors-Toolkit-EPEL-x86_64
repo --name=a-perfSONAR --baseurl=https://software.internet2.edu/rpms/el7/x86_64/latest

##############################
# Install Packages
##############################
%packages
@base
@core
@console-internet

authconfig
bash
binutils
chkconfig
comps-extras
cpp
device-mapper-multipath
gcc
glibc
glibc-common
glibc-devel
glibc-headers
httpd
kernel
kernel-headers
less
libgcc
libgomp
libpcap
ntp
openssh-clients
openssh-server
passwd
patch
perl-DBI
policycoreutils
rootfiles
syslinux
system-config-firewall-base
tcpdump
vim-common
vim-enhanced
xkeyboard-config

##############################
# Install Custom Packages
##############################
# EPEL
epel-release

# perfSONAR Repository
perfSONAR-repo

# perfSONAR Toolkit
perfsonar-toolkit
perfsonar-toolkit-systemenv

%end

##############################
# Run Post Scripts
##############################
%post --log=/root/post_install.log

##############################
# Resize root partition
# This is meant to be used with "autopart --nohome" option
# above to force root partition to use all available space
# The original script to resize root no longer works as CentOS 7
# no longer uses fixed names for LVM volumes
##############################
lvextend -r -l +100%FREE `df --output=source | grep -- -root`

##############################
# Disable Readahead
##############################
# Commented out as CentOS 7 no longer uses this file to configure
# readahead (tuned is now the recommended mechanism)
#sed -i 's/=\"yes\"/=\"no\"/g' /etc/sysconfig/readahead

##############################
# Configure Firewall
##############################
echo "" >> /etc/rc.local
echo "/usr/lib/perfsonar/scripts/configure_firewall install" >> /etc/rc.local

##########################################
# Make sure postgresql is setup properly
##########################################
echo "/usr/lib/esmond-database/configure-pgsql.sh 10" >> /etc/rc.local
echo "/usr/lib/perfsonar/scripts/system_environment/configure_esmond new" >> /etc/rc.local
echo "pscheduler internal db-update" >> /etc/rc.local

###################################################################
# Disable chronyd, enable ntpd since can't guarentee install order
###################################################################
echo "systemctl disable chronyd" >> /etc/rc.local
echo "systemctl stop chronyd" >> /etc/rc.local
echo "systemctl enable ntpd" >> /etc/rc.local
echo "systemctl start ntpd" >> /etc/rc.local

chmod +x /etc/rc.local

##########################################
# Record installation type
##########################################
mkdir -p /var/lib/perfsonar/bundles/
echo "netinstall-iso" > /var/lib/perfsonar/bundles/install_method

%end
