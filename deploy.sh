#!/usr/bin/env bash
set -euo pipefail

THEME_NAME="${THEME_NAME:-mitema}"
LOCAL_THEME_DIR="./theme/${THEME_NAME}"
DEPLOY_HOST="${DEPLOY_HOST:-}"
REMOTE_THEME_DIR="${REMOTE_THEME_DIR:-/var/www/moodle/theme/${THEME_NAME}}"
REMOTE_PURGE_CMD="${REMOTE_PURGE_CMD:-sudo -u www-data php /var/www/moodle/admin/cli/purge_caches.php}"

if [[ -z "${DEPLOY_HOST}" ]]; then
    echo "Defini DEPLOY_HOST. Ejemplo: DEPLOY_HOST=usuario@143.255.142.201 ./deploy.sh" >&2
    exit 1
fi

if [[ ! -d "${LOCAL_THEME_DIR}" ]]; then
    echo "No existe ${LOCAL_THEME_DIR}" >&2
    exit 1
fi

echo "-> Sincronizando ${THEME_NAME}..."
rsync -avz --delete "${LOCAL_THEME_DIR}/" "${DEPLOY_HOST}:${REMOTE_THEME_DIR}/"

echo "-> Limpiando cache en remoto..."
ssh "${DEPLOY_HOST}" "${REMOTE_PURGE_CMD}"

echo "OK Deploy completado"