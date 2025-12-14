# Configuración de Git y Respaldo en GitHub

## Estado Actual

✅ Repositorio git inicializado
✅ Todos los archivos agregados al staging
✅ Commit inicial realizado
✅ Remoto configurado: `https://github.com/MauricioPerera/nodes.git`
✅ Rama: `main`

## Próximos Pasos

Para hacer push al repositorio de GitHub, necesitas autenticarte. Tienes dos opciones:

### Opción 1: Usar Personal Access Token (Recomendado)

1. **Crear un Personal Access Token en GitHub:**
   - Ve a: https://github.com/settings/tokens
   - Click en "Generate new token (classic)"
   - Selecciona los scopes: `repo` (acceso completo a repositorios)
   - Genera el token y cópialo

2. **Hacer push usando el token:**
   ```bash
   cd "/home/mauricioperera/Projects/n8n nodes/agent memory bridge"
   git push -u origin main
   ```
   - Cuando pida usuario: tu nombre de usuario de GitHub
   - Cuando pida contraseña: pega el Personal Access Token

### Opción 2: Configurar SSH

1. **Generar clave SSH (si no tienes una):**
   ```bash
   ssh-keygen -t ed25519 -C "tu_email@example.com"
   ```

2. **Agregar la clave pública a GitHub:**
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
   - Copia la salida
   - Ve a: https://github.com/settings/keys
   - Click en "New SSH key"
   - Pega la clave pública

3. **Cambiar el remoto a SSH:**
   ```bash
   cd "/home/mauricioperera/Projects/n8n nodes/agent memory bridge"
   git remote set-url origin git@github.com:MauricioPerera/nodes.git
   git push -u origin main
   ```

### Opción 3: Usar GitHub CLI

Si tienes `gh` instalado:
```bash
gh auth login
cd "/home/mauricioperera/Projects/n8n nodes/agent memory bridge"
git push -u origin main
```

## Verificar Estado

```bash
cd "/home/mauricioperera/Projects/n8n nodes/agent memory bridge"
git status
git log --oneline -5
git remote -v
```

## Comandos Útiles

### Ver cambios pendientes
```bash
git status
```

### Agregar cambios
```bash
git add .
git commit -m "descripción de los cambios"
```

### Hacer push
```bash
git push origin main
```

### Ver historial
```bash
git log --oneline -10
```

## Nota sobre Repositorios Embebidos

El repositorio contiene algunos subdirectorios que son repositorios git embebidos:
- `LOKIVECTOR`
- `n8n`
- `n8n-docs`
- `n8n-nodes-rckflr-TextEmbeddings`
- `n8n-nodes-starter`

Estos se han agregado como submodules. Si necesitas actualizarlos:

```bash
git submodule update --init --recursive
```

O si prefieres excluirlos, agrégalos al `.gitignore`.

