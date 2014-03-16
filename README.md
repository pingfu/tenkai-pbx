tenkai-pbx
==========

Asterisk and FreePBX deployment script for Ubuntu.


About
=====

This script takes a _stock_ Ubuntu 12.04 LTS system and installs Asterisk with FreePBX. Once installed, you can use apt to maintant the Asterisk installation and the FreePBX upgrade scripts to keep your system updated.

Tenkai is a modified version of the Ballistic-PBX installation script written by Jonathan Roper.


Changes
=======

The major differences between the Ballistic-PBX installation script and Tenkai are:

* Tenkai is for unattended installations.
* Tenkai assumes installation is taking place over SSH. Does not try to install openssh-server
* Tenkai generates a random MySQL password for you.
* Asterisk is installed using apt, not compiled from source for better package maintenance.
* All dependancies are managed by apt.
* Removed DAHDI and libpri, Tenkai assumes a pure SIP/IAX deployment.
* Removed installation of OSSEC.
* Removed installation of iptables.
* Removed installation of SSH keys.
* Removed installation of TFTP server.
* Removed installation of kernel headers and compiler tools.
* Removed installation of Postfix
* Removed Apache TLS configuration.
* Script no longer creates a `/etc/ballistic/` directory
* Added fail2ban

Tenkai installs bare-bones Asterisk and FreePBX. No surprises.

Package List
============

Tenkai manages the installation of:

`apache2` `asterisk` `build-essential` `fail2ban` `flite` `libapache2-mod-auth-mysql` `libapache2-mod-php5` `libcurl4-openssl-dev` `libiksemel-dev` `libmysqlclient-dev` `libncurses5-dev` `libnewt-dev` `libspeex-dev` `libsqlite0-dev` `libsqlite3-dev` `libusb-dev` `libvorbis-dev` `libxml2` `libxml2-dev` `mpg123` `mysql-client` `mysql-server` `ntp` `ntpdate` `php5` `php5-cli` `php5-curl` `php5-gd` `php5-mcrypt` `php5-mysql` `php-db` `php-pear` `python-mysqldb` `python-psycopg2` `python-setuptools` `python-sqlalchemy` `sox` `sqlite` `sqlite3` `sysvinit-utils` `uuid-dev` `wget` `zlib1g-dev`


What tenkai does not do
=======================

What tenkai does not do, but you probably should:

* Configure log file rotation
* Configure your time zone (i.e. `$ dpkg-reconfigure tzdata`)
* Configure fail2ban
* Configure SSL/TLS
* Configure access controls to FreePBX in Apache


Usage
=====

```
$ cd /tmp
$ wget https://raw.github.com/pingfu/tenkai-pbx/master/tenkai-install-pbx.sh
$ chmod 755 tenkai-install-pbx.sh
$ sudo -s
$ ./tenkai-install-pbx.sh
```


Credit
======

Jonathan Roper for the original script - https://github.com/jonathan-roper/Ballistic-PBX


Other
=====

For FreePBX installation scripts on CentOS see http://upgrades.freepbxdistro.org/blank-centos-installer/