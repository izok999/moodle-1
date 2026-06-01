#!/usr/bin/env bash
set -euo pipefail

mkdir -p moodle-data/db moodle-data/moodledata

if [[ -f config.php ]]; then
    echo "config.php ya existe. Si queres reinstalar, borrarlo primero." >&2
    exit 1
fi

docker compose up -d db moodle
docker compose exec -T --user root moodle chmod 0777 /var/www/moodledata

uidgid="$(id -u):$(id -g)"

docker compose exec -T --user "$uidgid" moodle php admin/cli/install.php \
    --lang="${MOODLE_LANG:-es}" \
    --wwwroot="http://localhost:${MOODLE_HTTP_PORT:-8080}" \
    --dataroot=/var/www/moodledata \
    --dbtype=mariadb \
    --dbhost=db \
    --dbport=3306 \
    --dbname="${MOODLE_DATABASE_NAME:-moodle}" \
    --dbuser="${MOODLE_DATABASE_USER:-moodle}" \
    --dbpass="${MOODLE_DATABASE_PASSWORD:-moodle123}" \
    --prefix="${MOODLE_TABLE_PREFIX:-mdl_}" \
    --fullname="${MOODLE_SITE_NAME:-Mi Moodle Dev}" \
    --shortname="${MOODLE_SHORT_NAME:-Moodle Dev}" \
    --adminuser="${MOODLE_USERNAME:-admin}" \
    --adminpass="${MOODLE_PASSWORD:-Admin1234!}" \
    --adminemail="${MOODLE_EMAIL:-admin@example.com}" \
    --non-interactive \
    --agree-license

chmod 0644 config.php

docker compose exec -T moodle php admin/cli/cfg.php --name=theme --set="${MOODLE_THEME:-mitema}"
docker compose exec -T moodle php admin/cli/purge_caches.php

echo "OK Instalacion completada en http://localhost:${MOODLE_HTTP_PORT:-8080} con tema ${MOODLE_THEME:-mitema}"