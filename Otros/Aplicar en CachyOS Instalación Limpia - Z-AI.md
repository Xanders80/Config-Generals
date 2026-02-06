

¡Excelente elección de equipo y distro! El Dell Latitude 3410 con ese i5-10210U (Comet Lake) es un equipo muy capaz gracias a sus 8 hilos y los 16GB de RAM. **CachyOS** es la decisión perfecta para sacarle provecho, ya que sus kernels optimizados (BORE) y el uso de compilaciones LTO harán que la IDE, la emulación y el DJing fluyan con mucha suavidad.

He refinado, corregido y organizado tu guía en un flujo lógico de "Post-Instalación". He añadido configuraciones críticas para Audio (DJing) y corregido nombres de paquetes y dependencias para que todo funcione a la primera.

Aquí tienes tu guía definitiva para **CachyOS (Arch Based)** en el Dell Latitude 3410.

---

# 🚀 Guía Maestra de Post-Instalación: CachyOS (Dev + DJ + Emu)

## FASE 1: Configuración Base, Repositorios y Apariencia

### 1. Preparación del Sistema y Chaotic-AUR
Primero, actualizamos el sistema base y agregamos el repositorio **Chaotic-AUR**, esencial para obtener paquetes precompilados de AUR (como emuladores y apps de Android) sin esperar horas de compilación.

```bash
# 1. Actualizar sistema base
sudo pacman -Syu

# 2. Importar llaves y agregar Chaotic-AUR
sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB

sudo pacman -U \
  'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
  'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

# 3. Verificar y activar repositorio
sudo nano /etc/pacman.conf
```
*Agrega esto al final del archivo:*
```ini
[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
```

```bash
# 4. Instalar helper de AUR (Paru) y refrescar mirrors
sudo pacman -S paru --needed
sudo pacman -Syyu cachyos-mirrorlist
```

### 2. Configuración Visual (KDE Plasma)
Instala los temas y personaliza el entorno para ese look moderno tipo Windows 11/Nord que solicitaste.

```bash
# Instalar temas e iconos desde repositorios y AUR
paru -S kdewaita clay-decoration-kde win11-nord-dark-icon-theme vimix-cursor-kde sddm-theme-vinyl

# Aplicar configuraciones (Requiere reiniciar o recargar Plasma)
# Configuración manual recomendada desde: Apariencia -> Estilo de Plasma -> KdeWaita
# Decoraciones de Ventana -> Clay
# Iconos -> Win11-Nord-Dark
# Tema de Cursor -> Vimix (Negro)
# Pantalla de Bienvenida -> Vinyl
```

### 3. Terminal Pro (Starship)
Configura una terminal potente y rápida.

```bash
sudo pacman -S starship

# Configuración para Zsh (Por defecto en CachyOS suele ser zsh, si usas bash cambia el archivo)
echo 'eval "$(starship init zsh)"' >> ~/.zshrc

# Descargar configuración avanzada
starship preset nerd-font-symbols -o ~/.config/starship.toml

# Recargar terminal
source ~/.zshrc
```

### 4. Feedback de Contraseña (Sudo)
```bash
sudo nano /etc/sudoers
```
*Busca la línea de `Defaults` y agrégala o modifícala para que quede así:*
```plaintext
Defaults    env_reset,pwfeedback
```

---

## FASE 2: Kernel, Rendimiento y Tuning del Sistema

Para un equipo con esta CPU, el kernel **deckify-lto** y el scheduler **BORE** son ideales.

### 5. Instalación del Kernel Deckify y Tuning
```bash
# Instalar kernel deckify-lto y herramientas de CPU
sudo pacman -S linux-cachyos-deckify-lto linux-cachyos-deckify-lto-headers
sudo pacman -S cpupower

# Ajustar flags del gobernador de energía para rendimiento máximo
sudo cpupower frequency-set -g performance
```

### 6. Ajustes del Bootloader (GRUB) y Virtualización
Necesitamos activar IOMMU para virtualización y mejorar la gráfica Intel.

```bash
sudo nano /etc/default/grub
```
*Modifica la línea `GRUB_CMDLINE_LINUX_DEFAULT` o `GRUB_CMDLINE_LINUX`:*
```plaintext
GRUB_CMDLINE_LINUX="intel_iommu=on iommu=pt i915.enable_guc=2 i915.enable_fbc=1 mitigations=off"
```
*Nota: `mitigations=off` es opcional pero ayuda al rendimiento en CPU antiguas.*

```bash
# Regenerar GRUB
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### 7. Tuning Avanzado de Memoria y Red (Sysctl)
Aplicamos las configuraciones para tu hardware específico (16GB RAM + HDD/SSD).

```bash
sudo nano /etc/sysctl.d/99-performance.conf
```
*Pega lo siguiente:*
```ini
# Afinamiento para CachyOS BORE Scheduler
kernel.sched_cstate_aware=1
kernel.sched_child_runs_first=0

# Memoria: Mantener caché para IDEs y compilar, evitar swap prematuro
vm.vfs_cache_pressure=50
vm.swappiness=10

# I/O: Compilaciones grandes y cargas de DB
vm.dirty_background_ratio=15
vm.dirty_ratio=40

# Afinamiento de Red
net.core.default_qdisc=fq_codel
```

```bash
# Aplicar cambios
sudo sysctl --system
```

---

## FASE 3: Entorno de Desarrollo (Full Stack)

### 8. Instalación de Herramientas de Desarrollo
Instalamos VS Code, DBeaver, y todos los lenguajes solicitados.

```bash
# Herramientas Principales
sudo pacman -S visual-studio-code-bin dbeaver git jdk-openjdk jre-openjdk nodejs npm dotnet-sdk php php-apache php-fpm composer mariadb postgresql

# Herramientas extra (Android, etc) - Opcional y pesado
# paru -S android-studio android-sdk-platform-tools
```

### 9. Configuración de Git
```bash
git config --global user.name "Xanders80"
git config --global user.email "xanders80@gmail.com"
git config --global core.editor nano
```

### 10. Configuración PHP + Apache + MariaDB
*Para PHP/Laravel/WordPress.*

**Configurar PHP:**
```bash
sudo nano /etc/php/php.ini
```
*Descomenta y modifica estos valores:*
```ini
display_errors = On
error_reporting = E_ALL
memory_limit = 256M
upload_max_filesize = 128M
post_max_size = 128M
extension=pdo_mysql
extension=mysqli
extension=bcmath
opcache.enable=1
opcache.memory_consumption=256
opcache.interned_strings_buffer=32
```

**Configurar Apache:**
```bash
sudo nano /etc/httpd/conf/httpd.conf
```
1. Asegúrate de cargar el módulo prefork (necesario para php-apache):
   ```apache
   LoadModule mpm_prefork_module modules/mod_mpm_prefork.so
   # LoadModule mpm_event_module modules/mod_mpm_event.so  <-- Comentar este
   ```
2. Al final del archivo, carga PHP:
   ```apache
   LoadModule php_module modules/libphp.so
   AddHandler php-script .php
   Include conf/extra/php_module.conf
   ServerName localhost
   ```

**Iniciar Servicios y Base de Datos:**
```bash
# MariaDB
sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
sudo systemctl enable --now mariadb
sudo mariadb-secure-installation

# Apache y PHP-FPM
sudo systemctl enable --now httpd php-fpm

# PostgreSQL (Si la necesitas besides MariaDB)
sudo -iu postgres
initdb --locale=$LANG -E UTF8 -D '/var/lib/postgres/data'
exit
sudo systemctl enable --now postgresql
```

### 11. Configuración WordPress (Opcional)
```bash
# Crear DB MariaDB
sudo mariadb -u root -p
```
*SQL:*
```sql
CREATE DATABASE wordpress;
CREATE USER 'wpuser'@'localhost' IDENTIFIED BY 'Wpu*123';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

```bash
# Descargar WP (En tu carpeta de usuario o /srv/http)
cd /srv/http
sudo git clone https://github.com/WordPress/WordPress.git wordpress
sudo chown -R http:http /srv/http/wordpress

# Configurar Apache para WP
echo "Alias /wordpress \"/srv/http/wordpress/\"" | sudo tee -a /etc/httpd/conf/extra/httpd-wordpress.conf
echo "<Directory \"/srv/http/wordpress/\">" | sudo tee -a /etc/httpd/conf/extra/httpd-wordpress.conf
echo "    AllowOverride All" | sudo tee -a /etc/httpd/conf/extra/httpd-wordpress.conf
echo "    Require all granted" | sudo tee -a /etc/httpd/conf/extra/httpd-wordpress.conf
echo "</Directory>" | sudo tee -a /etc/httpd/conf/extra/httpd-wordpress.conf

# Incluir en httpd.conf
echo "Include conf/extra/httpd-wordpress.conf" | sudo tee -a /etc/httpd/conf/httpd.conf

# Reiniciar Apache
sudo systemctl restart httpd
```

---

## FASE 4: Audio Profesional (DJ con Mixxx)

Para evitar "cortes" en el audio (Xruns) al usar USBs o tiempo real, necesitamos dar prioridad al usuario.

### 12. Configuración de Audio en Tiempo Real
```bash
# Añadir usuario a grupo audio
sudo usermod -aG audio $USER

# Configurar límites de memoria y prioridad para audio
sudo nano /etc/security/limits.conf
```
*Agregar al final:*
```plaintext
@audio   -  rtprio     95
@audio   -  memlock    unlimited
```

### 13. Comando de Lanzamiento Mixxx Optimizado
Este comando aísla 2 núcleos de la CPU y le da la máxima prioridad posible para que el DJing nunca se trabe.

```bash
# Crea un alias o un script para lanzar Mixxx
echo 'alias mixxx-pro="pasuspender -- taskset -c 1-2 chrt -f 95 mixxx || mixxx"' >> ~/.zshrc
source ~/.zshrc
```
*Nota: `pasuspender` suspende PipeWire temporalmente si usas PulseAudio layer. En sistemas modernos con PipeWire, asegúrate de configurar la latencia en las preferencias de Mixxx (baja la Latencia del Buffer a 5-10ms si el HW lo permite).*

---

## FASE 5: Emulación y Gaming

### 14. Instalación de Emuladores
Instalamos desde Pacman y Chaotic-AUR (ahorrando compilación).

```bash
# Emuladores desde Repositorios
sudo pacman -S retroarch libretro-beetle-psx libretro-snes9x mednafen stella scummvm ppsspp dolphin-emu mupen64plus

# Emuladores desde AUR (Versiones optimizadas/AVX)
paru -S desmume-avx-git ppsspp-avx-git mupen64plus-qt citra-git azaharplus-appimage
```
*Nota sobre Azahar (Switch): Tu Intel UHD 620 puede correr juegos 2D de Switch, pero juegos 3D pesados correrán a baja resolución. `azaharplus` es una excelente optimización.*

### 15. Aceleración Gráfica Intel (VAAPI)
Crucial para emulación de PS2 (PCSX2) y video.
```bash
sudo pacman -S libva-intel-driver libva-utils intel-gpu-tools

# Forzar driver VAAPI correcto
echo 'export LIBVA_DRIVER_NAME=iHD' | sudo tee /etc/profile.d/libva.sh
source /etc/profile.d/libva.sh

# Probar
vainfo
```

---

## FASE 6: Virtualización y Android (Waydroid)

### 16. Configuración de Libvirt y KVM
```bash
# Activar servicios
sudo usermod -aG libvirt,kvm $USER
sudo systemctl enable --now libvirtd

# Configurar libvirtd
sudo nano /etc/libvirt/libvirtd.conf
```
*Descomentar:*
```ini
unix_sock_group = "libvirt"
unix_sock_rw_perms = "0770"
```

```bash
# Validar
virt-host-validate
```

### 17. Waydroid + Libhoudini (Apps Android)
```bash
# Instalar Waydroid
sudo pacman -S waydroid

# Script para libhoudini (mejora compatibilidad de apps)
git clone https://github.com/casualsnek/waydroid_script
cd waydroid_script
python3 -m venv venv
venv/bin/pip install -r requirements.txt
sudo venv/bin/python3 main.py
```

### 18. Optimización de Waydroid
Para darle más RAM y CPU a las apps de DJ o Desarrollo Android.

```bash
# Detener servicio
sudo systemctl stop waydroid-container

# Crear override
sudo mkdir -p /etc/systemd/system/waydroid-container.service.d
sudo nano /etc/systemd/system/waydroid-container.service.d/override.conf
```
*Pegar:*
```ini
[Service]
MemoryMax=4G
MemoryHigh=3.5G
MemorySwapMax=512M
AllowedCPUs=0,1,2,3
IOWeight=500
```

```bash
# Reiniciar
sudo systemctl daemon-reload
sudo systemctl start waydroid-container
```

### 19. Firewall (UFW) para KDE Connect y Waydroid
```bash
sudo pacman -S ufw
sudo ufw default allow FORWARD
sudo ufw allow 67 # DNS Waydroid
sudo ufw allow 53
sudo ufw allow 1714:1764/tcp # KDE Connect
sudo ufw allow 1714:1764/udp
sudo ufw enable
```

---

## FASE 7: Navegación y Utilidades Finales

### 20. Firefox "Racing"
```bash
# Abrir about:config y aplicar los siguientes tweaks
```
*Ajustes Clave para Linux/Wayland:*
```
gfx.webrender.all = true
gfx.webrender.compositor = true
media.ffmpeg.vaapi.enabled = true
media.rdd-vpx.enabled = true
widget.non-native-theme.enabled = false
privacy.resistFingerprinting = false
```
*Ajustes de Rendimiento (Red y Cache):*
```
network.http.max-connections = 96
network.http.max-persistent-connections-per-server = 10
browser.cache.disk.capacity = 512000
browser.cache.memory.capacity = 1048576
content.notify.interval = 100000
```

### 21. Utilidades Varias
```bash
sudo pacman -S htop neofetch bleachbit gparted telegram-desktop
```

---

**Notas Finales para el Dell Latitude 3410:**
1.  **Batería:** Si usas el kernel `deckify-lto`, el rendimiento será máximo, pero la batería durará menos. Para viajar, considera usar `linux-cachyos-bore` normal.
2.  **Temperaturas:** El i5-10210U se calienta al compilar o emular PS2. Vigila con `sensors` (instalar `lm_sensors`).
3.  **Waydroid:** Asegúrate de activar la "Virtualización" en el BIOS de Dell si experimentas errores de KVM.

¡Disfruta tu máquina optimizada! Es una bestia para desarrollo con estas configuraciones.
