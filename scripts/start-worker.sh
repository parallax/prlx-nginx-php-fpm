#!/bin/bash

printf "\033[1;1m ____   __    ____    __    __    __      __    _  _ 
(  _ \ /__\  (  _ \  /__\  (  )  (  )    /__\  ( \/ )
 )___//(__)\  )   / /(__)\  )(__  )(__  /(__)\  )  ( 
(__) (__)(__)(_)\_)(__)(__)(____)(____)(__)(__)(_/\_)\033[0m\n"

printf "\n\033[1;1mRunning Nginx PHP-FPM worker mode\033[0m\n\n"

# printf "%-30s %-30s\n" "Key" "Value"

# Container info:
printf "%-30s %-30s\n" "Site:" "$SITE_NAME"
printf "%-30s %-30s\n" "Branch:" "$SITE_BRANCH"
printf "%-30s %-30s\n" "Environment:" "$ENVIRONMENT"

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

# PHP Session Config
# If set
if [ ! -z "$PHP_SESSION_STORE" ]; then
    
    # Figure out which session save handler is in use, currently only supports redis
    if [ $PHP_SESSION_STORE == 'redis' ] || [ $PHP_SESSION_STORE == 'REDIS' ]; then
        if [ -z $PHP_SESSION_STORE_REDIS_HOST ]; then
            PHP_SESSION_STORE_REDIS_HOST='redis'
        fi
        if [ -z $PHP_SESSION_STORE_REDIS_PORT ]; then
            PHP_SESSION_STORE_REDIS_PORT='6379'
        fi
        printf "%-30s %-30s\n" "PHP Sessions:" "Redis"
        printf "%-30s %-30s\n" "PHP Redis Host:" "$PHP_SESSION_STORE_REDIS_HOST"
        printf "%-30s %-30s\n" "PHP Redis Port:" "$PHP_SESSION_STORE_REDIS_PORT"
        sed -i -e "s#session.save_handler = files#session.save_handler = redis\nsession.save_path = \"tcp://$PHP_SESSION_STORE_REDIS_HOST:$PHP_SESSION_STORE_REDIS_PORT\"#g" /etc/php/php.ini
    fi

fi

# Cron
# If DISABLE_CRON is set:
if [ ! -z "$DISABLE_CRON" ]; then

    # Disabled
    printf "%-30s %-30s\n" "Cron:" "Disabled"

fi

# If not set, enable monitoring:
if [ -z "$DISABLE_CRON" ]; then

    # Enabled
    printf "%-30s %-30s\n" "Cron:" "Enabled"

    cp /etc/supervisor.d/cron.conf /etc/supervisord-enabled/

fi

# Enable the worker-specific supervisor files
cp /etc/supervisord-worker/* /etc/supervisord-enabled/

printf "\n\033[1;1mStarting supervisord\033[0m\n\n"

# Start supervisord and services
exec /usr/bin/supervisord -n -c /etc/supervisord.conf