# Análisis de LokiVector para Integración con n8n

## Resumen Ejecutivo

LokiVector es una base de datos embebida que combina un document store (LokiJS) con búsqueda vectorial usando el algoritmo HNSW. Es **100% local**, no requiere servidores externos, y es perfecta para crear un nodo de Vector Store en n8n que funcione completamente offline.

## Características Principales

### 1. Base de Datos Embebida
- ✅ **100% local** - No requiere servidores externos
- ✅ **In-memory** con persistencia opcional
- ✅ **Crash-safe** - Recuperación automática después de crashes
- ✅ **Ligera** - Sin dependencias pesadas
- ✅ **Múltiples adapters** - File System, IndexedDB, Memory

### 2. Búsqueda Vectorial (HNSW)
- ✅ **Algoritmo HNSW** - Hierarchical Navigable Small World
- ✅ **Alta performance** - < 0.5ms por búsqueda
- ✅ **Escalable** - Maneja millones de vectores
- ✅ **Múltiples distancias** - Euclidiana y Coseno
- ✅ **Búsqueda híbrida** - Vectorial + filtros tradicionales

### 3. Funcionalidades Adicionales
- ✅ **Query API** - Sintaxis similar a MongoDB
- ✅ **Índices** - Únicos y binarios
- ✅ **Views** - Vistas dinámicas con filtros
- ✅ **Persistencia automática** - Guarda índices vectoriales
- ✅ **Estadísticas** - Monitoreo de índices

## API de Vector Search

### Crear Índice Vectorial

```javascript
const loki = require('lokivector');
const db = new loki('vector-db.db');
const collection = db.addCollection('documents');

// Crear índice vectorial
collection.ensureVectorIndex('embedding', {
  M: 16,                    // Max connections per node
  efConstruction: 200,        // Construction search size
  efSearch: 50,              // Query search size
  distanceFunction: 'cosine' // 'euclidean' o 'cosine'
});
```

### Insertar Documentos

```javascript
collection.insert({
  pageContent: 'Texto del documento',
  metadata: { source: 'file.pdf', page: 1 },
  embedding: [0.1, 0.2, 0.3, ...] // Vector de embeddings
});
```

### Búsqueda de Vecinos Más Cercanos

```javascript
// Buscar k vecinos más cercanos
const results = collection.findNearest('embedding', queryVector, {
  k: 10,
  includeDistance: true,
  filter: { category: 'ai' } // Filtro opcional
});

// Resultados incluyen:
// - Documento completo
// - $distance: Distancia calculada
// - $similarity: Similitud (1 - distancia para cosine)
```

### Búsqueda Similar

```javascript
// Buscar documentos similares a uno existente
const doc = collection.findOne({ id: '123' });
const similar = collection.findSimilar('embedding', doc, { k: 5 });
```

### Búsqueda Híbrida

```javascript
// Combinar búsqueda vectorial con filtros
const results = collection.hybridSearch(
  'embedding',
  queryVector,
  { category: 'ai', verified: true }, // Filtros tradicionales
  {
    k: 10,
    vectorWeight: 0.7,  // 70% peso vectorial
    queryWeight: 0.3    // 30% peso filtros
  }
);
```

## Interfaz Requerida para n8n Vector Store

Basado en el análisis de `createVectorStoreNode`, un Vector Store en n8n debe implementar:

### 1. Clase VectorStore (LangChain)

```typescript
class VectorStore {
  // Métodos requeridos por LangChain
  async similaritySearch(
    query: string,
    k: number,
    filter?: Record<string, any>
  ): Promise<Document[]>
  
  async similaritySearchVectorWithScore(
    queryVector: number[],
    k: number,
    filter?: Record<string, any>
  ): Promise<[Document, number][]>
  
  async addDocuments(documents: Document[]): Promise<string[]>
  
  async addVectors(vectors: number[][], documents: Document[]): Promise<string[]>
}
```

### 2. Funciones para createVectorStoreNode

```typescript
// Obtener instancia del Vector Store
async getVectorStoreClient(
  context: IExecuteFunctions | ISupplyDataFunctions,
  filter: Record<string, never> | undefined,
  embeddings: Embeddings,
  itemIndex: number
): Promise<VectorStore>

// Poblar el Vector Store con documentos
async populateVectorStore(
  context: IExecuteFunctions,
  embeddings: Embeddings,
  documents: Document[],
  itemIndex: number
): Promise<void>

// Opcional: Liberar recursos
async releaseVectorStoreClient(vectorStore: VectorStore): Promise<void>
```

## Implementación Propuesta

### Estructura del Nodo

```
VectorStoreLokiVector/
├── VectorStoreLokiVector.node.ts
├── VectorStoreLokiVector.node.json
└── LokiVectorStore.ts (wrapper que implementa VectorStore de LangChain)
```

### Wrapper LokiVectorStore

```typescript
import { VectorStore } from '@langchain/core/vectorstores';
import { Document } from '@langchain/core/documents';
import { Embeddings } from '@langchain/core/embeddings';

class LokiVectorStore extends VectorStore {
  private db: any; // Instancia de Loki
  private collection: any; // Collection de Loki
  private embeddings: Embeddings;
  private dbPath: string;
  private collectionName: string;

  constructor(
    embeddings: Embeddings,
    dbPath: string,
    collectionName: string = 'documents'
  ) {
    super(embeddings, {});
    this.embeddings = embeddings;
    this.dbPath = dbPath;
    this.collectionName = collectionName;
    this.initialize();
  }

  private initialize() {
    const loki = require('lokivector');
    this.db = new loki(this.dbPath, {
      autoload: true,
      autosave: true,
      autosaveInterval: 4000
    });

    // Obtener o crear collection
    this.collection = this.db.getCollection(this.collectionName) ||
      this.db.addCollection(this.collectionName);

    // Crear índice vectorial si no existe
    if (!this.collection.vectorIndices || !this.collection.vectorIndices.embedding) {
      this.collection.ensureVectorIndex('embedding', {
        M: 16,
        efConstruction: 200,
        efSearch: 50,
        distanceFunction: 'cosine' // Mejor para embeddings normalizados
      });
    }
  }

  async addDocuments(documents: Document[]): Promise<string[]> {
    const texts = documents.map(doc => doc.pageContent);
    const vectors = await this.embeddings.embedDocuments(texts);
    
    const ids: string[] = [];
    for (let i = 0; i < documents.length; i++) {
      const doc = documents[i];
      const inserted = this.collection.insert({
        pageContent: doc.pageContent,
        metadata: doc.metadata,
        embedding: vectors[i]
      });
      ids.push(inserted.$loki.toString());
    }
    
    this.db.save();
    return ids;
  }

  async addVectors(vectors: number[][], documents: Document[]): Promise<string[]> {
    const ids: string[] = [];
    for (let i = 0; i < documents.length; i++) {
      const inserted = this.collection.insert({
        pageContent: documents[i].pageContent,
        metadata: documents[i].metadata,
        embedding: vectors[i]
      });
      ids.push(inserted.$loki.toString());
    }
    this.db.save();
    return ids;
  }

  async similaritySearch(
    query: string,
    k: number,
    filter?: Record<string, any>
  ): Promise<Document[]> {
    const queryVector = await this.embeddings.embedQuery(query);
    return this.similaritySearchVectorWithScore(queryVector, k, filter)
      .then(results => results.map(([doc]) => doc));
  }

  async similaritySearchVectorWithScore(
    queryVector: number[],
    k: number,
    filter?: Record<string, any>
  ): Promise<[Document, number][]> {
    const options: any = {
      k,
      includeDistance: true
    };

    if (filter) {
      options.filter = filter;
    }

    const results = this.collection.findNearest('embedding', queryVector, options);
    
    return results.map((doc: any) => {
      const document = new Document({
        pageContent: doc.pageContent,
        metadata: {
          ...doc.metadata,
          id: doc.$loki.toString()
        }
      });
      
      // Convertir distancia a score (mayor = mejor)
      // Para cosine: similarity = 1 - distance
      const score = doc.$similarity || (1 - doc.$distance);
      
      return [document, score] as [Document, number];
    });
  }

  // Método adicional para búsqueda híbrida
  async hybridSearch(
    query: string,
    k: number,
    filter?: Record<string, any>,
    vectorWeight: number = 0.7
  ): Promise<Document[]> {
    const queryVector = await this.embeddings.embedQuery(query);
    
    const results = this.collection.hybridSearch(
      'embedding',
      queryVector,
      filter || {},
      {
        k,
        vectorWeight,
        queryWeight: 1 - vectorWeight
      }
    );

    return results.map((doc: any) => new Document({
      pageContent: doc.pageContent,
      metadata: {
        ...doc.metadata,
        id: doc.$loki.toString()
      }
    }));
  }
}
```

### Configuración del Nodo

```typescript
export class VectorStoreLokiVector extends createVectorStoreNode<LokiVectorStore>({
  meta: {
    displayName: 'LokiVector Store',
    name: 'vectorStoreLokiVector',
    description: '100% local vector store using LokiVector embedded database',
    icon: 'fa:database',
    iconColor: 'black',
    categories: ['AI'],
    subcategories: {
      AI: ['Vector Stores'],
    },
  },
  sharedFields: [
    {
      displayName: 'Database Path',
      name: 'dbPath',
      type: 'string',
      default: '~/.n8n/lokivector.db',
      description: 'Path to the LokiVector database file',
    },
    {
      displayName: 'Collection Name',
      name: 'collectionName',
      type: 'string',
      default: 'documents',
      description: 'Name of the collection to store vectors',
    },
    {
      displayName: 'Index M',
      name: 'indexM',
      type: 'number',
      default: 16,
      description: 'Max connections per node in HNSW index (higher = better accuracy, more memory)',
    },
    {
      displayName: 'Index efConstruction',
      name: 'efConstruction',
      type: 'number',
      default: 200,
      description: 'Exploration factor during index construction (higher = better quality, slower build)',
    },
    {
      displayName: 'Index efSearch',
      name: 'efSearch',
      type: 'number',
      default: 50,
      description: 'Exploration factor during search (higher = better accuracy, slower search)',
    },
    {
      displayName: 'Distance Function',
      name: 'distanceFunction',
      type: 'options',
      options: [
        { name: 'Cosine', value: 'cosine' },
        { name: 'Euclidean', value: 'euclidean' },
      ],
      default: 'cosine',
      description: 'Distance metric for vector comparison',
    },
  ],
  async getVectorStoreClient(context, _filter, embeddings, itemIndex) {
    const dbPath = context.getNodeParameter('dbPath', itemIndex) as string;
    const collectionName = context.getNodeParameter('collectionName', itemIndex) as string;
    
    return new LokiVectorStore(embeddings, dbPath, collectionName);
  },
  async populateVectorStore(context, embeddings, documents, itemIndex) {
    const vectorStore = await this.getVectorStoreClient(context, undefined, embeddings, itemIndex);
    await vectorStore.addDocuments(documents);
  },
  async releaseVectorStoreClient(vectorStore) {
    // LokiVector guarda automáticamente, pero podemos forzar un save
    if (vectorStore.db) {
      vectorStore.db.save();
    }
  },
}) {}
```

## Ventajas de LokiVector para n8n

### 1. 100% Local
- ✅ No requiere servidores externos (Pinecone, Weaviate, etc.)
- ✅ Funciona completamente offline
- ✅ No hay costos de API
- ✅ Privacidad total de datos

### 2. Performance
- ✅ Búsquedas < 0.5ms
- ✅ Inserción ~0.7ms por vector
- ✅ Escalable a millones de vectores
- ✅ Índices HNSW optimizados

### 3. Persistencia
- ✅ Crash-safe con recuperación automática
- ✅ Guarda índices vectoriales automáticamente
- ✅ Múltiples adapters (File System, IndexedDB)
- ✅ Sin pérdida de datos

### 4. Facilidad de Uso
- ✅ Sin configuración de servidor
- ✅ Un solo archivo de base de datos
- ✅ API simple y directa
- ✅ Compatible con LangChain

## Consideraciones de Implementación

### 1. Dependencias

```json
{
  "dependencies": {
    "@langchain/core": "^0.x.x",
    "lokivector": "file:../LOKIVECTOR" // O npm install @lokivector/core
  }
}
```

### 2. Path de Base de Datos

- Usar `~/.n8n/lokivector/` como directorio por defecto
- Permitir configuración por workflow o global
- Manejar paths absolutos y relativos

### 3. Gestión de Colecciones

- Una colección por workflow (recomendado)
- O colección compartida con filtros por workflowId
- Permitir múltiples colecciones en la misma DB

### 4. Configuración de Índices

- Crear índices automáticamente en primera inserción
- Permitir configuración de parámetros HNSW
- Validar dimensiones de vectores

### 5. Compatibilidad con Agent Memory Bridge

- El nodo Agent Memory Bridge ya funciona con cualquier Vector Store
- LokiVector será compatible automáticamente
- Permitirá memoria semántica 100% local

## Próximos Pasos

1. ✅ **Análisis completo** - Hecho
2. ⏳ **Crear wrapper LokiVectorStore** - Implementar clase que extiende VectorStore
3. ⏳ **Crear nodo n8n** - Usar createVectorStoreNode
4. ⏳ **Integrar dependencia** - Agregar lokivector al package.json
5. ⏳ **Probar con Local Embeddings** - Verificar funcionamiento end-to-end
6. ⏳ **Probar con Agent Memory Bridge** - Verificar memoria semántica local
7. ⏳ **Documentar** - Agregar a SETUP.md y README.md

## Referencias

- [LokiVector README](LOKIVECTOR/README.md)
- [Vector Search Guide](LOKIVECTOR/docs/VECTOR_SEARCH.md)
- [n8n Vector Store Documentation](n8n/packages/@n8n/nodes-langchain/nodes/vector_store/shared/createVectorStoreNode/README.md)
- [HNSW Algorithm Paper](https://arxiv.org/abs/1603.09320)

