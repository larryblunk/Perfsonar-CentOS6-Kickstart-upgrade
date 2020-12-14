# Perfsonar-CentOS7-Kickstart-install
A kickstart file for remotely installing a CentOS 7 and Perfsonar on existing CentOS 6 deviced

Perfsonar (www.perfsonar.net) ended support for CentOS 6 after 4.0.2 relesae and CentOS 6
itself went end-of-support on Nov 30, 2020.  Upgrading from CentOS 6 to CentOS 7 is not
officially support and is generally recommended one do a re-install instead.  Re-installing
remotely without direct console access can be accomplished using a Kickstart based install.
The Kickstart contained in this repository is based off the mechansim described in this
blog post -- https://fredrikaverpil.github.io/2015/12/30/install-centos-7-remotely-using-kickstart-and-grub/

The kickstart template used for this kickstart comes from the Perfsonar CentOS 7 net-install Kickstart file
at https://github.com/perfsonar/toolkit-building/blob/master/kickstarts/centos7-netinstall.cfg
