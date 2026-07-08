#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${1:-${SCRIPT_DIR}/provision_4_instancias.env}"

DEFAULT_PHP_BIN="/usr/bin/php"
if [[ -x "/usr/bin/php8.3" ]]; then
    DEFAULT_PHP_BIN="/usr/bin/php8.3"
fi

if [[ ! -f "${ENV_FILE}" ]]; then
    echo "Falta el archivo de variables: ${ENV_FILE}" >&2
    echo "Copia ${SCRIPT_DIR}/provision_4_instancias.env.example y rellena los valores reales." >&2
    exit 1
fi

# shellcheck disable=SC1090
source "${ENV_FILE}"

PHP_BIN="${PHP_BIN:-${DEFAULT_PHP_BIN}}"
SOURCE_DIR="${SOURCE_DIR:-/home/master/moodle-1}"
SITES_ROOT="${SITES_ROOT:-/home/master/moodle-sites}"
DATA_ROOT="${DATA_ROOT:-/home/master/moodledata}"
FORCE_REINSTALL="${FORCE_REINSTALL:-0}"

SITE_1_DIR="${SITE_1_DIR:-${SITES_ROOT}/institutotecnicosuperiordelnorte}"
SITE_2_DIR="${SITE_2_DIR:-${SITES_ROOT}/cepec}"
SITE_3_DIR="${SITE_3_DIR:-${SITES_ROOT}/sensorium}"
SITE_4_DIR="${SITE_4_DIR:-${SITES_ROOT}/institutotecnicosuperiorcem}"

DATA_1_DIR="${DATA_1_DIR:-${DATA_ROOT}/institutotecnicosuperiordelnorte}"
DATA_2_DIR="${DATA_2_DIR:-${DATA_ROOT}/cepec}"
DATA_3_DIR="${DATA_3_DIR:-${DATA_ROOT}/sensorium}"
DATA_4_DIR="${DATA_4_DIR:-${DATA_ROOT}/institutotecnicosuperiorcem}"

DB_HOST="${DB_HOST:-localhost}"
DB_TYPE="${DB_TYPE:-mariadb}"
DB_PREFIX="${DB_PREFIX:-mdl_}"

required_vars=(
    DOMINIO_1 DOMINIO_2 DOMINIO_3 DOMINIO_4
    DB_NAME_1 DB_NAME_2 DB_NAME_3 DB_NAME_4
    DB_USER_1 DB_USER_2 DB_USER_3 DB_USER_4
    DB_PASS_1 DB_PASS_2 DB_PASS_3 DB_PASS_4
    ADMIN_PASS_1 ADMIN_PASS_2 ADMIN_PASS_3 ADMIN_PASS_4
)

for var_name in "${required_vars[@]}"; do
    if [[ -z "${!var_name:-}" ]]; then
        echo "Falta definir ${var_name} en ${ENV_FILE}" >&2
        exit 1
    fi
done

ADMIN_USER_1="${ADMIN_USER_1:-admin}"
ADMIN_USER_2="${ADMIN_USER_2:-admin}"
ADMIN_USER_3="${ADMIN_USER_3:-admin}"
ADMIN_USER_4="${ADMIN_USER_4:-admin}"

ADMIN_EMAIL_1="${ADMIN_EMAIL_1:-admin@${DOMINIO_1}}"
ADMIN_EMAIL_2="${ADMIN_EMAIL_2:-admin@${DOMINIO_2}}"
ADMIN_EMAIL_3="${ADMIN_EMAIL_3:-admin@${DOMINIO_3}}"
ADMIN_EMAIL_4="${ADMIN_EMAIL_4:-admin@${DOMINIO_4}}"

FULLNAME_1="${FULLNAME_1:-Instituto Tecnico Superior del Norte}"
FULLNAME_2="${FULLNAME_2:-CEPEC}"
FULLNAME_3="${FULLNAME_3:-Sensorium}"
FULLNAME_4="${FULLNAME_4:-Instituto Tecnico Superior CEM}"

SHORTNAME_1="${SHORTNAME_1:-ITN}"
SHORTNAME_2="${SHORTNAME_2:-CEPEC}"
SHORTNAME_3="${SHORTNAME_3:-SENSORIUM}"
SHORTNAME_4="${SHORTNAME_4:-ITSCEM}"

require_command() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Falta el comando requerido: $cmd" >&2
        exit 1
    fi
}

create_directories() {
    mkdir -p \
        "${SITE_1_DIR}" "${SITE_2_DIR}" "${SITE_3_DIR}" "${SITE_4_DIR}" \
        "${DATA_1_DIR}" "${DATA_2_DIR}" "${DATA_3_DIR}" "${DATA_4_DIR}"
}

sync_code() {
    chmod 711 /home/master
    chmod 755 "${SITES_ROOT}"
    chmod 711 "${DATA_ROOT}"

    rsync -a --delete --exclude='/.git/' --exclude='/config.php' "${SOURCE_DIR}/" "${SITE_1_DIR}/"
    rsync -a --delete --exclude='/.git/' --exclude='/config.php' "${SOURCE_DIR}/" "${SITE_2_DIR}/"
    rsync -a --delete --exclude='/.git/' --exclude='/config.php' "${SOURCE_DIR}/" "${SITE_3_DIR}/"
    rsync -a --delete --exclude='/.git/' --exclude='/config.php' "${SOURCE_DIR}/" "${SITE_4_DIR}/"

    find "${SITES_ROOT}" -type d -exec chmod 755 {} +
    find "${SITES_ROOT}" -type f -exec chmod 644 {} +
    find "${SITES_ROOT}" -path '*/admin/cli/*.php' -exec chmod 755 {} +
}

prepare_acl() {
    if ! command -v setfacl >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y acl
    fi

    sudo setfacl -m u:www-data:rx /home/master
    sudo setfacl -m u:www-data:rx "${SITES_ROOT}"
    sudo setfacl -m u:www-data:rx "${DATA_ROOT}"

    sudo find "${SITES_ROOT}" -type d -exec setfacl -m u:www-data:rx {} +
    sudo find "${SITES_ROOT}" -type d -exec setfacl -m d:u:www-data:rx {} +
    sudo find "${SITES_ROOT}" -type f -exec setfacl -m u:www-data:r {} +
}

prepare_moodledata() {
    local current_user current_group
    current_user="$(id -un)"
    current_group="$(id -gn)"

    sudo chown -R "${current_user}:${current_group}" "${DATA_1_DIR}" "${DATA_2_DIR}" "${DATA_3_DIR}" "${DATA_4_DIR}"
    sudo chmod 2770 "${DATA_1_DIR}" "${DATA_2_DIR}" "${DATA_3_DIR}" "${DATA_4_DIR}"

    for data_dir in "${DATA_1_DIR}" "${DATA_2_DIR}" "${DATA_3_DIR}" "${DATA_4_DIR}"; do
        sudo setfacl -m u:www-data:rwx "${data_dir}"
        sudo setfacl -m d:u:www-data:rwx "${data_dir}"
    done
}

create_databases() {
    sudo mysql <<SQL
CREATE DATABASE IF NOT EXISTS \`${DB_NAME_1}\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS \`${DB_NAME_2}\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS \`${DB_NAME_3}\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS \`${DB_NAME_4}\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${DB_USER_1}'@'localhost' IDENTIFIED BY '${DB_PASS_1}';
CREATE USER IF NOT EXISTS '${DB_USER_2}'@'localhost' IDENTIFIED BY '${DB_PASS_2}';
CREATE USER IF NOT EXISTS '${DB_USER_3}'@'localhost' IDENTIFIED BY '${DB_PASS_3}';
CREATE USER IF NOT EXISTS '${DB_USER_4}'@'localhost' IDENTIFIED BY '${DB_PASS_4}';

ALTER USER '${DB_USER_1}'@'localhost' IDENTIFIED BY '${DB_PASS_1}';
ALTER USER '${DB_USER_2}'@'localhost' IDENTIFIED BY '${DB_PASS_2}';
ALTER USER '${DB_USER_3}'@'localhost' IDENTIFIED BY '${DB_PASS_3}';
ALTER USER '${DB_USER_4}'@'localhost' IDENTIFIED BY '${DB_PASS_4}';

GRANT ALL PRIVILEGES ON \`${DB_NAME_1}\`.* TO '${DB_USER_1}'@'localhost';
GRANT ALL PRIVILEGES ON \`${DB_NAME_2}\`.* TO '${DB_USER_2}'@'localhost';
GRANT ALL PRIVILEGES ON \`${DB_NAME_3}\`.* TO '${DB_USER_3}'@'localhost';
GRANT ALL PRIVILEGES ON \`${DB_NAME_4}\`.* TO '${DB_USER_4}'@'localhost';

FLUSH PRIVILEGES;
SQL
}

install_instance() {
    local site_dir="$1"
    local data_dir="$2"
    local domain="$3"
    local db_name="$4"
    local db_user="$5"
    local db_pass="$6"
    local fullname="$7"
    local shortname="$8"
    local admin_user="$9"
    local admin_pass="${10}"
    local admin_email="${11}"
    local table_count

    table_count="$(mysql -u"${db_user}" -p"${db_pass}" -D "${db_name}" -Nse "SHOW TABLES;" 2>/dev/null | wc -l | tr -d ' ')"

    if [[ -f "${site_dir}/config.php" && "${FORCE_REINSTALL}" != "1" && "${table_count}" != "0" ]]; then
        echo "Saltando ${site_dir}: ya existe config.php"
        return 0
    fi

    if [[ -f "${site_dir}/config.php" && ( "${FORCE_REINSTALL}" == "1" || "${table_count}" == "0" ) ]]; then
        rm -f "${site_dir}/config.php"
    fi

    "${PHP_BIN}" "${site_dir}/admin/cli/install.php" \
        --wwwroot="https://${domain}" \
        --dataroot="${data_dir}" \
        --dbtype="${DB_TYPE}" \
        --dbhost="${DB_HOST}" \
        --dbname="${db_name}" \
        --dbuser="${db_user}" \
        --dbpass="${db_pass}" \
        --prefix="${DB_PREFIX}" \
        --fullname="${fullname}" \
        --shortname="${shortname}" \
        --adminuser="${admin_user}" \
        --adminpass="${admin_pass}" \
        --adminemail="${admin_email}" \
        --lang=es \
        --non-interactive \
        --agree-license
}

install_cron() {
    local tmp_cron
    tmp_cron="$(mktemp)"
    sudo crontab -u www-data -l > "${tmp_cron}" 2>/dev/null || true

    add_cron_line() {
        local line="$1"
        if ! grep -Fqx "$line" "${tmp_cron}"; then
            echo "$line" >> "${tmp_cron}"
        fi
    }

    add_cron_line "* * * * * ${PHP_BIN} ${SITE_1_DIR}/admin/cli/cron.php >/dev/null 2>&1"
    add_cron_line "* * * * * ${PHP_BIN} ${SITE_2_DIR}/admin/cli/cron.php >/dev/null 2>&1"
    add_cron_line "* * * * * ${PHP_BIN} ${SITE_3_DIR}/admin/cli/cron.php >/dev/null 2>&1"
    add_cron_line "* * * * * ${PHP_BIN} ${SITE_4_DIR}/admin/cli/cron.php >/dev/null 2>&1"

    sudo crontab -u www-data "${tmp_cron}"
    rm -f "${tmp_cron}"
}

main() {
    require_command rsync
    require_command sudo
    require_command mysql

    if [[ ! -x "${PHP_BIN}" ]]; then
        echo "No existe o no es ejecutable PHP_BIN=${PHP_BIN}" >&2
        exit 1
    fi

    if [[ ! -d "${SOURCE_DIR}" ]]; then
        echo "No existe SOURCE_DIR=${SOURCE_DIR}" >&2
        exit 1
    fi

    echo "==> Validando sudo"
    sudo -v

    echo "==> Preparando carpetas"
    create_directories

    echo "==> Sincronizando codigo"
    sync_code

    echo "==> Preparando ACL para Apache"
    prepare_acl

    echo "==> Preparando moodledata"
    prepare_moodledata

    echo "==> Creando bases de datos y usuarios"
    create_databases

    echo "==> Instalando Instituto Tecnico Superior del Norte"
    install_instance "${SITE_1_DIR}" "${DATA_1_DIR}" "${DOMINIO_1}" "${DB_NAME_1}" "${DB_USER_1}" "${DB_PASS_1}" "${FULLNAME_1}" "${SHORTNAME_1}" "${ADMIN_USER_1}" "${ADMIN_PASS_1}" "${ADMIN_EMAIL_1}"

    echo "==> Instalando CEPEC"
    install_instance "${SITE_2_DIR}" "${DATA_2_DIR}" "${DOMINIO_2}" "${DB_NAME_2}" "${DB_USER_2}" "${DB_PASS_2}" "${FULLNAME_2}" "${SHORTNAME_2}" "${ADMIN_USER_2}" "${ADMIN_PASS_2}" "${ADMIN_EMAIL_2}"

    echo "==> Instalando Sensorium"
    install_instance "${SITE_3_DIR}" "${DATA_3_DIR}" "${DOMINIO_3}" "${DB_NAME_3}" "${DB_USER_3}" "${DB_PASS_3}" "${FULLNAME_3}" "${SHORTNAME_3}" "${ADMIN_USER_3}" "${ADMIN_PASS_3}" "${ADMIN_EMAIL_3}"

    echo "==> Instalando Instituto Tecnico Superior CEM"
    install_instance "${SITE_4_DIR}" "${DATA_4_DIR}" "${DOMINIO_4}" "${DB_NAME_4}" "${DB_USER_4}" "${DB_PASS_4}" "${FULLNAME_4}" "${SHORTNAME_4}" "${ADMIN_USER_4}" "${ADMIN_PASS_4}" "${ADMIN_EMAIL_4}"

    echo "==> Configurando cron de Moodle"
    install_cron

    cat <<EOF

Provision completado.

Docroots esperados en cPanel/Apache:
- ${DOMINIO_1} -> ${SITE_1_DIR}
- ${DOMINIO_2} -> ${SITE_2_DIR}
- ${DOMINIO_3} -> ${SITE_3_DIR}
- ${DOMINIO_4} -> ${SITE_4_DIR}

Sitio estatico separado:
- /home/master/cem_its
EOF
}

main "$@"