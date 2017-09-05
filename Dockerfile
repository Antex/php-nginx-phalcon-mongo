FROM ubuntu:latest 

MAINTAINER Akkapong Kajornwongwattana<akkapong.kaj@ascendcorp.com>

USER root

# Keep upstart from complaining
RUN dpkg-divert --local --rename --add /sbin/initctl && \
ln -sf /bin/true /sbin/initctl

COPY files/mongo.ini /etc/php/mods-available/mongo.ini

# Install PHP 7.0 and some modules
RUN apt-get update && \
apt-get install -y software-properties-common language-pack-en-base && \
LC_ALL=en_US.UTF-8 add-apt-repository ppa:ondrej/php-7.0 && \
apt-get update && \
apt-get install -y --force-yes libsasl2-dev libcurl4-openssl-dev mcrypt php7.0-dev php7.0-cli php7.0-curl php7.0-fpm php7.0-intl php7.0-json php7.0-mcrypt php7.0-opcache php7.0-sqlite3 php-pear && \
pecl install mongodb creates=/etc/php/7.0/cli/conf.d/20-mongo.ini && \
ln -s /etc/php/mods-available/mongo.ini /etc/php/7.0/cli/conf.d/20-mongo.ini && \
ln -s /etc/php/mods-available/mongo.ini /etc/php/7.0/fpm/conf.d/20-mongo.ini

# 
RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php/7.0/fpm/php.ini

# Copy website Nginx config file
COPY ./files/nginx-php7.conf /etc/nginx/sites-available/nginx-php7.conf

## Install Nginx ##
RUN nginx=stable && \
add-apt-repository ppa:nginx/$nginx && \
apt-get update && \
apt-get install -y nginx && \
rm -Rf /etc/nginx/sites-enabled/default && \
ln -s /etc/nginx/sites-available/nginx-php7.conf /etc/nginx/sites-enabled/default
###################

## Clean up installation files ##
RUN apt-get remove --purge -y software-properties-common && \
apt-get autoremove -y && \
apt-get clean && \
apt-get autoclean && \
echo -n > /var/lib/apt/extended_states && \
rm -rf /var/lib/apt/lists/* && \
rm -rf /usr/share/man/?? && \
rm -rf /usr/share/man/??_*

RUN rm -rf /var/www && \
mkdir -p /var/www/html 
#################################

## Start Install phpunit ##
RUN curl -fsSL https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer \
    && composer global require phpunit/phpunit ^6.2 --no-progress --no-scripts --no-interaction

RUN pecl install xdebug \
    && echo 'zend_extension=/usr/local/lib/php/extensions/no-debug-non-zts-20151012/xdebug.so' > \
        /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && php -m | grep xdebug

ENV PATH /root/.composer/vendor/bin:$PATH
## End Install phpunit ##


EXPOSE 80

ADD ./files/start.sh /start.sh
RUN chmod +x /start.sh && \
mkdir /run/php

CMD /start.sh
