# GLPI 11 on PHP 8.4 + Apache - portable image
FROM php:8.4-apache-bookworm

ARG GLPI_VERSION=11.0.9

# PHP extensions required/recommended by GLPI 11
ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN install-php-extensions bcmath bz2 exif gd intl ldap mysqli opcache zip apcu \
 && apt-get update && apt-get install -y --no-install-recommends mariadb-client \
 && rm -rf /var/lib/apt/lists/*

# GLPI sources
RUN curl -fsSL "https://github.com/glpi-project/glpi/releases/download/${GLPI_VERSION}/glpi-${GLPI_VERSION}.tgz" \
      | tar -xz -C /var/www/ \
 && mv /var/www/glpi/files /usr/src/glpi-files \
 && rm -f /var/www/glpi/install/install.php \
 && chown -R www-data:www-data /var/www/glpi/marketplace

# Keep config, data and logs outside the web root, in one volume
COPY downstream.php /var/www/glpi/inc/downstream.php
COPY php.ini /usr/local/etc/php/conf.d/99-glpi.ini
COPY apache-glpi.conf /etc/apache2/sites-available/000-default.conf
COPY --chmod=0755 entrypoint.sh /usr/local/bin/glpi-entrypoint
RUN a2enmod rewrite proxy proxy_http

ENV GLPI_VERSION=${GLPI_VERSION}
VOLUME ["/var/glpi", "/var/www/glpi/marketplace"]
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=5s --start-period=120s \
  CMD curl -fs -o /dev/null http://localhost/ || exit 1

ENTRYPOINT ["glpi-entrypoint"]
CMD ["apache2-foreground"]
