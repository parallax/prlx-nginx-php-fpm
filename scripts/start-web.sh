#!/bin/bash

printf "\033[1;1m ____   __    ____    __    __    __      __    _  _ 
(  _ \ /__\  (  _ \  /__\  (  )  (  )    /__\  ( \/ )
 )___//(__)\  )   / /(__)\  )(__  )(__  /(__)\  )  ( 
(__) (__)(__)(_)\_)(__)(__)(____)(____)(__)(__)(_/\_)\033[0m\n\n"

printf "\nRunning Nginx PHP-FPM web mode\n"

# Version numbers:
printf "\n\033[1;1mNginx Version:\033[0m `/usr/sbin/nginx -v 2>&1 | sed -e 's/nginx version: nginx\///g'`\n"
printf "\033[1;1mPHP Version:\033[0m `php -r 'echo phpversion();'`\n"

# Enable Nginx
cp /etc/supervisor.d/nginx.conf /etc/supervisord-enabled/

# Enable PHP-FPM
cp /etc/supervisor.d/php-fpm.conf /etc/supervisord-enabled/

# New Relic - if license key is set then configure and enable
if [ ! -z "$NEWRELIC_LICENSE_KEY" ]; then

    # Enabled
    printf "\n\033[1;1mNew Relic:\033[0m \xE2\x9C\x85\n"

    # Set the newrelic app name programatically with the info we already have in the container
    sed -i -e "s/newrelic.appname = \"PHP Application\"/newrelic.appname = \"${SITE_NAME}-${SITE_BRANCH}-${ENVIRONMENT}\"/g" /etc/php/conf.d/newrelic.ini

    # Set the newrelic license key
    sed -i -e "s/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/$NEWRELIC_LICENSE_KEY/g" /etc/php/conf.d/newrelic.ini

    # Enable New Relic
    cp /etc/supervisor.d/newrelic.conf /etc/supervisord-enabled/

fi

if [ -z "$NEWRELIC_LICENSE_KEY" ]; then

    # Disabled
    printf "\n\033[1;1mNew Relic:\033[0m \xE2\x9D\x8C\n"

fi

# If DISABLE_MONITORING is set:
if [ ! -z "$DISABLE_MONITORING" ]; then

    # Disabled
    printf "\n\033[1;1mMonitoring:\033[0m \xE2\x9D\x8C\n"

    rm -f /etc/nginx/sites-enabled/status.conf

fi

# If not set, enable monitoring:
if [ -z "$DISABLE_MONITORING" ]; then

    # Enabled
    printf "\n\033[1;1mMonitoring:\033[0m \xE2\x9C\x85\n"

    cp /etc/supervisor.d/nginx-exporter.conf /etc/supervisord-enabled/
    cp /etc/supervisor.d/php-fpm-exporter.conf /etc/supervisord-enabled/

fi

if [ ! -z "$NGINX_WEB_ROOT" ]; then

    # Replace web root
    sed -i -e "s#root /src/public#root $NGINX_WEB_ROOT#g" /etc/nginx/sites-enabled/site.conf

    printf "\n\033[1;1mNginx Web Root:\033[0m $NGINX_WEB_ROOT\n"

fi

if [ -z "$NGINX_WEB_ROOT" ]; then
    
    printf "\n\033[1;1mNginx Web Root:\033[0m /src/public\n"

fi

printf "\n\n"

# Start supervisord and services
exec /usr/bin/supervisord -n -c /etc/supervisord.conf