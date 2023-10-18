#!/bin/sh
echo "[i] Starting PHP+Nginx.."

# start php-fpm
mkdir -p /usr/logs/php-fpm
php-fpm82

# start nginx
mkdir -p /usr/logs/nginx
mkdir -p /tmp/nginx
chown nginx /tmp/nginx
nginx
