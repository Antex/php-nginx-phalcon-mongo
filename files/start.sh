#!/bin/bash

echo "start nginx...\n"
#/usr/sbin/nginx -g 'daemon off;'
/usr/sbin/nginx 

echo "start php...\n"
/usr/sbin/php-fpm7.0 -F