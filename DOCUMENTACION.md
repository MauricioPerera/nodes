# Documentación de Nodos Custom para n8n

Este paquete contiene nodos personalizados para n8n diseñados para trabajar con agentes de IA, embeddings locales y almacenamiento vectorial.

## Tabla de Contenidos

1. [Agent Memory Bridge](#agent-memory-bridge)
2. [Local Embeddings](#local-embeddings)
3. [Vector Store LokiVector](#vector-store-lokivector)
4. [Secure Code Tool](#secure-code-tool)
5. [Credential Vault](#credential-vault)

---

## Agent Memory Bridge

### Descripción

El nodo **Agent Memory Bridge** es un puente avanzado entre almacenes vectoriales y la memoria del agente de IA. Utiliza búsqueda semántica para recuperar historial de conversación relevante en lugar de una ventana fija de mensajes. Soporta múltiples niveles de memoria, bancos de conocimiento condicionales y skills.

### Características Principales

- **Memoria Semántica**: Búsqueda por similitud en lugar de ventana fija
- **Dos Niveles de Memoria Separados**:
  - Memoria Agente-Usuario (conversaciones)
  - Memoria Agente-Tools (interacciones con herramientas)
- **Múltiples Bancos de Conocimiento**: Soporta varios bancos con activación condicional
- **Skills Knowledge Base**: Base de conocimiento para procedimientos/recetas
- **Deduplicación**: Evita almacenar contenido duplicado
- **Caché de Respuestas**: Opción de cachear respuestas para reducir latencia
- **Caché de Embeddings**: Caché inteligente de embeddings usando SimHash para queries similares
- **Búsquedas Paralelas**: Todas las búsquedas se ejecutan en paralelo para mejor rendimiento
- **Retry Logic**: Reintentos automáticos con backoff exponencial para operaciones fallidas
- **Timeouts Configurables**: Previene búsquedas que cuelguen indefinidamente
- **Expiración Automática**: Limpieza automática de mensajes antiguos (TTL configurable)
- **Límite de Mensajes**: Control del número máximo de mensajes por sesión
- **Métricas de Rendimiento**: Sistema de métricas para monitorear el rendimiento del nodo
- **Procesamiento Avanzado de Memoria**: Extracción de entidades, consolidación de mensajes similares y resumen automático

### Inputs

1. **Vector Store** (requerido)
   - Almacén vectorial principal para memoria de conversación Agente-Usuario
   - Tipo: `AiVectorStore`

2. **Tools Vector Store** (opcional)
   - Almacén vectorial para memoria de interacciones Agente-Tools
   - Tipo: `AiVectorStore`
   - Solo se usa si "Separate Tools Memory" está habilitado

3. **Knowledge Base** (opcional, múltiples)
   - Puedes conectar múltiples bancos de conocimiento
   - Cada banco puede tener una condición de activación
   - Tipo: `AiVectorStore`

4. **Skills Knowledge Base** (opcional)
   - Base de conocimiento para procedimientos/recetas paso a paso
   - Tipo: `AiVectorStore`

5. **Embedding** (requerido)
   - Modelo de embeddings para búsqueda semántica
   - Tipo: `AiEmbedding`

### Outputs

- **Memory**: Memoria compatible con nodos de Agente de IA
  - Tipo: `AiMemory`

### Parámetros Principales

#### Configuración Básica

- **Session ID**: Identificador de sesión para separar diferentes contextos de conversación
  - Tipo: `string`
  - Ejemplo: `={{ $json.sessionId }}`

- **Top K**: Número de mensajes más relevantes a recuperar del almacén vectorial
  - Tipo: `number`
  - Por defecto: `10`

- **Score Threshold**: Puntuación mínima de similitud (0-1) para incluir mensajes
  - Tipo: `number`
  - Por defecto: `0.7`
  - Valores más altos = más estricto

- **Include Recent Messages**: Número de mensajes más recientes a incluir siempre
  - Tipo: `number`
  - Por defecto: `3`

#### Configuración de Tools Memory

- **Separate Tools Memory**: Activa memoria separada para interacciones Agente-Tools
  - Tipo: `boolean`
  - Por defecto: `false`

- **Tools Memory Top K**: Número de interacciones de tools a recuperar
  - Tipo: `number`
  - Por defecto: `5`
  - Solo visible si "Separate Tools Memory" está habilitado

- **Tools Memory Score Threshold**: Umbral de similitud para tools memory
  - Tipo: `number`
  - Por defecto: `0.7`
  - Solo visible si "Separate Tools Memory" está habilitado

- **Include Recent Tools**: Número de interacciones recientes a incluir siempre
  - Tipo: `number`
  - Por defecto: `3`
  - Solo visible si "Separate Tools Memory" está habilitado

#### Configuración de Knowledge Bases

- **Knowledge Bases**: Configuración de múltiples bancos de conocimiento
  - Tipo: `fixedCollection` (múltiples valores)
  - Cada banco tiene:
    - **Name**: Nombre identificador del banco
    - **Connection Index**: Índice de la conexión (0 = primera, 1 = segunda, etc.)
    - **Top K**: Número de documentos a recuperar
    - **Score Threshold**: Umbral de similitud mínimo
    - **Condition** (opcional): Expresión n8n que debe evaluarse a `true` para activar el banco
      - Ejemplos:
        - `{{ $json.userType === "premium" }}`
        - `{{ $json.language === "en" }}`
        - `{{ $json.category === "technical" }}`

#### Configuración de Skills Knowledge Base

- **Skills Knowledge Base Top K**: Número de skills más relevantes a recuperar
  - Tipo: `number`
  - Por defecto: `5`

- **Skills Knowledge Base Score Threshold**: Umbral de similitud para skills
  - Tipo: `number`
  - Por defecto: `0.7`

#### Configuración Avanzada

- **Enable Deduplication**: Evita guardar mensajes duplicados
  - Tipo: `boolean`
  - Por defecto: `true`

- **Enable SimHash**: Usa algoritmo SimHash para detectar contenido similar
  - Tipo: `boolean`
  - Por defecto: `true`

- **SimHash Threshold**: Umbral de distancia Hamming para SimHash (1-10)
  - Tipo: `number`
  - Por defecto: `3`
  - Valores más bajos = más estricto

- **Enable Response Caching**: Cachea respuestas para entradas idénticas
  - Tipo: `boolean`
  - Por defecto: `false`

- **Cache TTL (hours)**: Tiempo de vida del caché en horas
  - Tipo: `number`
  - Por defecto: `24`
  - `0` = sin expiración

- **Enable Persistent Cache**: Almacena caché en el vector store para persistencia
  - Tipo: `boolean`
  - Por defecto: `false`

#### Configuración de Rendimiento y Robustez

- **Search Timeout (ms)**: Tiempo máximo de espera por búsqueda en milisegundos
  - Tipo: `number`
  - Por defecto: `30000` (30 segundos)
  - Rango: 1000-300000
  - Previene búsquedas que cuelguen indefinidamente

- **Max Retries**: Número máximo de reintentos para búsquedas fallidas
  - Tipo: `number`
  - Por defecto: `2`
  - Rango: 0-5
  - Usa backoff exponencial entre reintentos

- **Retry Delay (ms)**: Delay inicial antes de reintentar en milisegundos
  - Tipo: `number`
  - Por defecto: `100`
  - Rango: 0-5000
  - El delay aumenta exponencialmente con cada reintento

#### Configuración de Limpieza Automática

- **Enable Auto Cleanup**: Activa limpieza automática de mensajes expirados y límites de mensajes
  - Tipo: `boolean`
  - Por defecto: `false`
  - Requiere que Message TTL o Max Messages Per Session estén configurados

- **Message TTL (days)**: Tiempo de vida de los mensajes en días
  - Tipo: `number`
  - Por defecto: `0` (sin expiración)
  - Los mensajes más antiguos que este valor serán eliminados automáticamente
  - Solo visible si "Enable Auto Cleanup" está habilitado

- **Max Messages Per Session**: Número máximo de mensajes a mantener por sesión
  - Tipo: `number`
  - Por defecto: `0` (ilimitado)
  - Los mensajes más antiguos se eliminarán cuando se exceda el límite
  - Solo visible si "Enable Auto Cleanup" está habilitado

#### Configuración de Métricas

- **Enable Metrics**: Activa la recolección de métricas de rendimiento
  - Tipo: `boolean`
  - Por defecto: `false`
  - Las métricas incluyen:
    - Número de búsquedas realizadas
    - Tasa de aciertos del caché de embeddings
    - Tiempo promedio de búsqueda
    - Número de errores
    - Uso de knowledge bases
  - Las métricas pueden ser accedidas mediante el método `getMetrics()` del objeto de memoria

#### Configuración de Procesamiento de Memoria

- **Enable Memory Processing**: Activa el procesamiento avanzado de memoria (extracción, consolidación, resumen)
  - Tipo: `boolean`
  - Por defecto: `false`
  - Requiere LLM Model para modos avanzados

- **Extraction Mode**: Modo de extracción de entidades y datos estructurados
  - Tipo: `options`
  - Opciones:
    - `None`: No extraer entidades
    - `Basic (Regex-based)`: Extrae emails, teléfonos, fechas, URLs, decisiones y preferencias usando patrones regex
    - `Advanced (LLM-based)`: Usa LLM para extraer entidades estructuradas (requiere LLM Model)
  - Por defecto: `none`

- **Consolidation Mode**: Modo de consolidación de mensajes similares
  - Tipo: `options`
  - Opciones:
    - `None`: No consolidar mensajes
    - `Similarity (SimHash)`: Agrupa mensajes similares usando algoritmo SimHash
    - `Semantic (Embeddings)`: Agrupa mensajes semánticamente similares usando embeddings
  - Por defecto: `none`

- **Summary Mode**: Modo de resumen de mensajes antiguos
  - Tipo: `options`
  - Opciones:
    - `None`: No resumir mensajes
    - `Threshold-based`: Resume cuando el número de mensajes alcanza un umbral
    - `Periodic`: Resume mensajes periódicamente (cada N horas)
  - Por defecto: `none`
  - Requiere LLM Model

- **Summary Threshold**: Número de mensajes antes de activar el resumen
  - Tipo: `number`
  - Por defecto: `50`
  - Rango: 10-1000
  - Solo visible si Summary Mode es `threshold`

- **Summary Period (hours)**: Horas entre resúmenes automáticos
  - Tipo: `number`
  - Por defecto: `24`
  - Rango: 1-168
  - Solo visible si Summary Mode es `periodic`

- **Max Cache Size**: Tamaño máximo de cada caché (content hash, SimHash, response, embedding)
  - Tipo: `number`
  - Por defecto: `1000`
  - Rango: 100-10000
  - Usa política LRU (Least Recently Used) para evicción automática
  - Controla el uso de memoria de los caches

### Ejemplos de Uso

#### Ejemplo 1: Configuración Básica

```
Vector Store (LokiVector) → Agent Memory Bridge → AI Agent
Embedding (LocalEmbeddings)
```

**Configuración:**
- Session ID: `={{ $json.sessionId }}`
- Top K: `10`
- Score Threshold: `0.7`

#### Ejemplo 2: Con Tools Memory Separada

```
Vector Store (Conversación) → Agent Memory Bridge → AI Agent
Tools Vector Store (Tools)  ↗
Embedding (LocalEmbeddings)
```

**Configuración:**
- Separate Tools Memory: `true`
- Tools Memory Top K: `5`
- Tools Memory Score Threshold: `0.7`

#### Ejemplo 3: Con Múltiples Knowledge Bases Condicionales

```
Vector Store → Agent Memory Bridge → AI Agent
KB Premium  ↗
KB Free     ↗
KB Español  ↗
Embedding
```

**Configuración de Knowledge Bases:**

1. **KB Premium**
   - Name: `Premium Docs`
   - Connection Index: `0`
   - Top K: `5`
   - Condition: `{{ $json.userType === "premium" }}`

2. **KB Free**
   - Name: `Free Docs`
   - Connection Index: `1`
   - Top K: `3`
   - Condition: `{{ $json.userType === "free" }}`

3. **KB Español**
   - Name: `Documentación Español`
   - Connection Index: `2`
   - Top K: `5`
   - Condition: `{{ $json.language === "es" }}`

#### Ejemplo 4: Con Skills Knowledge Base

```
Vector Store → Agent Memory Bridge → AI Agent
Skills KB   ↗
Embedding
```

**Configuración:**
- Skills Knowledge Base Top K: `5`
- Skills Knowledge Base Score Threshold: `0.7`

### Estructura de Datos

#### Memoria de Conversación

Los mensajes se almacenan con la siguiente estructura:

```json
{
  "pageContent": "Contenido del mensaje",
  "metadata": {
    "type": "human" | "ai" | "system",
    "content": "Contenido del mensaje",
    "sessionId": "session_123",
    "timestamp": 1234567890,
    "expiresAt": 1234567890000,
    "id": "human_1234567890_abc123"
  }
}
```

**Nota**: El campo `expiresAt` solo se incluye si se ha configurado Message TTL. Indica la fecha de expiración del mensaje en milisegundos.

#### Tools Memory

Los mensajes de tools se almacenan con:

```json
{
  "pageContent": "Resultado de tool",
  "metadata": {
    "type": "tool",
    "content": "Resultado de tool",
    "toolName": "nombre_tool",
    "toolCallId": "call_123",
    "sessionId": "session_123",
    "timestamp": 1234567890
  }
}
```

#### Knowledge Base

Los documentos del knowledge base deben tener:

```json
{
  "pageContent": "Contenido del documento",
  "metadata": {
    "id": "doc_123",
    "timestamp": 1234567890
  }
}
```

#### Skills Knowledge Base

Las skills deben tener:

```json
{
  "pageContent": "Procedimiento paso a paso...",
  "metadata": {
    "skillName": "Connect to Stripe API",
    "category": "API Integration",
    "timestamp": 1234567890
  }
}
```

### Mejoras de Rendimiento

El nodo ahora incluye varias optimizaciones:

1. **Búsquedas Paralelas**: Todas las búsquedas (conversación, tools, knowledge bases, skills) se ejecutan en paralelo, reduciendo significativamente el tiempo de respuesta.

2. **Retry con Backoff Exponencial**: Si una búsqueda falla, se reintenta automáticamente con un delay que aumenta exponencialmente (100ms, 200ms, 400ms...).

3. **Timeouts Configurables**: Cada búsqueda tiene un timeout configurable para prevenir cuelgues.

4. **Manejo Robusto de Errores**: Si un knowledge base falla, los demás continúan funcionando normalmente.

5. **Caché de Embeddings**: El nodo cachea embeddings de queries similares usando SimHash, reduciendo significativamente el tiempo de respuesta para consultas repetidas o similares.

6. **Limpieza Automática**: Con Auto Cleanup habilitado, los mensajes antiguos se eliminan automáticamente según TTL o límite de mensajes, manteniendo las bases de datos optimizadas.

7. **Métricas**: El sistema de métricas permite monitorear el rendimiento del nodo y optimizar la configuración según los patrones de uso.

8. **Procesamiento de Memoria**: El sistema de procesamiento avanzado permite:
   - **Extracción de Entidades**: Identificar y almacenar información estructurada (emails, teléfonos, decisiones, preferencias) directamente en los metadatos de los mensajes
   - **Consolidación**: Agrupar mensajes similares para reducir redundancia y mantener solo la información más relevante
   - **Resumen**: Comprimir conversaciones largas manteniendo el contexto clave, útil para sesiones muy extensas

### Métricas

Si has habilitado "Enable Metrics", puedes acceder a las métricas del nodo mediante el método `getMetrics()`:

```javascript
// En un nodo Code o Function
const memory = $input.item.json.memory; // Asumiendo que el objeto de memoria está disponible
const metrics = memory.getMetrics();

console.log('Búsquedas realizadas:', metrics.searches);
console.log('Tasa de aciertos del caché:', metrics.cacheHitRate);
console.log('Tiempo promedio de búsqueda:', metrics.avgSearchTime, 'ms');
console.log('Errores:', metrics.errors);
console.log('Búsquedas por knowledge base:', metrics.knowledgeBaseSearches);
```

**Métricas disponibles:**
- `searches`: Número total de búsquedas realizadas
- `cacheHitRate`: Tasa de aciertos del caché de embeddings (0-1)
- `cacheHits`: Número de aciertos en el caché
- `cacheMisses`: Número de fallos en el caché
- `avgSearchTime`: Tiempo promedio de búsqueda en milisegundos
- `errors`: Número de errores ocurridos
- `knowledgeBaseSearches`: Objeto con el número de búsquedas por knowledge base
- `entitiesExtracted`: Objeto con el número de entidades extraídas por tipo (emails, phones, dates, etc.)
- `totalEntitiesExtracted`: Número total de entidades extraídas
- `avgExtractionTime`: Tiempo promedio de extracción en milisegundos
- `extractionErrors`: Número de errores durante la extracción
- `cacheSizes`: Objeto con el tamaño actual de cada caché (contentHash, simHash, response, embedding)

### Notas Importantes

1. **Session ID**: Es crucial usar un Session ID único por conversación para separar contextos
2. **Score Threshold**: Ajusta según la calidad de tus embeddings y la precisión requerida
3. **Top K**: Valores más altos = más contexto pero mayor costo computacional
4. **Condiciones**: Las condiciones se evalúan en tiempo de ejecución usando expresiones n8n
5. **Deduplicación**: SimHash ayuda a detectar contenido similar, no solo idéntico
6. **Rendimiento**: Con múltiples knowledge bases, las búsquedas paralelas mejoran significativamente el tiempo de respuesta
7. **Timeouts**: Ajusta el timeout según el tamaño de tus bases de datos y la velocidad de red

---

## Local Embeddings

### Descripción

El nodo **Local Embeddings** genera embeddings de texto localmente usando modelos de transformers de Hugging Face. No requiere conexión a internet ni APIs externas, todo se ejecuta en tu servidor.

### Características Principales

- **100% Local**: No requiere conexión a internet
- **Modelos Pre-entrenados**: Usa modelos de Hugging Face
- **Compatible con LangChain**: Implementa la interfaz `Embeddings` de LangChain
- **Optimizado para Node.js**: Usa `@huggingface/transformers`

### Inputs

Ninguno (el nodo genera embeddings directamente)

### Outputs

- **Embedding**: Modelo de embeddings compatible con nodos de IA
  - Tipo: `AiEmbedding`

### Parámetros

- **Model Name**: Nombre del modelo de Hugging Face a usar
  - Tipo: `string`
  - Por defecto: `Xenova/multilingual-e5-small`
  - Ejemplos:
    - `Xenova/multilingual-e5-small` (multilingüe, pequeño)
    - `Xenova/all-MiniLM-L6-v2` (inglés, rápido)
    - `Xenova/paraphrase-multilingual-MiniLM-L12-v2` (multilingüe, mejor calidad)

### Ejemplos de Uso

#### Ejemplo 1: Configuración Básica

```
Local Embeddings → Agent Memory Bridge → AI Agent
```

**Configuración:**
- Model Name: `Xenova/multilingual-e5-small`

#### Ejemplo 2: Con Vector Store

```
Local Embeddings → Vector Store LokiVector
                  → Agent Memory Bridge → AI Agent
```

### Modelos Recomendados

1. **Xenova/multilingual-e5-small**
   - Multilingüe (100+ idiomas)
   - Tamaño: ~130MB
   - Buen balance velocidad/calidad

2. **Xenova/all-MiniLM-L6-v2**
   - Solo inglés
   - Tamaño: ~80MB
   - Muy rápido

3. **Xenova/paraphrase-multilingual-MiniLM-L12-v2**
   - Multilingüe
   - Tamaño: ~420MB
   - Mejor calidad

### Notas Importantes

1. **Primera Carga**: La primera vez que se usa un modelo, se descarga automáticamente
2. **Memoria**: Los modelos se cargan en memoria, considera el tamaño del modelo
3. **Rendimiento**: Modelos más grandes = mejor calidad pero más lento
4. **GPU**: Si tienes GPU disponible, se usará automáticamente

---

## Vector Store LokiVector

### Descripción

El nodo **Vector Store LokiVector** proporciona un almacén vectorial 100% local usando LokiJS con búsqueda HNSW (Hierarchical Navigable Small World). Es una base de datos de documentos embebida con capacidades de búsqueda vectorial.

### Características Principales

- **100% Local**: No requiere servicios externos
- **Búsqueda HNSW**: Algoritmo eficiente para búsqueda de vecinos más cercanos
- **Persistencia**: Los datos se guardan en disco
- **Compatible con LangChain**: Implementa la interfaz `VectorStore` de LangChain

### Inputs

- **Embedding** (requerido)
  - Modelo de embeddings para generar vectores
  - Tipo: `AiEmbedding`

### Outputs

- **Vector Store**: Almacén vectorial compatible con nodos de IA
  - Tipo: `AiVectorStore`

### Parámetros

#### Configuración Básica

- **Mode**: Modo de operación
  - Opciones:
    - `insert`: Insertar documentos
    - `load`: Cargar y buscar documentos
  - Tipo: `options`

- **Database Path**: Ruta donde se guarda la base de datos
  - Tipo: `string`
  - Por defecto: `./lokivector.db`
  - Ejemplo: `/path/to/vectorstore.db`

- **Collection Name**: Nombre de la colección en la base de datos
  - Tipo: `string`
  - Por defecto: `documents`

#### Configuración HNSW

- **M**: Número de conexiones bidireccionales en cada nivel
  - Tipo: `number`
  - Por defecto: `16`
  - Valores más altos = mejor calidad pero más lento

- **efConstruction**: Tamaño de la lista candidata durante construcción
  - Tipo: `number`
  - Por defecto: `200`
  - Valores más altos = mejor calidad pero construcción más lenta

- **efSearch**: Tamaño de la lista candidata durante búsqueda
  - Tipo: `number`
  - Por defecto: `50`
  - Valores más altos = mejor calidad pero búsqueda más lenta

- **Distance Function**: Función de distancia para comparar vectores
  - Opciones:
    - `euclidean`: Distancia euclidiana
    - `cosine`: Distancia coseno (recomendado para embeddings normalizados)
  - Tipo: `options`
  - Por defecto: `cosine`

#### Modo Insert

- **Clear Store**: Limpiar el almacén antes de insertar
  - Tipo: `boolean`
  - Por defecto: `false`
  - Solo visible en modo `insert`

#### Modo Load

- **Query**: Texto de búsqueda
  - Tipo: `string`
  - Solo visible en modo `load`

- **Top K**: Número de resultados a retornar
  - Tipo: `number`
  - Por defecto: `5`
  - Solo visible en modo `load`

### Ejemplos de Uso

#### Ejemplo 1: Insertar Documentos

```
Local Embeddings → Vector Store LokiVector (Mode: insert)
```

**Configuración:**
- Mode: `insert`
- Database Path: `./my_vectors.db`
- Collection Name: `documents`
- M: `16`
- efConstruction: `200`
- Distance Function: `cosine`

**Datos de entrada:**
```json
{
  "text": "Contenido del documento",
  "metadata": {
    "id": "doc_1",
    "category": "technical"
  }
}
```

#### Ejemplo 2: Buscar Documentos

```
Local Embeddings → Vector Store LokiVector (Mode: load)
```

**Configuración:**
- Mode: `load`
- Database Path: `./my_vectors.db`
- Collection Name: `documents`
- Query: `={{ $json.query }}`
- Top K: `5`

#### Ejemplo 3: En Workflow Completo

```
Local Embeddings → Vector Store LokiVector → Agent Memory Bridge → AI Agent
```

### Estructura de Datos

#### Documentos Insertados

```json
{
  "text": "Contenido del documento",
  "metadata": {
    "id": "doc_123",
    "category": "technical",
    "timestamp": 1234567890
  }
}
```

#### Resultados de Búsqueda

```json
{
  "pageContent": "Contenido del documento",
  "metadata": {
    "id": "doc_123",
    "category": "technical",
    "timestamp": 1234567890,
    "score": 0.95
  }
}
```

### Parámetros HNSW Explicados

1. **M (16)**: Número de conexiones en cada nivel del grafo
   - Más alto = mejor calidad, más memoria, construcción más lenta
   - Recomendado: 16-32

2. **efConstruction (200)**: Candidatos considerados durante construcción
   - Más alto = mejor calidad, construcción más lenta
   - Recomendado: 100-400

3. **efSearch (50)**: Candidatos considerados durante búsqueda
   - Más alto = mejor calidad, búsqueda más lenta
   - Recomendado: 50-200

4. **Distance Function**:
   - **Cosine**: Mejor para embeddings normalizados (recomendado)
   - **Euclidean**: Mejor para embeddings no normalizados

### Notas Importantes

1. **Primera Inserción**: La primera vez que insertas, se crea la base de datos
2. **Persistencia**: Los datos se guardan automáticamente en disco
3. **Rendimiento**: Ajusta `efSearch` según tus necesidades de velocidad vs calidad
4. **Memoria**: HNSW mantiene el índice en memoria para búsquedas rápidas
5. **Backup**: Haz backup del archivo `.db` para preservar tus datos

---

## Flujos de Trabajo Completos

### Flujo 1: Agente con Memoria Semántica Local

```
Local Embeddings → Vector Store LokiVector → Agent Memory Bridge → AI Agent
```

**Pasos:**
1. Configura `Local Embeddings` con modelo multilingüe
2. Crea `Vector Store LokiVector` y carga tus documentos
3. Conecta `Agent Memory Bridge` con configuración básica
4. Conecta `AI Agent` para usar la memoria semántica

### Flujo 2: Agente con Múltiples Bancos de Conocimiento

```
Local Embeddings → KB Premium (Vector Store)
                → KB Free (Vector Store)
                → KB Español (Vector Store)
                → Agent Memory Bridge → AI Agent
                  (con condiciones)
```

**Configuración de Knowledge Bases:**
- KB Premium: `{{ $json.userType === "premium" }}`
- KB Free: `{{ $json.userType === "free" }}`
- KB Español: `{{ $json.language === "es" }}`

### Flujo 3: Agente con Tools Memory Separada

```
Local Embeddings → Vector Store (Conversación)
                → Tools Vector Store (Tools)
                → Agent Memory Bridge → AI Agent
                  (Separate Tools Memory: true)
```

---

## Troubleshooting

### Agent Memory Bridge

**Problema**: No se recuperan mensajes relevantes
- **Solución**: Reduce `Score Threshold` o aumenta `Top K`

**Problema**: Se recuperan demasiados mensajes irrelevantes
- **Solución**: Aumenta `Score Threshold`

**Problema**: Condiciones no funcionan
- **Solución**: Verifica la sintaxis de la expresión n8n

**Problema**: Los mensajes no se están limpiando automáticamente
- **Solución**: 
  1. Verifica que "Enable Auto Cleanup" esté habilitado
  2. Verifica que Message TTL o Max Messages Per Session estén configurados
  3. Ten en cuenta que la limpieza automática requiere que el vector store soporte eliminación de documentos (algunos vector stores no lo soportan nativamente)
  4. La limpieza se ejecuta durante `loadMemoryVariables`, no de forma asíncrona en segundo plano

**Problema**: Las métricas no están disponibles
- **Solución**: Asegúrate de que "Enable Metrics" esté habilitado y que estés accediendo al método `getMetrics()` del objeto de memoria correcto

**Problema**: La extracción avanzada no funciona
- **Solución**: Verifica que hayas conectado un LLM Model y que "Extraction Mode" esté configurado como "Advanced"

**Problema**: El resumen no se está ejecutando
- **Solución**: 
  1. Verifica que "Summary Mode" no esté en "None"
  2. Verifica que hayas conectado un LLM Model
  3. Para modo "threshold", verifica que el número de mensajes haya alcanzado el umbral
  4. Para modo "periodic", verifica que haya pasado el tiempo configurado desde el último resumen

**Problema**: La consolidación elimina mensajes importantes
- **Solución**: Ajusta el umbral de similitud (SimHash Threshold) o el Score Threshold para ser más estricto. Considera desactivar la consolidación si necesitas mantener todos los mensajes

### Local Embeddings

**Problema**: Modelo tarda mucho en cargar
- **Solución**: Usa un modelo más pequeño o verifica tu conexión

**Problema**: Error de memoria
- **Solución**: Usa un modelo más pequeño o aumenta memoria disponible

### Vector Store LokiVector

**Problema**: Búsquedas muy lentas
- **Solución**: Reduce `efSearch` o `M`

**Problema**: Búsquedas no precisas
- **Solución**: Aumenta `efSearch` o `efConstruction`

**Problema**: Base de datos corrupta
- **Solución**: Elimina el archivo `.db` y recrea la base de datos

---

## Mejores Prácticas

1. **Session IDs**: Usa Session IDs únicos y consistentes
2. **Score Thresholds**: Ajusta según la calidad de tus embeddings
3. **Top K**: Balance entre contexto y rendimiento
4. **Condiciones**: Prueba las condiciones antes de usarlas en producción
5. **Backups**: Haz backup regular de tus bases de datos vectoriales
6. **Modelos**: Elige modelos según tu caso de uso (velocidad vs calidad)

---

---

## Secure Code Tool

### Descripción

El nodo **Secure Code Tool** permite a los agentes de IA ejecutar código de forma segura usando `nsjail` como sandbox. Está diseñado para trabajar en conjunto con el sistema de **Skills Knowledge Base** del Agent Memory Bridge, permitiendo que el agente consulte skills (procedimientos/recetas) para saber qué código ejecutar y cómo estructurarlo.

### Características Principales

- **Ejecución Segura**: Usa nsjail para aislamiento completo del sistema operativo
- **Integración con Skills**: Diseñado para trabajar con Skills Knowledge Base
- **Multi-lenguaje**: Soporta Python, JavaScript y Bash
- **Auto-detección**: Detecta automáticamente el lenguaje del código
- **Validación**: Valida código antes de ejecutar para detectar patrones peligrosos
- **Límites Configurables**: Control de tiempo, memoria y tamaño de código

### Caso de Uso: Agente con Skills

**Flujo de Trabajo:**

```
Usuario: "Calcula el promedio de estos números: [10, 20, 30, 40]"

Agente:
1. Consulta Skills Knowledge Base → Encuentra skill "Cálculos Estadísticos"
2. Skill contiene: "Para promedios usa: sum(data) / len(data)"
3. Agente genera código Python basado en la skill
4. Ejecuta código usando Secure Code Tool
5. Retorna resultado: "25.0"
```

### Parámetros

- **Default Language**: Lenguaje por defecto (Python, JavaScript, Bash, Auto-detect)
- **Max Execution Time**: Tiempo máximo de ejecución (1-300 segundos)
- **Max Memory**: Memoria máxima permitida (16-1024 MB)
- **Enable Network Access**: Permitir acceso a red (⚠️ aumenta riesgo de seguridad)
- **Max Code Length**: Longitud máxima del código (100-200K caracteres)
- **Allowed Imports**: Lista de imports permitidos para Python (separados por comas)
- **Enable Code Validation**: Validar código antes de ejecutar

### Requisitos

1. **nsjail instalado**:
   ```bash
   sudo apt-get install nsjail
   # O compilar desde: https://github.com/google/nsjail
   ```

2. **Permisos**:
   ```bash
   sudo setcap cap_sys_admin+ep $(which nsjail)
   ```

### Ejemplo de Uso con Skills

#### 1. Crear Skill en Skills Knowledge Base

```json
{
  "pageContent": "Título: Cálculos Estadísticos con Python\n\nPara calcular promedios, medianas y otras estadísticas:\n\n1. Usa listas de Python: data = [10, 20, 30]\n2. Promedio: sum(data) / len(data)\n3. Mediana: sorted(data)[len(data)//2]\n4. Máximo: max(data)\n5. Mínimo: min(data)\n\nEjemplo completo:\ndata = [10, 20, 30, 40, 50]\naverage = sum(data) / len(data)\nprint(f'Promedio: {average}')",
  "metadata": {
    "skillName": "Cálculos Estadísticos",
    "category": "Mathematics",
    "language": "python",
    "timestamp": 1234567890
  }
}
```

#### 2. Configurar Workflow

```
Skills KB (LokiVector) → Agent Memory Bridge → AI Agent
                                    ↓
                            Secure Code Tool
```

#### 3. El Agente Usa la Tool

Cuando el usuario pregunta algo que requiere código:
- El agente consulta Skills KB
- Encuentra skills relevantes
- Genera código siguiendo los patrones de las skills
- Ejecuta usando Secure Code Tool
- Retorna resultado

### Seguridad

- **Aislamiento Completo**: Código ejecutado en namespace aislado
- **Sin Acceso al Sistema**: No puede modificar archivos del host
- **Límites Estrictos**: CPU, memoria y tiempo controlados
- **Sin Red por Defecto**: Aislamiento de red (opcional habilitar)
- **Validación Pre-ejecución**: Detecta patrones peligrosos

### Troubleshooting

**Problema**: nsjail no está instalado
- **Solución**: Instalar nsjail: `sudo apt-get install nsjail`

**Problema**: Error de permisos al ejecutar
- **Solución**: Configurar capacidades: `sudo setcap cap_sys_admin+ep $(which nsjail)`

**Problema**: El código no se ejecuta
- **Solución**: Verificar que el lenguaje esté correctamente detectado o especificado

**Problema**: Timeout en ejecución
- **Solución**: Aumentar "Max Execution Time" si el código es complejo

### Integración con Credential Vault

Secure Code Tool puede recibir credenciales del Credential Vault para inyectarlas como variables de entorno:

```javascript
// El agente primero obtiene credenciales del vault
const creds = await credentialVault({
  credentialName: "OpenAI API",
  action: "getCredentialForInjection"
});

// Luego ejecuta código con las credenciales
secureCodeTool({
  code: "import os\nkey = os.environ.get('OPENAI_API_KEY')",
  credentials: [{
    envVarName: "OPENAI_API_KEY",
    credentialName: JSON.parse(creds)
  }]
});
```

Para más detalles, ver [SECURE_CODE_TOOL.md](./SECURE_CODE_TOOL.md) y [INTEGRACION_SKILLS_VAULT_CODE.md](./INTEGRACION_SKILLS_VAULT_CODE.md)

---

## Credential Vault

### Descripción

El nodo **Credential Vault** permite a los agentes de IA usar credenciales de forma segura sin poder leerlas ni modificarlas. El agente puede especificar qué credencial usar y qué acción realizar (por ejemplo, hacer una petición HTTP), pero nunca tiene acceso a los valores reales de las credenciales.

### Principio de Seguridad

**El agente puede USAR credenciales, pero NO puede LEERLAS ni MODIFICARLAS.**

### Características Principales

- **Uso Seguro de Credenciales**: El agente puede usar credenciales sin ver sus valores
- **Múltiples Credenciales**: Soporta múltiples credenciales con nombres amigables
- **Restricción de Dominios**: Puede restringir qué dominios pueden ser accedidos
- **Autenticación Automática**: Usa el sistema de autenticación de n8n
- **Soporte Multi-tipo**: Soporta httpHeaderAuth, oAuth2Api, httpBasicAuth, etc.

### Parámetros

- **Available Credentials**: Lista de credenciales disponibles en el vault
- **Enable HTTP Request Action**: Permitir peticiones HTTP (default: true)
- **Allowed Domains**: Lista de dominios permitidos (separados por comas)
- **Max Request Timeout**: Tiempo máximo de petición (1-300 segundos)

### Ejemplo de Uso

```javascript
credentialVault({
  credentialName: "OpenAI API",
  action: "httpRequest",
  params: {
    url: "https://api.openai.com/v1/models",
    method: "GET"
  }
})
```

### Seguridad

- **Sin Exposición**: Las credenciales se obtienen y usan internamente
- **Validación de Dominios**: Previene peticiones a dominios no autorizados
- **Solo Credenciales Configuradas**: El agente solo puede usar credenciales listadas

Para más detalles, ver [CREDENTIAL_VAULT.md](./CREDENTIAL_VAULT.md)

---

## Soporte

Para problemas o preguntas, consulta:
- Repositorio del proyecto
- Documentación de n8n
- Comunidad de n8n

