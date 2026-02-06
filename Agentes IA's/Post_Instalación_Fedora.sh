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
        exit 1
    fi
    imprimir_estado "$VERDE" "${paquetes[*]} instalado(s) correctamente."
}

# --- Lógica Principal del Script ---

# 1. Verificar privilegios de root.
verificar_root

imprimir_estado "$AMARILLO" "Iniciando el proceso de configuración del sistema..."

# 2. Habilitar pwfeedback en sudoers.
imprimir_estado "$AZUL" "Actualizando el archivo /etc/sudoers para habilitar 'pwfeedback'..."
if ! grep -q "Defaults.*pwfeedback" /etc/sudoers; then
    # Usamos un archivo temporal para evitar problemas de permisos con tee y sudo.
    # También es más seguro modificar sudoers con visudo o un método que valide la sintaxis.
    # Sin embargo, para este script, si el archivo no existe, lo creamos.
    if echo "Defaults env_reset,pwfeedback" | sudo tee -a /etc/sudoers > /dev/null; then
        imprimir_estado "$VERDE" "La línea 'Defaults env_reset,pwfeedback' se ha agregado correctamente a /etc/sudoers."
    else
        imprimir_estado "$ROJO" "Error al agregar la línea a /etc/sudoers. Por favor, revisa los permisos."
        exit 1
    fi
else
    imprimir_estado "$VERDE" "La línea 'Defaults env_reset,pwfeedback' ya existe en /etc/sudoers."
fi

# 3. Habilitar repositorios RPM Fusion.
imprimir_estado "$AZUL" "Habilitando repositorios RPM Fusion Free y Nonfree..."
RPMFUSION_FREE="https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
RPMFUSION_NONFREE="https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
instalar_dnf "$RPMFUSION_FREE" "$RPMFUSION_NONFREE"

# 4. Instalar repositorio de Terra (FyraLabs).
imprimir_estado "$AZUL" "Instalando el repositorio de Terra (FyraLabs)..."
if ! dnf install -y --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release; then
    imprimir_estado "$ROJO" "Error al instalar el repositorio de Terra. Asegúrate de que la URL sea correcta o verifica tu conexión."
    exit 1
fi
imprimir_estado "$VERDE" "Repositorio de Terra instalado correctamente."

# 5. Actualizar el grupo 'core'.
imprimir_estado "$AZUL" "Actualizando el grupo de paquetes 'core'..."
if ! dnf group upgrade -y core; then
    imprimir_estado "$ROJO" "Error al actualizar el grupo 'core'."
    exit 1
fi
imprimir_estado "$VERDE" "Grupo 'core' actualizado correctamente."

# --- Mensaje de Finalización y Recomendaciones ---

imprimir_estado "$VERDE" "Proceso de configuración completado exitosamente."

imprimir_estado "$AMARILLO" "--- Recomendaciones Post-Configuración ---"
imprimir_estado "$AMARILLO" "1. Verifica que los repositorios se hayan habilitado correctamente con:"
imprimir_estado "$AMARILLO" "   ${AZUL}dnf repolist${RESET}"
imprimir_estado "$AMARILLO" "2. Si encuentras problemas, revisa los logs de DNF en:"
imprimir_estado "$AMARILLO" "   ${AZUL}/var/log/dnf.log${RESET}"
imprimir_estado "$AMARILLO" "3. Considera reiniciar tu sistema para que todos los cambios se apliquen completamente."
imprimir_estado "$AMARILLO" "   ${AZUL}sudo reboot${RESET}"
