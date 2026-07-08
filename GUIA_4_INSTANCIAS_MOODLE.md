# Guia exacta para sacar 4 instancias de Moodle para otros institutos

Esta guia sirve para dos cosas:

- ejecutarla tu mismo paso a paso en Linux
- copiar el bloque final y darselo a otro modelo para que haga el trabajo sin ambiguedades

El punto de partida real asumido aqui es este servidor:

- usuario del servidor: `master`
- host: `superiorserver`
- home del usuario: `/home/master`
- sistema operativo: Ubuntu 24.04.4 LTS
- servidor web: Apache 2.4.58
- base de datos: MariaDB 10.11
- PHP CLI detectado: `/usr/bin/php` (`8.4.20`)
- instalacion Moodle origen: `/home/master/moodle-1`
- carpeta de copias Moodle: `/home/master/moodle-sites`
- carpeta de datos Moodle: `/home/master/moodledata`
- sitio estatico de biblioteca virtual: `/home/master/cem_its`

## Aclaracion importante de estructura

En esta maquina las rutas tienen este papel:

- `/home/master/moodle-1` es la instalacion Moodle origen desde la que vas a clonar codigo
- `/home/master/moodle-sites` contiene las futuras copias de codigo, una por instituto
- `/home/master/moodledata` contiene el `moodledata` aislado de cada instituto
- `/home/master/cem_its` no es Moodle: es el sitio estatico de biblioteca virtual y no forma parte de esta clonacion

Aunque existe `/home/master/moodle-base`, en esta guia exacta no se usa porque hoy esta vacio. El origen real es `/home/master/moodle-1`.

Los cuatro institutos son:

- `institutotecnicosuperiordelnorte`
- `cepec`
- `sensorium`
- `institutotecnicosuperiorcem`

El objetivo es crear cuatro instalaciones separadas de Moodle, cada una con:

- su propia carpeta de codigo
- su propia base de datos
- su propio directorio `moodledata`
- su propio `config.php`
- su propio subdominio

## Decision tecnica recomendada

No compartas estos elementos entre institutos:

- la base de datos
- el directorio `moodledata`
- el `config.php`

Puedes partir del mismo codigo, pero cada instituto debe quedar desplegado de forma independiente.

## Estructura objetivo exacta en este servidor

- codigo origen actual: `/home/master/moodle-1`
- sitio 1: `/home/master/moodle-sites/institutotecnicosuperiordelnorte`
- sitio 2: `/home/master/moodle-sites/cepec`
- sitio 3: `/home/master/moodle-sites/sensorium`
- sitio 4: `/home/master/moodle-sites/institutotecnicosuperiorcem`
- datos 1: `/home/master/moodledata/institutotecnicosuperiordelnorte`
- datos 2: `/home/master/moodledata/cepec`
- datos 3: `/home/master/moodledata/sensorium`
- datos 4: `/home/master/moodledata/institutotecnicosuperiorcem`

## Variables que debes decidir antes de empezar

El dominio base actual es `consultoraonbusiness.com`. Para esta instalacion, los subdominios quedan asi:

- `DOMINIO_BASE`: `consultoraonbusiness.com`
- `DOMINIO_1`: `institutotecnicosuperiordelnorte.consultoraonbusiness.com`
- `DOMINIO_2`: `cepec.consultoraonbusiness.com`
- `DOMINIO_3`: `sensorium.consultoraonbusiness.com`
- `DOMINIO_4`: `institutotecnicosuperiorcem.consultoraonbusiness.com`

## Nombres recomendados para las bases de datos en cPanel

Como en cPanel normalmente se usa el prefijo del usuario, recomiendo estos nombres cortos:

- base 1: `master_itn`
- base 2: `master_cepec`
- base 3: `master_sensor`
- base 4: `master_itcem`

Y estos usuarios:

- usuario 1: `master_itn_u`
- usuario 2: `master_cepec_u`
- usuario 3: `master_sensor_u`
- usuario 4: `master_itcem_u`

## 1. Preparar la estructura de carpetas

```bash
mkdir -p /home/master/moodle-sites/institutotecnicosuperiordelnorte
mkdir -p /home/master/moodle-sites/cepec
mkdir -p /home/master/moodle-sites/sensorium
mkdir -p /home/master/moodle-sites/institutotecnicosuperiorcem

mkdir -p /home/master/moodledata/institutotecnicosuperiordelnorte
mkdir -p /home/master/moodledata/cepec
mkdir -p /home/master/moodledata/sensorium
mkdir -p /home/master/moodledata/institutotecnicosuperiorcem
```

## 2. Instalar ACL para que Apache pueda servir codigo bajo `/home/master`

Ahora mismo `/home/master` esta en `750`, por lo que `www-data` no puede atravesarlo por defecto. Para mantener todo bajo tu usuario sin abrir de mas el `home`, instala ACL y concede acceso de lectura y travesia solo donde hace falta.

```bash
sudo apt-get update
sudo apt-get install -y acl

sudo setfacl -m u:www-data:rx /home/master
sudo setfacl -m u:www-data:rx /home/master/moodle-sites
sudo setfacl -m u:www-data:rx /home/master/moodledata

sudo find /home/master/moodle-sites -type d -exec setfacl -m u:www-data:rx {} +
sudo find /home/master/moodle-sites -type d -exec setfacl -m d:u:www-data:rx {} +
sudo find /home/master/moodle-sites -type f -exec setfacl -m u:www-data:r {} +
```

Con esto Apache puede leer el codigo en `/home/master/moodle-sites` sin exponer publicamente todo `/home/master`.

## 3. Copiar el codigo de Moodle desde `moodle-1`

Primero elimina `config.php` en los destinos por si hubo intentos previos:

```bash
rm -f /home/master/moodle-sites/institutotecnicosuperiordelnorte/config.php
rm -f /home/master/moodle-sites/cepec/config.php
rm -f /home/master/moodle-sites/sensorium/config.php
rm -f /home/master/moodle-sites/institutotecnicosuperiorcem/config.php
```

Luego clona el codigo origen a cada destino:

```bash
rsync -a --exclude='.git/' --exclude='config.php' /home/master/moodle-1/ /home/master/moodle-sites/institutotecnicosuperiordelnorte/
rsync -a --exclude='.git/' --exclude='config.php' /home/master/moodle-1/ /home/master/moodle-sites/cepec/
rsync -a --exclude='.git/' --exclude='config.php' /home/master/moodle-1/ /home/master/moodle-sites/sensorium/
rsync -a --exclude='.git/' --exclude='config.php' /home/master/moodle-1/ /home/master/moodle-sites/institutotecnicosuperiorcem/
```

## 4. Ajustar propietarios y permisos de `moodledata`

`moodledata` debe quedar fuera del web root y ser escribible por Apache.

```bash
sudo chown -R www-data:www-data /home/master/moodledata/institutotecnicosuperiordelnorte
sudo chown -R www-data:www-data /home/master/moodledata/cepec
sudo chown -R www-data:www-data /home/master/moodledata/sensorium
sudo chown -R www-data:www-data /home/master/moodledata/institutotecnicosuperiorcem

sudo chmod 2770 /home/master/moodledata/institutotecnicosuperiordelnorte
sudo chmod 2770 /home/master/moodledata/cepec
sudo chmod 2770 /home/master/moodledata/sensorium
sudo chmod 2770 /home/master/moodledata/institutotecnicosuperiorcem
```

## 5. Crear las cuatro bases de datos y usuarios

Ejecuta este bloque en MariaDB o MySQL:

```sql
CREATE DATABASE master_itn DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE master_cepec DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE master_sensor DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE master_itcem DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER 'master_itn_u'@'localhost' IDENTIFIED BY 'CAMBIA_DB_PASS_ITN';
CREATE USER 'master_cepec_u'@'localhost' IDENTIFIED BY 'CAMBIA_DB_PASS_CEPEC';
CREATE USER 'master_sensor_u'@'localhost' IDENTIFIED BY 'CAMBIA_DB_PASS_SENSOR';
CREATE USER 'master_itcem_u'@'localhost' IDENTIFIED BY 'CAMBIA_DB_PASS_ITCEM';

GRANT ALL PRIVILEGES ON master_itn.* TO 'master_itn_u'@'localhost';
GRANT ALL PRIVILEGES ON master_cepec.* TO 'master_cepec_u'@'localhost';
GRANT ALL PRIVILEGES ON master_sensor.* TO 'master_sensor_u'@'localhost';
GRANT ALL PRIVILEGES ON master_itcem.* TO 'master_itcem_u'@'localhost';

FLUSH PRIVILEGES;
```

Si tu cPanel agrega el prefijo automaticamente, usa exactamente los nombres finales que te muestre cPanel y replica esos mismos valores en los comandos CLI y en los `config.php`.

## 6. Crear los cuatro subdominios en cPanel

Usa cPanel solo para los subdominios y apunta cada docroot al directorio de codigo correcto:

- `institutotecnicosuperiordelnorte.tudominio.com` -> `/home/master/moodle-sites/institutotecnicosuperiordelnorte`
- `cepec.tudominio.com` -> `/home/master/moodle-sites/cepec`
- `sensorium.tudominio.com` -> `/home/master/moodle-sites/sensorium`
- `institutotecnicosuperiorcem.tudominio.com` -> `/home/master/moodle-sites/institutotecnicosuperiorcem`

`/home/master/cem_its` queda aparte y puede enlazar despues a estos cuatro subdominios desde la biblioteca virtual, pero no debe usarse como docroot de ninguna instancia Moodle.

## 7. Instalar cada instancia por CLI

Como el origen no trae `config.php` a los clones, el instalador CLI lo generara automaticamente con los datos correctos.

### Instancia 1: Instituto Tecnico Superior del Norte

```bash
/usr/bin/php /home/master/moodle-sites/institutotecnicosuperiordelnorte/admin/cli/install.php \
  --wwwroot=https://institutotecnicosuperiordelnorte.tudominio.com \
  --dataroot=/home/master/moodledata/institutotecnicosuperiordelnorte \
  --dbtype=mariadb \
  --dbhost=localhost \
  --dbname=master_itn \
  --dbuser=master_itn_u \
  --dbpass='CAMBIA_DB_PASS_ITN' \
  --prefix=mdl_ \
  --fullname='Instituto Tecnico Superior del Norte' \
  --shortname='ITN' \
  --adminuser=admin \
  --adminpass='CambiaAdminItn123!' \
  --adminemail='admin@institutotecnicosuperiordelnorte.tudominio.com' \
  --lang=es \
  --non-interactive \
  --agree-license
```

### Instancia 2: CEPEC

```bash
/usr/bin/php /home/master/moodle-sites/cepec/admin/cli/install.php \
  --wwwroot=https://cepec.tudominio.com \
  --dataroot=/home/master/moodledata/cepec \
  --dbtype=mariadb \
  --dbhost=localhost \
  --dbname=master_cepec \
  --dbuser=master_cepec_u \
  --dbpass='CAMBIA_DB_PASS_CEPEC' \
  --prefix=mdl_ \
  --fullname='CEPEC' \
  --shortname='CEPEC' \
  --adminuser=admin \
  --adminpass='CambiaAdminCepec123!' \
  --adminemail='admin@cepec.tudominio.com' \
  --lang=es \
  --non-interactive \
  --agree-license
```

### Instancia 3: Sensorium

```bash
/usr/bin/php /home/master/moodle-sites/sensorium/admin/cli/install.php \
  --wwwroot=https://sensorium.tudominio.com \
  --dataroot=/home/master/moodledata/sensorium \
  --dbtype=mariadb \
  --dbhost=localhost \
  --dbname=master_sensor \
  --dbuser=master_sensor_u \
  --dbpass='CAMBIA_DB_PASS_SENSOR' \
  --prefix=mdl_ \
  --fullname='Sensorium' \
  --shortname='SENSORIUM' \
  --adminuser=admin \
  --adminpass='CambiaAdminSensor123!' \
  --adminemail='admin@sensorium.tudominio.com' \
  --lang=es \
  --non-interactive \
  --agree-license
```

### Instancia 4: Instituto Tecnico Superior CEM

```bash
/usr/bin/php /home/master/moodle-sites/institutotecnicosuperiorcem/admin/cli/install.php \
  --wwwroot=https://institutotecnicosuperiorcem.tudominio.com \
  --dataroot=/home/master/moodledata/institutotecnicosuperiorcem \
  --dbtype=mariadb \
  --dbhost=localhost \
  --dbname=master_itcem \
  --dbuser=master_itcem_u \
  --dbpass='CAMBIA_DB_PASS_ITCEM' \
  --prefix=mdl_ \
  --fullname='Instituto Tecnico Superior CEM' \
  --shortname='ITSCEM' \
  --adminuser=admin \
  --adminpass='CambiaAdminItcem123!' \
  --adminemail='admin@institutotecnicosuperiorcem.tudominio.com' \
  --lang=es \
  --non-interactive \
  --agree-license
```

## 8. Contenido esperado de cada `config.php`

Despues de la instalacion CLI, cada `config.php` debe quedar equivalente a este patron.

### `config.php` de `institutotecnicosuperiordelnorte`

```php
<?php
unset($CFG);
global $CFG;
$CFG = new stdClass();

$CFG->dbtype = 'mariadb';
$CFG->dblibrary = 'native';
$CFG->dbhost = 'localhost';
$CFG->dbname = 'master_itn';
$CFG->dbuser = 'master_itn_u';
$CFG->dbpass = 'CAMBIA_DB_PASS_ITN';
$CFG->prefix = 'mdl_';
$CFG->dboptions = array(
    'dbpersist' => 0,
    'dbport' => '',
    'dbsocket' => '',
    'dbcollation' => 'utf8mb4_unicode_ci',
);

$CFG->wwwroot = 'https://institutotecnicosuperiordelnorte.tudominio.com';
$CFG->dataroot = '/home/master/moodledata/institutotecnicosuperiordelnorte';
$CFG->admin = 'admin';

$CFG->directorypermissions = 02770;

require_once(__DIR__ . '/lib/setup.php');
```

### `config.php` de `cepec`

```php
<?php
unset($CFG);
global $CFG;
$CFG = new stdClass();

$CFG->dbtype = 'mariadb';
$CFG->dblibrary = 'native';
$CFG->dbhost = 'localhost';
$CFG->dbname = 'master_cepec';
$CFG->dbuser = 'master_cepec_u';
$CFG->dbpass = 'CAMBIA_DB_PASS_CEPEC';
$CFG->prefix = 'mdl_';
$CFG->dboptions = array(
    'dbpersist' => 0,
    'dbport' => '',
    'dbsocket' => '',
    'dbcollation' => 'utf8mb4_unicode_ci',
);

$CFG->wwwroot = 'https://cepec.tudominio.com';
$CFG->dataroot = '/home/master/moodledata/cepec';
$CFG->admin = 'admin';

$CFG->directorypermissions = 02770;

require_once(__DIR__ . '/lib/setup.php');
```

### `config.php` de `sensorium`

```php
<?php
unset($CFG);
global $CFG;
$CFG = new stdClass();

$CFG->dbtype = 'mariadb';
$CFG->dblibrary = 'native';
$CFG->dbhost = 'localhost';
$CFG->dbname = 'master_sensor';
$CFG->dbuser = 'master_sensor_u';
$CFG->dbpass = 'CAMBIA_DB_PASS_SENSOR';
$CFG->prefix = 'mdl_';
$CFG->dboptions = array(
    'dbpersist' => 0,
    'dbport' => '',
    'dbsocket' => '',
    'dbcollation' => 'utf8mb4_unicode_ci',
);

$CFG->wwwroot = 'https://sensorium.tudominio.com';
$CFG->dataroot = '/home/master/moodledata/sensorium';
$CFG->admin = 'admin';

$CFG->directorypermissions = 02770;

require_once(__DIR__ . '/lib/setup.php');
```

### `config.php` de `institutotecnicosuperiorcem`

```php
<?php
unset($CFG);
global $CFG;
$CFG = new stdClass();

$CFG->dbtype = 'mariadb';
$CFG->dblibrary = 'native';
$CFG->dbhost = 'localhost';
$CFG->dbname = 'master_itcem';
$CFG->dbuser = 'master_itcem_u';
$CFG->dbpass = 'CAMBIA_DB_PASS_ITCEM';
$CFG->prefix = 'mdl_';
$CFG->dboptions = array(
    'dbpersist' => 0,
    'dbport' => '',
    'dbsocket' => '',
    'dbcollation' => 'utf8mb4_unicode_ci',
);

$CFG->wwwroot = 'https://institutotecnicosuperiorcem.tudominio.com';
$CFG->dataroot = '/home/master/moodledata/institutotecnicosuperiorcem';
$CFG->admin = 'admin';

$CFG->directorypermissions = 02770;

require_once(__DIR__ . '/lib/setup.php');
```

## 9. Programar el cron de cada instancia

La forma mas limpia es editar el crontab del usuario `www-data`:

```bash
sudo crontab -e -u www-data
```

Y pegar estas cuatro lineas:

```cron
* * * * * /usr/bin/php /home/master/moodle-sites/institutotecnicosuperiordelnorte/admin/cli/cron.php >/dev/null 2>&1
* * * * * /usr/bin/php /home/master/moodle-sites/cepec/admin/cli/cron.php >/dev/null 2>&1
* * * * * /usr/bin/php /home/master/moodle-sites/sensorium/admin/cli/cron.php >/dev/null 2>&1
* * * * * /usr/bin/php /home/master/moodle-sites/institutotecnicosuperiorcem/admin/cli/cron.php >/dev/null 2>&1
```

## 10. Checklist de verificacion final

Antes de dar por terminada cada instancia, comprueba esto:

- el subdominio abre la instalacion correcta
- el `wwwroot` coincide exactamente con el subdominio real
- `moodledata` no es accesible publicamente por URL
- Apache puede leer el codigo bajo `/home/master/moodle-sites`
- `www-data` puede escribir en el `moodledata` de esa instancia
- el cron funciona sin errores
- cada instituto entra a su propia base de datos
- los archivos subidos por un instituto no aparecen en otro
- `cem_its` sigue siendo un sitio estatico separado y no comparte `config.php`, base de datos ni `moodledata` con Moodle

## 11. Errores que no debes cometer

- reutilizar el mismo `moodledata` para dos institutos
- reutilizar la misma base de datos para dos institutos
- copiar un `config.php` viejo sin cambiar `wwwroot`, `dbname` y `dataroot`
- dejar `www-data` sin acceso de travesia a `/home/master`
- apuntar un subdominio Moodle a `/home/master/cem_its`
- meter `moodledata` dentro de un docroot publico

## Prompt exacto para pedirle esto a otro modelo

Copia y pega este texto tal cual, cambiando solo dominio base y claves:

```text
Quiero que me guies para crear 4 instancias separadas de Moodle en este servidor Linux:

- usuario: master
- host: superiorserver
- home: /home/master
- origen del codigo: /home/master/moodle-1
- copia 1: /home/master/moodle-sites/institutotecnicosuperiordelnorte
- copia 2: /home/master/moodle-sites/cepec
- copia 3: /home/master/moodle-sites/sensorium
- copia 4: /home/master/moodle-sites/institutotecnicosuperiorcem
- moodledata 1: /home/master/moodledata/institutotecnicosuperiordelnorte
- moodledata 2: /home/master/moodledata/cepec
- moodledata 3: /home/master/moodledata/sensorium
- moodledata 4: /home/master/moodledata/institutotecnicosuperiorcem
- dominio 1: institutotecnicosuperiordelnorte.tudominio.com
- dominio 2: cepec.tudominio.com
- dominio 3: sensorium.tudominio.com
- dominio 4: institutotecnicosuperiorcem.tudominio.com
- base de datos 1: master_itn
- base de datos 2: master_cepec
- base de datos 3: master_sensor
- base de datos 4: master_itcem
- usuario DB 1: master_itn_u
- usuario DB 2: master_cepec_u
- usuario DB 3: master_sensor_u
- usuario DB 4: master_itcem_u
- clave DB 1: [clave_itn]
- clave DB 2: [clave_cepec]
- clave DB 3: [clave_sensor]
- clave DB 4: [clave_itcem]
- php cli: /usr/bin/php
- sitio estatico aparte: /home/master/cem_its

Necesito que me entregues:

1. los comandos exactos para preparar carpetas y permisos
2. los comandos exactos para dar acceso a Apache bajo /home/master usando ACL
3. los comandos exactos para copiar el codigo desde /home/master/moodle-1
4. el SQL exacto para crear las 4 bases de datos y usuarios
5. los comandos exactos para instalar cada instancia por CLI
6. el cron exacto para las 4 instancias
7. el contenido esperado de cada config.php
8. una checklist final de validacion

No quiero explicacion general. Quiero instrucciones ejecutables, en orden, y con placeholders ya resueltos con mis rutas reales. /home/master/cem_its no forma parte de Moodle: solo es la biblioteca virtual estatica.
```

## Recomendacion final

Si tu objetivo es administrar cuatro institutos con el menor mantenimiento posible, manten una sola base de codigo versionada como origen, separa unicamente:

- base de datos
- `moodledata`
- `config.php`
- subdominio

Y deja `cem_its` como la capa estatica de acceso o biblioteca virtual que enlaza a cada plataforma, pero sin mezclarla con la logica ni el despliegue de Moodle.