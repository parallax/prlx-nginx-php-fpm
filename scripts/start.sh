#!/bin/bash

echo ' ____   __    ____    __    __    __      __    _  _ 
(  _ \ /__\  (  _ \  /__\  (  )  (  )    /__\  ( \/ )
 )___//(__)\  )   / /(__)\  )(__  )(__  /(__)\  )  ( 
(__) (__)(__)(_)\_)(__)(__)(____)(____)(__)(__)(_/\_)'

# Version numbers:
/usr/sbin/nginx -v
/usr/bin/php -v
/usr/bin/php -m

# Set the newrelic app name programatically with the info we already have in the container
sed -i -e "s/newrelic.appname = \"PHP Application\"/newrelic.appname = \"${SITE_NAME}-${SITE_BRANCH}-${ENVIRONMENT}\"/g" /etc/php7/conf.d/newrelic.ini

# Start supervisord and services
exec /usr/bin/supervisord -n -c /etc/supervisord.conf