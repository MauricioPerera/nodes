#!/bin/bash

# Script para desplegar nodos custom a n8n global
# Uso: ./deploy-to-n8n.sh [nombre-del-nodo]

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Directorios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTER_DIR="$SCRIPT_DIR/n8n-nodes-starter"
CUSTOM_DIR="$HOME/.n8n/custom"
DIST_DIR="$STARTER_DIR/dist/nodes"

# Verificar que estamos en el directorio correcto
if [ ! -d "$STARTER_DIR" ]; then
    echo -e "${RED}❌ Error: No se encuentra n8n-nodes-starter${NC}"
    exit 1
fi

# Verificar que existe package.json
if [ ! -f "$STARTER_DIR/package.json" ]; then
    echo -e "${RED}❌ Error: No se encuentra package.json${NC}"
    exit 1
fi

echo -e "${GREEN}📦 Compilando nodos...${NC}"
cd "$STARTER_DIR"

# Cargar NVM si existe
if [ -s "$HOME/.nvm/nvm.sh" ]; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm use 22 >/dev/null 2>&1 || true
fi

# Compilar
if ! npm run build >/tmp/n8n_build.log 2>&1; then
    echo -e "${RED}❌ Error al compilar. Ver logs en /tmp/n8n_build.log${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Compilación exitosa${NC}"

# Verificar que existe dist/nodes
if [ ! -d "$DIST_DIR" ]; then
    echo -e "${RED}❌ Error: No se encuentra dist/nodes${NC}"
    exit 1
fi

# Crear directorio custom si no existe
mkdir -p "$CUSTOM_DIR"

# Usar npm link para registrar el paquete como módulo npm
# Esto permite que n8n resuelva correctamente las dependencias (n8n-workflow, etc.)
echo -e "${GREEN}📦 Registrando paquete con npm link...${NC}"
cd "$STARTER_DIR"

# Crear link del paquete
if ! npm link >/tmp/npm_link.log 2>&1; then
    echo -e "${YELLOW}⚠️  npm link falló, intentando continuar...${NC}"
    cat /tmp/npm_link.log | tail -10
fi

# Crear node_modules en custom si no existe
mkdir -p "$CUSTOM_DIR/node_modules"

# Linkar el paquete en custom/node_modules
cd "$CUSTOM_DIR"
if ! npm link "n8n-nodes-agent-memory-bridge" >/tmp/npm_link_custom.log 2>&1; then
    echo -e "${YELLOW}⚠️  Link en custom falló, intentando método alternativo...${NC}"
    cat /tmp/npm_link_custom.log | tail -10
    
    # Método alternativo: copiar directamente (puede fallar con dependencias)
    echo -e "${YELLOW}📋 Usando método alternativo: copiando directamente...${NC}"
    if [ -n "$1" ]; then
        NODE_NAME="$1"
        NODE_SOURCE="$DIST_DIR/$NODE_NAME"
        
        if [ ! -d "$NODE_SOURCE" ]; then
            echo -e "${RED}❌ Error: Nodo '$NODE_NAME' no encontrado en dist/nodes${NC}"
            echo -e "${YELLOW}Nodos disponibles:${NC}"
            ls -1 "$DIST_DIR" | sed 's/^/  - /'
            exit 1
        fi
        
        echo -e "${GREEN}📋 Copiando nodo: $NODE_NAME${NC}"
        rm -rf "$CUSTOM_DIR/$NODE_NAME"
        cp -r "$NODE_SOURCE" "$CUSTOM_DIR/"
        echo -e "${GREEN}✅ Nodo copiado a $CUSTOM_DIR/$NODE_NAME${NC}"
    else
        # Copiar todos los nodos
        echo -e "${GREEN}📋 Copiando todos los nodos...${NC}"
        for node_dir in "$DIST_DIR"/*; do
            if [ -d "$node_dir" ]; then
                node_name=$(basename "$node_dir")
                echo "  - Copiando $node_name..."
                rm -rf "$CUSTOM_DIR/$node_name"
                cp -r "$node_dir" "$CUSTOM_DIR/"
            fi
        done
        echo -e "${GREEN}✅ Todos los nodos copiados${NC}"
    fi
else
    echo -e "${GREEN}✅ Paquete linkeado correctamente${NC}"
fi

# Verificar que n8n está instalado globalmente
if ! command -v n8n &> /dev/null; then
    echo -e "${YELLOW}⚠️  n8n no encontrado globalmente. Instálalo con: npm install -g n8n${NC}"
    exit 1
fi

# Detener n8n si está corriendo
echo -e "${YELLOW}🛑 Deteniendo n8n si está corriendo...${NC}"
pkill -f "n8n start" || true
pkill -f "n8n-node dev" || true
sleep 2

# Iniciar n8n
echo -e "${GREEN}🚀 Iniciando n8n...${NC}"
cd "$HOME"
n8n start >/tmp/n8n_deploy.log 2>&1 &
N8N_PID=$!

# Esperar a que n8n inicie
echo -e "${YELLOW}⏳ Esperando a que n8n inicie (máximo 60 segundos)...${NC}"
MAX_WAIT=60
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    if curl -s http://localhost:5678/healthz >/dev/null 2>&1; then
        echo -e "${GREEN}✅ n8n iniciado correctamente${NC}"
        break
    fi
    sleep 2
    WAITED=$((WAITED + 2))
    echo -n "."
done

if [ $WAITED -ge $MAX_WAIT ]; then
    echo -e "\n${RED}❌ Error: n8n no inició en 60 segundos${NC}"
    echo -e "${YELLOW}Ver logs en /tmp/n8n_deploy.log${NC}"
    tail -20 /tmp/n8n_deploy.log
    exit 1
fi

echo ""

# Verificar nodos
echo -e "${GREEN}🔍 Verificando nodos disponibles...${NC}"
sleep 5

# Cargar NVM nuevamente para el comando n8n
if [ -s "$HOME/.nvm/nvm.sh" ]; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm use 22 >/dev/null 2>&1 || true
fi

if n8n export:nodes --output=/tmp/n8n_nodes_check.json >/dev/null 2>&1; then
    CUSTOM_NODES=$(python3 -c "
import json
try:
    data = json.load(open('/tmp/n8n_nodes_check.json'))
    custom = [n for n in data if 'CUSTOM' in n.get('name', '')]
    print(len(custom))
    for n in custom:
        print(f\"{n.get('name')}|{n.get('displayName')}\")
except:
    print('0')
" 2>/dev/null || echo "0")
    
    NODE_COUNT=$(echo "$CUSTOM_NODES" | head -1)
    
    if [ "$NODE_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✅ Nodos CUSTOM encontrados: $NODE_COUNT${NC}"
        echo "$CUSTOM_NODES" | tail -n +2 | while IFS='|' read -r name display; do
            echo -e "  ${GREEN}✓${NC} $name - $display"
        done
        
        if [ -n "$1" ]; then
            # Verificar que el nodo específico está disponible
            if echo "$CUSTOM_NODES" | grep -qi "CUSTOM\.$1\|CUSTOM\.$(echo $1 | tr '[:upper:]' '[:lower:]')"; then
                echo ""
                echo -e "${GREEN}✅ El nodo '$1' está disponible en n8n${NC}"
                echo -e "${GREEN}🌐 Abre http://localhost:5678 para usar el nodo${NC}"
            else
                echo -e "${YELLOW}⚠️  El nodo '$1' no aparece en la lista de nodos CUSTOM${NC}"
            fi
        fi
    else
        echo -e "${RED}❌ No se encontraron nodos CUSTOM${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  No se pudo verificar los nodos, pero n8n está corriendo${NC}"
fi

echo ""
echo -e "${GREEN}✅ Despliegue completado${NC}"
echo -e "${GREEN}🌐 n8n disponible en: http://localhost:5678${NC}"
echo -e "${YELLOW}📝 Logs de n8n: /tmp/n8n_deploy.log${NC}"

