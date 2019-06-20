# prlx-nginx-php-fpm

> A relatively clean but full-featured, usable nginx and php-fpm docker image supporting PHP versions 5.6, 7.1, 7.2 maintained by [Parallax](https://parall.ax/)

## Docker Tags 

| PHP           | Nginx         | Docker tag                           |
| ------------- | ------------- | -------------                        |
| 5.6           | 1.17.0        | prlx/prlx-nginx-php-fpm:5.6-master   |
| 7.1           | 1.17.0        | prlx/prlx-nginx-php-fpm:7.1-master   |
| 7.2           | 1.17.0        | prlx/prlx-nginx-php-fpm:7.2-master   |
| 7.3           | 1.17.0        | prlx/prlx-nginx-php-fpm:7.3-master   |

[Browse all tags on Docker Hub](https://hub.docker.com/r/prlx/prlx-nginx-php-fpm/tags/)

# Environment Variables

These containers work with certain environment variables to control their operation. Environment variables marked as required may be omitted and things may seem to work OK but we do not test against omitting these so you may see some pretty interesting behaviour as a result.

Web/Worker just means whether these have any effect - nothing bad will happen if they are set on both.

For help running these locally with docker run see the [docker run reference](https://docs.docker.com/engine/reference/run/#env-environment-variables)

| Key                             | Description                                                                                                     | Required | Web | Worker |
| ---                             | ---                                                                                                             | ---      | --- | ---    |
| SITE_NAME                       | The name of your project, i.e. 'mywebsite'. Used by NR for app name.                                            | ✓        | ✓   | ✓      |
| SITE_BRANCH                     | The running branch of your project, i.e. 'master'. Used by NR for app name.                                     | ✓        | ✓   | ✓      |
| ENVIRONMENT                     | The environment you're running in, i.e. 'qa' or 'production'. Used by NR for app name.                          | ✓        | ✓   | ✓      |
| ATATUS_API_KEY                  | Your Atatus Project API key. Atatus won't be used if this is not set.                                           | ✖        | ✓   | ✓      |
| NGINX_PORT                      | Defaults to 80                                                                                                  | ✖        | ✓   | ✖      |
| NGINX_WEB_ROOT                  | Defaults to /src/public, use absolute paths if you wish to change this behaviour. Doesn't support '#' in paths! | ✖        | ✓   | ✖      |
| PHP_MEMORY_MAX                  | Maximum PHP request memory, in megabytes (i.e. '256'). Defaults to 128.                                         | ✖        | ✓   | ✓      |
| MAX_EXECUTION_TIME              | Maximum PHP and Nginx execution/fastcgi read timeout	                                                        | ✖        | ✓   | ✓      |
| PHP_FPM_WORKERS                 | Maximum PHP-FPM workers. Defaults to 4 if not set.                                                              | ✖        | ✓   | ✖      |
| DISABLE_OPCACHE                 | Set to any value (1, true, etc) to disable PHP Opcache                                                          | ✖        | ✓   | ✓      |
| PHP_OPCACHE_MEMORY              | Maximum PHP request memory, in megabytes (i.e. '64'). Defaults to 16.                                           | ✖        | ✓   | ✓      |
| DISABLE_CRON                    | Set to any value (1, true, etc) to disable Cron. Only runs on the worker!                                       | ✖        | ✖   | ✓      |
| PHP_SESSION_STORE               | If not set, PHP uses /tmp for sessions. If set to 'redis', uses redis for sessions                              | ✖        | ✓   | ✓      |
| PHP_SESSION_STORE_REDIS_HOST    | If not set, defaults to 'redis'. Only used if PHP_SESSION_STORE is set to redis                                 | ✖        | ✓   | ✓      |
| PHP_SESSION_STORE_REDIS_PORT    | If not set, defaults to 6379. Only used if PHP_SESSION_STORE is set to redis                                    | ✖        | ✓   | ✓      |
| PHP_DISABLE_CACHE_HEADERS       | Set to any value (1, true, etc) to disable PHP's default pragma: no-cache headers                               | ✖        | ✓   | ✖      |
| PHP_ENABLE_SHORT_TAGS           | Set to any value (1, true, etc) to enable PHP short tagging                                                     | ✖        | ✓   | ✓      |

# The web mode/command

The web mode is what you use to run a web server - unless you're using workers this is the only one you'll be using. It runs all the things you need to be able to run a PHP-FPM container in Kubernetes.

It is also the default behaviour for the docker containers meaning you don't need to specify a command or working directory to run.

## Ports and Services

Not everything is as straightforward as the idealistic world of Docker would have you believe. The "one process per container" doesn't really work for us in the real world so we've gone with "one logical service per container" instead.

We use [Supervisord](http://supervisord.org/) to bootstrap the following services in our Nginx PHP-FPM web mode container:

| Service                                                                                  | Description                                             | Port/Socket         |
| -------------                                                                            | -------------                                           | -------------       |
| [Nginx](https://www.nginx.com/)                                                          | Web server                                              | 0.0.0.0:80          |
| [PHP-FPM](https://php-fpm.org/)                                                          | PHP running as a pool of workers                        | /run/php.sock       |

## Example Container

There is an example container in [examples/hello-world](examples/hello-world). To run it:

```bash
cd examples/hello-world
docker build -t example .
docker run -p 8080:80 example
```

You should be able to visit the container on http://127.0.0.1:8080/ and see the contents of index.php from /examples/hello-world/src.

# Custom Startup Scripts

You can add behaviour to the built-in startup scripts for web, worker or both modes by adding a file to:

| File Path          | Runs on |
| ---                | ---     |
| /startup-all.sh    | All     |
| /startup-web.sh    | Web     |
| /startup-worker.sh | Worker  |

# The worker mode/command

The worker mode is used when you want to run a worker-type task in this container. Usually this means something like php artisan queue:work.

To run in this mode, change the Docker CMD to be /start-worker.sh instead of the default /start-web.sh.

You will need to ship your own worker supervisord jobs by adding these to /etc/supervisord-worker/ in your Dockerfile for your worker. Any .conf files in that directory will be picked up by supervisord to run when in worker mode.

An example of one of these files is provided below - feel free to amend as appropriate:

```
[program:laravel-queue]
command=/usr/bin/php artisan queue:listen 
directory=/src
autostart=true
autorestart=true
priority=15
stdout_events_enabled=true
stderr_events_enabled=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
```

## Cron Jobs on Worker

The worker has support for cron (can be disabled using DISABLE_CRON). To add a crontab, call it the name of the user you want it to run as (probably 'nobody') and ADD it to /etc/cron.d.

Example:

```
* * * * * date
```

# PHP Modules
| Module        | 5.6 | 7.1 | 7.2 |  7.3 |Notes                                                                                   |
| ---           | --- | --- | --- |  --- |---                                                                                     |
| apc           | ✓   | ✖   | ✖   | ✖   | Deprecated in PHP 7 and up                                                              |
| apcu          | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| bcmath        | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| calendar      | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| Core          | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| ctype         | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| curl          | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| date          | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| dom           | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| ereg          | ✓   | ✖   | ✖   | ✖   | Deprecated in PHP 7 and up                                                              |
| exif          | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| fileinfo      | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| filter        | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| ftp           | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| gd            | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| gettext       | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| hash          | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| iconv         | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| imagick       | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| intl          | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| json          | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| ldap          | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| libxml        | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| mbstring      | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| mcrypt        | ✓   | ✓   | ✖   | ✖   | Deprecated in PHP 7.2 and up                                                            |
| memcached     | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| mysqli        | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| mysql         | ✓   | ✖   | ✖   | ✖   | Deprecated in PHP 7 and up                                                              |
| mysqlnd       | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| openssl       | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| pcntl         | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| pcre          | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| PDO           | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| pdo_mysql     | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| pdo_sqlite    | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| Phar          | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| posix         | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| readline      | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| redis         | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| Reflection    | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| session       | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| SimpleXML     | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| soap          | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| sockets       | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| SPL           | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| sqlite3       | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| standard      | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| tidy          | ✖   | ✓   | ✓   | ✓    |Weirdly missing from upstream Alpine Linux repository                                   |
| tokenizer     | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| wddx          | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| xml           | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| xmlreader     | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| xmlrpc        | ✓   | ✓   | ✖   | ✖   |[Missing from upstream PHP 7.2](https://github.com/codecasts/php-alpine/issues/23)      |
| xmlwriter     | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| xsl           | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| Zend OPcache  | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| zip           | ✓   | ✓   | ✓   |  ✓   |                                                                                        |
| zlib          | ✓   | ✓   | ✓   |  ✓   |                                                                                        |