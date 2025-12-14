# n8n Custom Nodes - Agent Memory Bridge

Paquete de nodos personalizados para n8n que proporciona capacidades avanzadas de memoria semántica, embeddings locales y almacenamiento vectorial para agentes de IA.

## 🚀 Nodos Incluidos

### 1. Agent Memory Bridge
Puente avanzado entre almacenes vectoriales y memoria de agentes de IA con búsqueda semántica, múltiples niveles de memoria y bancos de conocimiento condicionales.

**Características:**
- ✅ Memoria semántica con búsqueda por similitud
- ✅ Dos niveles de memoria separados (Agente-Usuario y Agente-Tools)
- ✅ Múltiples bancos de conocimiento con activación condicional
- ✅ Skills Knowledge Base para procedimientos/recetas
- ✅ Deduplicación y caché de respuestas

### 2. Local Embeddings
Genera embeddings de texto localmente usando modelos de Hugging Face. 100% local, sin necesidad de APIs externas.

**Características:**
- ✅ Ejecución 100% local
- ✅ Modelos pre-entrenados de Hugging Face
- ✅ Compatible con LangChain
- ✅ Optimizado para Node.js

### 3. Vector Store LokiVector
Almacén vectorial 100% local con búsqueda HNSW. Base de datos embebida con capacidades de búsqueda vectorial.

**Características:**
- ✅ 100% local, sin servicios externos
- ✅ Búsqueda HNSW eficiente
- ✅ Persistencia en disco
- ✅ Compatible con LangChain

## 📦 Instalación

```bash
# Clonar el repositorio
git clone <repository-url>
cd "n8n nodes/agent memory bridge"

# Instalar dependencias
cd n8n-nodes-starter
npm install

# Compilar
npm run build

# Desplegar a n8n global
cd ..
./deploy-to-n8n.sh
```

## 🎯 Uso Rápido

### Flujo Básico: Agente con Memoria Semántica

```
Local Embeddings → Vector Store LokiVector → Agent Memory Bridge → AI Agent
```

1. **Configura Local Embeddings**
   - Model Name: `Xenova/multilingual-e5-small`

2. **Crea Vector Store**
   - Mode: `insert` (para cargar documentos)
   - Database Path: `./vectors.db`

3. **Configura Agent Memory Bridge**
   - Session ID: `={{ $json.sessionId }}`
   - Top K: `10`
   - Score Threshold: `0.7`

4. **Conecta AI Agent**
   - Conecta la salida de Memory Bridge al input Memory del Agent

## 📚 Documentación Completa

Para documentación detallada de cada nodo, consulta [DOCUMENTACION.md](./DOCUMENTACION.md)

## 🔧 Desarrollo

### Compilar

```bash
cd n8n-nodes-starter
npm run build
```

### Desplegar

```bash
./deploy-to-n8n.sh
```

### Desarrollo con Hot Reload

```bash
cd n8n-nodes-starter
npm run dev
```

## 📋 Requisitos

- Node.js 18+
- n8n instalado globalmente
- ~500MB de espacio en disco (para modelos de embeddings)

## 🎨 Ejemplos

### Ejemplo 1: Memoria Básica
```yaml
Local Embeddings
  └─> Vector Store LokiVector
      └─> Agent Memory Bridge
          └─> AI Agent
```

### Ejemplo 2: Con Tools Memory
```yaml
Local Embeddings
  ├─> Vector Store (Conversación)
  └─> Tools Vector Store
      └─> Agent Memory Bridge (Separate Tools Memory: true)
          └─> AI Agent
```

### Ejemplo 3: Múltiples Knowledge Bases
```yaml
Local Embeddings
  ├─> KB Premium (condición: userType === "premium")
  ├─> KB Free (condición: userType === "free")
  └─> KB Español (condición: language === "es")
      └─> Agent Memory Bridge
          └─> AI Agent
```

## 🐛 Troubleshooting

### El nodo no aparece en n8n
- Verifica que n8n esté corriendo: `n8n start`
- Verifica que el despliegue fue exitoso: `./deploy-to-n8n.sh`
- Revisa los logs: `/tmp/n8n_deploy.log`

### Error al cargar modelo de embeddings
- Verifica tu conexión a internet (primera descarga)
- Verifica que tienes suficiente espacio en disco
- Prueba con un modelo más pequeño

### Búsquedas vectoriales lentas
- Reduce `efSearch` en Vector Store LokiVector
- Reduce `Top K` en Agent Memory Bridge
- Considera usar un modelo de embeddings más pequeño

## 📝 Licencia

MIT

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor, abre un issue o pull request.

## 📧 Soporte

Para problemas o preguntas:
- Abre un issue en el repositorio
- Consulta la [documentación completa](./DOCUMENTACION.md)
- Revisa los logs de n8n

---

**Nota**: Este paquete está en desarrollo activo. Algunas características pueden cambiar.
