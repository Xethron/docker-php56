FROM debian:latest
MAINTAINER Bernhard Breytenbach <bernhard@coffeecode.co.za>

RUN apt-get update; \
    apt-get install apt-utils; \
    apt-get upgrade -y; \
    apt-get install -y locales; \
    apt-get autoremove -qy; \
    apt-get autoclean -qy

RUN locale-gen en_GB en_GB.UTF-8 && dpkg-reconfigure locales && update-locale en_GB.UTF-8

# set root password
RUN echo "root:toor" | chpasswd

RUN ln -sf /usr/share/zoneinfo/Africa/Johannesburg /etc/localtime

ENV APACHE_RUN_USER     www-data
ENV APACHE_RUN_GROUP    www-data
ENV APACHE_PID_FILE     /var/run/apache2.pid
ENV APACHE_RUN_DIR      /var/run/apache2
ENV APACHE_LOCK_DIR     /var/lock/apache2
ENV APACHE_LOG_DIR      /data/log/apache2

RUN dpkg-divert --local --rename --add /sbin/initctl
RUN rm /sbin/initctl; ln -s /bin/true /sbin/initctl

# Install Important Tools
RUN apt-get install -qy vim git wget curl supervisor; \
    apt-get autoremove -qy; \
    apt-get autoclean -qy

# Install Apache
RUN apt-get install -qy apache2; \
    apt-get autoremove -qy; \
    apt-get autoclean -qy

# Install MySQL
RUN DEBIAN_FRONTEND=noninteractive apt-get install -qy mysql-client mysql-server libmysqlclient-dev; \
    apt-get autoremove -qy; \
    apt-get autoclean -qy

# Install PHP
RUN apt-get install -qy libapache2-mod-php5 php5 php5-cli php-pear php-apc php5-gd php5-curl php5-mysql php5-sqlite phpunit php5-memcached php5-geoip php5-mcrypt php-pear php5-dev php5-xsl php5-imap php5-intl php5-xdebug php5-imagick ghostscript; \
    apt-get autoremove -qy; \
    apt-get autoclean -qy

# Install phpMyAdmin
RUN echo 'phpmyadmin phpmyadmin/dbconfig-install boolean true' | debconf-set-selections
RUN echo 'phpmyadmin phpmyadmin/app-password-confirm password ' | debconf-set-selections
RUN echo 'phpmyadmin phpmyadmin/mysql/admin-pass password ' | debconf-set-selections
RUN echo 'phpmyadmin phpmyadmin/mysql/app-pass password ' | debconf-set-selections
RUN echo 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2' | debconf-set-selections

RUN mysqld & \
    service apache2 start; \
    sleep 10; \
    apt-get install -y phpmyadmin; \
    sleep 15; \
    mysqladmin -u root shutdown; \
    apt-get autoremove -qy; \
    apt-get autoclean -qy

# Install Node.js
RUN curl --silent --location https://deb.nodesource.com/setup_5.x | bash -
RUN apt-get install -y nodejs; \
    apt-get autoremove -qy; \
    apt-get autoclean -qy

# Install WkHtmlToPdf
ADD wkhtmltox-0.12.2.1_linux-jessie-amd64.deb /root/wkhtmltox-0.12.2.1_linux-jessie-amd64.deb
RUN apt-get install -qy xfonts-75dpi wkhtmltopdf; \
    dpkg -i /root/wkhtmltox-0.12.2.1_linux-jessie-amd64.deb; \
    apt-get -f install; \
    apt-get autoremove -qy; \
    apt-get autoclean -qy

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php && mv -f composer.phar /usr/local/bin/composer
RUN composer global require hirak/prestissimo
RUN composer global require psy/psysh:@stable

# Setup Apache
RUN sed -i -e"s/DocumentRoot \/var\/www\/html/DocumentRoot \/var\/www/" \
    /etc/apache2/sites-available/000-default.conf \
    /etc/apache2/sites-available/default-ssl.conf
RUN a2enmod rewrite
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Setup PHP
ADD config/php.ini /etc/php5/apache2/php.ini
ADD config/xdebug.ini /etc/php5/mods-available/xdebug.ini
RUN php5dismod xdebug

# Setup PHP CLI
ADD config/php-cli.ini /etc/php5/cli/php.ini

# Setup MySQL
ADD config/my.cnf /etc/mysql/my.cnf

# Setup PHPMyAdmin
ADD config/config.inc.php /etc/phpmyadmin/config.inc.php

# Setup PHP Browsecap
ADD config/browscap.ini /etc/php5/browscap.ini
RUN sed -i "s/;browscap = extra\/browscap.ini/browscap = \/etc\/php5\/browscap.ini/" /etc/php5/cli/php.ini

# Setup Deployer
RUN wget http://deployer.org/deployer.phar && mv -f deployer.phar /usr/local/bin/dep && chmod +x /usr/local/bin/dep

RUN sed -i -e "s/33\:33/1000:1000/" /etc/passwd
RUN sed -i -e "s/\:33\:/:1000:/" /etc/group

VOLUME /conf
VOLUME /data
VOLUME /var/www

RUN echo "www-data:root" | chpasswd www-data
RUN chown -R www-data: /var/www
RUN chmod -R ug+rwX /var/www

ADD config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 80 443 3306 9000

ADD start.sh /start.sh
RUN chmod u+x /start.sh

CMD ["/start.sh"]
