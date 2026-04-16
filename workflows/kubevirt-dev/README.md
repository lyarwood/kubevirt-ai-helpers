# Demo: kubevirt-dev Workflow

This document walks through creating an ACP session using the `kubevirt-dev` workflow. The workflow implements a complete development loop for the kubevirt/kubevirt codebase - it loads coding conventions and ownership context upfront (guides), then iterates through automated quality gates (sensors) until the implementation converges or the iteration cap is reached.

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
| **Prompt** | `Implement a new VMI condition that tracks guest agent connectivity` |
| **Repo URL** | `https://github.com/kubevirt/kubevirt` (use left/right for suggestions or type manually) |
| **Repo Branch** | `main` (or your feature branch) |

Press `Ctrl+A` to add the repo.

### 4. Select model

Tab to **Model** and use left/right to select `Claude Sonnet 4.6` (or your preferred model).

### 5. Select workflow

Tab to **Workflow** and use left/right to cycle to **Custom**, then fill in:

| Field | Value |
|-------|-------|
| **Git URL** | `https://github.com/lyarwood/kubevirt-ai-helpers` |
| **Branch** | `main` |
| **Path** | `workflows/kubevirt-dev` |

### 6. Create

Press `Enter` to create the session. You'll be returned to the session list where the new session should appear with phase `Pending` -> `Creating` -> `Running`.

### 7. Chat

Press `Enter` on the new session to open the chat view. The agent will greet you and ask what you would like to implement. You can respond with:

- A GitHub issue URL: `https://github.com/kubevirt/kubevirt/issues/12345`
- A GitHub issue reference: `kubevirt/kubevirt#12345`
- A Jira ticket: `CNV-12345`
- A free-text description: `Add memory hotplug support for Windows guests`

## Option 2: Create via acptui CLI

```sh
acptui create kubevirt \
  --prompt "Implement kubevirt/kubevirt#12345" \
  --display-name "Dev: guest agent condition" \
  --repo https://github.com/kubevirt/kubevirt \
  --workflow-url https://github.com/lyarwood/kubevirt-ai-helpers \
  --workflow-branch main \
  --workflow-path workflows/kubevirt-dev
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
    "initialPrompt": "Implement kubevirt/kubevirt#12345",
    "displayName": "Dev: guest agent condition",
    "llmSettings": {
      "model": "claude-sonnet-4-6",
      "temperature": 0.7
    },
    "repos": [
      {"url": "https://github.com/kubevirt/kubevirt", "branch": "main"}
    ],
    "activeWorkflow": {
      "gitUrl": "https://github.com/lyarwood/kubevirt-ai-helpers",
      "branch": "main",
      "path": "workflows/kubevirt-dev"
    }
  }' | python3 -m json.tool
```

Then open `acptui kubevirt` and select the session to interact with it.

## What to expect

The workflow follows the harness pattern - guides prevent errors before they happen, sensors detect errors after each change, and the agent loop iterates until convergence.

### Phase 1: Context Loading (Guides)

The agent loads feedforward context before writing any code:

1. **Parses** the task input (GitHub issue, Jira ticket, or free text) to extract intent and requirements
2. **Identifies** affected packages and maps them to the owning SIG (compute, network, storage)
3. **Loads** OWNERS_ALIASES and directory-level OWNERS files
4. **Studies** neighbouring code in the target packages to learn local patterns
5. **Internalizes** KubeVirt coding conventions from the review checklist

### Phase 2: Planning

The agent presents a plan covering files to change, approach, test strategy, risk areas, and commit structure. It waits for your confirmation before proceeding.

### Phase 3: Implementation

The agent writes code following the loaded conventions, including unit tests and e2e tests where applicable.

### Phase 4: Sensor Loop

Five sensors run in sequence - each gates the next:

| Sensor | What it runs | What it catches |
|--------|-------------|-----------------|
| Generate | `make generate` | Stale deepcopy, client-gen, mocks |
| Build | `make build` | Compilation errors |
| Unit test | `make test` (targeted) | Logic errors in changed packages |
| Lint | `make lint` | Style, static analysis, security |
| Self-review | Convention check | Architecture, naming, test patterns |

On failure, the sensor output is fed back and the agent fixes the issue (up to 3 attempts per sensor). If a sensor exhausts its attempts, the workflow halts and reports the remaining issues.

### Phase 5: Commit Preparation

When all sensors pass, the agent presents proposed commits with messages and a session summary. It waits for your confirmation before committing.

### Example prompts to try

```
Implement kubevirt/kubevirt#12345
```

```
https://github.com/kubevirt/kubevirt/issues/12345
```

```
CNV-54321
```

```
Add a new condition to VMI status that tracks when the guest agent is connected
```

```
Refactor the migration controller to use a workqueue instead of polling
```

## Monitoring progress

While the agent works, you can:

- **Watch the chat** - responses stream in real-time via SSE
- **Toggle thinking blocks** - press `Tab` to expand/collapse reasoning
- **View tasks** - press `Ctrl+T` to see background subagent tasks
- **Browse files** - press `Ctrl+F` to check generated files in the workspace
- **Open in browser** - press `Esc` to go back to the session list, then `w` to open the web UI for a richer view
