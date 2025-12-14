# n8n Custom Nodes - Agent Memory Bridge

Paquete de nodos personalizados para n8n que proporciona capacidades avanzadas de memoria semántica, embeddings locales, almacenamiento vectorial y herramientas de seguridad para agentes de IA.

## 🚀 Nodos Incluidos

### 1. Agent Memory Bridge
Puente avanzado entre almacenes vectoriales y memoria de agentes de IA con búsqueda semántica, múltiples niveles de memoria y bancos de conocimiento condicionales.

**Características:**
- ✅ **Memoria Semántica**: Búsqueda por similitud en lugar de ventana fija
- ✅ **Niveles de Memoria**: Separación entre memoria Agente-Usuario y Agente-Tools
- ✅ **Knowledge Bases**: Múltiples bancos con activación condicional
- ✅ **Skills System**: Base de conocimiento para procedimientos/recetas
- ✅ **Optimización**: Deduplicación, caché de respuestas y caché de embeddings (SimHash)
- ✅ **Resiliencia**: Retry logic, timeouts configurables y manejo de errores
- ✅ **Métricas**: Sistema completo de monitoreo de rendimiento

### 2. Local Embeddings
Genera embeddings de texto localmente usando modelos de Hugging Face. 100% local, sin necesidad de APIs externas.

**Características:**
- ✅ **100% Local**: Sin dependencia de servicios externos
- ✅ **Modelos SOTA**: Acceso a modelos de Hugging Face (e.g. Xenova/multilingual-e5-small)
- ✅ **Optimizado**: Ejecución eficiente en Node.js
- ✅ **Estándar**: Compatible con la interfaz de LangChain

### 3. Vector Store LokiVector
Almacén vectorial 100% local con búsqueda HNSW (Hierarchical Navigable Small World). Base de datos embebida de alto rendimiento.

**Características:**
- ✅ **Zero Config**: Base de datos embebida sin infraestructura extra
- ✅ **Alto Rendimiento**: Búsqueda HNSW eficiente
- ✅ **Persistencia**: Almacenamiento seguro en disco
- ✅ **Flexible**: Soporta distancias Euclideana y Coseno

### 4. Secure Code Tool
Entorno de ejecución seguro (sandbox) para que los agentes escriban y ejecuten código sin riesgos.

**Características:**
- ✅ **Sandboxing**: Aislamiento completo usando `nsjail`
- ✅ **Multi-lenguaje**: Soporte para Python, JavaScript y Bash
- ✅ **Seguridad**: Validación de código y límites de recursos (CPU, RAM, Tiempo)
- ✅ **Integración**: Diseñado para trabajar con Skills Knowledge Base

### 5. Credential Vault
Bóveda de credenciales que permite a los agentes utilizar autenticación sin exponer los secretos.

**Características:**
- ✅ **Privacidad**: El agente usa las credenciales sin leer sus valores
- ✅ **Control**: Restricción de dominios permitidos
- ✅ **Versatilidad**: Soporta múltiples tipos de autenticación (OAuth2, Basic, Header, etc.)
- ✅ **Seguridad**: Inyección segura en tiempo de ejecución

## 📦 Instalación

Estos nodos están disponibles como paquetes npm independientes. Puedes instalarlos directamente en tu instancia de n8n.

### Nodos Verificados por n8n

| Nodo | Paquete NPM | Enlace |
|------|-------------|--------|
| **Agent Memory Bridge** | `n8n-nodes-agent-memory-bridge` | [NPM](https://www.npmjs.com/package/n8n-nodes-agent-memory-bridge) |
| **Credential Vault** | `n8n-nodes-credential-vault` | [NPM](https://www.npmjs.com/package/n8n-nodes-credential-vault) |

### Nodos de la Comunidad

| Nodo | Paquete NPM | Enlace |
|------|-------------|--------|
| **Local Embeddings** | `n8n-nodes-local-embeddings` | [NPM](https://www.npmjs.com/package/n8n-nodes-local-embeddings) |
| **LokiVector Store** | `n8n-nodes-lokivector-store` | [NPM](https://www.npmjs.com/package/n8n-nodes-lokivector-store) |
| **Secure Code Tool** | `n8n-nodes-secure-code-tool` | [NPM](https://www.npmjs.com/package/n8n-nodes-secure-code-tool) |

### Cómo instalar en n8n

Para instalar estos nodos en tu instancia de n8n:

1. Ve a **Settings** > **Community Nodes**.
2. Haz clic en **Install**.
3. Pega el nombre del paquete npm (ej. `n8n-nodes-agent-memory-bridge`).
4. Haz clic en **Install**.

Alternativamente, si usas Docker, puedes instalarlos montando un volumen o extendiendo la imagen:

```bash
# Ejemplo en el directorio custom de n8n
cd ~/.n8n/custom
npm install n8n-nodes-agent-memory-bridge n8n-nodes-credential-vault
```

## 🎯 Uso Rápido

### Flujo Completo: Agente Avanzado

```
Local Embeddings → Vector Store LokiVector → Agent Memory Bridge → AI Agent
                                                    ↓
                                            Secure Code Tool
```

1. **Configura Local Embeddings**
   - Model Name: `Xenova/multilingual-e5-small`

2. **Crea Vector Store**
   - Mode: `insert` (para cargar documentos/skills)
   - Database Path: `./vectors.db`

3. **Configura Agent Memory Bridge**
   - Session ID: `={{ $json.sessionId }}`
   - Top K: `10`
   - Score Threshold: `0.7`

4. **Conecta AI Agent**
   - Conecta la salida de Memory Bridge al input Memory del Agent
   - Conecta Secure Code Tool como herramienta

## 📚 Documentación Completa

Para documentación detallada de cada nodo y ejemplos avanzados, consulta:

- [Documentación General](./DOCUMENTACION.md)
- [Secure Code Tool](./SECURE_CODE_TOOL.md)
- [Credential Vault](./CREDENTIAL_VAULT.md)
- [Análisis LokiVector](./ANALISIS_LOKIVECTOR.md)

## 🔧 Desarrollo (Opcional)

Si deseas contribuir o modificar el código fuente:

### Compilar

```bash
cd n8n-nodes-starter
npm run build
```

### Desarrollo con Hot Reload

```bash
cd n8n-nodes-starter
npm run dev
```
