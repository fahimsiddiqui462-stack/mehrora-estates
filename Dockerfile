FROM php:8.2-apache

RUN docker-php-ext-install pdo_mysql \
 && apt-get update \
 && apt-get install -y --no-install-recommends default-mysql-client \
 && rm -rf /var/lib/apt/lists/* \
 && rm -f /etc/apache2/mods-enabled/mpm_event.* /etc/apache2/mods-enabled/mpm_worker.* \
 && a2enmod mpm_prefork rewrite headers expires >/dev/null \
 && apache2ctl -t

WORKDIR /var/www/html
COPY . /var/www/html

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh && chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 80
CMD ["/usr/local/bin/entrypoint.sh"]
