FROM alpine:3.7

ENV PHP_VERSION 7.2

RUN apk add --no-cache bash ca-certificates openssl

# Install PHP

# Add PHP public keys 
ADD https://php.codecasts.rocks/php-alpine.rsa.pub /etc/apk/keys/php-alpine.rsa.pub

RUN apk --no-cache add ca-certificates && \
  echo "@php https://php.codecasts.rocks/v3.7/php-$PHP_VERSION" >> /etc/apk/repositories

RUN apk add --no-cache \
  php7@php \
  php7-common@php \
  php7-curl@php \
  php7-dom@php \
  php7-exif@php \
  php7-ftp@php \
  php7-gd@php \
  php7-iconv@php \
  php7-mbstring@php \
  php7-mysqli@php \
  php7-mysqlnd@php \
  php7-openssl@php \
  php7-pdo@php \
  php7-session@php \
  php7-posix@php \
  php7-soap@php \
  php7-zip@php \
  php7-ldap@php \
  php7-bcmath@php \
  php7-calendar@php \
  php7-gettext@php \
  php7-json@php \
  php7-pcntl@php \
  php7-apcu@php \
  php7-phar@php \
  php7-sockets@php \
  php7-tidy@php \
  php7-wddx@php \
  php7-xmlreader@php \
  php7-zip@php \
  php7-zlib@php \
  php7-xsl@php \
  php7-opcache@php \
  php7-imagick@php \
  php7-ctype@php \ 
  php7-pdo_mysql@php \ 
  php7-pdo_sqlite@php \ 
  php7-sqlite3@php \ 
  php7-redis@php \ 
  php7-fpm@php \
  supervisor 

# These only exist in 7.1, not 7.2
#RUN apk add --no-cache php7-mcrypt@php \
#  php7-xmlrpc@php

RUN apk add --no-cache nginx

ADD conf/nginx.conf /etc/nginx/nginx.conf

RUN mkdir -p /etc/nginx/sites-enabled/; \ 
  mkdir -p /src; \
  ln -s /etc/php7 /etc/php; \
  ln -s /usr/bin/php7 /usr/bin/php

ADD conf/nginx-site.conf /etc/nginx/sites-enabled/site.conf

# Nginx temp upload dir
RUN mkdir -p /var/nginx-uploads && chown nobody:nobody /var/nginx-uploads

## PHP
ADD conf/php-fpm.conf /etc/php7/php-fpm.conf
ADD conf/php.ini /etc/php7/php.ini
ADD conf/php-www.conf /etc/php7/php-fpm.d/www.conf

# Supervisor
ADD conf/supervisord.conf /etc/supervisord.conf

# Scripts
ADD scripts/start.sh /start.sh
RUN chmod 755 /start.sh

# Test Nginx
RUN nginx -c /etc/nginx/nginx.conf -t

# Test PHP-FPM
RUN /usr/sbin/php-fpm7 --fpm-config /etc/php7/php-fpm.conf -t

CMD ["/start.sh"]