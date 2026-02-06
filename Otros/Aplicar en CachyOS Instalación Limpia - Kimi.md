Perfecto. Entonces validamos que **`cachyos-v3/linux-cachyos-deckify-lto`** es el kernel correcto para tu Dell Latitude 3410. A continuación tienes la **Guía Maestra de Reinstalación Optimizada**, secuenciada para que la ejecutes paso a paso tras instalar CachyOS.

---

# 📋 GUÍA MAESTRA - REINSTALACIÓN CACHYOS
## Dell Latitude 3410 | i5-10210U | 16GB RAM | Intel UHD | Triple Uso: Dev + ProAudio + Emulation

> **Versión Kernel Validada:** `deckify-lto` 6.18.7-2 (x86-64-v3)  
> **Entorno:** KDE Plasma | PipeWire | GRUB

---

## FASE 1: POST-INSTALACIÓN INMEDIATA

### 1.1 Optimizar Mirrors y Sistema Base
```bash
# Actualizar mirrorlist a los más rápidos (herramienta nativa CachyOS)
sudo pacman -Sy pacman-contrib cachyos-rate-mirrors
sudo cachyos-rate-mirrors

# Actualización completa inicial
sudo pacman -Syyu

# Instalar base-devel y headers del kernel deckify
sudo pacman -S base-devel linux-cachyos-deckify-lto-headers
```

### 1.2 Configuración GRUB para Intel + Deckify
```bash
sudo nano /etc/default/grub
```

**Reemplazar** la línea `GRUB_CMDLINE_LINUX_DEFAULT` por:
```ini
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash intel_pstate=active intel_idle.max_cstate=2 i915.enable_guc=3 i915.enable_fbc=1 i915.max_vfs=7 mitigations=off nowatchdog nmi_watchdog=0 modprobe.blacklist=pcspkr"
```

**Aplicar cambios:**
```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

---

## FASE 2: SISTEMA BASE OPTIMIZADO

### 2.1 ZRAM + Swap Emergencia (16GB RAM)
```bash
sudo nano /etc/systemd/zram-generator.conf
```

Contenido:
```ini
[zram0]
zram-size = min(ram / 2, 4096)
compression-algorithm = zstd
swap-priority = 100
```

**Swap de emergencia en disco (2GB):**
```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
echo '/swapfile none swap defaults 0 0' | sudo tee -a /etc/fstab

# Activar
sudo systemctl daemon-reload
sudo systemctl restart systemd-zram-setup@zram0.service
sudo swapon -a
```

### 2.2 Sysctl Híbrido (Dev + Real-time Audio)
```bash
sudo nano /etc/sysctl.d/99-latitude-opt.conf
```

Contenido:
```ini
# VM: Agresivo para compilaciones, conservador swap
vm.swappiness=10
vm.vfs_cache_pressure=50
vm.dirty_ratio=25
vm.dirty_background_ratio=10
vm.dirty_expire_centisecs=300
vm.dirty_writeback_centisecs=100

# Networking Dev
net.core.netdev_max_backlog = 65536
net.core.somaxconn = 32768
net.ipv4.tcp_fastopen = 3

# Kernel Deckify (BORE already optimized)
kernel.numa_balancing = 0
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512
```

```bash
sudo sysctl --system
```

### 2.3 Gestión Térmica y Prioridades
```bash
# Instalar gestores de energía y prioridad
sudo pacman -S tlp tlp-rdw thermald ananicy-cpp
sudo systemctl enable --now tlp thermald ananicy-cpp

# Config TLP para rendimiento en AC, silencio en batería
sudo nano /etc/tlp.conf
```

Editar estas líneas:
```ini
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=powersave
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=0
CPU_ENERGY_PERF_POLICY_ON_AC=performance
CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power
```

### 2.4 Reglas Ananicy-CPP Personalizadas
```bash
sudo mkdir -p /etc/ananicy.d/
sudo nano /etc/ananicy.d/latitude-rules.rules
```

Contenido:
```ini
# Desarrollo IDEs
{ "name": "code-oss", "type": "Doc-View" }
{ "name": "code", "type": "Doc-View" }
{ "name": "idea", "type": "Doc-View" }
{ "name": "studio", "type": "Doc-View" }

# Audio/DJ - Prioridad máxima
{ "name": "mixxx", "type": "LowLatency_RT" }
{ "name": "pipewire", "type": "LowLatency_RT" }
{ "name": "pipewire-pulse", "type": "LowLatency_RT" }

# Emuladores - Evitar stuttering
{ "name": "pcsx2-qt", "type": "Game" }
{ "name": "ppsspp", "type": "Game" }
{ "name": "dolphin-emu", "type": "Game" }
{ "name": "retroarch", "type": "Game" }
```

---

## FASE 3: TERMINAL Y HERRAMIENTAS DEV

### 3.1 Shell Zsh + Starship
```bash
sudo pacman -S zsh starship eza bat ripgrep fd procs bottom btop
chsh -s $(which zsh)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Configurar Starship
mkdir -p ~/.config
starship preset nerd-font-symbols -o ~/.config/starship.toml
```

Añadir a `~/.zshrc`:
```bash
# Al final del archivo
eval "$(starship init zsh)"

# Aliases útiles
alias ls='eza --icons=auto --group-directories-first'
alias ll='eza -la --icons=auto --sort=modified'
alias cat='bat --style=plain'
alias top='btop'
```

### 3.2 Gestión de Versiones (Mise)
```bash
sudo pacman -S mise
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc

# Instalar toolchains
mise plugin add java nodejs dotnet-core php composer
mise install java@21 nodejs@20 dotnet-core@8.0 php@8.3
mise use --global java@21 nodejs@20 dotnet-core@8.0 php@8.3

# Re-cargar shell
exec zsh
```

---

## FASE 4: STACK DESARROLLO COMPLETO

### 4.1 .NET 8/9
```bash
# Ya instalado via mise, pero agregamos ASP.NET y herramientas
sudo pacman -S aspnet-runtime dotnet-sdk

# Variables de rendimiento
echo 'export DOTNET_CLI_TELEMETRY_OPTOUT=1' >> ~/.zshrc
echo 'export MSBuildEnableWorkloadResolver=false' >> ~/.zshrc
```

### 4.2 PHP/Laravel/WordPress
```bash
sudo pacman -S php php-fpm php-intl php-gd php-pgsql php-sqlite php-redis php-xsl php-zip php-curl php-bcmath php-mbstring composer

# Instalar Laravel CLI
composer global require laravel/installer
echo 'export PATH="$HOME/.config/composer/vendor/bin:$PATH"' >> ~/.zshrc

# Configurar PHP para desarrollo
sudo nano /etc/php/php.ini
```

Modificar:
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
opcache.validate_timestamps=1
```

### 4.3 Java/Kotlin/Android
```bash
sudo pacman -S kotlin gradle maven

# Android Studio (appimage o native)
yay -S android-studio  # O descargar tarball oficial si prefieres control manual
```

### 4.4 Containers (Podman/Distrobox)
```bash
sudo pacman -S podman podman-compose podman-docker distrobox
sudo systemctl enable --now podman.socket

# Permisos sin sudo
sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 $USER
```

---

## FASE 5: ENTORNO GRÁFICO KDE Y APARIENCIA

### 5.1 Temas y Configuración Visual
```bash
# Dependencias
sudo pacman -S kvantum qt6ct gnome-themes-extra

# Instalar desde System Settings > Appearance > Get New...
# - Plasma Style: Kdewaita
# - Application Style: Kvantum-dark
# - Window Decorations: Clay
# - Icons: Win11-nord-dark (o Tela-circle-black para menos consumo)
# - Cursor: Vimix-cursors
# - Splash Screen: Vinyl
```

### 5.2 Firefox Acelerado (Intel UHD)
```bash
sudo pacman -S cachyos-firefox-settings intel-gpu-tools gstreamer-vaapi libva-intel-driver libva-utils
```

Configurar en `about:config`:
```
media.ffmpeg.vaapi.enabled = true
media.ffvpx.enabled = false
gfx.webrender.all = true
layers.acceleration.force-enabled = true
```

---

## FASE 6: AUDIO PROFESIONAL (DJ)

### 6.1 PipeWire Low-Latency
```bash
sudo pacman -S mixxx pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber calf jack2
```

Configuración:
```bash
mkdir -p ~/.config/pipewire/pipewire.conf.d/
nano ~/.config/pipewire/pipewire.conf.d/low-latency.conf
```

Contenido:
```json
context.properties = {
    default.clock.rate = 48000
    default.clock.quantum = 256
    default.clock.min-quantum = 128
    default.clock.max-quantum = 512
}
```

### 6.2 Prioridad Real-time
```bash
sudo mkdir -p /etc/security/limits.d/
echo '@audio - rtprio 95' | sudo tee /etc/security/limits.d/audio.conf
echo '@audio - memlock unlimited' | sudo tee -a /etc/security/limits.d/audio.conf
sudo usermod -a -G audio $USER
```

### 6.3 Script Lanzamiento Mixxx (RT)
Añadir a `~/.zshrc`:
```bash
alias mixxx-rt='pw-metadata -n settings 0 clock.force-rate 48000 && chrt -f 90 ionice -c1 -n0 mixxx'
```

---

## FASE 7: EMULACIÓN OPTIMIZADA (Intel UHD)

### 7.1 Instalación Stack Emuladores
```bash
sudo pacman -S \
    retroarch libretro-core-info \
    dolphin-emu \
    pcsx2 \
    ppsspp \
    mupen64plus \
    mednafen mednaffe \
    scummvm \
    fs-uae
```

### 7.2 Configuración Intel UHD (Comet Lake)
Crear lanzadores optimizados:
```bash
mkdir -p ~/.local/bin

# PCSX2 Optimizado
cat > ~/.local/bin/pcsx2-intel << 'EOF'
#!/bin/bash
export MESA_GL_VERSION_OVERRIDE="4.6"
export vblank_mode=0
chrt -f 75 nice -n -5 /usr/bin/pcsx2-qt "$@"
EOF

# Dolphin Optimizado  
cat > ~/.local/bin/dolphin-intel << 'EOF'
#!/bin/bash
export vblank_mode=0
chrt -f 75 /usr/bin/dolphin-emu "$@"
EOF

chmod +x ~/.local/bin/pcsx2-intel ~/.local/bin/dolphin-intel
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
```

**Configuración explícita:**
- **PCSX2**: Backend Vulkan, Internal Resolution 1x Native (PS2 es pesado para UHD), Anisotropic Filtering Off.
- **Dolphin**: Backend Vulkan, Compile Shaders Before Starting: ON, Native resolution.
- **PPSSPP**: Backend Vulkan, 2x PSP (1080p max) - no más.

---

## FASE 8: BASES DE DATOS Y VIRTUALIZACIÓN

### 8.1 MariaDB (Config 16GB RAM)
```bash
sudo pacman -S mariadb
sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
sudo systemctl enable --now mariadb

# Optimizar para desarrollo local
sudo nano /etc/my.cnf.d/server.cnf
```

Añadir en `[mysqld]`:
```ini
innodb_buffer_pool_size = 2G
innodb_log_file_size = 256M
query_cache_size = 64M
tmp_table_size = 128M
```

```bash
sudo mysql_secure_installation
```

### 8.2 PostgreSQL
```bash
sudo pacman -S postgresql
sudo mkdir /var/lib/postgres/data
sudo chown postgres:postgres /var/lib/postgres/data
sudo -iu postgres initdb -E UTF8 -D '/var/lib/postgres/data'
sudo systemctl enable --now postgresql

# Crear usuario dev
sudo -iu postgres psql -c "CREATE USER $USER WITH SUPERUSER PASSWORD 'tu_password_segura';"
sudo -iu postgres psql -c "CREATE DATABASE $USER OWNER $USER;"
```

### 8.3 KVM/QEMU (virt-manager)
```bash
sudo pacman -S qemu-base virt-manager virt-viewer vde2 bridge-utils dnsmasq edk2-ovmf libosinfo

# Configurar libvirt
sudo nano /etc/libvirt/libvirtd.conf
```

Descomentar:
```ini
unix_sock_group = "libvirt"
unix_sock_rw_perms = "0770"
```

```bash
sudo usermod -aG libvirt,kvm $USER
sudo systemctl enable --now libvirtd
sudo virt-host-validate  # Verificación
```

### 8.4 Waydroid (Android) + LibHoudini
```bash
sudo pacman -S waydroid
sudo waydroid init -s GAPPS

# Límites de recursos (4GB RAM para Waydroid)
sudo mkdir -p /etc/systemd/system/waydroid-container.service.d/
sudo tee /etc/systemd/system/waydroid-container.service.d/override.conf << EOF
[Service]
MemoryMax=4G
MemoryHigh=3.5G
AllowedCPUs=0-3
CPUWeight=150
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now waydroid-container

# Instalar LibHoudini (traducción ARM)
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

## FASE 9: SEGURIDAD Y FIREWALL

```bash
sudo pacman -S ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing

# KDE Connect
sudo ufw allow 1714:1764/tcp
sudo ufw allow 1714:1764/udp

# Waydroid
sudo ufw allow 53
sudo ufw allow 67

# SSH (opcional)
sudo ufw allow 22/tcp

sudo ufw enable
sudo systemctl enable ufw
```

---

## FASE 10: CHECKLIST FINAL

Script de validación post-instalación:
```bash
cat > ~/validar-sistema.sh << 'EOF'
#!/bin/bash
echo "=== VALIDACIÓN LATITUDE 3410 ==="
echo "Kernel:" && uname -r
echo -e "\nTemperaturas:" && sensors | grep -E "Core|temp" | head -4
echo -e "\nZRAM:" && zramctl && free -h | grep Mem
echo -e "\nGPU:" && vainfo 2>/dev/null | grep -E "VAProfileH264|iHD" | head -2
echo -e "\nVirt:" && sudo virt-host-validate 2>/dev/null | grep -c "FAIL" && echo "KVM OK (0 fails esperados)"
echo -e "\nDev Tools:" && echo "Node $(node -v), PHP $(php -v | head -1 | cut -d' ' -f2), Java $(java -version 2>&1 | head -1 | cut -d' ' -f3 | tr -d '"'), .NET $(dotnet --version)"
echo -e "\nWaydroid:" && waydroid status 2>/dev/null | grep Session
echo -e "\n=== LISTO ==="
EOF
chmod +x ~/validar-sistema.sh
```

**Ejecutar tras reiniciar:**
```bash
~/validar-sistema.sh
```

---

## 🎛️ NOTAS FINALES

1. **Kernel**: Mantén `deckify-lto`. Si alguna vez necesitas modo "ultra-batería", instala paralelo `linux-cachyos` y eliges en el GRUB al bootear.
2. **Temperaturas**: El i5-10210U con deckify se comporta bien, pero si haces builds de 30+ minutos, pon la laptop sobre superficie dura o usa base refrigerante.
3. **PS2 Emulation**: Con Intel UHD, mantén PCSX2 en 1x Native Resolution. Juegos pesados (God of War 2) pueden ir a 40-50fps, usa "EE Cyclerate" en -1 o -2 para compensar si es necesario.

Guárdala en un archivo `.md` o imprímela. ¿Necesitas que profundice en alguna sección específica antes de tu reinstalación?
