# Perfsonar-CentOS7-Kickstart-install
A kickstart file for remotely installing a CentOS 7 and Perfsonar on existing CentOS 6 device

Perfsonar (www.perfsonar.net) ended support for CentOS 6 after 4.0.2 release and CentOS 6
itself went end-of-support on Nov 30, 2020.  Upgrading from CentOS 6 to CentOS 7 is not
officially support and it's generally recommended one do a re-install instead.  Re-installing
remotely without direct console access can be accomplished using a Kickstart based install.
The Kickstart contained in this repository is based off the mechansim described in this
blog post -- https://fredrikaverpil.github.io/2015/12/30/install-centos-7-remotely-using-kickstart-and-grub/

The kickstart template used for this kickstart comes from the Perfsonar CentOS 7 net-install Kickstart file
at https://github.com/perfsonar/toolkit-building/blob/master/kickstarts/centos7-netinstall.cfg

Here are the basic steps involved:
1) If you wish to migrate existing config (and optionally existing data), follow
instructions located at https://docs.perfsonar.net/install_migrate_centos7.html.
Note that the ps_migrate_backup.sh script will likely fail if you do not replace
the Postgresql 8.4 pg_dump binary in /usr/bin with the one from Postgresql 9.5. This
is what I did as a quick hack to replace it -- 
cd /usr/bin; mv pg_dump pg_dump.orig; ln -s /usr/pgsql-9.5/bin/pg_dump

2) Update the ps_upgrade.ks kickstart file where indicated and copy to /boot directory

3) Download vmlinuz and initrd.img files from http://linux.mirrors.es.net/centos/7/os/x86_64/isolinux
and place in /boot directory.

4) Update /boot/grub/grub.conf file and add a new boot option as the first entry to direct
the Kickstart installation on next reboot.

5) Reboot box and optionally use VNC to follow installation process if enabled in Kickstart file.
