#!/bin/bash

printf "\033[1;1m ____   __    ____    __    __    __      __    _  _ 
(  _ \ /__\  (  _ \  /__\  (  )  (  )    /__\  ( \/ )
 )___//(__)\  )   / /(__)\  )(__  )(__  /(__)\  )  ( 
(__) (__)(__)(_)\_)(__)(__)(____)(____)(__)(__)(_/\_)\033[0m\n"

printf "\n\033[1;1mRunning Nginx PHP-FPM web mode\033[0m\n\n"

# printf "%-30s %-30s\n" "Key" "Value"

# Container info:
printf "%-30s %-30s\n" "Site:" "$SITE_NAME"
printf "%-30s %-30s\n" "Branch:" "$SITE_BRANCH"
printf "%-30s %-30s\n" "Environment:" "$ENVIRONMENT"

# Enable Nginx
cp /etc/supervisor.d/nginx.conf /etc/supervisord-enabled/

# Enable PHP-FPM
cp /etc/supervisor.d/php-fpm.conf /etc/supervisord-enabled/

# Atatus - if api key is set then configure and enable
if [ ! -z "$ATATUS_API_KEY" ]; then

    # Enabled
    printf "%-30s %-30s\n" "Atatus:" "Enabled"

    # Set the atatus api key
    sed -i -e "s/atatus.api_key = \"\"/atatus.api_key = \"$ATATUS_API_KEY\"/g" /etc/php/conf.d/atatus.ini

    # Set the release stage to be the environment
    sed -i -e "s/atatus.release_stage = \"production\"/atatus.release_stage = \"$ENVIRONMENT\"/g" /etc/php/conf.d/atatus.ini

    # Set the app version to be the build
    sed -i -e "s/atatus.app_version = \"\"/atatus.app_version = \"$BUILD\"/g" /etc/php/conf.d/atatus.ini

    # Set the tags to contain useful data
    sed -i -e "s/atatus.tags = \"\"/atatus.tags = \"$SITE_NAME, $ENVIRONMENT, $BUILD, $SITE_BRANCH\"/g" /etc/php/conf.d/atatus.ini

fi

# Atatus - if api key is not set then disable
if [ -z "$ATATUS_API_KEY" ]; then

    # Disabled
    printf "%-30s %-30s\n" "Atatus:" "Disabled"
    rm -f /etc/php/conf.d/atatus.ini

fi

# Version numbers:
printf "%-30s %-30s\n" "PHP Version:" "`php -r 'echo phpversion();'`"
printf "%-30s %-30s\n" "Nginx Version:" "`/usr/sbin/nginx -v 2>&1 | sed -e 's/nginx version: nginx\///g'`"

if [ ! -z "$NGINX_WEB_ROOT" ]; then

    # Replace web root
    sed -i -e "s#root /src/public#root $NGINX_WEB_ROOT#g" /etc/nginx/sites-enabled/site.conf

    printf "%-30s %-30s\n" "Nginx Web Root:" "$NGINX_WEB_ROOT"

fi

if [ -z "$NGINX_WEB_ROOT" ]; then
    
    printf "%-30s %-30s\n" "Nginx Web Root:" "/src/public"

fi

# PHP Max Memory
# If set
if [ ! -z "$PHP_MEMORY_MAX" ]; then
    
    # Set PHP.ini accordingly
    sed -i -e "s#memory_limit = 128M#memory_limit = ${PHP_MEMORY_MAX}M#g" /etc/php/php.ini

fi

# Print the real value
printf "%-30s %-30s\n" "PHP Memory Max:" "`php -r 'echo ini_get("memory_limit");'`"

# PHP Opcache
# If not set
if [ -z "$DISABLE_OPCACHE" ]; then
    
    printf "%-30s %-30s\n" "PHP Opcache:" "Enabled"

fi
# If set
if [ ! -z "$DISABLE_OPCACHE" ]; then
    
    printf "%-30s %-30s\n" "PHP Opcache:" "Disabled"
    
    # Set PHP.ini accordingly
    sed -i -e "s#opcache.enable=1#opcache.enable=0#g" /etc/php/php.ini
    sed -i -e "s#opcache.enable_cli=1#opcache.enable_cli=0#g" /etc/php/php.ini

fi

# PHP Opcache Memory
# If set
if [ ! -z "$PHP_OPCACHE_MEMORY" ]; then
    
    # Set PHP.ini accordingly
    sed -i -e "s#opcache.memory_consumption=16#opcache.memory_consumption=${PHP_OPCACHE_MEMORY}#g" /etc/php/php.ini

fi

# Print the real value
printf "%-30s %-30s\n" "Opcache Memory Max:" "`php -r 'echo ini_get("opcache.memory_consumption");'`M"

# Max Execution Time
# If set
if [ ! -z "$MAX_EXECUTION_TIME" ]; then
    
    # Set PHP.ini accordingly
    sed -i -e "s#max_execution_time = 600#max_execution_time = ${MAX_EXECUTION_TIME}#g" /etc/php/php.ini

    # Modify the nginx read timeout
    sed -i -e "s#fastcgi_read_timeout 600s;#fastcgi_read_timeout ${MAX_EXECUTION_TIME}s;#g" /etc/nginx/sites-enabled/site.conf
fi

# Print the value
printf "%-30s %-30s\n" "Nginx Max Read:" "`cat /etc/nginx/sites-enabled/site.conf | grep 'fastcgi_read_timeout' | sed -e 's/fastcgi_read_timeout//g'`"

# Print the value
printf "%-30s %-30s\n" "PHP Max Execution Time:" "`cat /etc/php/php.ini | grep 'max_execution_time = ' | sed -e 's/max_execution_time = //g'`"

# PHP-FPM Max Workers
# If set
if [ ! -z "$PHP_FPM_WORKERS" ]; then
        
    # Set PHP.ini accordingly
    sed -i -e "s#pm.max_children = 2#pm.max_children = $PHP_FPM_WORKERS#g" /etc/php/php-fpm.d/www.conf

fi

# Print the value
printf "%-30s %-30s\n" "PHP-FPM Max Workers:" "`cat /etc/php/php-fpm.d/www.conf | grep 'pm.max_children = ' | sed -e 's/pm.max_children = //g'`"
# End PHP-FPM

printf "\n\033[1;1mStarting supervisord\033[0m\n\n"

# Start supervisord and services
exec /usr/bin/supervisord -n -c /etc/supervisord.conf