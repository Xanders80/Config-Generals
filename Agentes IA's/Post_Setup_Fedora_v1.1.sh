#!/bin/bash

# --- Colores ---
# Define colores para mejorar la legibilidad de la salida en la terminal.
AMARILLO='\033[1;33m'
AZUL='\033[1;34m'
VERDE='\033[1;32m'
ROJO='\033[1;31m'
RESET='\033[0m'

# --- Funciones Utilitarias ---

# Función para imprimir mensajes de estado con colores.
imprimir_estado() {
    local color="$1"
    local mensaje="$2"
    echo -e "${color}${mensaje}${RESET}"
}

# Función para verificar si el script se ejecuta como root.
verificar_root() {
    if [[ $EUID -ne 0 ]]; then
        imprimir_estado "$ROJO" "Este script debe ser ejecutado con privilegios de superusuario (sudo)."
        exit 1
    fi
}

# Función para manejar la instalación de paquetes DNF.
instalar_dnf() {
    local paquetes=("$@")
    imprimir_estado "$AZUL" "Instalando: ${paquetes[*]}..."
    if ! dnf install -y "${paquetes[@]}"; then
        imprimir_estado "$ROJO" "Error al instalar ${paquetes[*]}."

    fi
    imprimir_estado "$VERDE" "${paquetes[*]} instalado(s) correctamente."
}

# Función para verificar si un comando existe.
comando_existe() {
    type "$1" &>/dev/null
}

# Función para actualizar una configuración en un archivo .ini
actualizar_config_php() {
    local archivo="$1"
    local clave="$2"
    local valor="$3"
    imprimir_estado "$AZUL" "Actualizando '$clave' a '$valor' en '$archivo'..."
    if grep -qE "^\s*([;#]\s*)?${clave}\s*=" "$archivo"; then
        # La clave existe, la actualizamos (considerando comentarios y espacios)
        if ! sed -i -E "s/^\s*([;#]\s*)?${clave}\s*=.*/${clave}=${valor}/" "$archivo"; then
            imprimir_estado "$ROJO" "Error al actualizar '$clave' en '$archivo'."
            return 1
        fi
    else
        # La clave no existe, la añadimos al final del archivo
        if ! echo "${clave}=${valor}" >> "$archivo"; then
            imprimir_estado "$ROJO" "Error al añadir '$clave' a '$archivo'."
            return 1
        fi
    fi
    imprimir_estado "$VERDE" "'$clave' configurado."
    return 0
}

# Función para actualizar el pg_hba.conf de PostgreSQL
actualizar_pg_hba() {
    local pg_hba_file="/var/lib/pgsql/data/pg_hba.conf"

    imprimir_estado "$AZUL" "Configurando la autenticación en $pg_hba_file..."

    if [[ ! -f "$pg_hba_file" ]]; then
        imprimir_estado "$ROJO" "Error: Archivo $pg_hba_file no encontrado. PostgreSQL podría no estar inicializado correctamente."
        return 1
    fi

    # Reemplaza las líneas de configuración usando sed:
    # 1. Busca líneas con "replication" y cambia 'peer' o 'ident' por 'md5'
    # 2. Elimina comentarios iniciales (opcional, si están comentadas)
    sed -i -e '/^local[[:space:]]\+replication[[:space:]]\+all[[:space:]]\+/ s/peer$/md5/' \
        -e '/^host[[:space:]]\+replication[[:space:]]\+all[[:space:]]\+/ s/ident$/md5/' \
        -e '/^#local[[:space:]]\+replication/ s/#//; s/peer$/md5/' \
        -e '/^#host[[:space:]]\+replication/ s/#//; s/ident$/md5/' \
        "$pg_hba_file"

    imprimir_estado "$VERDE" "Autenticación pg_hba.conf configurada a 'md5'."
    imprimir_estado "$AZUL" "Reiniciando el servicio PostgreSQL para aplicar los cambios en pg_hba.conf..."
    if ! systemctl restart postgresql; then
        imprimir_estado "$ROJO" "Error al reiniciar el servicio PostgreSQL."
        return 1
    fi
    imprimir_estado "$VERDE" "Servicio PostgreSQL reiniciado."

    return 0
}

# Nueva función para reconstruir la base de datos DNF
reconstruir_dnf_db() {
    imprimir_estado "$AZUL" "Iniciando la reconstrucción y limpieza de la base de datos DNF..."

    # 1. Actualizar certificados raíz (es una buena práctica antes de cualquier operación DNF importante)
    imprimir_estado "$AZUL" "Actualizando certificados raíz..."
    if ! dnf install ca-certificates -y; then
        imprimir_estado "$ROJO" "Error al instalar 'ca-certificates'. Puede que haya problemas de red o repositorios."
        return 1
    fi
    if ! update-ca-trust; then
        imprimir_estado "$ROJO" "Error al actualizar la base de datos de confianza de CA."
        return 1
    fi
    imprimir_estado "$VERDE" "Certificados raíz actualizados."

    # 2. Limpiar caché de DNF
    # dnf clean all es el comando más completo para limpiar la caché.
    # Incluye dbcache, metadata y packages.
    imprimir_estado "$AZUL" "Limpiando toda la caché de DNF (metadatos y paquetes descargados)..."
    if ! dnf clean all; then
        imprimir_estado "$AMARILLO" "Advertencia: Falló 'dnf clean all'. Esto podría indicar un problema, pero el script intentará continuar."
    else
        imprimir_estado "$VERDE" "Caché de DNF limpiada."
    fi

    # rm -rf /var/cache/dnf/* es una limpieza más agresiva, pero dnf clean all debería ser suficiente
    # y es más seguro que borrar directamente directorios de caché.
    # Sin embargo, si quieres la limpieza más exhaustiva posible:
    # imprimir_estado "$AZUL" "Eliminando archivos de caché DNF directamente..."
    # if sudo rm -rf /var/cache/dnf/*; then
    #     imprimir_estado "$VERDE" "Archivos de caché DNF eliminados directamente."
    # else
    #     imprimir_estado "$AMARILLO" "Advertencia: Falló la eliminación directa de archivos de caché DNF."
    # fi

    # 3. Regenerar la caché de metadatos
    imprimir_estado "$AZUL" "Generando nueva caché de metadatos de los repositorios DNF..."
    if ! dnf makecache; then
        imprimir_estado "$ROJO" "Error al generar la caché de DNF. Verifica tu conexión a internet y los repositorios."
        return 1
    fi
    imprimir_estado "$VERDE" "Caché de DNF generada correctamente."

    # 4. Eliminar paquetes huérfanos
    imprimir_estado "$AZUL" "Eliminando paquetes instalados como dependencias que ya no son necesarios (autoremove)..."
    # El flag -y es importante para que no se detenga y pida confirmación.
    # Sin embargo, si el usuario prefiere revisar qué se eliminará, se podría quitar el -y.
    if ! dnf autoremove -y; then
        imprimir_estado "$AMARILLO" "Advertencia: No se pudieron eliminar paquetes huérfanos, o no hay ninguno. Revisa la salida de 'sudo dnf autoremove' si persiste la preocupación."
    else
        imprimir_estado "$VERDE" "Paquetes huérfanos eliminados (si los había)."
    fi

    imprimir_estado "$VERDE" "Reconstrucción y limpieza de la base de datos DNF completada."
    return 0
}


# --- Lógica Principal del Script ---

# 1. Verificar privilegios de root.
verificar_root
imprimir_estado "$AMARILLO" "Iniciando el proceso de instalación de aplicaciones al sistema..."

# Opcional: Ejecutar la reconstrucción de DNF al inicio del script si lo consideras un paso inicial necesario.
# Si lo pones aquí, asegúrate de que el usuario entiende que se hará automáticamente.
# imprimir_estado "$AZUL" "Realizando reconstrucción de la base de datos DNF antes de las instalaciones..."
# if ! reconstruir_dnf_db; then
#     imprimir_estado "$ROJO" "La reconstrucción de la base de datos DNF falló. Esto podría afectar instalaciones posteriores."
#     # Decide si quieres detener el script aquí o continuar con una advertencia.
#     #
# fi

# 2. Instalar el módulo del kernel KVM y herramientas de virtualización.
imprimir_estado "$AZUL" "Instalando el grupo de virtualización DNF (KVM, QEMU, libvirt)..."
if ! dnf group install -y --with-optional virtualization; then
    imprimir_estado "$ROJO" "Error al instalar el grupo de virtualización. Verifica tu conexión o repositorios."

fi
imprimir_estado "$VERDE" "Grupo de virtualización instalado correctamente."

# 3. Añadir el usuario actual a los grupos 'kvm' y 'libvirt'.
imprimir_estado "$AZUL" "Añadiendo el usuario '${SUDO_USER:-$USER}' a los grupos 'kvm' y 'libvirt'..."

# Usamos SUDO_USER si el script se ejecuta con sudo, de lo contrario usamos USER.
# Esto asegura que el usuario que ejecuta el script sea el añadido.
CURRENT_USER="${SUDO_USER:-$USER}"

if ! getent group kvm &>/dev/null; then
    imprimir_estado "$ROJO" "El grupo 'kvm' no existe. KVM podría no estar completamente instalado o soportado."
else
    if ! usermod -aG kvm "$CURRENT_USER"; then
        imprimir_estado "$ROJO" "Error al añadir a '${CURRENT_USER}' al grupo 'kvm'."

    fi
    imprimir_estado "$VERDE" "Usuario '${CURRENT_USER}' añadido al grupo 'kvm'."
fi

if ! getent group libvirt &>/dev/null; then
    imprimir_estado "$ROJO" "El grupo 'libvirt' no existe. libvirt podría no estar completamente instalado."
else
    if ! usermod -aG libvirt "$CURRENT_USER"; then
        imprimir_estado "$ROJO" "Error al añadir a '${CURRENT_USER}' al grupo 'libvirt'."

    fi
    imprimir_estado "$VERDE" "Usuario '${CURRENT_USER}' añadido al grupo 'libvirt'."
fi

# 4. Iniciar y habilitar el servicio libvirtd.
imprimir_estado "$AZUL" "Iniciando y habilitando el servicio 'libvirtd'..."
if ! systemctl is-active --quiet libvirtd; then
    if ! systemctl start libvirtd; then
        imprimir_estado "$ROJO" "Error al iniciar el servicio 'libvirtd'."

    fi
    imprimir_estado "$VERDE" "Servicio 'libvirtd' iniciado."
else
    imprimir_estado "$VERDE" "Servicio 'libvirtd' ya está en ejecución."
fi

if ! systemctl is-enabled --quiet libvirtd; then
    if ! systemctl enable libvirtd; then
        imprimir_estado "$ROJO" "Error al habilitar el servicio 'libvirtd'."

    fi
    imprimir_estado "$VERDE" "Servicio 'libvirtd' ya está habilitado."
fi

# 5. Instalar Mixxx
instalar_dnf mixxx

# 6. Instalar guvcview
instalar_dnf guvcview

## Configuración Multimedia

### 7. Instalar grupo multimedia de DNF

imprimir_estado "$AZUL" "Instalando el grupo 'multimedia' de DNF..."
if ! dnf group install -y multimedia; then
    imprimir_estado "$ROJO" "Error al instalar el grupo 'multimedia'. Verifica tu conexión o repositorios."

fi
imprimir_estado "$VERDE" "Grupo 'multimedia' instalado correctamente."

### 8. Cambiar a la versión completa de FFmpeg

imprimir_estado "$AZUL" "Cambiando a la versión completa de FFmpeg ('ffmpeg-free' a 'ffmpeg')..."
if ! dnf swap 'ffmpeg-free' 'ffmpeg' --allowerasing -y; then
    imprimir_estado "$ROJO" "Error al cambiar de 'ffmpeg-free' a 'ffmpeg'. Algunos paquetes pueden estar en conflicto."

fi
imprimir_estado "$VERDE" "FFmpeg completo instalado correctamente."

### 9. Actualizar componentes GStreamer

imprimir_estado "$AZUL" "Actualizando componentes GStreamer para el grupo multimedia..."
if ! dnf upgrade @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y; then
    imprimir_estado "$ROJO" "Error al actualizar los componentes GStreamer."

fi
imprimir_estado "$VERDE" "Componentes GStreamer actualizados correctamente."

### 10. Instalar controladores y utilidades de aceleración de video (VA-API)

imprimir_estado "$AZUL" "Instalando controladores VA-API y utilidades de soporte de video..."
instalar_dnf mesa-va-drivers-freeworld gstreamer1-vaapi libva-utils

### 11. Configurar controladores de video Intel para VA-API

imprimir_estado "$AZUL" "Cambiando a 'intel-media-driver' y/o instalando 'libva-intel-driver'..."
if dnf list installed libva-intel-media-driver &>/dev/null; then
    imprimir_estado "$AZUL" "Realizando swap de 'libva-intel-media-driver' a 'intel-media-driver'..."
    if ! dnf swap libva-intel-media-driver intel-media-driver --allowerasing -y; then
        imprimir_estado "$ROJO" "Error al realizar el swap de controladores Intel. Podría haber conflictos."
    else
        imprimir_estado "$VERDE" "Swap de controladores Intel completado."
    fi
else
    imprimir_estado "$AMARILLO" "El paquete 'libva-intel-media-driver' no está instalado para realizar el swap. Procediendo a instalar 'libva-intel-driver'."
fi
instalar_dnf libva-intel-driver

### 12. Habilitar y configurar OpenH264 para Firefox

imprimir_estado "$AZUL" "Instalando paquetes de OpenH264 para Firefox y habilitando el repositorio Cisco..."
if ! dnf install -y openh264 gstreamer1-plugin-openh264 mozilla-openh264; then
    imprimir_estado "$ROJO" "Error al instalar los paquetes de OpenH264. Verifica tus repositorios."

fi
imprimir_estado "$VERDE" "Paquetes de OpenH264 instalados correctamente."

imprimir_estado "$AZUL" "Habilitando el repositorio 'fedora-cisco-openh264'..."
if ! dnf config-manager --set-enabled fedora-cisco-openh264; then
    imprimir_estado "$ROJO" "Error al habilitar el repositorio 'fedora-cisco-openh264'."

fi
imprimir_estado "$VERDE" "Repositorio 'fedora-cisco-openh264' habilitado."

## Herramientas de Desarrollo

### 13. Configurar Git

imprimir_estado "$AZUL" "Verificando e instalando Git si es necesario..."
if ! comando_existe git; then
    imprimir_estado "$AMARILLO" "Git no encontrado. Procediendo a instalar Git..."
    instalar_dnf git
else
    imprimir_estado "$VERDE" "Git ya está instalado."
fi

imprimir_estado "$AZUL" "Configurando la información global de usuario de Git..."
GIT_USER="${SUDO_USER:-$USER}"

if sudo -u "$GIT_USER" git config --global user.name "Xanders80"; then
    imprimir_estado "$VERDE" "Configurado git user.name para '${GIT_USER}'."
else
    imprimir_estado "$ROJO" "Error al configurar git user.name para '${GIT_USER}'."

fi

if sudo -u "$GIT_USER" git config --global user.email "xanders80@gmail.com"; then
    imprimir_estado "$VERDE" "Configurado git user.email para '${GIT_USER}'."
else
    imprimir_estado "$ROJO" "Error al configurar git user.email para '${GIT_USER}'."

fi

imprimir_estado "$AZUL" "Verificando la configuración global de Git para '${GIT_USER}'..."
if sudo -u "$GIT_USER" git config --global --list; then
    imprimir_estado "$VERDE" "Configuración global de Git listada correctamente."
else
    imprimir_estado "$ROJO" "Error al listar la configuración global de Git."

fi

### 14. Instalar .NET SDK 9.0

imprimir_estado "$AZUL" "Instalando .NET SDK 9.0..."
instalar_dnf dotnet-sdk-9.0

### 15. Verificar instalaciones de .NET

imprimir_estado "$AZUL" "Listando los SDKs de .NET instalados..."
if sudo -u "$CURRENT_USER" dotnet --list-sdks; then
    imprimir_estado "$VERDE" "SDKs de .NET listados correctamente."
else
    imprimir_estado "$ROJO" "Error al listar los SDKs de .NET. Asegúrate de que .NET esté en el PATH del usuario."
fi

imprimir_estado "$AZUL" "Listando los runtimes de .NET instalados..."
if sudo -u "$CURRENT_USER" dotnet --list-runtimes; then
    imprimir_estado "$VERDE" "Runtimes de .NET listados correctamente."
else
    imprimir_estado "$ROJO" "Error al listar los runtimes de .NET. Asegúrate de que .NET esté en el PATH del usuario."
fi

### 16. Instalar Visual Studio Code

imprimir_estado "$AZUL" "Añadiendo el repositorio oficial de Visual Studio Code..."
if ! sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'; then
    imprimir_estado "$ROJO" "Error al añadir el repositorio de VS Code."

fi
imprimir_estado "$VERDE" "Repositorio de VS Code añadido."

imprimir_estado "$AZUL" "Actualizando la lista de paquetes disponibles para DNF..."
if ! dnf check-update; then
    imprimir_estado "$ROJO" "Error al actualizar la lista de paquetes. Verifica tu conexión o repositorios."

fi
imprimir_estado "$VERDE" "Lista de paquetes actualizada."

imprimir_estado "$AZUL" "Instalando Visual Studio Code..."
if ! dnf install -y code; then
    imprimir_estado "$ROJO" "Error al instalar Visual Studio Code. Verifica que el repositorio se añadió correctamente y tu conexión."

fi
imprimir_estado "$VERDE" "Visual Studio Code instalado correctamente."

### 17. Instalar Node.js

imprimir_estado "$AZUL" "Instalando Node.js..."
instalar_dnf nodejs

imprimir_estado "$AZUL" "Verificando la versión de Node.js y npm instaladas..."
if comando_existe node; then
    imprimir_estado "$VERDE" "Node.js versión: $(node -v)"
else
    imprimir_estado "$ROJO" "Node.js no se encontró después de la instalación."
fi

if comando_existe npm; then
    imprimir_estado "$VERDE" "npm versión: $(npm -v)"
else
    imprimir_estado "$ROJO" "npm no se encontró después de la instalación."
fi

## Configuración de Entorno PHP

### 18. Instalar paquetes de PHP y extensiones

imprimir_estado "$AZUL" "Instalando el grupo base de PHP con opciones..."
if ! dnf group install -y --with-optional php; then
    imprimir_estado "$ROJO" "Error al instalar el grupo 'php'. Verifica tu conexión o repositorios."

fi
imprimir_estado "$VERDE" "Grupo 'php' instalado correctamente."

imprimir_estado "$AZUL" "Instalando extensiones PHP adicionales (php-fpm, php-redis, php-pecl-xdebug3)..."
instalar_dnf php-fpm php-redis php-pecl-xdebug3

### 19. Configurar php.ini

imprimir_estado "$AZUL" "Buscando y actualizando las opciones de configuración en php.ini..."
PHP_INI_PATH=$(php -i | grep "Loaded Configuration File" | awk '{print $NF}')

if [[ -z "$PHP_INI_PATH" ]]; then
    imprimir_estado "$ROJO" "No se pudo encontrar el archivo php.ini principal. La configuración manual podría ser necesaria."

fi
imprimir_estado "$AZUL" "Usando php.ini: ${PHP_INI_PATH}"

actualizar_config_php "$PHP_INI_PATH" "display_errors" "On"
actualizar_config_php "$PHP_INI_PATH" "error_reporting" "E_ALL"
actualizar_config_php "$PHP_INI_PATH" "memory_limit" "256M"
actualizar_config_php "$PHP_INI_PATH" "upload_max_filesize" "128M"
actualizar_config_php "$PHP_INI_PATH" "post_max_size" "128M"
actualizar_config_php "$PHP_INI_PATH" "opcache.enable" "1"
actualizar_config_php "$PHP_INI_PATH" "opcache.memory_consumption" "256"
actualizar_config_php "$PHP_INI_PATH" "opcache.interned_strings_buffer" "32"

imprimir_estado "$AZUL" "Añadiendo o verificando la configuración de Xdebug..."
XDEBUG_CONF_FILE="/etc/php.d/15-xdebug.ini"

if [[ ! -f "$XDEBUG_CONF_FILE" ]]; then
    imprimir_estado "$AMARILLO" "Creando archivo de configuración de Xdebug: ${XDEBUG_CONF_FILE}"
    echo "" | sudo tee "$XDEBUG_CONF_FILE" &>/dev/null
fi

if ! grep -q "zend_extension=xdebug.so" "$XDEBUG_CONF_FILE"; then
    imprimir_estado "$AZUL" "Añadiendo zend_extension a $XDEBUG_CONF_FILE..."
    if ! echo "zend_extension=xdebug.so" | sudo tee -a "$XDEBUG_CONF_FILE" &>/dev/null; then
        imprimir_estado "$ROJO" "Error al añadir zend_extension para Xdebug."

    fi
    imprimir_estado "$VERDE" "zend_extension añadido."
else
    imprimir_estado "$VERDE" "zend_extension ya presente."
fi

actualizar_config_php "$XDEBUG_CONF_FILE" "xdebug.mode" "develop,debug"
actualizar_config_php "$XDEBUG_CONF_FILE" "xdebug.start_with_request" "yes"
actualizar_config_php "$XDEBUG_CONF_FILE" "xdebug.client_host" "127.0.0.1"
actualizar_config_php "$XDEBUG_CONF_FILE" "xdebug.client_port" "9003"


### 20. Configurar Apache (HTTPD)

imprimir_estado "$AZUL" "Instalando el servidor web Apache (httpd)..."
instalar_dnf httpd

imprimir_estado "$AZUL" "Iniciando y habilitando los servicios 'php-fpm' y 'httpd'..."
if ! systemctl start php-fpm; then
    imprimir_estado "$ROJO" "Error al iniciar el servicio 'php-fpm'."

fi
imprimir_estado "$VERDE" "Servicio 'php-fpm' iniciado."

imprimir_estado "$AZUL" "Verificando estado del servicio 'php-fpm'..."
if ! systemctl status php-fpm --no-pager; then
    imprimir_estado "$AMARILLO" "El estado de php-fpm muestra advertencias o errores. Revísalo manualmente."
fi

if ! systemctl enable --now httpd php-fpm; then
    imprimir_estado "$ROJO" "Error al habilitar e iniciar los servicios 'httpd' y 'php-fpm' en el arranque."

fi
imprimir_estado "$VERDE" "Servicios 'httpd' y 'php-fpm' habilitados e iniciados."

### 21. Instalar Composer (Gestor de Dependencias PHP)

imprimir_estado "$AZUL" "Instalando Composer (Gestor de Dependencias PHP)..."
if ! comando_existe php; then
    imprimir_estado "$ROJO" "PHP no está instalado o no se encuentra en el PATH. No se puede instalar Composer."

fi

if ! php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"; then
    imprimir_estado "$ROJO" "Error al descargar el instalador de Composer."

fi
imprimir_estado "$VERDE" "Instalador de Composer descargado."

if ! php composer-setup.php --install-dir=/usr/local/bin --filename=composer; then
    imprimir_estado "$ROJO" "Error al instalar Composer."
    php -r "unlink('composer-setup.php');" &>/dev/null

fi
imprimir_estado "$VERDE" "Composer instalado en /usr/local/bin/composer."

if ! php -r "unlink('composer-setup.php');"; then
    imprimir_estado "$ROJO" "Error al eliminar el archivo de instalación de Composer."
else
    imprimir_estado "$VERDE" "Archivo de instalación de Composer eliminado."
fi

imprimir_estado "$AZUL" "Verificando la instalación de Composer..."
if ! comando_existe composer; then
    imprimir_estado "$ROJO" "Composer no se encontró después de la instalación."

fi
imprimir_estado "$VERDE" "Composer versión: $(composer --version)"

### 22. Crear archivo de prueba info.php

imprimir_estado "$AZUL" "Creando el archivo de prueba 'info.php' en /var/www/html/..."
if ! echo "<?php phpinfo();" | sudo tee /var/www/html/info.php &>/dev/null; then
    imprimir_estado "$ROJO" "Error al crear el archivo 'info.php'."

fi
imprimir_estado "$VERDE" "Archivo 'info.php' creado en /var/www/html/. Accede a http://localhost/info.php para verificar la configuración."

## Bases de Datos y Herramientas Adicionales

### 23. Configuración de MariaDB (MySQL)

imprimir_estado "$AZUL" "Instalando el grupo MySQL/MariaDB..."
if ! dnf group install -y --with-optional mysql; then
    imprimir_estado "$ROJO" "Error al instalar el grupo 'mysql'. Verifica tu conexión o repositorios."

fi
imprimir_estado "$VERDE" "Grupo 'mysql' instalado correctamente."

imprimir_estado "$AZUL" "Iniciando y habilitando el servicio 'mariadb'..."
if ! systemctl start mariadb; then
    imprimir_estado "$ROJO" "Error al iniciar el servicio 'mariadb'."

fi
imprimir_estado "$VERDE" "Servicio 'mariadb' iniciado."

if ! systemctl enable --now mariadb; then
    imprimir_estado "$ROJO" "Error al habilitar el servicio 'mariadb' en el arranque."

fi
imprimir_estado "$VERDE" "Servicio 'mariadb' habilitado para iniciar en el arranque."

imprimir_estado "$AMARILLO" "¡ATENCIÓN! Se recomienda ejecutar 'mysql_secure_installation' manualmente."
imprimir_estado "$AMARILLO" "Este paso es interactivo y te guiará para configurar la seguridad de tu servidor MariaDB/MySQL (establecer contraseña de root, eliminar usuarios anónimos, etc.)."
imprimir_estado "$AMARILLO" "Para ejecutarlo después de que el script termine, usa: ${AZUL}sudo mysql_secure_installation${RESET}"
imprimir_estado "$AMARILLO" "El script continuará, pero asegúrate de realizar este paso importante."

### 24. Configuración de PostgreSQL

imprimir_estado "$AZUL" "Instalando el grupo PostgreSQL (sql-server)..."
if ! dnf group install -y --with-optional sql-server; then
    imprimir_estado "$ROJO" "Error al instalar el grupo 'sql-server' (PostgreSQL). Verifica tu conexión o repositorios."

fi
imprimir_estado "$VERDE" "Grupo 'sql-server' (PostgreSQL) instalado correctamente."

imprimir_estado "$AZUL" "Inicializando la base de datos de PostgreSQL..."
if ! postgresql-setup --initdb; then
    imprimir_estado "$ROJO" "Error al inicializar la base de datos de PostgreSQL. Revisa los logs."

fi
imprimir_estado "$VERDE" "Base de datos de PostgreSQL inicializada."

imprimir_estado "$AZUL" "Habilitando e iniciando el servicio 'postgresql'..."
if ! systemctl enable --now postgresql; then
    imprimir_estado "$ROJO" "Error al habilitar e iniciar el servicio 'postgresql'."

fi
imprimir_estado "$VERDE" "Servicio 'postgresql' habilitado e iniciado."

# Llamada a la nueva función de configuración de pg_hba.conf
if ! actualizar_pg_hba; then
    imprimir_estado "$ROJO" "Falló la configuración automática de pg_hba.conf. Es posible que debas editarlo manualmente."
    imprimir_estado "$AMARILLO" "Por favor, revisa las instrucciones manuales para pg_hba.conf en la sección de 'Recomendaciones Post-Configuración'."
fi

## Mantenimiento del Sistema

### 25. Reconstruir Base de Datos DNF y Limpieza

# Llamada a la nueva función
if ! reconstruir_dnf_db; then
    imprimir_estado "$ROJO" "La reconstrucción de la base de datos DNF y la limpieza encontraron problemas."
    imprimir_estado "$AMARILLO" "Puedes intentar ejecutar los comandos manualmente o revisar los logs de DNF."
fi

## Mensaje de Finalización y Recomendaciones

imprimir_estado "$VERDE" "Proceso de instalación y configuración completado exitosamente."

imprimir_estado "$AMARILLO" "--- Recomendaciones Post-Configuración ---"
imprimir_estado "$AMARILLO" "1. Verifica que los repositorios se hayan habilitado correctamente con:"
imprimir_estado "$AMARILLO" "   ${AZUL}dnf repolist${RESET}"
imprimir_estado "$AMARILLO" "2. Si encuentras problemas, revisa los logs de DNF en:"
imprimir_estado "$AMARILLO" "   ${AZUL}/var/log/dnf.log${RESET}"
imprimir_estado "$AMARILLO" "3. Considera reiniciar tu sistema para que todos los cambios se apliquen completamente."
imprimir_estado "$AMARILLO" "   ${AZUL}sudo reboot${RESET}"
imprimir_estado "$AMARILLO" "4. Para verificar la aceleración de video (especialmente con Intel), puedes ejecutar:"
imprimir_estado "$AMARILLO" "   ${AZUL}vainfo${RESET}"
imprimir_estado "$AMARILLO" "5. Si experimentas problemas con .NET, verifica las variables de entorno o la instalación manual de repositorios de Microsoft, si aplica."
imprimir_estado "$AMARILLO" "6. Para confirmar que OpenH264 está funcionando en Firefox, visita una página como meet.google.com o test.webrtc.org."
imprimir_estado "$AMARILLO" "7. Inicia VS Code desde el menú de aplicaciones o ejecutando:"
imprimir_estado "$AMARILLO" "   ${AZUL}code${RESET}"
imprimir_estado "$AMARILLO" "8. **Para gestionar las versiones de Node.js (opcional), considera usar NVM (Node Version Manager).**"
imprimir_estado "$AMARILLO" "9. **Verifica la configuración de PHP y Apache:**"
imprimir_estado "$AMARILLO" "   Accede a la página de prueba PHP en tu navegador: ${AZUL}http://localhost/info.php${RESET}"
imprimir_estado "$AMARILLO" "   Asegúrate de que los servicios httpd y php-fpm estén activos: ${AZUL}sudo systemctl status httpd php-fpm${RESET}"
imprimir_estado "$AMARILLO" "   Revisa los logs de Apache si hay problemas: ${AZUL}sudo journalctl -xeu httpd${RESET}"
imprimir_estado "$AMARILLO" "   Si usas SELinux, puede que necesites ajustar contextos para /var/www/html."
imprimir_estado "$AMARILLO" "10. **Asegura tus bases de datos:**"
imprimir_estado "$AMARILLO" "    Recuerda ejecutar ${AZUL}sudo mysql_secure_installation${RESET} para MariaDB/MySQL."
imprimir_estado "$AMARILLO" "    Aunque el script intentó configurar ${AZUL}pg_hba.conf${RESET} automáticamente,"
imprimir_estado "$AMARILLO" "    si hay problemas, o si necesitas configuraciones avanzadas, puedes editarlo manualmente:"
imprimir_estado "$AMARILLO" "    ${AZUL}sudo nano /var/lib/pgsql/data/pg_hba.conf${RESET}"
imprimir_estado "$AMARILLO" "    Después de editarlo, **siempre reinicia PostgreSQL:** ${AZUL}sudo systemctl restart postgresql${RESET}"
imprimir_estado "$AMARILLO" "    Puedes crear un usuario PostgreSQL inicial para pruebas: ${AZUL}sudo -u postgres createuser --interactive${RESET}"
imprimir_estado "$AMARILLO" "    Y luego un database para ese usuario: ${AZUL}sudo -u postgres createdb -O <nombre_usuario> <nombre_db>${RESET}"
