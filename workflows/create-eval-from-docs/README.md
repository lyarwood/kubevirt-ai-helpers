# Demo: create-eval-from-docs Workflow

This document walks through creating an ACP session using the `create-eval-from-docs` workflow. The workflow generates MCPChecker evaluation tasks from KubeVirt user-guide documentation for the kubernetes-mcp-server project.

## Prerequisites

- [`acptui`](https://github.com/lyarwood/acptui) built and on your PATH (see [install instructions](#installing-acptui) below)
- Logged in to your ACP instance: `acptui login https://ambient-code.apps.example.com`
- Access to a project (e.g. `kubevirt`)
- The `kubevirt-ai-helpers` repository available at `https://github.com/lyarwood/kubevirt-ai-helpers`

### Installing acptui

[acptui](https://github.com/lyarwood/acptui) is a terminal UI for browsing and managing Ambient Code Platform sessions.

```sh
git clone https://github.com/lyarwood/acptui.git
cd acptui
make install
```

Then authenticate with your ACP instance:

```sh
acptui login https://ambient-code.apps.example.com
```

This opens your browser to the OpenShift login page. After authenticating, paste the token back into the terminal.

## Option 1: Create via acptui TUI

### 1. Launch acptui

```sh
acptui kubevirt
```

### 2. Create a new session

Press `n` to open the create session form.

### 3. Fill in the form

| Field | Value |
|-------|-------|
| **Prompt** | `Generate eval tasks for the live-migration docs` |
| **Repo URL** | `https://github.com/kubevirt/user-guide` (use left/right for suggestions or type manually) |
| **Repo Branch** | `main` |

Press `Ctrl+A` to add the first repo, then add the second:

| Field | Value |
|-------|-------|
| **Repo URL** | `https://github.com/containers/kubernetes-mcp-server` |
| **Repo Branch** | `main` |

Press `Ctrl+A` to add. You should see both repos listed.

### 4. Select model

Tab to **Model** and use left/right to select `Claude Sonnet 4.6` (or your preferred model).

### 5. Select workflow

Tab to **Workflow** and use left/right to cycle to **Custom**, then fill in:

| Field | Value |
|-------|-------|
| **Git URL** | `https://github.com/lyarwood/kubevirt-ai-helpers` |
| **Branch** | `main` |
| **Path** | `workflows/create-eval-from-docs` |

### 6. Create

Press `Enter` to create the session. You'll be returned to the session list where the new session should appear with phase `Pending` → `Creating` → `Running`.

### 7. Chat

Press `Enter` on the new session to open the chat view. The agent will greet you with the workflow's startup prompt, asking which documentation to convert. You can respond with:

- A specific doc: `docs/compute/live_migration.md`
- A keyword: `live-migration`
- A category: `compute` (batch-processes all docs in that category)

## Option 2: Create via acptui CLI

```sh
acptui create kubevirt \
  --prompt "Generate eval tasks for the live-migration docs" \
  --display-name "Generate live-migration eval tasks" \
  --repo https://github.com/kubevirt/user-guide \
  --repo https://github.com/containers/kubernetes-mcp-server \
  --workflow-url https://github.com/lyarwood/kubevirt-ai-helpers \
  --workflow-branch main \
  --workflow-path workflows/create-eval-from-docs
```

Then open `acptui kubevirt` to interact with the session.

## Option 3: Create via curl

```sh
TOKEN=$(python3 -c "import json; print(json.load(open('$HOME/.config/ambient/config.json')).get('access_token',''))")
API_URL=$(python3 -c "import json; print(json.load(open('$HOME/.config/ambient/config.json')).get('api_url',''))")
USER=$(python3 -c "import json; print(json.load(open('$HOME/.config/ambient/config.json')).get('user',''))")

curl -s -X POST "${API_URL}/api/projects/kubevirt/agentic-sessions" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-Forwarded-Access-Token: $TOKEN" \
  -H "X-Forwarded-User: $USER" \
  -H "Content-Type: application/json" \
  -d '{
    "initialPrompt": "Generate eval tasks for the live-migration docs",
    "displayName": "Generate live-migration eval tasks",
    "llmSettings": {
      "model": "claude-sonnet-4-6",
      "temperature": 0.7
    },
    "repos": [
      {"url": "https://github.com/kubevirt/user-guide", "branch": "main"},
      {"url": "https://github.com/containers/kubernetes-mcp-server", "branch": "main"}
    ],
    "activeWorkflow": {
      "gitUrl": "https://github.com/lyarwood/kubevirt-ai-helpers",
      "branch": "main",
      "path": "workflows/create-eval-from-docs"
    }
  }' | python3 -m json.tool
```

Then open `acptui kubevirt` and select the session to interact with it.

## What to expect

The workflow will:

1. **Resolve** the input to documentation files in the user-guide repo
2. **Read and classify** each doc (procedural/declarative/conceptual)
3. **Map** documented workflows to available MCP tools (`vm_create`, `vm_lifecycle`, `resources_create_or_update`, etc.)
4. **Assess** difficulty tier (tier1-beginner through tier3-advanced)
5. **Generate** MCPChecker v1alpha2 task YAML files with setup/prompt/verify/cleanup phases
6. **Self-review** against the quality rubric (prompt quality, verify coverage, setup/cleanup, conventions, MCP tool mapping)
7. **Write** generated files to `kubernetes-mcp-server/evals/tasks/kubevirt/`
8. **Report** a summary of what was generated and any gaps identified

### Example prompts to try

```
Generate eval tasks for the live-migration docs
```

```
Process the compute category
```

```
Generate tasks for cpu-hotplug, memory-hotplug, and hotplug-volumes
```

```
Generate eval tasks from docs/storage/snapshot_restore_api.md
```

## Monitoring progress

While the agent works, you can:

- **Watch the chat** — responses stream in real-time via SSE
- **Toggle thinking blocks** — press `Tab` to expand/collapse reasoning
- **View tasks** — press `Ctrl+T` to see background subagent tasks
- **Browse files** — press `Ctrl+F` to check generated files in the workspace
- **Open in browser** — press `Esc` to go back to the session list, then `w` to open the web UI for a richer view

## Future work: in-session eval testing

Currently generated eval tasks must be tested outside the ACP session, either locally via `make local-env-setup-kubevirt && make run-server && make run-evals` in the kubernetes-mcp-server repo, or through its CI workflow (`.github/workflows/mcpchecker.yaml`).

Ideally the workflow would test generated evals end-to-end within the ACP session itself by launching a kind cluster with KubeVirt, starting the MCP server, and running mcpchecker. However, ACP runner pods run as non-root (UID 1001) with all capabilities dropped and no container runtime (Docker/Podman) available, so kind clusters cannot be created inside the pod.

Potential approaches to investigate:

- **Pre-provisioned cluster**: If KubeVirt is already deployed on the ACP cluster (or a connected cluster), the workflow could build the MCP server binary (Go toolchain is available in the runner), point it at that cluster, and run mcpchecker against the generated tasks. This requires a kubeconfig with access to a KubeVirt-enabled cluster injected as a session environment variable or secret.
- **MCP server as a sidecar or service**: Deploy the kubernetes-mcp-server as a Kubernetes service in the ACP cluster namespace, then add it as a custom MCP server in the session spec (`spec.mcpServers.custom`). The agent could then run mcpchecker directly against it.
- **External kubeconfig**: Ask the user to provide a kubeconfig for a cluster with KubeVirt via an environment variable. The runner builds the MCP server, starts it with that kubeconfig, and runs the generated evals.

The kubernetes-mcp-server repo provides the building blocks for all of these approaches: `make kubevirt-install` (KubeVirt v1.7.0 + CDI + Multus), `make mcpchecker` (downloads the mcpchecker binary), and `make run-evals` (runs evals against a running MCP server).
