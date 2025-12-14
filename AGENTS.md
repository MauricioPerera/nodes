# AGENTS.md

## Project Overview
This project provides a set of custom nodes for n8n designed to enhance AI agents with advanced semantic memory, local embeddings, vector storage, and secure execution tools. It includes:
- **Agent Memory Bridge**: Advanced memory management.
- **Local Embeddings**: 100% local text embeddings using Hugging Face models.
- **Vector Store LokiVector**: Local embedded vector database (HNSW).
- **Secure Code Tool**: Sandboxed code execution using `nsjail`.
- **Credential Vault**: Secure credential management for agents.

## Installation (NPM)
These nodes are published on NPM and can be installed directly:

- `n8n-nodes-agent-memory-bridge` (Verified)
- `n8n-nodes-credential-vault` (Verified)
- `n8n-nodes-local-embeddings`
- `n8n-nodes-lokivector-store`
- `n8n-nodes-secure-code-tool`

## Development Setup
> **⚠️ Important Note**: The source code directory `n8n-nodes-starter` is currently missing/empty in this checkout.

Once the source code is present in `n8n-nodes-starter`:

- **Install Dependencies**:
  ```bash
  cd n8n-nodes-starter
  npm install
  ```

- **Build Project**:
  ```bash
  npm run build
  ```

- **Start Development Server**:
  ```bash
  npm run dev
  ```

- **Run Tests**:
  ```bash
  npm test
  ```

## Code Style & Conventions
- **Language**: TypeScript (Strict Mode).
- **Linter**: ESLint (follow standard n8n node conventions).
- **Formatting**: Prettier.
- **Architecture**:
  - Each node resides in its own directory under `nodes/`.
  - Node definitions follow `INodeType` interface from `n8n-workflow`.
  - Use `ITaskDataFunctions` for execution logic.

## Directory Structure
- `n8n-nodes-starter/` (Root of the node package source - currently missing)
- `DOCUMENTACION.md`: General technical documentation.
- `SECURE_CODE_TOOL.md`: Specific details on the sandboxing tool.
- `CREDENTIAL_VAULT.md`: Details on the credential management system.
- `INTEGRACION_SKILLS_VAULT_CODE.md`: Guide on integrating skills, credentials, and code execution.

## Critical Context for Agents
- **Secure Code Tool**: Requires `nsjail` installed on the host system to function. It uses Linux namespaces for isolation.
- **LokiVector**: Uses `lokijs` with an HNSW index. It is persistent and local.
- **Memory Bridge**: Designed to work with LangChain-compatible vector stores.
