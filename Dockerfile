FROM alpine:3.7

RUN apk add --no-cache bash ca-certificates openssl

# Install PHP

RUN apk add --no-cache \
  php5 \
  php5-common \
  php5-curl \
  php5-dom \
  php5-exif \
  php5-ftp \
  php5-gd \
  php5-iconv \
#  php5-mbstring \
  php5-mysqli \
#  php5-mysqlnd \
  php5-openssl \
  php5-pdo \
#  php5-session \
  php5-posix \
  php5-soap \
  php5-zip \
  php5-ldap \
  php5-bcmath \
  php5-calendar \
  php5-gettext \
  php5-json \
  php5-pcntl \
  php5-apcu \
  php5-mcrypt \
  php5-phar \
  php5-sockets \
#  php5-tidy \
  php5-wddx \
  php5-xmlreader \
  php5-zip \
  php5-zlib \
  php5-xmlrpc \
  php5-xsl \
  php5-opcache \
#  php5-imagick \
  php5-ctype \ 
  php5-pdo_mysql \ 
  php5-pdo_sqlite \ 
  php5-sqlite3 \ 
#  php5-redis \ 
  php5-fpm \
  supervisor 

RUN apk add --no-cache nginx

ADD conf/nginx.conf /etc/nginx/nginx.conf

RUN mkdir -p /etc/nginx/sites-enabled/; \ 
  mkdir -p /src; \
  ln -s /etc/php5 /etc/php; \
  ln -s /usr/bin/php5 /usr/bin/php

ADD conf/nginx-site.conf /etc/nginx/sites-enabled/site.conf

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

CMD ["/start.sh"]