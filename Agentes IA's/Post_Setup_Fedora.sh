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


# --- Lógica Principal del Script ---

# 1. Verificar privilegios de root.
verificar_root
imprimir_estado "$AMARILLO" "Iniciando el proceso de instalación de aplicaciones al sistema..."

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

# 5. Instalar Mixxx guvcview libreoffice-langpack-es
instalar_dnf mixxx guvcview libreoffice-langpack-es

## Configuración Multimedia
### 7. Instalar grupo multimedia de DNF
imprimir_estado "$AZUL" "Instalando el grupo 'multimedia' de DNF..."
if ! dnf group install -y --with-optional multimedia; then
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

### 14. Instalar grupo java-development de DNF
imprimir_estado "$AZUL" "Instalando el grupo 'java-development' de DNF..."
if ! dnf group install -y --with-optional java-development; then
    imprimir_estado "$ROJO" "Error al instalar el grupo 'java-development'. Verifica tu conexión o repositorios."
fi
imprimir_estado "$VERDE" "Grupo 'java-development' instalado correctamente."

### 15. Instalar grupo c-development de DNF
imprimir_estado "$AZUL" "Instalando el grupo 'c-development' de DNF..."
if ! dnf group install -y --with-optional c-development; then
    imprimir_estado "$ROJO" "Error al instalar el grupo 'c-development'. Verifica tu conexión o repositorios."
fi
imprimir_estado "$VERDE" "Grupo 'c-development' instalado correctamente."

imprimir_estado "$AZUL" "Instalando extensiones c-development adicionales (mesa-libGL-devel, openssl-devel, zlib-devel)..."
instalar_dnf mesa-libGL-devel openssl-devel zlib-devel ncurses-devel readline-devel systemd-devel

### 16. Instalar .NET SDK 9.0
imprimir_estado "$AZUL" "Instalando .NET SDK 9.0..."
instalar_dnf dotnet-sdk-9.0

### 17. Verificar instalaciones de .NET
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

### 18. Instalar Visual Studio Code
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

### 19. Instalar Node.js
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
### 20. Instalar paquetes de PHP y extensiones
imprimir_estado "$AZUL" "Instalando el grupo base de PHP con opciones..."
if ! dnf group install -y --with-optional php; then
    imprimir_estado "$ROJO" "Error al instalar el grupo 'php'. Verifica tu conexión o repositorios."
fi
imprimir_estado "$VERDE" "Grupo 'php' instalado correctamente."

imprimir_estado "$AZUL" "Instalando extensiones PHP adicionales (php-fpm, php-redis, php-pecl-xdebug3)..."
instalar_dnf php-fpm php-redis php-pecl-xdebug3

### 21. Configurar php.ini
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

### 22. Configurar Apache (HTTPD)
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

### 23. Instalar Composer (Gestor de Dependencias PHP)
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

### 23. Crear archivo de prueba info.php
imprimir_estado "$AZUL" "Creando el archivo de prueba 'info.php' en /var/www/html/..."
if ! echo "<?php phpinfo();" | sudo tee /var/www/html/info.php &>/dev/null; then
    imprimir_estado "$ROJO" "Error al crear el archivo 'info.php'."
fi
imprimir_estado "$VERDE" "Archivo 'info.php' creado en /var/www/html/. Accede a http://localhost/info.php para verificar la configuración."

## Bases de Datos y Herramientas Adicionales
### 24. Configuración de MariaDB (MySQL)
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

### 25. Configuración de PostgreSQL
imprimir_estado "$AZUL" "Instalando el grupo PostgreSQL (sql-server)..."
if ! dnf group install -y --with-optional sql-server; then
    imprimir_estado "$ROJO" "Error al instalar el grupo 'sql-server' (PostgreSQL). Verifica tu conexión o repositorios."
fi
imprimir_estado "$VERDE" "Grupo 'sql-server' (PostgreSQL) instalado correctamente."

imprimir_estado "$AZUL" "Inicializando la base de datos de PostgreSQL..."
# postgresql-setup --initdb inicializa el clúster de base de datos
if ! postgresql-setup --initdb; then
    imprimir_estado "$ROJO" "Error al inicializar la base de datos de PostgreSQL. Revisa los logs."
fi
imprimir_estado "$VERDE" "Base de datos de PostgreSQL inicializada."

imprimir_estado "$AZUL" "Habilitando e iniciando el servicio 'postgresql'..."
if ! systemctl enable --now postgresql; then
    imprimir_estado "$ROJO" "Error al habilitar e iniciar el servicio 'postgresql'."
fi
imprimir_estado "$VERDE" "Servicio 'postgresql' habilitado e iniciado."

imprimir_estado "$AMARILLO" "¡ATENCIÓN! Es necesario configurar el archivo pg_hba.conf de PostgreSQL para la autenticación."
imprimir_estado "$AMARILLO" "Este paso requiere edición manual para evitar problemas de permisos y formato."
imprimir_estado "$AMARILLO" "1. Abre el archivo de configuración: ${AZUL}sudo nano /var/lib/pgsql/data/pg_hba.conf${RESET}"
imprimir_estado "$AMARILLO" "2. Busca las líneas que definen la autenticación para conexiones locales y de replicación (ej. 'local', 'host')."
imprimir_estado "$AMARILLO" "3. Cambia el método de autenticación a 'md5' o 'trust' según tu necesidad."
imprimir_estado "$AMARILLO" "   Ejemplo de líneas a buscar y modificar:"
imprimir_estado "$AMARILLO" "   ${AZUL}local   all             all                                     md5${RESET}"
imprimir_estado "$AMARILLO" "   ${AZUL}host    all             all             127.0.0.1/32            md5${RESET}"
imprimir_estado "$AMARILLO" "   ${AZUL}host    all             all             ::1/128                 md5${RESET}"
imprimir_estado "$AMARILLO" "   ${AZUL}local   replication     all                                     md5${RESET}"
imprimir_estado "$AMARILLO" "   ${AZUL}host    replication     all             127.0.0.1/32            md5${RESET}"
imprimir_estado "$AMARILLO" "   ${AZUL}host    replication     all             ::1/128                 md5${RESET}"
imprimir_estado "$AMARILLO" "4. Guarda los cambios y sal del editor."
imprimir_estado "$AMARILLO" "5. **Reinicia el servicio PostgreSQL para aplicar los cambios:** ${AZUL}sudo systemctl restart postgresql${RESET}"
imprimir_estado "$AMARILLO" "El script continuará, pero asegúrate de realizar estos pasos importantes."

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
imprimir_estado "$AMARILLO" "8. Para gestionar las versiones de Node.js (opcional), considera usar NVM (Node Version Manager)."
imprimir_estado "$AMARILLO" "9. **Verifica la configuración de PHP y Apache:**"
imprimir_estado "$AMARILLO" "   Accede a la página de prueba PHP en tu navegador: ${AZUL}http://localhost/info.php${RESET}"
imprimir_estado "$AMARILLO" "   Asegúrate de que los servicios httpd y php-fpm estén activos: ${AZUL}sudo systemctl status httpd php-fpm${RESET}"
imprimir_estado "$AMARILLO" "   Revisa los logs de Apache si hay problemas: ${AZUL}sudo journalctl -xeu httpd${RESET}"
imprimir_estado "$AMARILLO" "   Si usas SELinux, puede que necesites ajustar contextos para /var/www/html."
imprimir_estado "$AMARILLO" "10. **Asegura tus bases de datos:**"
imprimir_estado "$AMARILLO" "    Recuerda ejecutar ${AZUL}sudo mysql_secure_installation${RESET} para MariaDB/MySQL."
imprimir_estado "$AMARILLO" "    Configura ${AZUL}/var/lib/pgsql/data/pg_hba.conf${RESET} y ${AZUL}reinicia PostgreSQL${RESET}."
