tenkai
======

Asterisk and FreePBX deployment script for Ubuntu.

About
=====

This script takes a _stock_ Ubuntu 12.04 LTS system and installs Asterisk with FreePBX. Once installed, Asterisk you can use apt (for asterisk) and the FreePBX upgrade scripts to keep your system updated.

Tenkai is a modified version of the Ballistic-PBX installation script written by Jonathan Roper.

Changes
=======

The major differences between the Ballistic-PBX installation script and Tenkai are:

* Tenkai is an unattended installation script.
* Asterisk is installed using apt, not compiled from source.
* All dependancies are also manged by apt to keep your system clean.
* Removed DAHDI and libpri, assumes pure SIP/IAX deployment.
* Removed installation of OSSEC.
* Removed installation of Iptables.
* Removed installation of SSH keys.
* Removed installation of TFTP server.
* Removed installation of kernel headers and compiler tools.
* Removed Apache TLS configuration.
* Script no longer creates a directory in /etc
* Assumes installation is taking place over SSH, so does not try to install openssh-server
* Added fail2ban

Tenkai does exactly what it says on the tin, no surprises.

What this script does not do
============================

What this script does not do, but you probably should:

* Configure log file rotation
* Configure your time zone `$ dpkg-reconfigure tzdata`
* Configure fail2ban
* Configure SSL/TLS
* Configure access controls to FreePBX in Apache
* 

Usage
=====

$ cd /tmp
$ wget https://raw.github.com/pingfu/tenkai/master/install-pbx.sh
$ chmod 755 install-pbx.sh
$ sudo -s
$ ./install-pbx.sh

Credit
======

Jonathan Roper for the original script - https://github.com/jonathan-roper/Ballistic-PBX

Other
=====

For FreePBX installation scripts on CentOS see http://upgrades.freepbxdistro.org/blank-centos-installer/