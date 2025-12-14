# Instrucciones para Encontrar los Nodos en la UI de n8n

## Estado Actual
- ✅ Los nodos están compilados y disponibles
- ✅ n8n los carga correctamente
- ✅ Los nodos aparecen en la UI de n8n

## Dónde Encontrar los Nodos

### 1. Abre n8n
Navega a: **http://localhost:5678**

### 2. Crea un nuevo workflow o abre uno existente

### 3. Agrega un nodo

Haz clic en el botón **+** para agregar un nodo.

### 4. Busca los nodos

Los nodos custom aparecen con el prefijo `CUSTOM.` y están organizados por categorías:

#### Agent Memory Bridge
- **Categoría**: AI > Memory
- **Nombre en n8n**: `CUSTOM.agentMemoryBridge`
- **Display Name**: "Agent Memory Bridge"
- **Cómo encontrarlo**:
  1. En el panel de nodos, ve a **AI** > **Memory**
  2. O busca directamente "Agent Memory Bridge" en el buscador
  3. O busca "memory bridge" o "CUSTOM.agentMemoryBridge"

#### Local Embeddings
- **Categoría**: AI > Embeddings
- **Nombre en n8n**: `CUSTOM.localEmbeddings`
- **Display Name**: "Local Embeddings"
- **Cómo encontrarlo**:
  1. En el panel de nodos, ve a **AI** > **Embeddings**
  2. O busca directamente "Local Embeddings" en el buscador
  3. O busca "local embeddings" o "CUSTOM.localEmbeddings"

#### Otros Nodos
- **Example**: `CUSTOM.example` - Nodo de ejemplo
- **GitHub Issues**: `CUSTOM.githubIssues` - Nodo de ejemplo con OAuth2

## Uso de los Nodos

### Agent Memory Bridge

Este nodo conecta un Vector Store y Embeddings al nodo Agent para proporcionar memoria semántica.

**Configuración**:
1. Conecta un nodo **Vector Store** al input "Vector Store"
2. Conecta un nodo **Embeddings** (como Local Embeddings) al input "Embedding"
3. Configura el **Session ID** para separar diferentes contextos de conversación
4. Ajusta parámetros como Top K, Score Threshold, etc.
5. Conecta la salida "Memory" al nodo **Agent**

### Local Embeddings

Este nodo genera embeddings localmente usando modelos de Hugging Face.

**Configuración**:
1. Selecciona el modelo (por defecto: multilingual-e5-small)
2. El modelo se descargará automáticamente en el primer uso
3. Conecta la salida "Embeddings" a un Vector Store o Agent Memory Bridge

**Modelos disponibles**:
- **multilingual-e5-small**: 384 dimensiones, multilingüe, cuantizado
- **multilingual-e5-base**: 768 dimensiones, multilingüe, cuantizado
- **all-MiniLM-L6-v2**: 384 dimensiones, solo inglés, cuantizado

## Verificación

### Verificar que los nodos están disponibles

```bash
# Usar el script de verificación
./verificar_nodo.sh

# O verificar manualmente
n8n export:nodes --output=/tmp/nodes.json
python3 -c "import json; data = json.load(open('/tmp/nodes.json')); custom = [n for n in data if 'CUSTOM' in n.get('name', '')]; print(f'Total nodos CUSTOM: {len(custom)}'); [print(f\"  - {n.get('name')}: {n.get('displayName')}\") for n in custom]"
```

### Verificar en la UI

1. Abre n8n: http://localhost:5678
2. Crea un nuevo workflow
3. Haz clic en el botón **+** para agregar un nodo
4. Busca "Agent Memory Bridge" o "Local Embeddings"
5. Si aparecen en los resultados, están correctamente instalados

## Solución de Problemas

### El nodo no aparece en la búsqueda

1. **Verifica que n8n esté corriendo**:
   ```bash
   curl http://localhost:5678/healthz
   ```

2. **Verifica que el nodo esté cargado**:
   ```bash
   n8n export:nodes | grep -i "CUSTOM"
   ```

3. **Reinicia n8n**:
   ```bash
   pkill -f "n8n start"
   ./deploy-to-n8n.sh
   ```

### El nodo aparece pero no funciona

1. **Verifica los logs de n8n**:
   ```bash
   tail -50 /tmp/n8n_deploy.log
   ```

2. **Verifica que las dependencias estén instaladas**:
   ```bash
   ls -la ~/.n8n/custom/node_modules/n8n-nodes-agent-memory-bridge
   ```

3. **Recompila y redespliega**:
   ```bash
   ./deploy-to-n8n.sh
   ```

## Notas

- Los nodos custom siempre tienen el prefijo `CUSTOM.` en su nombre interno
- El display name es el que ves en la UI
- Los nodos se organizan por las categorías definidas en `codex.categories` y `codex.subcategories`
- Después de modificar un nodo, debes recompilar y reiniciar n8n para ver los cambios
