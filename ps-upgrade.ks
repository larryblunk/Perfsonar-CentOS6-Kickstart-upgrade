##############################
# ps-upgrade.ks
#
# This kickstart file can be used to remotely install CentOS over a CentOS 6
# based Perfsonar installation. It is specific to the x86_64
# architecture. It does a full re-install, so you will need to follow
# https://docs.perfsonar.net/install_migrate_centos7.html
# if you wish to migrate existing Perfsonar configuration and data.
# Note that you will likely need to replace the Postgres8 pg_dump
# binary in /usr/bin to run the ps_migrate_backup.sh script. For example,
# cd /usr/bin; mv pg_dump pg_dump.orig; ln -s /usr/pgsql-9.5/bin/pg_dump
#
# It is based on the Perfsonar net-install kickstart located at
# https://github.com/perfsonar/toolkit-building/blob/master/kickstarts/centos7-netinstall.cfg
# with several modifications and is current as of 10Dec2020.
# Please see README sections below and update where indicated.
#
# For devices with static IP assignments, this kickstart can be placed on
# the local disk (generally /boot partition on /dev/sda1).  You will also
# need to download the CentOS 7 vmlinuz and initrd.img files from
# http://linux.mirrors.es.net/centos/7/os/x86_64/isolinux
# and place them in the /boot partition.
# Finally, add an entry to your /boot/grub/grub.conf file as the first
# entry in order to boot this kickstart and CentOS 7 on reboot
#
# title Install CentOS 7 Perfsonar
#	kernel /vmlinuz ks=hd:/dev/sda1:/ps-upgrade.ks
#	initrd /initrd.img
##############################

install
url --url=http://linux.mirrors.es.net/centos/7/os/x86_64

##############################
# README
# The following has been added to set root password and force a reboot
# after installation for automatic installation.  You will need to fill
# in the encrypted root password from your existing system.
# You may also wish to uncomment and enable remote ssh and vnc support below
# to follow installation progress and possibly rescue stuck installation
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
# Boot configuration
##############################
zerombr
bootloader --location=mbr

##############################
# README
# Disk partitioning
# autopart tells the install to automatically create LVM volumes
# and the --nohome indicates it should not create a separate home volume.
# The root partition will still be 50GB.  The post install lvextend
# command below will extend the root volume to use all available space
# If you have more than one disk you may wish to uncomment the ignoredisk
# directive below to force using a particular disk
##############################
autopart --type=lvm --nohome
#ignoredisk --only-use=sda

##############################
# README
# Network configuration
# This assumes you are using a statically configured IP address and
# you will need to fill in the appropriate values. MAC address can be found
# with ifconfig command. The MAC address is used instead of interface name
# as interface names changed between CentOS 6 and 7.
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
