# Secure Code Tool - Ejecución Segura de Código con nsjail

## 📋 Descripción

El nodo **Secure Code Tool** permite a los agentes de IA ejecutar código de forma segura usando `nsjail` como sandbox. Está diseñado para trabajar en conjunto con el sistema de **Skills Knowledge Base** del Agent Memory Bridge, permitiendo que el agente consulte skills (procedimientos/recetas) para saber qué código ejecutar y cómo estructurarlo.

## 🎯 Caso de Uso Principal

**Flujo de Trabajo con Skills y Credenciales:**

```
Usuario: "Procesa estos datos usando la API de OpenAI"

Agente:
1. Consulta Skills Knowledge Base → Encuentra skill "Procesamiento con OpenAI"
2. Skill indica: usar credencial "OpenAI API" como OPENAI_API_KEY
3. Agente llama Credential Vault → Obtiene credenciales (sin verlas)
4. Agente genera código basado en la skill
5. Ejecuta código usando Secure Code Tool con credenciales inyectadas
6. Retorna resultado al usuario
```

## 🏗️ Arquitectura

### Integración con Skills Knowledge Base

El agente puede:
1. **Consultar Skills**: Buscar procedimientos relevantes en Skills Knowledge Base
2. **Aprender Patrones**: Las skills contienen ejemplos y patrones de código
3. **Generar Código**: Crear código basado en las skills consultadas
4. **Ejecutar Seguro**: Usar Secure Code Tool para ejecutar el código de forma aislada

### Flujo Completo

```
┌─────────────────────────────────────────────────────────┐
│                    AI Agent                             │
│  ┌──────────────────────────────────────────────────┐  │
│  │ 1. Usuario pregunta: "Procesa estos datos"        │  │
│  └──────────────┬───────────────────────────────────┘  │
│                 ▼                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │ 2. Consulta Skills Knowledge Base                 │  │
│  │    - Busca skills relevantes                      │  │
│  │    - Encuentra: "Procesamiento de Datos con       │  │
│  │      Python"                                      │  │
│  └──────────────┬───────────────────────────────────┘  │
│                 ▼                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │ 3. Genera código basado en skill                 │  │
│  │    import pandas as pd                           │  │
│  │    df = pd.DataFrame(data)                       │  │
│  │    result = df.process()                         │  │
│  └──────────────┬───────────────────────────────────┘  │
│                 ▼                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │ 4. Llama Secure Code Tool                         │  │
│  │    - Valida código                                │  │
│  │    - Ejecuta con nsjail                          │  │
│  │    - Retorna resultado                            │  │
│  └──────────────┬───────────────────────────────────┘  │
│                 ▼                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │ 5. Presenta resultado al usuario                  │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## 🔧 Configuración

### Requisitos Previos

1. **nsjail instalado**:
   ```bash
   # Ubuntu/Debian
   sudo apt-get install nsjail

   # O compilar desde fuente
   git clone https://github.com/google/nsjail
   cd nsjail
   make
   sudo make install
   ```

2. **Permisos**:
   ```bash
   # Opción 1: Ejecutar n8n con capacidades
   sudo setcap cap_sys_admin+ep /usr/bin/node

   # Opción 2: Ejecutar n8n como root (no recomendado)
   # Opción 3: Usar Docker con privilegios
   ```

### Configuración del Nodo

1. **Conectar al AI Agent**:
   - El nodo debe estar conectado como Tool al AI Agent
   - Aparecerá en la lista de herramientas disponibles

2. **Parámetros**:
   - **Default Language**: Lenguaje por defecto (Python, JavaScript, Bash, Auto-detect)
   - **Max Execution Time**: Tiempo máximo de ejecución (1-300 segundos)
   - **Max Memory**: Memoria máxima (16-1024 MB)
   - **Enable Network Access**: Permitir acceso a red (⚠️ aumenta riesgo)
   - **Max Code Length**: Longitud máxima del código (100-200K caracteres)
   - **Allowed Imports**: Lista de imports permitidos (Python)
   - **Enable Code Validation**: Validar código antes de ejecutar

## 📝 Formato de Entrada

El agente puede llamar la tool de dos formas:

### Formato 1: String Simple
```javascript
// El agente pasa código directamente como string
secureCodeTool("print('Hello World')")
```

### Formato 2: Objeto con Metadata y Credenciales
```javascript
// El agente puede especificar lenguaje, configuración y credenciales
secureCodeTool({
  code: "import os\nimport requests\napi_key = os.environ.get('OPENAI_API_KEY')\n# ... usar API",
  language: "python",
  maxTime: 10,
  maxMemory: 64,
  credentials: [
    {
      envVarName: "OPENAI_API_KEY",
      credentialName: {
        // Credenciales obtenidas del Credential Vault
        // El agente debe llamar el vault primero
        "name": "Authorization",
        "value": "Bearer sk-..."
      }
    }
  ]
})
```

**Nota**: Las credenciales deben obtenerse primero del Credential Vault usando la acción `getCredentialForInjection`.

## 🎓 Ejemplos de Skills para el Agente

### Skill 1: Procesamiento de Datos con Python

**Contenido de la Skill:**
```
Título: Procesamiento de Datos con Python

Cuando necesites procesar datos, usa Python con pandas:

1. Importa pandas: import pandas as pd
2. Crea DataFrame: df = pd.DataFrame(data)
3. Aplica operaciones: df.mean(), df.sum(), df.groupby()
4. Retorna resultado: return result.to_dict()

Ejemplo:
import pandas as pd
data = [{"value": 10}, {"value": 20}, {"value": 30}]
df = pd.DataFrame(data)
result = df["value"].mean()
print(f"Promedio: {result}")
```

**Uso por el Agente:**
- El agente consulta esta skill cuando el usuario pide procesar datos
- Genera código siguiendo el patrón de la skill
- Ejecuta usando Secure Code Tool

### Skill 2: Cálculos Matemáticos

**Contenido de la Skill:**
```
Título: Cálculos Matemáticos con Python

Para cálculos matemáticos usa el módulo math:

1. Importa: import math
2. Funciones comunes:
   - math.sqrt(x) - raíz cuadrada
   - math.pow(x, y) - potencia
   - math.sin(x) - seno
   - math.pi - constante pi

Ejemplo:
import math
result = math.sqrt(144)
print(result)  # 12.0
```

### Skill 3: Manipulación de Strings

**Contenido de la Skill:**
```
Título: Manipulación de Strings en Python

Para manipular strings usa métodos nativos:

1. .upper() - convertir a mayúsculas
2. .lower() - convertir a minúsculas
3. .split() - dividir string
4. .join() - unir strings
5. re module - expresiones regulares

Ejemplo:
import re
text = "Hello World 123"
numbers = re.findall(r'\d+', text)
print(numbers)  # ['123']
```

## 🔒 Seguridad

### Aislamiento con nsjail

El código se ejecuta en un namespace completamente aislado:
- **Sin acceso al sistema host**: No puede modificar archivos fuera del sandbox
- **Límites de recursos**: CPU, memoria y tiempo estrictamente controlados
- **Sin red por defecto**: Aislamiento de red (opcional habilitar)
- **Usuario sin privilegios**: Ejecuta como `nobody:nogroup`

### Validaciones Adicionales

1. **Validación de Patrones Peligrosos**:
   - Detecta `os.system`, `subprocess`, `eval`, `exec`
   - Detecta operaciones de escritura de archivos
   - Detecta comandos de eliminación

2. **Whitelist de Imports** (Python):
   - Solo permite imports especificados
   - Previene importación de módulos peligrosos

3. **Límites Estrictos**:
   - Tamaño máximo de código
   - Tiempo máximo de ejecución
   - Memoria máxima
   - Tamaño máximo de salida (10MB)

## 📊 Ejemplo de Workflow Completo

### Setup del Workflow

```
┌─────────────────┐
│  Skills KB      │  (Vector Store con skills)
│  (LokiVector)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Agent Memory   │
│  Bridge         │  (Conecta Skills KB)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  AI Agent       │
│                 │
│  Tools:         │
│  - Secure Code  │
│    Tool         │
└─────────────────┘
```

### Ejemplo de Conversación

**Usuario**: "Calcula la raíz cuadrada de 256"

**Agente**:
1. Consulta Skills KB → Encuentra skill "Cálculos Matemáticos"
2. Lee: "Usa math.sqrt() para raíces cuadradas"
3. Genera código:
   ```python
   import math
   result = math.sqrt(256)
   print(result)
   ```
4. Ejecuta con Secure Code Tool
5. Retorna: "16.0"

## 🛠️ Instalación y Configuración

### 1. Instalar nsjail

```bash
# Verificar si está instalado
which nsjail

# Si no está, instalar
sudo apt-get update
sudo apt-get install nsjail

# O compilar desde fuente (más reciente)
git clone https://github.com/google/nsjail.git
cd nsjail
make
sudo make install
```

### 2. Configurar Permisos

```bash
# Opción recomendada: Usar capacidades
sudo setcap cap_sys_admin+ep $(which nsjail)

# Verificar
getcap $(which nsjail)
```

### 3. Agregar Nodo al Proyecto

El nodo ya está incluido en `package.json`. Solo necesitas:

```bash
cd n8n-nodes-starter
npm run build
./deploy-to-n8n.sh
```

### 4. Configurar Skills Knowledge Base

Crea skills en formato:

```json
{
  "pageContent": "Título: Procesamiento de Datos\n\nCuando necesites procesar datos...\n\nEjemplo:\nimport pandas as pd\n...",
  "metadata": {
    "skillName": "Procesamiento de Datos",
    "category": "Data Processing",
    "language": "python",
    "timestamp": 1234567890
  }
}
```

## ⚠️ Limitaciones y Consideraciones

### Limitaciones Actuales

1. **Solo Linux**: nsjail es específico de Linux
2. **Requiere Privilegios**: Necesita `CAP_SYS_ADMIN` o ejecutar como root
3. **Overhead**: ~50-100ms por ejecución (creación de namespace)
4. **Lenguajes Soportados**: Python, JavaScript, Bash (otros requieren configuración)

### Alternativas Multiplataforma

Si necesitas multiplataforma:
- **Docker**: Ejecutar código en contenedor aislado
- **gVisor**: Sandboxing de Google (muy seguro)
- **Firejail**: Alternativa más simple

## 🎯 Mejores Prácticas

### Para Skills

1. **Estructura Clara**:
   - Título descriptivo
   - Pasos numerados
   - Ejemplos de código completos
   - Casos de uso comunes

2. **Específicas y Accionables**:
   - ❌ "Procesa datos"
   - ✅ "Calcula promedio usando pandas: df.mean()"

3. **Incluir Ejemplos**:
   - Código funcional completo
   - Casos de uso reales
   - Manejo de errores

### Para el Agente

1. **Consultar Skills Primero**: Siempre buscar skills relevantes antes de generar código
2. **Seguir Patrones**: Usar los patrones de las skills como guía
3. **Validar Código**: El agente puede validar código antes de ejecutar
4. **Manejar Errores**: Preparar para errores de ejecución

## 📈 Métricas y Monitoreo

El nodo registra:
- Tiempo de ejecución
- Código de salida
- Errores (si los hay)
- Patrones peligrosos detectados

Puedes acceder a estos logs en la ejecución del workflow.

## 🔄 Flujo de Ejecución Detallado

1. **Agente recibe solicitud del usuario**
2. **Agente consulta Skills KB** (a través de Agent Memory Bridge)
3. **Agente encuentra skills relevantes** (ej: "Cálculos Matemáticos")
4. **Agente lee skill y entiende el patrón**
5. **Agente genera código** siguiendo el patrón de la skill
6. **Agente llama Secure Code Tool** con el código
7. **Secure Code Tool valida código** (patrones peligrosos, tamaño, etc.)
8. **Secure Code Tool prepara entorno** (directorio temporal, archivo de código)
9. **Secure Code Tool ejecuta con nsjail** (namespace aislado)
10. **Secure Code Tool captura resultado** (stdout, stderr, exit code)
11. **Secure Code Tool limpia** (elimina directorio temporal)
12. **Secure Code Tool retorna resultado** al agente
13. **Agente presenta resultado** al usuario

## 🚀 Próximos Pasos

1. **Probar con Skills Básicas**: Crear skills simples y probar el flujo
2. **Expandir Skills**: Agregar más skills según necesidades
3. **Optimizar**: Ajustar límites de recursos según uso
4. **Monitorear**: Revisar logs y métricas de ejecución

## 📚 Referencias

- [nsjail GitHub](https://github.com/google/nsjail)
- [Agent Memory Bridge Documentation](./DOCUMENTACION.md)
- [Skills Knowledge Base](./DOCUMENTACION.md#skills-knowledge-base)

