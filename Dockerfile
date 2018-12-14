FROM ubuntu:16.04

MAINTAINER Antex <antex.name@gmail.com>

USER root

RUN apt-get update
RUN apt-get install -y software-properties-common python-software-properties language-pack-en-base
RUN LC_ALL=en_US.UTF-8 add-apt-repository ppa:ondrej/php
RUN apt-get update
RUN apt-get install -y php7.1

#Install
#RUN apt-get update && apt-get install -y \
RUN apt-get install -y \
git \
nginx \
php7.1-fpm \
php7.1-cli \
php7.1-gd \
curl \
vim \
wget \
php7.1-mysql \
php7.1-curl \
php7.1-intl \
php-pear \
php7.1-mcrypt \
php-memcache \
php7.1-xml \
php7.1-mbstring


#Packages for phalcon instalation
RUN apt-get install -y gcc make re2c libpcre3-dev php7.1-dev build-essential  php7.1-zip

#Install composer
ENV COMPOSER_ALLOW_SUPERUSER=1
RUN curl -sS http://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

#Install zephir
RUN composer global require "phalcon/zephir:dev-master"
RUN git clone git://github.com/phalcon/php-zephir-parser.git
RUN cd php-zephir-parser && phpize && ./configure && make && make install

#Install phalconphp with php7
RUN git clone https://github.com/phalcon/cphalcon.git -b 3.3.x --single-branch

RUN echo "extension=zephir_parser.so" >> /etc/php/7.1/fpm/conf.d/31-zephir_parser.ini
RUN echo "extension=zephir_parser.so" >> /etc/php/7.1/cli/conf.d/31-zephir_parser.ini

#Building Phalcon
RUN cd cphalcon && ~/.composer/vendor/bin/zephir build --backend=ZendEngine3
RUN echo "extension=phalcon.so" >> /etc/php/7.1/fpm/conf.d/30-phalcon.ini
RUN echo "extension=phalcon.so" >> /etc/php/7.1/cli/conf.d/30-phalcon.ini


#Re-Builging
RUN ./cphalcon/ext/configure
RUN make
RUN make install

#Install phalcon dev tool
RUN composer require "phalcon/devtools" -d /usr/local/bin/
RUN ln -s /usr/local/bin/vendor/phalcon/devtools/phalcon.php /usr/bin/phalcon



# Install Mongodb
RUN apt-get install -y --force-yes mongodb-clients telnet iputils-ping nano mc htop 
RUN apt-get install -y --force-yes php7.1-mbstring mcrypt pkg-config libssl-dev openssl libsslcommon2-dev && \
pecl install mongodb

RUN echo "extension=mongodb.so" >> /etc/php/7.1/fpm/conf.d/30-phalcon.ini
RUN echo "extension=mongodb.so" >> /etc/php/7.1/cli/conf.d/30-phalcon.ini

#phpInfo
#RUN touch /var/www/info.php
#RUN echo "<?php echo phpInfo(); ?>" > /var/www/info.php

#Install phpunit
RUN wget https://phar.phpunit.de/phpunit-6.2.phar -O /usr/local/bin/phpunit && \
    chmod +x /usr/local/bin/phpunit

#RUN composer global require phpunit/phpunit ^6.2 --no-progress --no-scripts --no-interaction

RUN pecl install xdebug \
    && echo "zend_extension=/usr/lib/php/20160303/xdebug.so" > /etc/php/7.1/fpm/conf.d/30-xdebug.ini \
    && echo "zend_extension=/usr/lib/php/20160303/xdebug.so" > /etc/php/7.1/cli/conf.d/30-xdebug.ini


#Networking
EXPOSE 80 443

#Nginx Conf
COPY default /etc/nginx/sites-available/
RUN rm /etc/nginx/sites-enabled/default
RUN ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Clean up installation files
RUN rm -rf /cphalcon


#Start sh
ADD start.sh /start.sh
RUN chmod +x /start.sh

RUN mkdir -p /var/www/
WORKDIR /var/www/

VOLUME /var/www/

#Starting it
ENTRYPOINT ["/start.sh"]
