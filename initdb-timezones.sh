#!/bin/sh
# Lets GLPI read timezone names (per-user timezones)
mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" -e "GRANT SELECT ON mysql.time_zone_name TO '$MARIADB_USER'@'%'; FLUSH PRIVILEGES;"
