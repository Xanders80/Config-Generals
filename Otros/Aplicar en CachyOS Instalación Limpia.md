# Guía de Configuración Post-Instalación - CachyOS

Guía completa para la configuración de CachyOS en entornos de desarrollo y producción personal.

## Tabla de Contenidos

1. [Configuración de Apariencia KDE](#1-configuración-de-apariencia-kde)
2. [Terminal y Starship](#2-terminal-y-starship)
3. [Repositorios Adicionales](#3-repositorios-adicionales)
4. [Instalación de Paquetes](#4-instalación-de-paquetes)
5. [Configuración de Firewall](#5-configuración-de-firewall)
6. [Virtualización KVM](#6-virtualización-kvm)
7. [Configuración Git](#7-configuración-git)
8. [Aceleración por Hardware Intel](#8-aceleración-por-hardware-intel)
9. [.NET Core](#9-net-core)
10. [PHP y Apache](#10-php-y-apache)
11. [MariaDB](#11-mariadb)
12. [PostgreSQL](#12-postgresql)
13. [WordPress](#13-wordpress)
14. [Waydroid](#14-waydroid)
15. [Optimización del Sistema](#15-optimización-del-sistema)
16. [Firefox - Configuración Avanzada](#16-firefox---configuración-avanzada)
17. [Notas Temporales](#17-notas-temporales)

---

## 1. Configuración de Apariencia KDE

### Temas y Estilos

- **Estilo de Plasma:** Kdewaita
- **Decoraciones de ventanas:** Clay
- **Iconos:** Win11-nord-dark
- **Cursores:** Vimix Cursores
- **Pantalla de Bienvenida:** Vinyl

### Mostrar Asteriscos al Escribir Contraseña

Editar configuración de sudoers:

```bash
sudo nano /etc/sudoers
```

Agregar la siguiente línea:

```ini
Defaults        env_reset,pwfeedback
```

---

## 2. Terminal y Starship

Instalar [Starship](https://starship.rs/):

```bash
sudo pacman -S starship
```

### Configuración por Shell

**Bash** (`~/.bashrc`):

```bash
eval "$(starship init bash)"
```

**Fish** (`~/.config/fish/config.fish`):

```fish
starship init fish | source
```

**Zsh** (`~/.zshrc`):

```zsh
eval "$(starship init zsh)"
```

### Tema Nerd Fonts

```bash
starship preset nerd-font-symbols -o ~/.config/starship.toml
```

> **Referencia:** [Configuraciones adicionales TOML](https://github.com/starship/starship/discussions/1107)

---

## 3. Repositorios Adicionales

### Actualizar sistema base

```bash
sudo pacman -Syu
```

### Instalar Chaotic AUR

```bash
sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
```

### Configurar pacman.conf

```bash
sudo nano /etc/pacman.conf
```

Añadir al final:

```ini
[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
```

### Instalar Paru y actualizar mirrors

```bash
sudo pacman -S paru --needed
sudo pacman -Syyu cachyos-mirrorlist
sudo pacman -Syyu
```

### Cambiar Kernel

Migrar a `deckify-lto` y actualizar flags del programador (flash y lowlatency).

> ⚠️ **Reiniciar el PC** después de actualizar el kernel.

---

## 4. Instalación de Paquetes

### Generales

```bash
cachyos-firefox-settings ntfs-3g sshfs hardinfo2 guvcview bleachbit isoimagewriter kcharselect kolourpaint okular partitionmanager gnome-nettool easyeffects mixxx vlc picard lbzip2 arj lzop cpio webp-pixbuf-loader libreoffice waydroid intel-gpu-tools gstreamer-vaapi libva-intel-driver libva-utils qemu-base qemu-img virt-manager virt-viewer vde2 bridge-utils openbsd-netcat edk2-ovmf libosinfo swtpm virtiofsd libvirt speech-dispatcher telegram
```

### Programación

```bash
antigravity visual-studio-code-bin dbeaver dotnet jdk-openjdk nodejs php php-redis composer mariadb postgresql wordpress
```

**Opcional:**

```bash
android-studio android-sdk android-sdk-platform-tools android-emulator
```

### Juegos

```bash
mednafen mednaffe dolphin-emu-git desmume-avx-git stella ppsspp-avx-git scummvm citron mupen64plus
```

**Con Paru:**

```bash
azaharplus-appimage mupen64plus-qt
```

---

## 5. Configuración de Firewall

Configuración UFW para Waydroid y KDE Connect:

```bash
# Políticas por defecto
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Tráfico Web
sudo ufw allow http
sudo ufw allow https

# SSH
sudo ufw allow ssh
sudo ufw allow 22/tcp

# KDE Connect
sudo ufw allow 1714:1764/tcp
sudo ufw allow 1714:1764/udp

# Waydroid DNS/DHCP
sudo ufw allow in on waydroid0 to any port 53 proto udp
sudo ufw allow in on waydroid0 to any port 67 proto udp

# Habilitar y persistir
sudo ufw enable
sudo systemctl enable ufw
```

---

## 6. Virtualización KVM

### Configurar libvirtd

```bash
sudo nano /etc/libvirt/libvirtd.conf
```

Descomentar:

```ini
unix_sock_group = "libvirt"
unix_sock_rw_perms = "0770"
```

### Parámetros Kernel (Comet Lake)

```bash
sudo nano /etc/default/grub
```

Reemplazar `GRUB_CMDLINE_LINUX_DEFAULT`:

```ini
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash intel_pstate=active intel_idle.max_cstate=2 i915.enable_guc=3 i915.enable_fbc=1 i915.max_vfs=7 mitigations=off nowatchdog nmi_watchdog=0 modprobe.blacklist=pcspkr"
```

Regenerar GRUB:

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### Permisos y Servicio

```bash
sudo usermod -aG libvirt,kvm $USER
sudo usermod -aG libvirt $(whoami)
sudo systemctl start libvirtd
sudo systemctl enable --now libvirtd
```

Validar:

```bash
sudo virt-host-validate
```

---

## 7. Configuración Git

```bash
git config --global user.name "Xanders80"
git config --global user.email "xanders80@gmail.com"
git config --global --list
```

---

## 8. Aceleración por Hardware Intel

Validar herramientas:

```bash
sudo intel_gpu_top
```

Configurar driver VA-API:

```bash
echo 'export LIBVA_DRIVER_NAME=iHD' | sudo tee /etc/profile.d/libva.sh
source /etc/profile.d/libva.sh
```

---

## 9. .NET Core

Verificar instalación:

```bash
dotnet --list-sdks
dotnet --list-runtimes
```

---

## 10. PHP y Apache

### Configurar PHP

```bash
sudo nano /etc/php/php.ini
```

Ajustes:

```ini
memory_limit = 2G
display_errors = On
error_reporting = E_ALL
upload_max_filesize = 256M
post_max_size = 256M
opcache.enable=1
opcache.memory_consumption=512
opcache.interned_strings_buffer=64
opcache.max_accelerated_files=20000
opcache.revalidate_freq=0
opcache.validate_timestamps=1
```

> Nota: `opcache.validate_timestamps=0` en producción, `1` en desarrollo.

Descomentar extensiones:

- `pdo_mysql`
- `bcmath`
- `mysqli`

### Configurar Apache (httpd.conf)

```bash
sudo nano /etc/httpd/conf/httpd.conf
```

Descomentar:

```apache
LoadModule mpm_event_module modules/mod_mpm_event.so
LoadModule proxy_module modules/mod_proxy.so
LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so
```

Agregar:

```apache
AddHandler php-script .php
ServerName localhost
Include conf/extra/php-fpm.conf
```

### Configurar PHP-FPM

```bash
sudo nano /etc/httpd/conf/extra/php-fpm.conf
```

Contenido:

```apache
<FilesMatch \.php$>
    SetHandler "proxy:unix:/run/php-fpm/php-fpm.sock|fcgi://localhost/"
</FilesMatch>

<IfModule dir_module>
    DirectoryIndex index.php index.html
</IfModule>
```

### Iniciar Servicios

```bash
sudo systemctl start httpd php-fpm
sudo systemctl enable --now php-fpm httpd
```

### Verificación

```bash
echo "<?php phpinfo();" | sudo tee /srv/http/info.php
```

Acceder a: `http://localhost/info.php`

---

## 11. MariaDB

### Inicializar

```bash
sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
sudo systemctl enable mariadb --now
sudo systemctl start mariadb
sudo mariadb-secure-installation
```

### Optimización (16GB RAM)

```bash
sudo nano /etc/my.cnf.d/optimization.cnf
```

```ini
[mysqld]
innodb_buffer_pool_size = 4G
innodb_log_file_size = 512M
innodb_flush_log_at_trx_commit = 2
query_cache_size = 128M
tmp_table_size = 256M
max_heap_table_size = 256M
key_buffer_size = 256M
```

---

## 12. PostgreSQL

### Inicializar

```bash
sudo -iu postgres
initdb --locale=$LANG -E UTF8 -D '/var/lib/postgres/data'
```

### Configuración (16GB RAM)

```bash
sudo -iu postgres
nano /var/lib/postgres/data/postgresql.conf
```

Ajustar:

```ini
shared_buffers = 4GB
effective_cache_size = 8GB
maintenance_work_mem = 1GB
work_mem = 256MB
wal_buffers = 16MB
```

### Iniciar y Configurar Usuario

```bash
sudo systemctl enable postgresql.service --now
sudo -iu postgres
psql
```

```sql
ALTER USER postgres WITH PASSWORD 'you_secure-password';
```

---

## 13. WordPress

### Base de Datos

```bash
sudo mariadb
```

```sql
CREATE DATABASE wordpress;
CREATE USER 'wpuser'@'localhost' IDENTIFIED BY 'tu_contraseña_segura';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### Configuración

```bash
cd wordpress
cp wp-config-sample.php wp-config.php
```

Editar `wp-config.php`:

```php
define('DB_NAME', 'wordpress');
define('DB_USER', 'wpuser');
define('DB_PASSWORD', 'Wpu*123');
define('DB_HOST', 'localhost');
```

### Virtual Host Apache

Crear `/etc/httpd/conf/extra/httpd-wordpress.conf`:

```apache
Alias /wordpress "/usr/share/webapps/wordpress/"
<Directory "/usr/share/webapps/wordpress/">
    AllowOverride All
    Options FollowSymlinks
    Require all granted
</Directory>
```

Incluir en `httpd.conf`:

```apache
Include conf/extra/httpd-wordpress.conf
```

### Permisos

```bash
sudo chown -R http:http /usr/share/webapps/wordpress/
sudo chmod -R 755 /usr/share/webapps/wordpress/
sudo systemctl status httpd
```

Finalizar instalación en: `http://localhost/wordpress`

---

## 14. Waydroid

### Límites de Recursos (4GB RAM)

```bash
sudo mkdir -p /etc/systemd/system/waydroid-container.service.d/
sudo tee /etc/systemd/system/waydroid-container.service.d/override.conf << EOF
[Service]
MemoryMax=4G
MemoryHigh=3.5G
MemorySwapMax=512M
AllowedCPUs=0,1,2,3
IOWeight=500
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now waydroid-container
```

### LibHoudini (Traducción ARM)

```bash
cd ~
git clone https://github.com/casualsnek/waydroid_script
cd waydroid_script
python3 -m venv venv
venv/bin/pip install -r requirements.txt
sudo systemctl stop waydroid-container
sudo venv/bin/python3 main.py install libhoudini
sudo systemctl start waydroid-container
```

---

## 15. Optimización del Sistema

### Sysctl (99-master-performance.conf)

```bash
sudo nano /etc/sysctl.d/99-master-performance.conf
```

```ini
# --- MEMORIA (16GB RAM) ---
vm.swappiness=10
vm.vfs_cache_pressure=50

# --- I/O & WRITEBACK (SSD Optimizado) ---
vm.dirty_background_ratio=5
vm.dirty_ratio=15
vm.dirty_expire_centisecs=300
vm.dirty_writeback_centisecs=100

# --- SCHEDULER (CachyOS BORE / Deckify) ---
kernel.sched_cstate_aware=1
kernel.sched_child_runs_first=0
kernel.sched_tunable_scaling=1
kernel.numa_balancing=0

# --- RED & CONECTIVIDAD ---
net.core.somaxconn=1024
net.core.netdev_max_backlog=65536
net.core.default_qdisc=fq_codel
net.ipv4.tcp_fastopen=3
net.ipv4.ip_forward=1

# --- RECURSOS DE USUARIO (IDEs & File Watching) ---
fs.inotify.max_user_watches=524288
fs.inotify.max_user_instances=512
```

Aplicar:

```bash
sudo sysctl --system
```

### Mixxx (Alta Prioridad)

Usar en línea de comando para acceso directo:

```bash
-c 'pasuspender -- taskset -c 1-2 chrt -f 95 mixxx || mixxx'
```

---

## 16. Firefox - Configuración Avanzada

> **Nota:** En Ajustes desactivar "Rendimiento automático"

Acceder a `about:config`:

### Gráficos y Renderizado

| Preferencia                  | Valor   | Descripción                 |
| ---------------------------- | ------- | --------------------------- |
| `gfx.webrender.all`          | `true`  | Forzar WebRender            |
| `media.ffmpeg.vaapi.enabled` | `true`  | Decodificación por hardware |
| `media.av1.enabled`          | `true`  | Codecs modernos             |
| `media.ffvpx.enabled`        | `false` | Desactivar decoder interno  |
| `media.rdd-vpx.enabled`      | `false` | Forzar VA-API para VP9/VP8  |

### Rendimiento (RAM)

| Preferencia                     | Valor     | Descripción               |
| ------------------------------- | --------- | ------------------------- |
| `browser.cache.disk.enable`     | `false`   | Desactivar caché en disco |
| `browser.cache.memory.enable`   | `true`    | Forzar caché en RAM       |
| `browser.cache.memory.capacity` | `1048576` | 1GB en KB                 |

### Privacidad y Seguridad

| Preferencia                                | Valor   | Descripción                  |
| ------------------------------------------ | ------- | ---------------------------- |
| `privacy.trackingprotection.enabled`       | `true`  | Protección contra rastreo    |
| `network.cookie.cookieBehavior`            | `5`     | Total Cookie Protection      |
| `toolkit.telemetry.enabled`                | `false` | Desactivar telemetría        |
| `datareporting.healthreport.uploadEnabled` | `false` | Desactivar reportes de salud |

### Red

| Preferencia                                          | Valor   | Descripción             |
| ---------------------------------------------------- | ------- | ----------------------- |
| `network.dns.disablePrefetch`                        | `false` | Mantener prefetch DNS   |
| `network.http.max-persistent-connections-per-server` | `10`    | Conexiones persistentes |
| `network.http.pacing.requests.enabled`               | `false` | Desactivar pacing       |

---

## 17. Notas Temporales

### Montaje Disco HDD (NTFS)

Temporal:

```bash
sudo mount -t ntfs-3g /dev/sdb1 /mnt
sudo mount -t ntfs-3g -o force /dev/sdb1 /run/media/xanders/Bliblioteca\ de\ Juegos
```

Permanente (`/etc/fstab`):

```fstab
UUID=55B81DDA497FCAAD "/run/media/xanders/Biblioteca de Juegos" ntfs-3g defaults,noatime,users,umask=000 0 0
```

### VSCode Remote Tunnel

URL de acceso remoto:

```
https://vscode.dev/tunnel/dell-latitude-3410/run/media/xandnew/MSD Xanders/Documentos/Condominios-Vzla
```

### Rutas de Emulación

**AzaharPlus:**

```
/home/xandnew/.local/share/azaharplus-emu/sdmc/
```

---

## Referencias del Sistema

- **Usuario:** Xanders80
- **Email:** xanders80@gmail.com
- **Distribución:** CachyOS (Arch-based)
- **Kernel Recomendado:** deckify-lto
- **RAM:** 16GB (optimizaciones configuradas)
- **GPU:** Intel (Comet Lake)

```

Este Markdown incluye:
- **Navegación estructurada** con tabla de contenidos
- **Bloques de código** con syntax highlighting para bash, ini, php, sql, apache y fstab
- **Tablas** para la configuración de Firefox
- **Callouts** de advertencia (⚠️) y notas informativas
- **Metadatos** del sistema al final para referencia
- **Formato consistente** manteniendo todos los comandos y rutas exactas del original
```
