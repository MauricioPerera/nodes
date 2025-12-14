#!/bin/bash
# Script para verificar si el nodo AgentMemoryBridge está disponible en n8n

set -e

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm use 22 >/dev/null 2>&1

# Verificar si n8n está corriendo
if ! curl -s http://localhost:5678/healthz >/dev/null 2>&1; then
    echo "ERROR: n8n no está corriendo"
    exit 1
fi

# Exportar nodos
TMP_FILE="/tmp/n8n_nodes_verificacion_$$.json"
n8n export:nodes --output="$TMP_FILE" >/dev/null 2>&1

# Buscar el nodo (buscar por nombre exacto CUSTOM.agentMemoryBridge o por displayName)
if python3 -c "
import json
import sys
try:
    with open('$TMP_FILE', 'r') as f:
        data = json.load(f)
    nodes = [n for n in data if n.get('name', '') == 'CUSTOM.agentMemoryBridge' or 'agentMemoryBridge' in n.get('name', '').lower() or 'Agent Memory Bridge' in n.get('displayName', '')]
    if nodes:
        print('SÍ')
        sys.exit(0)
    else:
        print('NO')
        sys.exit(1)
except Exception as e:
    print(f'ERROR: {e}')
    sys.exit(2)
" 2>/dev/null; then
    RESULTADO="SÍ"
    EXIT_CODE=0
else
    RESULTADO="NO"
    EXIT_CODE=1
fi

# Limpiar
rm -f "$TMP_FILE" 2>/dev/null

echo "$RESULTADO"
exit $EXIT_CODE

