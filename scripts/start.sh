#!/bin/bash

# Set the newrelic app name programatically with the info we already have in the container
sed -i -e "s/newrelic.appname = \"PHP Application\"/newrelic.appname = \"${SITE_NAME}-${SITE_BRANCH}-${ENVIRONMENT}\"/g" /etc/php7/conf.d/newrelic.ini

# Start supervisord and services
exec /usr/bin/supervisord -n -c /etc/supervisord.conf