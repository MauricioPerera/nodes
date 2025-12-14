# Análisis: Nodo Tool con nsjail para Ejecución Segura de Código

## 📋 Resumen Ejecutivo

**Viabilidad**: ✅ **ALTA** - Técnicamente viable con consideraciones importantes

**Recomendación**: Implementar con arquitectura híbrida (nsjail + validaciones adicionales)

**Complejidad**: Media-Alta (requiere integración con sistema operativo y gestión de procesos)

---

## 🎯 Objetivo

Crear un nodo tipo Tool para agentes de IA que ejecute código de forma segura usando `nsjail`, proporcionando un nivel de aislamiento superior al sandboxing actual de n8n.

---

## 🔍 Análisis Técnico

### 1. Estado Actual de Ejecución de Código en n8n

#### ToolCode Actual
- **JavaScript**: Usa `JsTaskRunnerSandbox` o `vm2` (legacy)
- **Python**: Usa `PythonTaskRunnerSandbox` o `Pyodide` (en navegador)
- **Limitaciones**:
  - Aislamiento a nivel de proceso Node.js/Python
  - No hay aislamiento completo del sistema operativo
  - Riesgos de escape del sandbox
  - Acceso limitado pero no completamente restringido a recursos del sistema

#### Estructura de un Tool Node
```typescript
// Ejemplo basado en ToolCode.node.ts
export class ToolCode implements INodeType {
  description: INodeTypeDescription = {
    displayName: 'Code Tool',
    name: 'toolCode',
    usableAsTool: true, // ← Clave para que funcione como tool
    codex: {
      categories: ['AI'],
      subcategories: { AI: ['Tools'] },
    },
    // ...
  };

  async supplyData(this: ISupplyDataFunctions): Promise<SupplyData> {
    // Retorna una función que el agente puede llamar
    return {
      response: async (query: string) => {
        // Ejecutar código aquí
        return result;
      },
    };
  }
}
```

---

## 🛡️ nsjail: Análisis de Seguridad

### ¿Qué es nsjail?

`nsjail` es una herramienta de sandboxing a nivel de sistema operativo que:
- Usa namespaces de Linux (user, PID, mount, network, IPC, UTS)
- Proporciona aislamiento completo del sistema host
- Permite configurar límites de recursos (CPU, memoria, tiempo)
- Restringe acceso a archivos y red
- Soporta múltiples lenguajes (Python, Node.js, C, etc.)

### Ventajas sobre Sandboxing Actual

| Aspecto | Sandbox Actual (vm2/Pyodide) | nsjail |
|---------|------------------------------|--------|
| **Aislamiento** | Proceso aislado | Namespace completo del OS |
| **Escape de Sandbox** | Posible con exploits | Muy difícil (requiere escape de namespace) |
| **Límites de Recursos** | Limitados | CPU, memoria, tiempo configurables |
| **Acceso a Sistema** | Limitado pero presente | Completamente restringido |
| **Overhead** | Bajo | Medio (creación de namespace) |
| **Compatibilidad** | Solo Node.js/Python | Cualquier lenguaje/binario |

---

## 🏗️ Arquitectura Propuesta

### Diseño del Nodo

```
┌─────────────────────────────────────────┐
│     Agent Memory Bridge (AI Agent)      │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│      Secure Code Tool (nsjail)          │
│  ┌──────────────────────────────────┐  │
│  │ 1. Validación de Código            │  │
│  │    - Sintaxis                      │  │
│  │    - Patrones peligrosos           │  │
│  │    - Límites de tamaño             │  │
│  └──────────────┬─────────────────────┘  │
│                 ▼                         │
│  ┌──────────────────────────────────┐   │
│  │ 2. Preparación de Entorno         │   │
│  │    - Crear directorio temporal    │   │
│  │    - Copiar código                │   │
│  │    - Configurar nsjail            │   │
│  └──────────────┬─────────────────────┘   │
│                 ▼                         │
│  ┌──────────────────────────────────┐   │
│  │ 3. Ejecución con nsjail          │   │
│  │    nsjail --config config.json   │   │
│  │      -- /usr/bin/python3 code.py │   │
│  └──────────────┬─────────────────────┘   │
│                 ▼                         │
│  ┌──────────────────────────────────┐   │
│  │ 4. Captura de Resultados         │   │
│  │    - stdout/stderr               │   │
│  │    - Código de salida            │   │
│  │    - Métricas (tiempo, memoria)  │   │
│  └──────────────┬─────────────────────┘   │
│                 ▼                         │
│  ┌──────────────────────────────────┐   │
│  │ 5. Limpieza                       │   │
│  │    - Eliminar directorio temp    │   │
│  │    - Liberar recursos            │   │
│  └──────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

### Estructura del Código

```typescript
// SecureCodeTool.node.ts
import { exec } from 'child_process';
import { promisify } from 'util';
import { writeFile, mkdtemp, rm } from 'fs/promises';
import { join } from 'path';
import { tmpdir } from 'os';

const execAsync = promisify(exec);

export class SecureCodeTool implements INodeType {
  description: INodeTypeDescription = {
    displayName: 'Secure Code Tool',
    name: 'secureCodeTool',
    icon: 'fa:shield-alt',
    group: ['transform'],
    version: 1,
    description: 'Execute code securely using nsjail sandboxing',
    usableAsTool: true,
    codex: {
      categories: ['AI'],
      subcategories: { AI: ['Tools'] },
    },
    properties: [
      {
        displayName: 'Language',
        name: 'language',
        type: 'options',
        options: [
          { name: 'Python', value: 'python' },
          { name: 'JavaScript (Node.js)', value: 'javascript' },
          { name: 'Bash', value: 'bash' },
        ],
        default: 'python',
        required: true,
      },
      {
        displayName: 'Max Execution Time (seconds)',
        name: 'maxTime',
        type: 'number',
        default: 30,
        typeOptions: { minValue: 1, maxValue: 300 },
      },
      {
        displayName: 'Max Memory (MB)',
        name: 'maxMemory',
        type: 'number',
        default: 128,
        typeOptions: { minValue: 16, maxValue: 1024 },
      },
      {
        displayName: 'Enable Network',
        name: 'enableNetwork',
        type: 'boolean',
        default: false,
        description: 'Allow network access (increases security risk)',
      },
    ],
  };

  async supplyData(this: ISupplyDataFunctions): Promise<SupplyData> {
    const language = this.getNodeParameter('language', 0) as string;
    const maxTime = this.getNodeParameter('maxTime', 0) as number;
    const maxMemory = this.getNodeParameter('maxMemory', 0) as number;
    const enableNetwork = this.getNodeParameter('enableNetwork', 0) as boolean;

    const toolHandler = async (query: string | IDataObject): Promise<string> => {
      const code = typeof query === 'string' ? query : (query.code as string);
      
      if (!code || typeof code !== 'string') {
        throw new NodeOperationError(
          this.getNode(),
          'Code must be a non-empty string',
        );
      }

      // 1. Validación de código
      this.validateCode(code, language);

      // 2. Preparar entorno
      const workDir = await mkdtemp(join(tmpdir(), 'nsjail-'));
      const codeFile = this.getCodeFileName(language);
      const codePath = join(workDir, codeFile);

      try {
        // Escribir código a archivo
        await writeFile(codePath, code, 'utf-8');

        // 3. Ejecutar con nsjail
        const result = await this.executeWithNsjail({
          codePath,
          language,
          maxTime,
          maxMemory,
          enableNetwork,
          workDir,
        });

        return result.output;
      } catch (error) {
        throw new NodeOperationError(
          this.getNode(),
          `Execution failed: ${(error as Error).message}`,
        );
      } finally {
        // 5. Limpieza
        await rm(workDir, { recursive: true, force: true });
      }
    };

    return {
      response: toolHandler,
    };
  }

  private validateCode(code: string, language: string): void {
    // Validaciones básicas
    if (code.length > 100000) {
      throw new NodeOperationError(
        this.getNode(),
        'Code exceeds maximum length (100KB)',
      );
    }

    // Patrones peligrosos
    const dangerousPatterns = [
      /import\s+os\s*$/m, // En algunos contextos
      /subprocess|exec|eval|__import__/,
      /fs\.|require\(['"]fs['"]\)/,
      /child_process|spawn|exec/,
    ];

    for (const pattern of dangerousPatterns) {
      if (pattern.test(code)) {
        this.logger.warn('Potentially dangerous pattern detected', { pattern });
        // Podría ser un false positive, solo loguear
      }
    }
  }

  private getCodeFileName(language: string): string {
    const extensions: Record<string, string> = {
      python: 'code.py',
      javascript: 'code.js',
      bash: 'code.sh',
    };
    return extensions[language] || 'code.txt';
  }

  private async executeWithNsjail(config: {
    codePath: string;
    language: string;
    maxTime: number;
    maxMemory: number;
    enableNetwork: boolean;
    workDir: string;
  }): Promise<{ output: string; exitCode: number; metrics: any }> {
    const { codePath, language, maxTime, maxMemory, enableNetwork, workDir } = config;

    // Determinar comando según lenguaje
    const command = this.getExecutionCommand(language, codePath);

    // Configuración de nsjail
    const nsjailArgs = [
      '--config', '/dev/stdin', // Leer config desde stdin
      '--chroot', workDir,
      '--user', 'nobody',
      '--group', 'nogroup',
      '--time_limit', maxTime.toString(),
      '--rlimit_as', (maxMemory * 1024 * 1024).toString(), // MB a bytes
      '--rlimit_core', '0', // Sin core dumps
      '--rlimit_fsize', (10 * 1024 * 1024).toString(), // 10MB max file size
      '--rlimit_nofile', '32',
      '--rlimit_nproc', '1', // Solo un proceso
      '--disable_clone_newnet', enableNetwork ? 'false' : 'true', // Red
      '--disable_clone_newuser', 'false',
      '--disable_clone_newns', 'false',
      '--disable_clone_newpid', 'false',
      '--disable_clone_newipc', 'false',
      '--disable_clone_newuts', 'false',
      '--disable_clone_newcgroup', 'false',
      '--cgroup_mem_max', (maxMemory * 1024 * 1024).toString(),
      '--cgroup_pids_max', '1',
      '--cgroup_cpu_ms_per_sec', '100', // 100% CPU permitido
      '--', // Separador: después de esto viene el comando
      ...command,
    ];

    const startTime = Date.now();
    
    try {
      const { stdout, stderr } = await execAsync(
        `nsjail ${nsjailArgs.join(' ')}`,
        {
          timeout: (maxTime + 5) * 1000, // +5 segundos de margen
          maxBuffer: 10 * 1024 * 1024, // 10MB max output
        },
      );

      const executionTime = Date.now() - startTime;

      return {
        output: stdout || stderr || '',
        exitCode: 0,
        metrics: {
          executionTime,
          memoryUsed: 'N/A', // nsjail no reporta esto directamente
        },
      };
    } catch (error: any) {
      const executionTime = Date.now() - startTime;
      
      // nsjail puede retornar códigos de error específicos
      const exitCode = error.code || 1;
      
      return {
        output: error.stderr || error.message || 'Execution failed',
        exitCode,
        metrics: {
          executionTime,
          error: true,
        },
      };
    }
  }

  private getExecutionCommand(language: string, codePath: string): string[] {
    const commands: Record<string, string[]> = {
      python: ['/usr/bin/python3', codePath],
      javascript: ['/usr/bin/node', codePath],
      bash: ['/bin/bash', codePath],
    };

    return commands[language] || ['/bin/cat', codePath];
  }
}
```

---

## ⚠️ Consideraciones y Desafíos

### 1. Requisitos del Sistema

**Dependencias**:
- `nsjail` instalado en el sistema
- Permisos para crear namespaces (requiere `CAP_SYS_ADMIN` o ejecutar como root)
- Espacio en disco para directorios temporales
- Recursos suficientes para crear namespaces

**Solución**: 
- Verificar disponibilidad de nsjail al inicializar
- Documentar requisitos de instalación
- Proporcionar script de instalación

### 2. Permisos y Seguridad

**Problema**: nsjail requiere privilegios elevados para crear namespaces.

**Soluciones**:
- **Opción A**: Ejecutar n8n con capacidades necesarias
  ```bash
  sudo setcap cap_sys_admin+ep /usr/bin/node
  ```
- **Opción B**: Usar `nsjail` con `--mode o` (usando overlayfs)
- **Opción C**: Ejecutar en contenedor Docker con privilegios

### 3. Performance

**Overhead**:
- Creación de namespace: ~50-100ms
- Ejecución: similar a ejecución normal
- Limpieza: ~10-20ms

**Optimización**:
- Pool de namespaces pre-creados (avanzado)
- Reutilización de directorios temporales
- Caché de validaciones

### 4. Compatibilidad Multiplataforma

**Problema**: nsjail es específico de Linux.

**Soluciones**:
- **Linux**: Usar nsjail completo
- **macOS/Windows**: Fallback a sandboxing actual o Docker
- **Docker**: Ejecutar código en contenedor aislado

### 5. Gestión de Errores

**Consideraciones**:
- Timeouts deben ser manejados correctamente
- Errores de nsjail deben ser parseados
- Logs deben ser claros para debugging

---

## 🔒 Mejoras de Seguridad Adicionales

### 1. Validación de Código Pre-ejecución

```typescript
private validateCodeAdvanced(code: string, language: string): void {
  // AST parsing para detectar patrones peligrosos
  // Whitelist de imports permitidos
  // Límites de complejidad ciclomática
  // Detección de bucles infinitos potenciales
}
```

### 2. Rate Limiting

```typescript
private executionQueue: Map<string, number> = new Map();

private async checkRateLimit(sessionId: string): Promise<void> {
  const now = Date.now();
  const lastExecution = this.executionQueue.get(sessionId) || 0;
  const minInterval = 1000; // 1 segundo entre ejecuciones

  if (now - lastExecution < minInterval) {
    throw new NodeOperationError(
      this.getNode(),
      'Rate limit exceeded. Please wait before executing again.',
    );
  }

  this.executionQueue.set(sessionId, now);
}
```

### 3. Monitoreo y Auditoría

```typescript
private logExecution(code: string, result: any, metrics: any): void {
  this.logger.info('Code execution completed', {
    codeLength: code.length,
    language: this.language,
    executionTime: metrics.executionTime,
    exitCode: result.exitCode,
    sessionId: this.sessionId,
    timestamp: Date.now(),
  });
}
```

---

## 📊 Comparación de Opciones

| Opción | Seguridad | Performance | Complejidad | Recomendación |
|--------|-----------|-------------|-------------|---------------|
| **nsjail** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ✅ Mejor para producción |
| **Docker** | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ✅ Alternativa multiplataforma |
| **Firejail** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ | ⚠️ Menos mantenido |
| **gVisor** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ✅ Google, muy seguro |
| **Sandbox Actual** | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐ | ❌ No suficiente para código arbitrario |

---

## 🚀 Plan de Implementación

### Fase 1: Prototipo Básico (1-2 semanas)
1. ✅ Crear estructura básica del nodo
2. ✅ Integración básica con nsjail
3. ✅ Soporte para Python
4. ✅ Validaciones básicas
5. ✅ Manejo de errores

### Fase 2: Mejoras de Seguridad (1 semana)
1. ✅ Validación avanzada de código
2. ✅ Rate limiting
3. ✅ Monitoreo y logging
4. ✅ Métricas de ejecución

### Fase 3: Soporte Multi-lenguaje (1 semana)
1. ✅ JavaScript/Node.js
2. ✅ Bash
3. ✅ Otros lenguajes según necesidad

### Fase 4: Optimización (1 semana)
1. ✅ Pool de namespaces
2. ✅ Caché de validaciones
3. ✅ Mejoras de performance

### Fase 5: Documentación y Testing (1 semana)
1. ✅ Documentación completa
2. ✅ Tests unitarios
3. ✅ Tests de seguridad
4. ✅ Guía de instalación

---

## 🎯 Recomendaciones Finales

### ✅ Implementar si:
- Necesitas ejecutar código arbitrario de usuarios
- La seguridad es crítica
- Tienes control sobre el sistema (Linux)
- Puedes instalar nsjail

### ⚠️ Considerar alternativas si:
- Necesitas multiplataforma (usar Docker)
- No puedes instalar nsjail (usar gVisor o Firejail)
- Performance es crítico (optimizar o usar sandbox actual)

### 🔒 Mejores Prácticas:
1. **Siempre validar código antes de ejecutar**
2. **Limitar recursos estrictamente**
3. **Monitorear todas las ejecuciones**
4. **Mantener nsjail actualizado**
5. **Usar whitelist de imports/funciones cuando sea posible**
6. **Implementar rate limiting**
7. **Logging completo para auditoría**

---

## 📝 Conclusión

**Viabilidad**: ✅ **ALTA**

Crear un nodo Tool con nsjail es **técnicamente viable y altamente recomendable** para ejecución segura de código. Proporciona un nivel de seguridad significativamente superior al sandboxing actual de n8n.

**Próximos Pasos**:
1. Verificar disponibilidad de nsjail en el sistema objetivo
2. Crear prototipo básico con Python
3. Probar en entorno controlado
4. Iterar basado en feedback y necesidades

**Riesgo Principal**: Requisitos de permisos del sistema. Debe planificarse la instalación y configuración adecuada.

