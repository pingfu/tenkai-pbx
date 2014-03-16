tenkai
======

Asterisk and FreePBX deployment script for Ubuntu.

About
=====

This script takes a stock Ubuntu 12.04 LTS system and installs Asterisk with FreePBX. Once installed, Asterisk you can use apt (for asterisk) and the FreePBX upgrade scripts to keep your system updated. 

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
* Removed Apache TLS configuration.
* Script no longer creates a directory in /etc
* Assumes installation is taking place over SSH, so does not try to install openssh-server
* Added fail2ban


What this script does not do
============================

* Harden your server
* Configure asterisk log file rotation
* Set the time zone `$ dpkg-reconfigure tzdata`


Usage
=====



Credit
======

https://github.com/jonathan-roper/Ballistic-PBX

Other
=====

For CentOS installation scripts see http://upgrades.freepbxdistro.org/blank-centos-installer/