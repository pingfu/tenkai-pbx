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
# Todo
# ----
# 1. Add -unattended switch
# 2. Save passwords to /tmp/tenkai-pbx-install.log
#
#
# Credit
# ------
# Original script by jonathan@star2billing.com - https://github.com/jonathan-roper/Ballistic-PBX
#





# ---------------------- Install Dependencies ------------------------
function funcdependencies()
{
  export DEBIAN_FRONTEND=noninteractive

  apt-get update -y

  #install asterisk
  apt-get install -y asterisk

  #install mysql server
  debconf-set-selections <<< 'mysql-server mysql-server/root_password password $MYSQLROOTPASSWD'
  debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password $MYSQLROOTPASSWD'

  echo mysql-server mysql-server/root_password password $MYSQLROOTPASSWD | sudo debconf-set-selections
  echo mysql-server mysql-server/root_password_again password $MYSQLROOTPASSWD | sudo debconf-set-selections

  apt-get install -y mysql-server

  #install dependencies
  apt-get install -y -q apache2 mysql-client build-essential flite libapache2-mod-auth-mysql libapache2-mod-php5 libcurl4-openssl-dev libiksemel-dev libmysqlclient-dev libncurses5-dev libnewt-dev libspeex-dev libsqlite0-dev libusb-dev libvorbis-dev libxml2 libxml2-dev mpg123 php5 php5-cli php5-curl php5-gd php5-mcrypt php5-mysql php-db php-pear python-mysqldb python-psycopg2 python-setuptools python-sqlalchemy sox sqlite sysvinit-utils wget zlib1g-dev libsqlite3-dev sqlite3 uuid-dev fail2ban ntp ntpdate

  #Set MySQL to start automatically
  update-rc.d mysql remove
  update-rc.d mysql defaults

  #Sync the clock
  /usr/sbin/ntpdate -su pool.ntp.org
  hwclock --systohc

  service asterisk start
}

# ---------------------- Freepbx 2.11.0 ------------------------
function funcfreepbx()
{
  #echo check we've got the mysql password
  until mysql -u root -p$MYSQLROOTPASSWD -e ";" ; do 
    echo "Tenkai did not install MySQL for you. Please enter the MySQL root password: "
    read MYSQLROOTPASSWD
    echo "Incorrect."
  done

	# Get FreePBX
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

  mkdir /var/www/html
  chown    asterisk:asterisk /var/run/asterisk
  chown -R asterisk:asterisk /etc/asterisk
  chown -R asterisk:asterisk /var/www/
  chown -R asterisk:asterisk /var/www/html/
  chown -R asterisk:asterisk /var/lib/asterisk
  chown -R asterisk:asterisk /etc/asterisk
  chown -R asterisk:asterisk /var/{lib,log,spool}/asterisk
  chown -R asterisk:asterisk /var/lock/apache2

  # configure apache
  ln -s /etc/apache2/mods-available/auth_mysql.load /etc/apache2/mods-enabled/auth_mysql.load
  sed -i 's/\(^upload_max_filesize = \).*/\120M/' /etc/php5/apache2/php.ini
  sed -i 's/post_max_size = .*/post_max_size = 100M/' /etc/php5/apache2/php.ini
  sed -i 's/^\(SAFE_AST_BACKGROUND=\s*\).*$/\11/' /usr/sbin/safe_asterisk
  sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/apache2/apache2.conf
  sed -i 's/www-data/asterisk/g'  /etc/apache2/envvars
  echo 'ServerName localhost' >> /etc/apache2/apache2.conf
  service apache2 restart

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

  #Insert admin / admin user into FreePBX
  mysql -uroot -p$MYSQLROOTPASSWD asterisk -e "INSERT INTO ampusers (username,password_sha1,extension_low,extension_high,deptname,sections) VALUES ('vm', '3559095f228e3d157f2e10971a9283b28d86395c', '', '', '', '');"

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

  /etc/init.d/apache2 reload
  amportal kill
  amportal start

  #Write info
  echo ""
  echo "Login to http://localhost/html/admin/ to complete the installation."
  echo ""
  echo "Tenkai set the following passwords:"
  echo "  MySQL Root Password   = $MYSQLROOTPASSWD"
  echo "  Asterisk ARI Password = $ARIPASSW"
  echo "  AMPortal Password     = $FREEPBXPASSW"
  echo ""

  ExitFinish=1
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
  echo " 1)  Install Asterisk, FreePBX and dependencies"
  echo " 9)  Quit"
  echo ""
  echo -n "(0-1) : "
  read OPTION < /dev/tty
}








ExitFinish=0

while [ $ExitFinish -eq 0 ]; do

    show_menu

    case $OPTION in
        1) 
            funcrandpass
            MYSQLROOTPASSWD=$RANDOMPASSW
            funcdependencies
            funcfreepbx
        ;;
        9)
        ExitFinish=1
        ;;
        *)
    esac

done