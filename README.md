# Perfsonar-CentOS7-Kickstart-install
A kickstart file for remotely installing CentOS 7 + Perfsonar on an existing CentOS 6 Perfsonar installation.

Perfsonar (www.perfsonar.net) ended support for CentOS 6 after the 4.0.2 release and CentOS 6
itself went end-of-support on Nov 30, 2020.  Upgrading from CentOS 6 to CentOS 7 is not
officially supported and it's generally recommended to do a re-install instead.  Re-installing
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
is what I did as a quick hack to replace it--
```
cd /usr/bin; mv pg_dump pg_dump.orig; ln -s /usr/pgsql-9.5/bin/pg_dump
```

2) Modify the ps_upgrade.ks kickstart file from this repository where indicated (in particular, the rootpw and
network commands) and copy to /boot directory

3) Download vmlinuz and initrd.img files from http://linux.mirrors.es.net/centos/7/os/x86_64/isolinux
and place in /boot directory.
```
curl -o /boot/vmlinuz http://linux.mirrors.es.net/centos/7/os/x86_64/isolinux/vmlinuz
curl -o /boot/initrd.img http://linux.mirrors.es.net/centos/7/os/x86_64/isolinux/initrd.img
```

4) Update /boot/grub/grub.conf file and add a new boot option (as below) as the first entry to direct
the Kickstart installation on next reboot. Enabling sshd is optional -- make sure to set a ssh password in
the kickstart file if enabled.
```
title Install CentOS 7 Perfsonar
 kernel /vmlinuz ks=hd:/dev/sda1:/ps-upgrade.ks sshd=1
 initrd /initrd.img
```

5) Remote VNC access may also be enabled in kickstart file to follow installation process.
