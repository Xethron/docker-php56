#!/bin/sh
mkdir -p /data/log/supervisor
mkdir -p /data/log/apache2
mkdir -p /data/log/mysql
mkdir -p /var/run/sshd
mkdir -p /data/conf
mkdir -p /data/db

cat << EOF >> /etc/profile
alias www='cd /var/www/'
EOF

## SETUP APACHE CONFIG ##
if [ -f /var/www/000-default.conf ]; then
    a2dissite 000-default
    ln -sf /var/www/000-default.conf /etc/apache2/sites-enabled/
fi
for file in `find "/var/www/" -maxdepth 2 -name "*.site"`; do
    # ENABLE APACHE SITES #
    ln -sf "$file" "/etc/apache2/sites-enabled/`basename \"$file\" .site`.conf"
    # SETUP HOSTS FILE FOR ALL SERVER NAMES #
    echo '127.0.0.1' $(cat "$file" | grep 'ServerName\|ServerAlias' | awk '{print $2}') >> /etc/hosts
done;

## HOME DIR SETUP ##
if [ ! -d /data/root ]; then
    mv /root /data/
fi
rm -rf /root/; ln -s /data/root/ /root

## MYSQL SETUP ##
if [ ! -f /data/conf/my.cnf ]; then
    mv /etc/mysql/my.cnf /data/conf/my.cnf
    ln -sf /data/conf/my.cnf /etc/mysql/my.cnf
    chmod o-r /etc/mysql/my.cnf
fi

if [ ! -f /data/db/ibdata1 ]; then
    mv /var/lib/mysql/* /data/db/

    /usr/bin/mysqld_safe &
    sleep 10s

    echo "GRANT ALL ON *.* TO root@'%' IDENTIFIED BY 'password' WITH GRANT OPTION; FLUSH PRIVILEGES" | mysql

    killall mysqld
    sleep 10s
fi
## END MYSQL SETUP ##

## RUN SUPERVISORD ##
/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
