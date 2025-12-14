# Configuración de Nodos Custom para n8n Global

Esta guía explica cómo desplegar nodos custom a una instalación global de n8n usando `npm link` para resolver correctamente las dependencias.

## Método Recomendado: Script Automático

El script `deploy-to-n8n.sh` automatiza todo el proceso:

```bash
# Desplegar todos los nodos
./deploy-to-n8n.sh

# Desplegar un nodo específico (no recomendado, mejor desplegar todos)
./deploy-to-n8n.sh LocalEmbeddings
```

### ¿Qué hace el script?

1. ✅ **Compila los nodos** usando `npm run build`
2. ✅ **Registra el paquete** con `npm link` en el proyecto
3. ✅ **Linkea el paquete** en `~/.n8n/custom/node_modules/` para que n8n resuelva dependencias
4. ✅ **Detiene n8n** si está corriendo
5. ✅ **Inicia n8n global** en segundo plano
6. ✅ **Espera** a que n8n esté listo (verifica `/healthz`)
7. ✅ **Verifica** que los nodos estén disponibles usando `n8n export:nodes`
8. ✅ **Muestra reporte** de todos los nodos CUSTOM encontrados

### Requisitos

- Node.js v22 o superior (recomendado usar nvm)
- n8n instalado globalmente: `npm install -g n8n`
- Python 3 (para el script de verificación)

## Método Manual (Alternativa)

Si prefieres hacerlo manualmente:

### 1. Compilar los nodos

```bash
cd n8n-nodes-starter
npm run build
```

### 2. Registrar el paquete con npm link

```bash
# Desde el directorio del proyecto
cd n8n-nodes-starter
npm link
```

### 3. Linkear en ~/.n8n/custom/

```bash
# Crear directorio si no existe
mkdir -p ~/.n8n/custom/node_modules

# Linkear el paquete
cd ~/.n8n/custom
npm link n8n-nodes-agent-memory-bridge
```

### 4. Iniciar n8n

```bash
# Detener n8n si está corriendo
pkill -f "n8n start"

# Iniciar n8n
n8n start
```

### 5. Verificar que los nodos estén disponibles

```bash
n8n export:nodes --output=/tmp/nodes.json
cat /tmp/nodes.json | grep -i "CUSTOM"
```

## Estructura Resultante

Después del despliegue, la estructura será:

```
~/.n8n/custom/
  └── node_modules/
      └── n8n-nodes-agent-memory-bridge/  (symlink)
          └── dist/
              └── nodes/
                  ├── AgentMemoryBridge/
                  │   ├── AgentMemoryBridge.node.js
                  │   └── AgentMemoryBridge.node.json
                  ├── LocalEmbeddings/
                  │   ├── LocalEmbeddings.node.js
                  │   └── LocalEmbeddings.node.json
                  └── ...
```

## Nodos Disponibles

Este proyecto incluye los siguientes nodos custom:

1. **Agent Memory Bridge** (`CUSTOM.agentMemoryBridge`)
   - Categoría: AI > Memory
   - Conecta un Vector Store y Embeddings al nodo Agent para memoria semántica

2. **Local Embeddings** (`CUSTOM.localEmbeddings`)
   - Categoría: AI > Embeddings
   - Genera embeddings localmente usando `@huggingface/transformers`
   - Modelos soportados: multilingual-e5-small, multilingual-e5-base, all-MiniLM-L6-v2

3. **Example** (`CUSTOM.example`)
   - Nodo de ejemplo incluido en el starter

4. **GitHub Issues** (`CUSTOM.githubIssues`)
   - Nodo de ejemplo completo con OAuth2 y API token

## Notas Importantes

### ¿Por qué usar `npm link`?

- **Resuelve dependencias**: Permite que n8n resuelva correctamente `n8n-workflow` y otras dependencias peer
- **Mantiene estructura**: El paquete se comporta como un módulo npm real
- **Evita errores**: Previene errores como "Cannot find module 'n8n-workflow'"

### NO usar `npm run dev` para n8n global

- `npm run dev` usa `~/.n8n-node-cli` como carpeta de usuario
- Para n8n global, usa `n8n start` después de linkear el paquete

### Reiniciar n8n después de cambios

Cada vez que modifiques y recompiles los nodos:

```bash
# Opción 1: Usar el script (recomendado)
./deploy-to-n8n.sh

# Opción 2: Manual
pkill -f "n8n start"
n8n start
```

### Verificación de Nodos

Los nodos aparecerán con el prefijo `CUSTOM.` en n8n:
- `CUSTOM.agentMemoryBridge`
- `CUSTOM.localEmbeddings`
- `CUSTOM.example`
- etc.

## Solución de Problemas

### Error: "Cannot find module 'n8n-workflow'"

**Causa**: El paquete no está linkeado correctamente o se copió directamente sin usar `npm link`.

**Solución**: 
1. Asegúrate de haber ejecutado `npm link` en el proyecto
2. Asegúrate de haber ejecutado `npm link n8n-nodes-agent-memory-bridge` en `~/.n8n/custom/`
3. Verifica que existe `~/.n8n/custom/node_modules/n8n-nodes-agent-memory-bridge`

### Los nodos no aparecen en la UI

**Verificación**:
```bash
n8n export:nodes --output=/tmp/nodes.json
python3 -c "import json; data = json.load(open('/tmp/nodes.json')); custom = [n for n in data if 'CUSTOM' in n.get('name', '')]; print(f'Nodos CUSTOM: {len(custom)}'); [print(f\"  - {n.get('name')}: {n.get('displayName')}\") for n in custom]"
```

**Si no aparecen**:
1. Verifica que los nodos estén en `package.json` bajo `n8n.nodes`
2. Verifica que tengan `codex.categories` y `codex.subcategories` correctamente definidos
3. Reinicia n8n completamente

### n8n no inicia

**Verifica logs**:
```bash
tail -50 /tmp/n8n_deploy.log
```

**Problemas comunes**:
- Puerto 5678 ya en uso: `pkill -f "n8n start"` y vuelve a intentar
- Error de permisos: Verifica que tienes permisos en `~/.n8n/`

## Scripts Útiles

### Verificar nodo específico

```bash
./verificar_nodo.sh
```

### Ver todos los nodos CUSTOM

```bash
n8n export:nodes --output=/tmp/nodes.json
python3 -c "import json; data = json.load(open('/tmp/nodes.json')); custom = [n for n in data if 'CUSTOM' in n.get('name', '')]; [print(f\"{n.get('name')}: {n.get('displayName')}\") for n in custom]"
```

## Referencias

- [n8n Custom Nodes Documentation](https://docs.n8n.io/integrations/creating-nodes/)
- [npm link Documentation](https://docs.npmjs.com/cli/v10/commands/npm-link)
