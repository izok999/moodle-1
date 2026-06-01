# Guia exacta para sacar 3 copias de Moodle para otros institutos

Esta guia sirve para dos cosas:

- ejecutarla tu mismo paso a paso en Linux
- copiar el bloque final y darselo a otro modelo para que haga el trabajo sin ambiguedades

El punto de partida asumido aqui es este proyecto local:

- codigo base actual: `/home/izak/moodle-dev`

El objetivo es crear tres instalaciones separadas para tres institutos, cada una con:

- su propia carpeta de codigo
- su propia base de datos
- su propio directorio `moodledata`
- su propio `config.php`
- su propio dominio o subdominio

## Decision tecnica recomendada

No compartas estos elementos entre institutos:

- la base de datos
- el directorio `moodledata`
- el `config.php`

Puedes compartir el mismo punto de partida del codigo, pero cada instituto debe quedar desplegado de forma independiente.

## Estructura objetivo

Usa nombres claros y estables. Ejemplo:

- codigo instituto A: `/home/izak/moodle-inst-a`
- codigo instituto B: `/home/izak/moodle-inst-b`
- codigo instituto C: `/home/izak/moodle-inst-c`
- datos instituto A: `/home/izak/moodledata-inst-a`
- datos instituto B: `/home/izak/moodledata-inst-b`
- datos instituto C: `/home/izak/moodledata-inst-c`

## Variables que debes decidir antes de empezar

Reemplaza estos valores en todos los comandos y ejemplos:

- `DOMINIO_A`: `https://a.tudominio.com`
- `DOMINIO_B`: `https://b.tudominio.com`
- `DOMINIO_C`: `https://c.tudominio.com`
- `DB_A`: `moodle_a`
- `DB_B`: `moodle_b`
- `DB_C`: `moodle_c`
- `DB_USER_A`: usuario de la base de datos A
- `DB_USER_B`: usuario de la base de datos B
- `DB_USER_C`: usuario de la base de datos C
- `DB_PASS_A`: clave de la base de datos A
- `DB_PASS_B`: clave de la base de datos B
- `DB_PASS_C`: clave de la base de datos C

## Ruta 1: crear 3 copias completas del proyecto actual

Esta es la opcion mas directa si quieres que cada instituto tenga su propio directorio de codigo.

### 1. Copiar el codigo actual

Ejecuta esto desde Linux:

```bash
cp -a /home/izak/moodle-dev /home/izak/moodle-inst-a
cp -a /home/izak/moodle-dev /home/izak/moodle-inst-b
cp -a /home/izak/moodle-dev /home/izak/moodle-inst-c
```

### 2. Crear directorios `moodledata`

```bash
mkdir -p /home/izak/moodledata-inst-a
mkdir -p /home/izak/moodledata-inst-b
mkdir -p /home/izak/moodledata-inst-c
```

Si el usuario del servidor web es `www-data`, ajusta permisos:

```bash
chown -R www-data:www-data /home/izak/moodledata-inst-a
chown -R www-data:www-data /home/izak/moodledata-inst-b
chown -R www-data:www-data /home/izak/moodledata-inst-c
chmod -R 0770 /home/izak/moodledata-inst-a
chmod -R 0770 /home/izak/moodledata-inst-b
chmod -R 0770 /home/izak/moodledata-inst-c
```

### 3. Crear tres bases de datos

Ejemplo en MariaDB o MySQL:

```sql
CREATE DATABASE moodle_a DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE moodle_b DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE moodle_c DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER 'moodle_a_user'@'localhost' IDENTIFIED BY 'cambia_esta_clave_a';
CREATE USER 'moodle_b_user'@'localhost' IDENTIFIED BY 'cambia_esta_clave_b';
CREATE USER 'moodle_c_user'@'localhost' IDENTIFIED BY 'cambia_esta_clave_c';

GRANT ALL PRIVILEGES ON moodle_a.* TO 'moodle_a_user'@'localhost';
GRANT ALL PRIVILEGES ON moodle_b.* TO 'moodle_b_user'@'localhost';
GRANT ALL PRIVILEGES ON moodle_c.* TO 'moodle_c_user'@'localhost';

FLUSH PRIVILEGES;
```

### 4. Ajustar el `config.php` de cada copia

En cada directorio de codigo, el archivo `config.php` debe apuntar a su propia base de datos, su propio `moodledata` y su propio dominio.

Ejemplo para la instalacion A:

```php
<?php
unset($CFG);
global $CFG;
$CFG = new stdClass();

$CFG->dbtype = 'mysqli';
$CFG->dblibrary = 'native';
$CFG->dbhost = 'localhost';
$CFG->dbname = 'moodle_a';
$CFG->dbuser = 'moodle_a_user';
$CFG->dbpass = 'cambia_esta_clave_a';
$CFG->prefix = 'mdl_';
$CFG->dboptions = array(
    'dbpersist' => 0,
    'dbport' => '',
    'dbsocket' => '',
    'dbcollation' => 'utf8mb4_unicode_ci',
);

$CFG->wwwroot = 'https://a.tudominio.com';
$CFG->dataroot = '/home/izak/moodledata-inst-a';
$CFG->admin = 'admin';

$CFG->directorypermissions = 02770;

require_once(__DIR__ . '/lib/setup.php');
```

Repite el mismo patron para B y C, cambiando:

- `dbname`
- `dbuser`
- `dbpass`
- `wwwroot`
- `dataroot`

### 5. Instalar dependencias si hace falta

Si cada copia necesita dependencias locales:

```bash
cd /home/izak/moodle-inst-a
composer install
npm install

cd /home/izak/moodle-inst-b
composer install
npm install

cd /home/izak/moodle-inst-c
composer install
npm install
```

Si ya tienes dependencias validas en la copia origen y tu despliegue no necesita recompilarlas, puedes omitir este paso hasta validar cada instancia.

### 6. Configurar el servidor web

Cada instituto debe resolver a una carpeta distinta de codigo:

- `a.tudominio.com` -> `/home/izak/moodle-inst-a`
- `b.tudominio.com` -> `/home/izak/moodle-inst-b`
- `c.tudominio.com` -> `/home/izak/moodle-inst-c`

Si usas Nginx o Apache, crea un virtual host por instituto.

### 7. Ejecutar la instalacion web o CLI

Para terminar la instalacion puedes usar la interfaz web abriendo cada dominio, o la CLI de Moodle.

Ejemplo CLI para A:

```bash
php /home/izak/moodle-inst-a/admin/cli/install.php \
  --wwwroot=https://a.tudominio.com \
  --dataroot=/home/izak/moodledata-inst-a \
  --dbtype=mysqli \
  --dbhost=localhost \
  --dbname=moodle_a \
  --dbuser=moodle_a_user \
  --dbpass='cambia_esta_clave_a' \
  --fullname='Instituto A' \
  --shortname='INSTA' \
  --adminuser=admin \
  --adminpass='CambiaAdminA123!' \
  --adminemail='admin@a.tudominio.com' \
  --non-interactive \
  --agree-license
```

Repite el mismo patron para B y C.

### 8. Programar el cron de cada instancia

Ejemplo:

```bash
* * * * * /usr/bin/php /home/izak/moodle-inst-a/admin/cli/cron.php >/dev/null
* * * * * /usr/bin/php /home/izak/moodle-inst-b/admin/cli/cron.php >/dev/null
* * * * * /usr/bin/php /home/izak/moodle-inst-c/admin/cli/cron.php >/dev/null
```

## Ruta 2: una sola base de codigo y 3 despliegues separados

Si quieres reducir mantenimiento, en vez de copiar el codigo tres veces puedes tener una sola fuente de codigo versionada y desplegarla a tres destinos. Aun asi, cada instituto necesita su propio:

- `config.php`
- `moodledata`
- base de datos
- dominio

Esta ruta es mejor si haras actualizaciones frecuentes y quieres minimizar diferencias.

## Personalizacion por instituto

Si solo cambian logos, colores, nombre del centro o textos, evita tocar el core de Moodle. Usa:

- un tema hijo o tema personalizado
- ajustes del sitio
- plugins locales si hay logica extra

Si cada instituto va a tener reglas o codigo distinto, entonces si conviene separar mas claramente los despliegues o incluso llevar ramas distintas.

## Checklist de verificacion final

Antes de dar por terminada cada instancia, comprueba esto:

- el dominio abre la instalacion correcta
- el `wwwroot` coincide exactamente con el dominio real
- `moodledata` no es accesible publicamente por URL
- el cron funciona
- cada instituto entra a su propia base de datos
- los archivos subidos por un instituto no aparecen en otro
- los correos salientes salen con la configuracion correcta

## Errores que no debes cometer

- reutilizar el mismo `moodledata` para dos institutos
- reutilizar la misma base de datos para dos institutos
- copiar `config.php` sin cambiar `wwwroot`
- dejar permisos inseguros en `moodledata`
- personalizar el core si solo necesitas branding

## Prompt exacto para pedirle esto a otro modelo

Copia y pega este texto tal cual, cambiando solo los valores entre corchetes:

```text
Quiero que me guies para crear 3 instancias separadas de Moodle a partir de este proyecto local en Linux:

- origen del codigo: /home/izak/moodle-dev
- copia A: [ruta codigo A]
- copia B: [ruta codigo B]
- copia C: [ruta codigo C]
- moodledata A: [ruta moodledata A]
- moodledata B: [ruta moodledata B]
- moodledata C: [ruta moodledata C]
- dominio A: [dominio A]
- dominio B: [dominio B]
- dominio C: [dominio C]
- base de datos A: [db A]
- base de datos B: [db B]
- base de datos C: [db C]
- usuario DB A: [usuario A]
- usuario DB B: [usuario B]
- usuario DB C: [usuario C]
- clave DB A: [clave A]
- clave DB B: [clave B]
- clave DB C: [clave C]

Necesito que me entregues:

1. los comandos exactos para copiar el proyecto
2. los comandos exactos para crear los directorios moodledata
3. el SQL exacto para crear las 3 bases de datos y usuarios
4. el contenido exacto de cada config.php
5. los comandos exactos para instalar cada instancia por CLI
6. el cron exacto para las 3 instancias
7. una checklist final de validacion

No quiero explicacion general. Quiero instrucciones ejecutables, en orden, y con placeholders ya resueltos con mis datos.
```

## Recomendacion final

Si tu objetivo es administrar tres institutos con el menor mantenimiento posible, usa la misma version de Moodle para los tres, personaliza por tema o configuracion y separa unicamente:

- base de datos
- `moodledata`
- `config.php`
- dominio

Si quieres, el siguiente paso util es rellenar esta guia con tus nombres reales de institutos, dominios y credenciales para dejarla lista para ejecutar sin editar nada mas.