# About

Zabbix template for monitoring [PHP-FPM](http://php.net/manual/en/install.fpm.php).

## Requirements

- `jq`
- `curl`

## Installation

Copy `php-fpm.sh` to the scripts directory.

```
cp php-fpm.sh /etc/zabbix/scripts
chmod 750 /etc/zabbix/scripts/php-fpm.sh
chown zabbix:zabbix /etc/zabbix/scripts/php-fpm.sh
```

Include `php-fpm.conf` to the Zabbix agent configuration file.

```
cp php-fpm.conf /etc/zabbix/zabbix-agentd.d/
```

Enable PHP-FPM status page.

```
[www]
user = nobody
group = nobody
listen = 127.0.0.1:9000
pm = dynamic
pm.status_path = /php-fpm-status
[...]
```

Set up NGINX as a reverse proxy to allow Zabbix grab PHP-FPM status page.

```
server {
    listen 80 default_server;

    server_name _;

    access_log off;
    error_log off;

    location / {}

    location /php-fpm-status {
        allow 127.0.0.1/32;
        deny all;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```


Done. Now you can import `zbx_php-fpm.xml` file to the Zabbix.

## Usage

Import `zbx_php-fpm.xml` to the Zabbix.

## License

[MIT](LICENSE)

