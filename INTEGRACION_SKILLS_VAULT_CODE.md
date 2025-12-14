# Integración: Skills + Credential Vault + Secure Code Tool

## 📋 Descripción

Esta guía explica cómo integrar **Skills Knowledge Base**, **Credential Vault** y **Secure Code Tool** para permitir que el agente ejecute código de forma segura usando credenciales, guiado por skills.

## 🎯 Flujo Completo

```
Usuario: "Procesa estos datos usando la API de OpenAI"

1. Agente consulta Skills KB
   → Encuentra skill: "Procesamiento con OpenAI API"
   → Skill contiene: código Python + referencia a credencial "OpenAI API"

2. Agente llama Credential Vault
   → Obtiene credenciales (sin verlas)
   → Las credenciales están listas para usar

3. Agente llama Secure Code Tool
   → Pasa código de la skill
   → Pasa credenciales (como variables de entorno)
   → Código se ejecuta en nsjail con credenciales disponibles

4. Resultado retornado al usuario
```

## 🔧 Configuración

### 1. Setup del Workflow

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
│  - Credential   │
│    Vault        │
│  - Secure Code  │
│    Tool         │
└─────────────────┘
```

### 2. Configurar Skills con Referencias a Credenciales

Las skills deben incluir:
- Código de ejemplo
- Referencia a qué credencial usar
- Nombre de variable de entorno sugerido

**Ejemplo de Skill:**

```json
{
  "pageContent": "Título: Procesamiento con OpenAI API\n\nPara procesar datos usando la API de OpenAI:\n\n1. Usa la credencial 'OpenAI API' del vault\n2. La API key estará disponible como variable de entorno: OPENAI_API_KEY\n3. Código de ejemplo:\n\nimport os\nimport requests\n\napi_key = os.environ.get('OPENAI_API_KEY')\nheaders = {'Authorization': f'Bearer {api_key}'}\nresponse = requests.post('https://api.openai.com/v1/chat/completions', headers=headers, json=data)\nprint(response.json())\n\nNota: El código debe usar variables de entorno, nunca hardcodear credenciales.",
  "metadata": {
    "skillName": "Procesamiento con OpenAI API",
    "category": "API Integration",
    "language": "python",
    "credentialName": "OpenAI API",
    "envVarName": "OPENAI_API_KEY",
    "timestamp": 1234567890
  }
}
```

### 3. Configurar Credential Vault

1. Agregar credenciales al vault:
   - Name: "OpenAI API"
   - Type: "httpHeaderAuth"
   - Description: "API key para OpenAI"

2. Asignar la credencial real en n8n

### 4. Configurar Secure Code Tool

1. Habilitar "Enable Credential Injection"
2. El agente pasará las credenciales en el input

## 📝 Uso por el Agente

### Flujo de Ejecución

**Paso 1: Consultar Skills**

El agente consulta Skills KB cuando el usuario pide algo que requiere código:

```javascript
// El agente busca en Skills KB
// Encuentra: "Procesamiento con OpenAI API"
// Lee: usar credencial "OpenAI API", variable de entorno "OPENAI_API_KEY"
```

**Paso 2: Obtener Credenciales del Vault**

El agente llama Credential Vault para obtener las credenciales (sin verlas):

```javascript
// El agente NO puede hacer esto directamente
// En su lugar, el agente debe pasar las credenciales como parte del código
// O usar un flujo donde Secure Code Tool obtiene las credenciales

// Opción 1: El agente llama el vault primero (para validar)
credentialVault({
  credentialName: "OpenAI API",
  action: "testConnection"
})

// Opción 2: Pasar referencia en el código (recomendado)
```

**Paso 3: Ejecutar Código con Credenciales**

El agente llama Secure Code Tool con código y referencias a credenciales:

```javascript
secureCodeTool({
  code: `
import os
import requests

api_key = os.environ.get('OPENAI_API_KEY')
headers = {'Authorization': f'Bearer {api_key}'}
response = requests.post('https://api.openai.com/v1/chat/completions', 
                         headers=headers, 
                         json={'model': 'gpt-4', 'messages': [...]})
print(response.json())
  `,
  language: "python",
  credentials: [
    {
      vaultName: "OpenAI API",
      envVarName: "OPENAI_API_KEY"
    }
  ]
})
```

**Nota**: En la implementación actual, las credenciales deben pasarse directamente como datos en el campo `credentials`, no como referencias. El agente debe obtenerlas del vault primero.

## 🔄 Flujo Alternativo (Recomendado)

Dado que el agente no puede obtener credenciales directamente del vault (por seguridad), el flujo recomendado es:

### Opción A: Credenciales en Skills (Solo Referencias)

Las skills solo contienen referencias a credenciales, no los valores:

```json
{
  "pageContent": "Usa la credencial 'OpenAI API' disponible como OPENAI_API_KEY",
  "metadata": {
    "credentialName": "OpenAI API",
    "envVarName": "OPENAI_API_KEY"
  }
}
```

El agente genera código que usa la variable de entorno, y Secure Code Tool debe tener las credenciales pre-configuradas o el usuario debe configurarlas manualmente.

### Opción B: Secure Code Tool con Credenciales Pre-configuradas

Secure Code Tool puede tener credenciales pre-configuradas que se inyectan automáticamente:

1. Configurar credenciales en Secure Code Tool
2. El agente solo especifica qué credencial usar por nombre
3. Secure Code Tool inyecta automáticamente

## 🛠️ Implementación Actual

### Funcionamiento

1. **El agente consulta Skills**: Las skills indican qué credenciales usar
2. **El agente llama Credential Vault**: Para obtener credenciales (sin verlas)
3. **El agente pasa credenciales a Secure Code Tool**: Como parte del input
4. **Secure Code Tool inyecta credenciales**: Como variables de entorno en el código ejecutado

### Flujo de Credenciales

**IMPORTANTE**: El agente NO puede leer credenciales directamente. Debe:
1. Llamar Credential Vault con `getCredentialForInjection`
2. Recibir las credenciales (como JSON)
3. Pasarlas a Secure Code Tool en el campo `credentials`

**Ejemplo de flujo del agente:**

```javascript
// Paso 1: Obtener credenciales del vault
const credResponse = await credentialVault({
  credentialName: "OpenAI API",
  action: "getCredentialForInjection",
  params: { envVarName: "OPENAI_API_KEY" }
});

// Paso 2: Parsear respuesta (contiene credenciales como JSON)
const credentials = JSON.parse(credResponse);

// Paso 3: Ejecutar código con credenciales
await secureCodeTool({
  code: "import os\napi_key = os.environ.get('OPENAI_API_KEY')",
  credentials: [
    {
      envVarName: "OPENAI_API_KEY",
      credentialName: credentials // Credenciales obtenidas del vault
    }
  ]
});
```

### Limitaciones

1. **El agente debe llamar el vault primero**: No hay acceso directo automático
2. **Credenciales se pasan explícitamente**: Deben incluirse en el input de Secure Code Tool
3. **Solo variables de entorno**: Las credenciales se inyectan como env vars, no están en el código

## 🎯 Mejores Prácticas

### Para Skills

1. **Incluir Referencias a Credenciales**:
   ```
   "Usa la credencial 'OpenAI API' disponible como OPENAI_API_KEY"
   ```

2. **Documentar Variables de Entorno**:
   ```
   "La API key estará en: os.environ.get('OPENAI_API_KEY')"
   ```

3. **Ejemplos de Código Seguro**:
   ```
   "NUNCA hardcodear credenciales. Siempre usar variables de entorno."
   ```

### Para el Agente

1. **Consultar Skills Primero**: Siempre buscar skills relevantes
2. **Identificar Credenciales Necesarias**: De las skills, identificar qué credenciales se necesitan
3. **Generar Código Seguro**: Código que use variables de entorno, no valores hardcodeados
4. **Validar con Vault**: Usar `testConnection` para verificar que las credenciales existen

## 📊 Ejemplo Completo

### Skill en Skills KB

```json
{
  "pageContent": "Título: Llamar API de GitHub\n\nPara hacer peticiones a la API de GitHub:\n\n1. Usa credencial 'GitHub Token'\n2. Token disponible como GITHUB_TOKEN\n3. Código:\n\nimport os\nimport requests\n\ntoken = os.environ.get('GITHUB_TOKEN')\nheaders = {'Authorization': f'token {token}'}\nresponse = requests.get('https://api.github.com/user', headers=headers)\nprint(response.json())",
  "metadata": {
    "skillName": "GitHub API",
    "credentialName": "GitHub Token",
    "envVarName": "GITHUB_TOKEN"
  }
}
```

### Flujo del Agente

1. Usuario: "Obtén mi información de GitHub"
2. Agente consulta Skills → Encuentra "GitHub API"
3. Agente genera código basado en la skill
4. Agente llama Secure Code Tool:
   ```javascript
   {
     code: "import os\nimport requests\ntoken = os.environ.get('GITHUB_TOKEN')\nheaders = {'Authorization': f'token {token}'}\nresponse = requests.get('https://api.github.com/user', headers=headers)\nprint(response.json())",
     language: "python",
     credentials: [
       {
         vaultName: "GitHub Token",
         envVarName: "GITHUB_TOKEN",
         credentialName: { "token": "ghp_xxxxx" } // Valores obtenidos del vault
       }
     ]
   }
   ```
5. Secure Code Tool inyecta credenciales como variables de entorno
6. Código se ejecuta con credenciales disponibles
7. Resultado retornado

## 🚀 Próximos Pasos

1. **Mejorar Integración**: Permitir que Secure Code Tool obtenga credenciales directamente del vault
2. **Skills Mejoradas**: Skills que incluyan plantillas de código con placeholders para credenciales
3. **Validación Automática**: Verificar que las credenciales necesarias estén disponibles antes de ejecutar código

## 📚 Referencias

- [Agent Memory Bridge](./DOCUMENTACION.md#agent-memory-bridge)
- [Secure Code Tool](./SECURE_CODE_TOOL.md)
- [Credential Vault](./CREDENTIAL_VAULT.md)

