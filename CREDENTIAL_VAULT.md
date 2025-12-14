# Credential Vault - Vault Seguro de Credenciales para Agentes

## 📋 Descripción

El nodo **Credential Vault** permite a los agentes de IA usar credenciales de forma segura sin poder leerlas ni modificarlas. El agente puede especificar qué credencial usar y qué acción realizar (por ejemplo, hacer una petición HTTP), pero nunca tiene acceso a los valores reales de las credenciales.

## 🔒 Principio de Seguridad

**El agente puede USAR credenciales, pero NO puede LEERLAS ni MODIFICARLAS.**

```
┌─────────────────────────────────────────────────────────┐
│                    AI Agent                             │
│  ┌──────────────────────────────────────────────────┐  │
│  │ "Haz una petición a la API de OpenAI"            │  │
│  └──────────────┬───────────────────────────────────┘  │
│                 ▼                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │ Llama Credential Vault:                          │  │
│  │ {                                                 │  │
│  │   credentialName: "OpenAI API",                  │  │
│  │   action: "httpRequest",                         │  │
│  │   params: { url: "...", method: "POST" }         │  │
│  │ }                                                 │  │
│  └──────────────┬───────────────────────────────────┘  │
│                 ▼                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │ Credential Vault:                                │  │
│  │ 1. Obtiene credenciales (internamente)           │  │
│  │ 2. Aplica autenticación                         │  │
│  │ 3. Ejecuta petición HTTP                         │  │
│  │ 4. Retorna resultado                            │  │
│  │                                                  │  │
│  │ ❌ El agente NUNCA ve las credenciales          │  │
│  └──────────────┬───────────────────────────────────┘  │
│                 ▼                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │ Resultado: { data: "..." }                      │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## 🎯 Casos de Uso

### 1. Peticiones HTTP Autenticadas

El agente puede hacer peticiones a APIs que requieren autenticación:

```javascript
// El agente llama:
credentialVault({
  credentialName: "GitHub Token",
  action: "httpRequest",
  params: {
    url: "https://api.github.com/user",
    method: "GET"
  }
})

// El vault usa las credenciales internamente
// El agente recibe solo el resultado
```

### 2. Múltiples Credenciales

El vault puede contener múltiples credenciales:

- "OpenAI API" → Para llamadas a OpenAI
- "GitHub Token" → Para operaciones en GitHub
- "Database Credentials" → Para conexiones a BD
- "Stripe API" → Para pagos

El agente solo necesita especificar el nombre de la credencial.

### 3. Restricción de Dominios

Puedes restringir qué dominios pueden ser accedidos:

```
Allowed Domains: api.openai.com,api.github.com
```

Esto previene que el agente haga peticiones a dominios no autorizados.

## 🔧 Configuración

### 1. Agregar Credenciales al Vault

En la configuración del nodo, agrega credenciales:

```
Available Credentials:
  - Name: "OpenAI API"
    Type: "httpHeaderAuth"
    Description: "API key para OpenAI"
  
  - Name: "GitHub Token"
    Type: "httpHeaderAuth"
    Description: "Token de GitHub"
```

### 2. Configurar Credenciales en n8n

Para cada credencial, debes:
1. Crear la credencial en n8n (Settings → Credentials)
2. Asignarla al nodo Credential Vault
3. Especificar el tipo correcto (httpHeaderAuth, oAuth2Api, etc.)

### 3. Conectar al Agente

El nodo debe estar conectado como Tool al AI Agent.

## 📝 Formato de Entrada

El agente puede llamar la tool de dos formas:

### Formato 1: Objeto Directo
```javascript
credentialVault({
  credentialName: "OpenAI API",
  action: "httpRequest",
  params: {
    url: "https://api.openai.com/v1/models",
    method: "GET",
    headers: {
      "Content-Type": "application/json"
    }
  }
})
```

### Formato 2: String JSON
```javascript
credentialVault(JSON.stringify({
  credentialName: "GitHub Token",
  action: "httpRequest",
  params: {
    url: "https://api.github.com/user/repos",
    method: "GET"
  }
}))
```

## 🎬 Acciones Disponibles

### 1. `httpRequest` - Petición HTTP Autenticada

Hace una petición HTTP usando las credenciales especificadas.

**Parámetros:**
- `url` (requerido): URL de la petición
- `method` (opcional): Método HTTP (GET, POST, PUT, DELETE, etc.) - Default: GET
- `headers` (opcional): Headers adicionales
- `body` (opcional): Cuerpo de la petición (para POST/PUT)
- `qs` o `query` (opcional): Query parameters
- `timeout` (opcional): Timeout en milisegundos

**Ejemplo:**
```javascript
{
  credentialName: "OpenAI API",
  action: "httpRequest",
  params: {
    url: "https://api.openai.com/v1/chat/completions",
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    body: {
      model: "gpt-4",
      messages: [{ role: "user", content: "Hello" }]
    }
  }
}
```

### 2. `testConnection` - Probar Conexión

Verifica que una credencial esté disponible y configurada correctamente.

**Parámetros:**
- Ninguno (solo necesita `credentialName`)

**Ejemplo:**
```javascript
{
  credentialName: "OpenAI API",
  action: "testConnection"
}
```

## 🔐 Seguridad

### Protecciones Implementadas

1. **Sin Exposición de Credenciales**:
   - Las credenciales se obtienen internamente usando `getCredentials()`
   - Se usan a través de `httpRequestWithAuthentication()`
   - El agente nunca ve los valores reales

2. **Restricción de Dominios**:
   - Puedes especificar dominios permitidos
   - El vault valida la URL antes de hacer la petición
   - Previene peticiones a dominios no autorizados

3. **Validación de Credenciales**:
   - Solo las credenciales configuradas en el vault están disponibles
   - El agente no puede acceder a credenciales no listadas

4. **Timeouts Configurables**:
   - Límite de tiempo máximo para peticiones
   - Previene peticiones que se cuelguen indefinidamente

### Tipos de Credenciales Soportados

- `httpHeaderAuth` - Autenticación por header (API keys, tokens)
- `httpBasicAuth` - Autenticación básica HTTP
- `httpQueryAuth` - Autenticación por query parameter
- `oAuth2Api` - OAuth 2.0
- `oAuth1Api` - OAuth 1.0
- `httpDigestAuth` - Digest authentication
- `httpCustomAuth` - Autenticación personalizada

## 📊 Ejemplo de Workflow Completo

### Setup del Workflow

```
┌─────────────────┐
│  Credential     │  (Configurar credenciales)
│  Vault          │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  AI Agent       │
│                 │
│  Tools:         │
│  - Credential   │
│    Vault        │
└─────────────────┘
```

### Ejemplo de Conversación

**Usuario**: "Obtén mi información de GitHub"

**Agente**:
1. Identifica que necesita hacer una petición a GitHub
2. Llama Credential Vault:
   ```javascript
   {
     credentialName: "GitHub Token",
     action: "httpRequest",
     params: {
       url: "https://api.github.com/user",
       method: "GET"
     }
   }
   ```
3. Credential Vault:
   - Obtiene credenciales internamente (el agente no las ve)
   - Aplica autenticación
   - Hace la petición
   - Retorna resultado
4. Agente presenta resultado al usuario

## 🛠️ Instalación y Configuración

### 1. Agregar Nodo al Proyecto

El nodo ya está incluido en `package.json`. Solo necesitas:

```bash
cd n8n-nodes-starter
npm run build
./deploy-to-n8n.sh
```

### 2. Configurar Credenciales

1. **Crear Credenciales en n8n**:
   - Ve a Settings → Credentials
   - Crea las credenciales necesarias (OpenAI, GitHub, etc.)

2. **Configurar el Vault**:
   - Agrega el nodo Credential Vault
   - En "Available Credentials", agrega cada credencial:
     - Name: Nombre amigable (ej: "OpenAI API")
     - Type: Tipo de credencial (ej: "httpHeaderAuth")
     - Description: Descripción opcional
   - Asigna las credenciales reales al nodo

3. **Configurar Restricciones** (Opcional):
   - "Allowed Domains": Lista de dominios permitidos
   - "Max Request Timeout": Tiempo máximo de petición

### 3. Conectar al Agente

- Conecta Credential Vault como Tool al AI Agent
- El agente ahora puede usar las credenciales de forma segura

## ⚠️ Limitaciones y Consideraciones

### Limitaciones Actuales

1. **Solo HTTP Requests**: Actualmente solo soporta peticiones HTTP
2. **Sin Modificación**: El agente no puede modificar credenciales (por diseño)
3. **Sin Lectura**: El agente no puede leer valores de credenciales (por diseño)

### Mejores Prácticas

1. **Nombres Descriptivos**: Usa nombres claros para las credenciales (ej: "OpenAI API" en lugar de "cred1")
2. **Restricción de Dominios**: Siempre especifica dominios permitidos en producción
3. **Timeouts Apropiados**: Configura timeouts según tus necesidades
4. **Documentación**: Usa descriptions para documentar qué hace cada credencial

## 🎯 Casos de Uso Avanzados

### 1. Múltiples APIs

El agente puede usar diferentes credenciales según la necesidad:

```javascript
// Para OpenAI
credentialVault({
  credentialName: "OpenAI API",
  action: "httpRequest",
  params: { url: "https://api.openai.com/..." }
})

// Para GitHub
credentialVault({
  credentialName: "GitHub Token",
  action: "httpRequest",
  params: { url: "https://api.github.com/..." }
})
```

### 2. Integración con Skills

Las skills pueden guiar al agente sobre qué credencial usar:

```
Skill: "Para llamar a la API de OpenAI, usa la credencial 'OpenAI API'"
```

El agente consulta la skill, identifica la credencial correcta, y la usa.

## 📈 Monitoreo y Logs

El vault registra:
- Qué credenciales se usan
- URLs accedidas
- Errores de autenticación
- Timeouts

Puedes acceder a estos logs en la ejecución del workflow.

## 🔄 Flujo de Ejecución Detallado

1. **Agente recibe solicitud del usuario**
2. **Agente identifica necesidad de credenciales**
3. **Agente llama Credential Vault** con:
   - `credentialName`: Nombre de la credencial
   - `action`: Acción a realizar
   - `params`: Parámetros de la acción
4. **Credential Vault valida**:
   - Credencial existe en el vault
   - Dominio permitido (si está configurado)
5. **Credential Vault obtiene credenciales** (internamente, sin exponer)
6. **Credential Vault aplica autenticación** usando n8n's credential system
7. **Credential Vault ejecuta acción** (HTTP request, etc.)
8. **Credential Vault retorna resultado** (sin credenciales)
9. **Agente presenta resultado** al usuario

## 🚀 Próximos Pasos

1. **Configurar Credenciales**: Crea las credenciales necesarias en n8n
2. **Agregar al Vault**: Configura el vault con las credenciales
3. **Conectar al Agente**: Conecta el vault como tool
4. **Probar**: Prueba haciendo peticiones desde el agente

## 📚 Referencias

- [Agent Memory Bridge Documentation](./DOCUMENTACION.md)
- [Secure Code Tool](./SECURE_CODE_TOOL.md)
- [n8n Credentials Documentation](https://docs.n8n.io/integrations/credentials/)

