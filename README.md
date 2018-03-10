![Parallax](https://parallax.exposecms.com/parallax/img/logo.png "Parallax")

# prlx-nginx-php-fpm

> A relatively clean but full-featured, usable nginx and php-fpm docker image supporting PHP versions 5.6, 7.1, 7.2

## Docker Tags 

| PHP           | Nginx         | Docker tag                    |
| ------------- | ------------- | -------------                 |
| 5.6           | 1.13.9        | prlx/prlx-nginx-php-fpm:5.6   |
| 7.1           | 1.13.9        | prlx/prlx-nginx-php-fpm:7.1   |
| 7.2           | 1.13.9        | prlx/prlx-nginx-php-fpm:7.2   |

[Browse all tags on Docker Hub](https://hub.docker.com/r/prlx/prlx-nginx-php-fpm/tags/)

# Environment Variables

These containers work with certain environment variables to control their operation. Environment variables marked as required may be omitted and things may seem to work OK but we do not test against omitting these so you may see some pretty interesting behaviour as a result.

Web/Worker just means whether these have any effect - nothing bad will happen if they are set on both.

For help running these locally with docker run see the [docker run reference](https://docs.docker.com/engine/reference/run/#env-environment-variables)

| Key                  | Description                                                                                                     | Required | Web | Worker |
| ---                  | ---                                                                                                             | ---      | --- | ---    |
| SITE_NAME            | The name of your project, i.e. 'mywebsite'. Used by NR for app name.                                            | ✓        | ✓   | ✓      |
| SITE_BRANCH          | The running branch of your project, i.e. 'master'. Used by NR for app name.                                     | ✓        | ✓   | ✓      |
| ENVIRONMENT          | The environment you're running in, i.e. 'qa' or 'production'. Used by NR for app name.                          | ✓        | ✓   | ✓      |
| NEWRELIC_LICENSE_KEY | Your New Relic license key. New Relic won't be used if this is not set.                                         | ✖        | ✓   | ✓      |
| DISABLE_MONITORING   | Set to any value (1, true, etc) to disable all monitoring functionality (see ports/services)                    | ✖        | ✓   | ✖      |
| NGINX_WEB_ROOT       | Defaults to /src/public, use absolute paths if you wish to change this behaviour. Doesn't support '#' in paths! | ✖        | ✓   | ✖      |
| PHP_MEMORY_MAX       | Maximum PHP request memory, in megabytes (i.e. '256'). Defaults to 128.                                         | ✖        | ✓   | ✓      |
| DISABLE_OPCACHE      | Set to any value (1, true, etc) to disable PHP Opcache                                                          | ✖        | ✓   | ✓      |

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
| [Nginx Status](https://github.com/vozlt/nginx-module-vts)                                | nginx-module-vts stats                                  | 127.0.0.1:9001      |
| [Nginx Exporter](https://github.com/hnlq715/nginx-vts-exporter)                          | Exports nginx-module-vts stats as Prometheus metrics    | 0.0.0.0:9913        |
| [PHP-FPM Status](https://brandonwamboldt.ca/understanding-the-php-fpm-status-page-1603/) | PHP-FPM Statistics                                      | 127.0.0.1:9000      |
| [PHP-FPM Exporter](https://github.com/bakins/php-fpm-exporter)                           | Exports php-fpm stats as Prometheus metrics             | 0.0.0.0:8080        |
| [New Relic](https://newrelic.com/)                                                       | New Relic APM, has a free version (but without alerting)| /tmp/.newrelic.sock |

You don't have to run all of these services - if you're not using Kubernetes, the status and Prometheus exporters are likely to be of little use to you, in which case we would suggest setting DISABLE_MONITORING to 'true' to only have an Nginx listening on 0.0.0.0:80 and a PHP-FPM socket at /run/php.sock.

# The worker mode/command

The worker mode is used when you want to run a worker-type task in this container. Usually this means something like php artisan queue:work.

To run in this mode, change the Docker CMD to be /start-worker.sh instead of the default /start-web.sh.

You will need to ship your own worker supervisord jobs by adding these to /etc/supervisord-enabled/ in your Dockerfile for your worker. Any .conf files in that directory will be picked up by supervisord.

An example of one of these files is provided below - feel free to amend as appropriate:

```
[program:php artisan queue:work]
command=/usr/bin/php artisan queue:work 
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