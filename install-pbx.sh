#!/bin/bash
#
# Tenkai
# Install Asterisk and FreePBX on Ubuntu LTS 12.04
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
#
# About
# -----
# This script takes a stock Ubuntu 12.04 LTS system and installs Asterisk with FreePBX. 
# Once installed, Asterisk you can use apt (for asterisk) and the FreePBX upgrade scripts
# to keep your system updated. 
# 
# Tenkai is a modified version of the Ballistic-PBX installation script written by Jonathan Roper.
#
#
# Credit
# ------
# Original script by jonathan@star2billing.com - https://github.com/jonathan-roper/Ballistic-PBX
#





# ---------------------- Install Dependencies ------------------------
function funcdependencies()
{

  KERNELARCH=$(uname -p)

  apt-get -y autoremove
  apt-get -f install
  apt-get -y update
  apt-get -y upgrade

  echo ""
  echo ""
  echo ""
  echo "If the Kernel has been updated, we advise you to reboot your server and re-run the install script!"
  echo "If you are not sure whether the kernel has been updated, reboot and start again"
  echo ""
  echo "Press CTRL C to exit and reboot, or enter to continue"
  [ -f /var/run/reboot-required ] && echo "*** System restart required ***" || echo "*** System restart NOT required ***"
  read TEMP

  # check timezone
  # dpkg-reconfigure tzdata

  #install asterisk
  apt-get -i install asterisk

  #install dependencies
  apt-get -y install libsqlite3-dev sqlite3 uuid-dev
  apt-get -y install mysql-server
  apt-get -y install mysql-client libmysqlclient-dev build-essential sysvinit-utils libxml2 libxml2-dev libncurses5-dev libcurl4-openssl-dev libvorbis-dev libspeex-dev 
  apt-get -y unixodbc unixodbc-dev libiksemel-dev wget iptables php5 php5-cli php-pear php5-mysql php-db libapache2-mod-php5 php5-gd php5-curl sqlite libnewt-dev libusb-dev zlib1g-dev 
  apt-get -y libsqlite0-dev libapache2-mod-auth-mysql sox mpg123 flite php5-mcrypt python-setuptools python-mysqldb python-psycopg2 python-sqlalchemy ntp

  #extras
  apt-get -y install wget sudo iptables vim subversion flex bison libtiff-tools ghostscript autoconf gcc g++ automake libtool patch
  apt-get -y install linux-headers-$(uname -r)

  #remove the following packages for security.
  apt-get -y remove nfs-common portmap

  #Enable Mod_Auth_MySQL
  ln -s /etc/apache2/mods-available/auth_mysql.load /etc/apache2/mods-enabled/auth_mysql.load

  #Set MySQL to start automatically
  update-rc.d mysql remove
  update-rc.d mysql defaults

  #Sync the clock
  apt-get -y install ntp ntpdate
  /usr/sbin/ntpdate -su pool.ntp.org
  hwclock --systohc
}

# ---------------------- Freepbx 11 ------------------------
function funcfreepbx() {

  #check asterisk is running, before FreePBX is installed.
  if test -f /var/run/asterisk/asterisk.pid; 
  then

    #Don't allow progress until access confirmed to database
    #Check root password set, if not, ask for it
    if [ -z "${MYSQLROOTPASSWD+xxx}" ]; then read -p "Enter MySQL root password " MYSQLROOTPASSWD; fi

    if [ -z "$MYSQLROOTPASSWD" ] && [ "${MYSQLROOTPASSWD+xxx}" = "xxx" ]; then read -p "Enter MySQL root password " MYSQLROOTPASSWD; fi 

    echo "Please enter the MySQL root password"
    until mysql -uroot -p$MYSQLROOTPASSWD -e ";" ; do 
    	echo "Please enter the MySQL root password"
		read MYSQLROOTPASSWD
		echo "password incorrect"

	done
    
  #Write FreePBX info
  echo "MySQL Root Password = $MYSQLROOTPASS"
  
  #Set Apache to run as asterisk
  sed -i 's/www-data/asterisk/g'  /etc/apache2/envvars
  chown -R asterisk:asterisk /var/lock/apache2
  /etc/init.d/apache2 restart
    
	# Get FreePBX - Unzip and modify
  cd /usr/src
  rm -rf freepbx*.tar.gz
  rm -rf freepbx
  wget http://mirror.freepbx.org/freepbx-2.11.0.tar.gz
  tar zxfv freepbx*.tar.gz
  rm -rf freepbx*.tar.gz
  mv freepbx-2* freepbx

  mkdir /var/www/html
  mkdir /var/lib/asterisk/bin

  cd /usr/src/freepbx

  if [ ! -f /etc/amportal.conf ]; 
  then

    #Prepare Amportal and copy it into location.
    #Generate random password for FreePBX database user
    funcrandpass
    FREEPBXPASSW=$RANDOMPASSW

    #Generate random password for the AMI
    funcrandpass
    AMIPASSW=$RANDOMPASSW

    #make some changes to Amportal
    sed -i 's/AUTHTYPE=none/AUTHTYPE=database/g' amportal.conf

    #write out the new database user and password
    echo "
AMPDBUSER=asteriskuser
AMPDBPASS=$FREEPBXPASSW
    	" >> amportal.conf

    sed -i "s/AMPMGRPASS=amp111/AMPMGRPASS=$AMIPASSW/g"  amportal.conf

    #Set the ARI password
    funcrandpass
    ARIPASSW=$RANDOMPASSW
    sed -i "s/ARI_ADMIN_PASSWORD=ari_password/ARI_ADMIN_PASSWORD=$ARIPASSW/g"  amportal.conf

    cp amportal.conf /etc/amportal.conf

	else	
		#Amportal already prepared, just go on to installation.
		echo "Amportal already setup, go straight to installation"
	fi

	source /etc/amportal.conf

  #create the MySQL databases
  mysqladmin -uroot -p$MYSQLROOTPASSWD create asterisk
  mysqladmin -uroot -p$MYSQLROOTPASSWD create asteriskcdrdb
  mysql -uroot -p$MYSQLROOTPASSWD  asterisk < SQL/newinstall.sql
  mysql -uroot -p$MYSQLROOTPASSWD asteriskcdrdb < SQL/cdr_mysql_table.sql
  mysql -uroot -p$MYSQLROOTPASSWD -e "GRANT ALL PRIVILEGES ON asterisk.* TO asteriskuser@localhost IDENTIFIED BY '$AMPDBPASS'"
  mysql -uroot -p$MYSQLROOTPASSWD -e "GRANT ALL PRIVILEGES ON asteriskcdrdb.* TO asteriskuser@localhost IDENTIFIED BY '$AMPDBPASS'"
  ./install_amp --username=$AMPDBUSER --password=$AMPDBPASS

  chown -R asterisk:asterisk /etc/asterisk
  chown -R asterisk:asterisk /var/www/html/
  chown -R asterisk:asterisk /var/lib/asterisk

  #Remove files, and re-symlink 
  rm /etc/asterisk/cel.conf
  rm /etc/asterisk/cel_odbc.conf
  rm /etc/asterisk/logger.conf
  rm /etc/asterisk/extensions.conf
  rm /etc/asterisk/iax.conf
  rm /etc/asterisk/sip_notify.conf
  rm /etc/asterisk/features.conf
  rm /etc/asterisk/sip.conf
  rm /etc/asterisk/confbridge.conf
  rm /etc/asterisk/ccss.conf
  rm /etc/asterisk/udptl.conf
  /var/lib/asterisk/bin/retrieve_conf 

  #Bring modules upto date and get useful modules
  /var/lib/asterisk/bin/module_admin upgradeall

  /var/lib/asterisk/bin/module_admin download asterisk-cli
  /var/lib/asterisk/bin/module_admin download asteriskinfo 
  /var/lib/asterisk/bin/module_admin download backup 
  /var/lib/asterisk/bin/module_admin download fw_ari
  /var/lib/asterisk/bin/module_admin download iaxsettings
  /var/lib/asterisk/bin/module_admin download languages 
  /var/lib/asterisk/bin/module_admin download logfiles 
  /var/lib/asterisk/bin/module_admin download phpinfo
  /var/lib/asterisk/bin/module_admin download sipsettings 
  /var/lib/asterisk/bin/module_admin download weakpasswords 
  /var/lib/asterisk/bin/module_admin download fw_langpacks

  /var/lib/asterisk/bin/module_admin install asterisk-cli
  /var/lib/asterisk/bin/module_admin install asteriskinfo 
  /var/lib/asterisk/bin/module_admin install backup 
  /var/lib/asterisk/bin/module_admin install fw_ari
  /var/lib/asterisk/bin/module_admin install iaxsettings
  /var/lib/asterisk/bin/module_admin install languages 
  /var/lib/asterisk/bin/module_admin install logfiles 
  /var/lib/asterisk/bin/module_admin install phpinfo 
  /var/lib/asterisk/bin/module_admin install sipsettings 
  /var/lib/asterisk/bin/module_admin install weakpasswords 
  /var/lib/asterisk/bin/module_admin install fw_langpacks

  /var/lib/asterisk/bin/module_admin reload

  # Stop the ability to type the URL of the module and bypass security
  echo "
  Options -Indexes
  <Files .htaccess>
  deny from all
  </Files> 
  " > /var/www/html/admin/modules/.htaccess

  #Set the AMI to only listen on 127.0.0.1
  sed -i 's/bindaddr = 0.0.0.0/bindaddr = 127.0.0.1/g' /etc/asterisk/manager.conf


  #Get FreePBX to start automatically on boot.
  echo '#!/bin/bash' > /etc/init.d/amportal-start
  echo '/usr/local/sbin/amportal start' >> /etc/init.d/amportal-start
  chmod +x /etc/init.d/amportal-start
  update-rc.d amportal-start start 99 2 3 4 5 .

  echo '#!/bin/bash' > /etc/init.d/amportal-stop
  echo '/usr/local/sbin/amportal stop' >> /etc/init.d/amportal-stop
  chmod +x /etc/init.d/amportal-stop
  update-rc.d amportal-stop stop 10 0 1 6 .

  /etc/init.d/asterisk stop
  update-rc.d -f asterisk remove

  /etc/init.d/apache2 restart
  amportal kill
  amportal start

  #Insert admin / admin user into FreePBX
  mysql -uroot -p$MYSQLROOTPASSWD asterisk -e "INSERT INTO ampusers (username,password_sha1,extension_low,extension_high,deptname,sections) VALUES ('vm', '3559095f228e3d157f2e10971a9283b28d86395c', '', '', '', '');"

  echo "Log into the FreePBX interface for the first time with:"
  echo "username = vm"
  echo "password = vmadmin"
  echo "This can be changed via the FreePBX administrator interface later."
  echo "Press Enter to continue"
  read TEMP

else

    clear
    echo "asterisk is not running"
    echo "please correct this before installing FreePBX"
    echo "Press enter to return to the install menu."
    read temp
fi

#Write FreePBX info
echo "MySQL Root Password = $MYSQLROOTPASS"
}

# ---------------------- Generate Random Password -------------------
function funcrandpass()
{
  RANDOMPASSW=`cat /dev/urandom | tr -cd [:alnum:] | head -c 30`
}

# ---------------------- Menu ------------------------
function show_menu()
{
  echo " > Tenkai (ubuntu)"
  echo "================================"
  echo " 0)  Install Asterisk, FreePBX and dependencies"
  echo " 1)  Quit"
  echo ""
  echo -n "(0-1) : "
  read OPTION < /dev/tty
}



ExitFinish=0

while [ $ExitFinish -eq 0 ]; do

    show_menu

    case $OPTION in
        0) 
            funcdependencies
            funcfreepbx
            echo "done"
        ;;
        1)
        ExitFinish=1
        ;;
        *)
    esac

done