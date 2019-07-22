#!/bin/bash
printf "Copying configuration to writeable folder\n"
cp -R /etc/config/read/* /etc/config/write/

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
if [ ! -z "$ATATUS_APM_LICENSE_KEY" ] && [ "$ATATUS_APM_LICENSE_KEY" != "test" ]; then

    # Enabled
    printf "%-30s %-30s\n" "Atatus:" "Enabled"

    # Set the atatus api key
    sed -i -e "s/atatus.license_key = \"\"/atatus.license_key = \"$ATATUS_APM_LICENSE_KEY\"/g" /etc/config/write/php/conf.d/atatus.ini

    # Set the release stage to be the environment
    sed -i -e "s/atatus.release_stage = \"production\"/atatus.release_stage = \"$ENVIRONMENT\"/g" /etc/config/write/php/conf.d/atatus.ini

    # Set the app name to be site_name environment
    sed -i -e "s/atatus.app_name = \"PHP App\"/atatus.app_name = \"$SITE_NAME\"/g" /etc/config/write/php/conf.d/atatus.ini

    # Set the app version to be the branch build
    sed -i -e "s/atatus.app_version = \"\"/atatus.app_version = \"$SITE_BRANCH-$BUILD\"/g" /etc/config/write/php/conf.d/atatus.ini

    # Set the tags to contain useful data
    sed -i -e "s/atatus.tags = \"\"/atatus.tags = \"$SITE_BRANCH-$BUILD, $SITE_BRANCH\"/g" /etc/config/write/php/conf.d/atatus.ini

fi

# Atatus - if api key is not set then disable
if [ -z "$ATATUS_APM_LICENSE_KEY" ] && [ "$ATATUS_APM_LICENSE_KEY" != "test" ]; then

    # Disabled
    printf "%-30s %-30s\n" "Atatus:" "Disabled"
    rm -f /etc/config/write/php/conf.d/atatus.ini

fi

# Atatus - configure raw sql logs if desirable
if [ ! -z "$ATATUS_APM_RAW_SQL" ]; then

    # Enabled
    printf "%-30s %-30s\n" "Atatus SQL:" "Raw"

    # Set the atatus api key
    sed -i -e "s/atatus.sql.capture = \"normalized\"/atatus.sql.capture = \"raw\"/g" /etc/config/write/php/conf.d/atatus.ini

fi

# Atatus - configure laravel queues if desirable
if [ ! -z "$ATATUS_APM_LARAVEL_QUEUES" ]; then

    # Enabled
    printf "%-30s %-30s\n" "Atatus Laravel Queues:" "Yes"

    # Set the atatus api key
    sed -i -e "s/atatus.laravel.enable_queues = false/atatus.laravel.enable_queues = true/g" /etc/config/write/php/conf.d/atatus.ini

fi

# Whether to send cache headers automatically for PHP scripts
if [ ! -z "$PHP_DISABLE_CACHE_HEADERS" ]; then
    sed -i -e "s#session.cache_limiter = nocache#session.cache_limiter = ''#g" /etc/config/write/php/php.ini
fi

php -r 'echo "";'

# Version numbers:
printf "%-30s %-30s\n" "PHP Version:" "`php -r 'echo phpversion();'`"
printf "%-30s %-30s\n" "Nginx Version:" "`/usr/sbin/nginx -v 2>&1 | sed -e 's/nginx version: nginx\///g'`"

if [ ! -z "$NGINX_PORT" ]; then
    printf "%-30s %-30s\n" "Nginx Port:" "$NGINX_PORT"
    sed -i -e "s#listen 80#listen $NGINX_PORT#g" /etc/config/write/nginx/sites-enabled/site.conf
fi

if [ -z "$NGINX_PORT" ]; then
    printf "%-30s %-30s\n" "Nginx Port:" "80"
fi

if [ ! -z "$NGINX_WEB_ROOT" ]; then

    # Replace web root
    sed -i -e "s#root /src/public#root $NGINX_WEB_ROOT#g" /etc/config/write/nginx/sites-enabled/site.conf

    printf "%-30s %-30s\n" "Nginx Web Root:" "$NGINX_WEB_ROOT"

fi

if [ -z "$NGINX_WEB_ROOT" ]; then
    
    printf "%-30s %-30s\n" "Nginx Web Root:" "/src/public"

fi

# PHP Max Memory
# If set
if [ ! -z "$PHP_MEMORY_MAX" ]; then
    
    # Set PHP.ini accordingly
    sed -i -e "s#memory_limit = 128M#memory_limit = ${PHP_MEMORY_MAX}M#g" /etc/config/write/php/php.ini

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
    sed -i -e "s#opcache.enable=1#opcache.enable=0#g" /etc/config/write/php/php.ini
    sed -i -e "s#opcache.enable_cli=1#opcache.enable_cli=0#g" /etc/config/write/php/php.ini

fi

# PHP Opcache Memory
# If set
if [ ! -z "$PHP_OPCACHE_MEMORY" ]; then
    
    # Set PHP.ini accordingly
    sed -i -e "s#opcache.memory_consumption=16#opcache.memory_consumption=${PHP_OPCACHE_MEMORY}#g" /etc/config/write/php/php.ini

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
        sed -i -e "s#session.save_handler = files#session.save_handler = redis\nsession.save_path = \"tcp://$PHP_SESSION_STORE_REDIS_HOST:$PHP_SESSION_STORE_REDIS_PORT\"#g" /etc/config/write/php/php.ini
    fi

fi

# Max Execution Time
# If set
if [ ! -z "$MAX_EXECUTION_TIME" ]; then
    
    # Set PHP.ini accordingly
    sed -i -e "s#max_execution_time = 600#max_execution_time = ${MAX_EXECUTION_TIME}#g" /etc/config/write/php/php.ini

    # Modify the nginx read timeout
    sed -i -e "s#fastcgi_read_timeout 600s;#fastcgi_read_timeout ${MAX_EXECUTION_TIME}s;#g" /etc/config/write/nginx/sites-enabled/site.conf
fi

# Print the value
printf "%-30s %-30s\n" "Nginx Max Read:" "`cat /etc/config/write/nginx/sites-enabled/site.conf | grep 'fastcgi_read_timeout' | sed -e 's/fastcgi_read_timeout//g'`"

# Print the value
printf "%-30s %-30s\n" "PHP Max Execution Time:" "`cat /etc/config/write/php/php.ini | grep 'max_execution_time = ' | sed -e 's/max_execution_time = //g'`"

# PHP-FPM Max Workers
# If set
if [ ! -z "$PHP_FPM_WORKERS" ]; then
        
    # Set PHP.ini accordingly
    sed -i -e "s#pm.max_children = 4#pm.max_children = $PHP_FPM_WORKERS#g" /etc/config/write/php/www.conf

fi

# Enable short tags for older sites
if [ ! -z "$PHP_ENABLE_SHORT_TAGS" ]; then
    sed -i -e 's/short_open_tag = Off/short_open_tag = On/g' /etc/config/write/php/php.ini
fi

# Nginx custom snippets
if [ -f /etc/nginx/custom.conf ]; then
    printf "%-30s %-30s\n" "Custom Nginx Snippet:" "Enabled"
    /usr/bin/php /usr/local/bin/nginx-custom
fi

if [ ! -f /etc/nginx/custom.conf ]; then
    printf "%-30s %-30s\n" "Custom Nginx Snippet:" "Not Found"
fi

# Set SMTP settings
if [ "$ENVIRONMENT" == 'production' ]; then
    
    if [ -z "$MAIL_HOST" ]; then
        export MAIL_HOST=master-smtp.smtp-production
    fi

    if [ -z "$MAIL_PORT" ]; then
        export MAIL_PORT=25
    fi

fi

if [ "$ENVIRONMENT" == 'qa' ]; then
    
    if [ -z "$MAIL_HOST" ]; then
        export MAIL_HOST=master-smtp.mailhog-production
    fi
fi

if [ -z "$MAIL_DRIVER" ]; then
    export MAIL_DRIVER=mail
fi

if [ -z "$MAIL_PORT" ]; then
    export MAIL_PORT=25
fi

printf "%-30s %-30s\n" "SMTP:" "$MAIL_HOST:$MAIL_PORT"
sed -i -e "s#sendmail_path = /usr/sbin/sendmail -t -i#sendmail_path = /usr/sbin/sendmail -t -i -S $MAIL_HOST:$MAIL_PORT#g" /etc/config/write/php/php.ini


# Startup scripts
if [ -f /startup-all.sh ]; then
    printf "%-30s %-30s\n" "Startup Script:" "Running"
    chmod +x /startup-all.sh && ./startup-all.sh
fi

if [ -f /startup-web.sh ]; then
    printf "%-30s %-30s\n" "Web Startup Script:" "Running"
    chmod +x /startup-web.sh && ./startup-web.sh
fi

# Print the value
printf "%-30s %-30s\n" "PHP-FPM Max Workers:" "`cat /etc/config/write/php/www.conf | grep 'pm.max_children = ' | sed -e 's/pm.max_children = //g'`"
# End PHP-FPM