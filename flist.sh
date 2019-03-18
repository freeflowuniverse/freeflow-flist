#!/bin/bash
set -ex

export DEBIAN_FRONTEND=noninteractive

apt-get update
#apt-get install mariadb* -y
#apt-get install apache2 -y
apt-get install lamp-server^ -y
apt-get install php-curl php-gd php-mbstring -y
apt-get install php-intl php-zip wget -y
apt-get install php-ldap php-apcu php-sqlite3 -y
apt-get install cron ssh telnet -y
apt-get install net-tools iputils-ping vim curl tmux rsync git -y
apt-get install restic -y 
wget https://raw.githubusercontent.com/threefoldgrid/freeflow/master/utils/startup.toml -O /.startup.toml

cd /etc/apache2/sites-available
rm 000-default.conf

apache_file='/etc/apache2/sites-available/freeflowpages.com.conf'
/bin/cat <<EOF > $apache_file 
<VirtualHost *:80>
	ServerName www.freeflowpages.com
	ServerAdmin webmaster@localhost
	DocumentRoot /var/www/html/humhub
	ErrorLog ${APACHE_LOG_DIR}/error.log
	CustomLog ${APACHE_LOG_DIR}/access.log combined
	<Directory /var/www/html/humhub>
                Options Indexes FollowSymLinks MultiViews
                AllowOverride All
                Require all granted
        </Directory>
</VirtualHost>
EOF

a2ensite freeflowpages.com.conf
a2enmod rewrite

# below is setup of MySQL master node
CNF_file='/etc/mysql/mysql.conf.d/mysqld.cnf'
/bin/cat <<EOF > $CNF_file
[mysqld_safe]
socket          = /var/run/mysqld/mysqld.sock
nice            = 0
[mysqld]
user            = mysql
pid-file        = /var/run/mysqld/mysqld.pid
socket          = /var/run/mysqld/mysqld.sock
port            = 3306
basedir         = /usr
datadir         = /var/lib/mysql
tmpdir          = /tmp
lc-messages-dir = /usr/share/mysql
skip-external-locking
bind-address    =    0.0.0.0
key_buffer_size         = 16M
max_allowed_packet      = 16M
thread_stack            = 192K
thread_cache_size       = 8
myisam-recover-options  = BACKUP
query_cache_limit       = 1M
query_cache_size        = 16M
log_error = /var/log/mysql/error.log
server-id               = 1
log_bin                 = /var/mysql/binlog/mysql-bin.log
expire_logs_days        = 10
max_binlog_size   = 100M
binlog_do_db            = humhub
EOF
tar -cpzf "/root/archives/humhub.tar.gz" --exclude dev --exclude sys --exclude proc  /

