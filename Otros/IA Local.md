# 🚀 **Guía Completa: OpenCode + llama.cpp-vulkan en CachyOS (FINAL)**

**Hardware**: Dell Latitude 3410 | Intel i5-10210U | 16GB RAM | Intel UHD Graphics | CachyOS kernel 6.19.5 | KDE Plasma 6.6.2 | Fish Shell

## 📋 **Índice**

1. [Instalación llama.cpp-vulkan](#1-instalación-llamacpp-vulkan)
2. [Configuración Fish Functions](#2-configuración-fish-functions)
3. [Script OpenCode + Auto-Servidor](#3-script-opencode--auto-servidor)
4. [Integración Acceso Directo KDE](#4-integración-acceso-directo-kde)
5. [Configuración Anti-Loop](#5-configuración-anti-loop)
6. [Monitoreo y Comandos Útiles](#6-monitoreo-y-comandos-útiles)

---

## **1. Instalación llama.cpp-vulkan**

### **Paso 1.1: Dependencias Vulkan**

```fish
sudo pacman -S --needed base-devel cmake git vulkan-headers vulkan-intel vulkan-validation-layers
```

### **Paso 1.2: Compilación Manual (Optimizada CachyOS)**

```fish
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp
cmake -B build -DGGML_VULKAN=1 -DGGML_BLAS=ON -DCMAKE_BUILD_TYPE=Release -j$(nproc)
sudo cmake --install build --config Release --prefix=/usr/local
sudo cp -f build/bin/* /usr/local/bin/
fish_add_path -p /usr/local/bin
```

### **Paso 1.3: Modelo Optimizado (Qwen2.5-3B)**

```fish
mkdir -p ~/models/llama-cpp
cd ~/models/llama-cpp
huggingface-cli download Qwen/Qwen2.5-3B-Instruct-GGUF qwen2.5-3b-instruct-q5_k_m.gguf --local-dir .
```

---

## **2. Configuración Fish Functions**

### **Función `llama` Principal (Anti-Loop)**

```fish
cat > ~/.config/fish/functions/llama.fish << 'EOF'
function llama
    set -l model ~/models/llama-cpp/qwen2.5-3b-instruct-q5_k_m.gguf
    set -l threads 8

    switch $argv[1]
        case server
            llama-server -m $model --host 0.0.0.0 --port 8080 \
                -c 2048 -t $threads -ngl 10 \
                --temp 0.7 --top-p 0.9 --repeat-penalty 1.15 \
                --ctx-size 2048 --batch-size 512
        case '*'
            llama-cli -m $model -p "$argv[2..]" -n 256 \
                -c 4096 -t $threads -ngl 10 \
                --temp 0.7 --top-p 0.9
    end
end
EOF
funcsave llama
```

### **Función `llama-status`**

```fish
cat > ~/.config/fish/functions/llama-status.fish << 'EOF'
function llama-status
    echo "🔍 Verificando llama-server..."
    if pgrep -f "llama-server.*8080" > /dev/null
        set PID (pgrep -f "llama-server.*8080")
        set RAM (ps -o rss= -p $PID | awk '{printf "%.1f GB\n", $1/1024/1024}')
        echo "✅ ACTIVO (PID: $PID) | RAM: $RAM"
        curl -s --max-time 2 http://localhost:8080/v1/models | jq '.data[0].id // "No models"'
    else
        echo "❌ INACTIVO"
    end
end
EOF
funcsave llama-status
```

---

## **3. Script OpenCode + Auto-Servidor**

### **`~/.local/bin/opencode-gui-smart.fish` (GUI Completo)**

```fish
cat > ~/.local/bin/opencode-gui-smart.fish << 'EOF'
#!/usr/bin/env fish
set SERVER_PID_FILE /tmp/llama-server-opencode.pid
set SERVER_PORT 8080
set MODEL_PATH ~/models/llama-cpp/qwen2.5-3b-instruct-q5_k_m.gguf
set THREADS 8

function start_llama_server
    if pgrep -f "llama-server.*$SERVER_PORT" > /dev/null
        echo "✅ Servidor ya activo"
        return 0
    end
    rm -f $SERVER_PID_FILE
    setsid llama-server -m $MODEL_PATH --host 0.0.0.0 --port $SERVER_PORT \
        -c 2048 -t $THREADS -ngl 10 --temp 0.7 --top-p 0.9 --repeat-penalty 1.15 \
        > /tmp/llama-server-gui.log 2>&1 &
    echo $last_pid > $SERVER_PID_FILE
    sleep 3
    curl -s http://localhost:$SERVER_PORT/v1/models > /dev/null && echo "✅ Listo!" || echo "❌ Error"
end

function stop_llama_server
    pkill -f "llama-server.*$SERVER_PORT" 2>/dev/null
    rm -f $SERVER_PID_FILE
end

start_llama_server
echo "🎨 Abriendo opencode-desktop..."
gtk-launch opencode-desktop 2>/dev/null || opencode

while pgrep -f opencode-desktop > /dev/null 2>/dev/null; do sleep 1; end
stop_llama_server
EOF
chmod +x ~/.local/bin/opencode-gui-smart.fish
```

---

## **4. Integración Acceso Directo KDE**

### **Modificar Acceso Directo EXISTENTE**

```fish
# 1. Localizar
find /usr/share/applications ~/.local/share/applications -name "*opencode*" 2>/dev/null

# 2. Modificar Exec= (ejemplo: /usr/share/applications/opencode-desktop.desktop)
sudo sed -i 's|^Exec=.*|Exec=/home/xandnew/.local/bin/opencode-gui-smart.fish %U|' /usr/share/applications/opencode-desktop.desktop

# 3. Actualizar KDE cache
kbuildsycoca6 --noincremental
```

**Resultado**: Click en **mismo icono OpenCode** → inicia servidor + GUI → cierra todo al salir.

---

## **5. Configuración OpenCode Anti-Loop**

### **OpenCode Settings (GUI)**

```
Chat Settings:
❌ Auto-submit / Continue generating
✅ Stop on new line
🔢 Max tokens: 256
⏱️ Timeout: 20s
🌡️ Temperature: 0.7
```

### **Configuración JSON** (`~/.config/opencode/opencode.json`)

```json
{
  "provider": {
    "local-llama": {
      "baseURL": "http://localhost:8080/v1",
      "models": {
        "qwen2.5-local": {
          "contextLength": 2048,
          "completionOptions": {
            "temperature": 0.7,
            "topP": 0.9,
            "maxTokens": 256
          }
        }
      }
    }
  }
}
```

---

## **6. Monitoreo y Comandos Útiles**

### **Comandos Esenciales**

```fish
llama-status           # Estado servidor
llama server &         # Servidor manual
llama "Pregunta"       # Chat rápido
pkill -f "llama-server" # Parar servidor
cat /tmp/llama-server-gui.log  # Logs
```

### **Alias Rápidos** (`~/.config/fish/config.fish`)

```fish
alias opencode=~/.local/bin/opencode-gui-smart.fish
alias llama-status='pgrep -f "llama-server.*8080" && echo "✅" || echo "❌"'
```

### **Rendimiento Esperado** (Tu Hardware)

```
📊 Qwen2.5-3B Q5_K_M
💻 i5-10210U + UHD Graphics
⚡ 25-40 tok/s (CPU + Vulkan)
🧠 RAM: 4-6 GB
🎯 Contexto: 2048 tokens
```

---

## **🎯 Flujo Diario FINAL**

```
1. 👆 Click "OpenCode" en menú KDE
2. 🚀 llama-server inicia automáticamente (anti-loop)
3. 🎨 OpenCode GUI abre conectada
4. 💻 Ctrl+I (inline), Ctrl+L (chat), Ctrl+R (refactor)
5. ❌ Cierra ventana → servidor cierra limpio
```

## **✅ Verificación Completa**

```fish
llama-status          # ✅ Servidor OK
opencode              # 🚀 Flujo completo
llama "Test función"  # 💬 Chat funciona
```

## Compila llama.cpp con Vulkan (tu CachyOS/Fedora lo soporta):

```bash
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp
mkdir build && cd build
cmake .. -DLLAMA_VULKAN=ON -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release -j8
sudo cp bin/llama-server /usr/local/bin/
```

**¡Todo optimizado para tu CachyOS + Fish + KDE Plasma 6.6.2!** 🎉

---

_Última actualización: 06/Mar/2026 | Xanders San | CachyOS Edition_
