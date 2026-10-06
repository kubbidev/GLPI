#!/usr/bin/env bash
set -euo pipefail

: "${GLPI_DB_HOST:=db}" "${GLPI_DB_PORT:=3306}" "${GLPI_DB_NAME:=glpi}" "${GLPI_DB_USER:=glpi}"
: "${GLPI_DB_PASSWORD:?GLPI_DB_PASSWORD must be set}"
: "${GLPI_LANGUAGE:=en_GB}" "${GLPI_AUTO_UPDATE:=true}"
console() { runuser -u www-data -- php /var/www/glpi/bin/console --no-interaction "$@"; }

# Persistent directories (seed the files tree on first run)
mkdir -p /var/glpi/config /var/glpi/files /var/glpi/logs
[ -n "$(ls -A /var/glpi/files)" ] || cp -a /usr/src/glpi-files/. /var/glpi/files/
chown -R www-data:www-data /var/glpi /var/www/glpi/marketplace

echo "Waiting for database ${GLPI_DB_HOST}:${GLPI_DB_PORT}..."
for i in $(seq 1 60); do
  mariadb-admin ping -h"$GLPI_DB_HOST" -P"$GLPI_DB_PORT" -u"$GLPI_DB_USER" -p"$GLPI_DB_PASSWORD" --skip-ssl --silent && break
  [ "$i" = 60 ] && { echo "Database not reachable" >&2; exit 1; }
  sleep 2
done

if [ ! -f /var/glpi/config/config_db.php ]; then
  echo "Installing GLPI ${GLPI_VERSION} database schema..."
  console database:install --db-host="$GLPI_DB_HOST" --db-port="$GLPI_DB_PORT" \
    --db-name="$GLPI_DB_NAME" --db-user="$GLPI_DB_USER" --db-password="$GLPI_DB_PASSWORD" \
    --default-language="$GLPI_LANGUAGE" --reconfigure
  console database:enable_timezones || true
elif [ "$GLPI_AUTO_UPDATE" = "true" ]; then
  console database:update
fi

# GLPI cron loop (replaces /etc/cron.d/glpi)
( while sleep 60; do runuser -u www-data -- php /var/www/glpi/front/cron.php >/dev/null 2>&1 || true; done ) &

exec docker-php-entrypoint "$@"
