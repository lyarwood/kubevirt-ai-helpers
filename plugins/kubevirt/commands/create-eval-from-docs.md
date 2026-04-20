---
description: Generate MCPChecker evaluation tasks from KubeVirt user-guide documentation
argument-hint: <doc-path-or-feature>
---

## Name
kubevirt:create-eval-from-docs

## Synopsis
```
/kubevirt:create-eval-from-docs <doc-path-or-feature>
```

## Description
The `kubevirt:create-eval-from-docs` command reads KubeVirt user-guide documentation and generates MCPChecker evaluation tasks for the kubernetes-mcp-server project. It extracts actionable workflows from documentation, maps them to available MCP tools, and produces v1alpha2 task YAML files with setup, prompt, verify, and cleanup phases.

This command bridges the gap between user-facing documentation and automated evaluation coverage. Each generated task validates that an AI agent can complete a real user workflow using the kubernetes-mcp-server's KubeVirt and core toolsets.

### Workflow

```
Input                  Analysis                 Generation             Output
-----                  --------                 ----------             ------
Doc path/feature  -->  Read & classify doc  --> Map to MCP tools  --> Task YAML files
                       Extract workflows        Assess difficulty      Verify helpers
                       Identify prereqs         Detect tool gaps       Summary report
```

### What It Generates

For each viable workflow found in the documentation:
- A v1alpha2 MCPChecker task YAML file with all four phases (setup, prompt, verify, cleanup)
- New verify helper functions if existing helpers do not cover the workflow
- A summary report with tier classification, MCP tool mapping, and gap analysis

### MCP Tool Coverage

The generated tasks test agent use of these MCP tools:

| Toolset | Tools | Use Cases |
|---------|-------|-----------|
| kubevirt | `vm_create`, `vm_clone`, `vm_lifecycle` | VM creation, cloning, start/stop/restart |
| core | `resources_create_or_update`, `resources_get`, `resources_list`, `resources_delete` | Any K8s/KubeVirt resource CRUD |
| core | `pods_log`, `pods_exec`, `events_list` | Debugging, inspection |
| prompts | `vm-troubleshoot` | Structured VM diagnostics |

## Implementation

Refer to the detailed implementation guide in `plugins/kubevirt/skills/create-eval-from-docs/SKILL.md` for step-by-step instructions.

### Step 1: Parse Input

Accept one of:
- Path to a user-guide markdown file (e.g., `docs/compute/live_migration.md`)
- Feature keyword (e.g., `live-migration`, `cpu-hotplug`)
- Category name (e.g., `compute`, `storage`) to batch-process all docs in a category

### Step 2: Read and Classify Documentation

Read the doc and classify as procedural (HIGH convertibility), declarative (MEDIUM), or conceptual (LOW). Extract YAML examples, kubectl/virtctl commands, feature gates, and step-by-step procedures.

### Step 3: Map Workflows to MCP Tools

Cross-reference extracted workflows against available kubernetes-mcp-server tools. Flag workflows requiring tools not yet available as MCP tool gaps.

### Step 4: Assess Difficulty and Tier

Classify each workflow into tiers:
- **Tier 1** (easy/medium): Clear steps, no special hardware, existing MCP tools
- **Tier 2** (medium/hard): Needs new verify helpers or complex setup
- **Tier 3** (hard/skip): Requires special cluster features or missing MCP tools

### Step 5: Generate Task YAML Files

Produce v1alpha2 MCPChecker task files following existing conventions from `kubernetes-mcp-server/evals/tasks/kubevirt/`.

### Step 6: Generate or Extend Verify Helpers

Create new verify helper functions following the patterns in `kubernetes-mcp-server/evals/tasks/kubevirt/helpers/verify-vm.sh`.

### Step 7: Generate Summary Report

Output a per-workflow table with tier, difficulty, MCP tools used, gaps, and generated file paths.

### Step 8: Commit, Push, and Create PR

After writing files, offer to commit the generated tasks to a feature branch in the kubernetes-mcp-server repo. Ask the user which remote to push to (listing available remotes), then optionally create a PR against upstream. Each step requires explicit user confirmation.

## Output Formatting Rules

### ASCII-Only Requirement
All output text MUST use plain ASCII characters only:
- Do NOT use Unicode symbols, special characters, or emojis
- Use markdown headers `#`/`##`/`###` for section breaks
- Prefer single dashes `-` over double dashes `--` in prose

## Return Value

- **Generated task files**: v1alpha2 YAML files written to `kubernetes-mcp-server/evals/tasks/kubevirt/<task-name>/task.yaml`
- **New verify helpers**: Shell functions written to `kubernetes-mcp-server/evals/tasks/kubevirt/helpers/`
- **Summary report**: Markdown table with workflow inventory, tier classification, and gap analysis
- **MCP tool gaps**: List of workflows requiring tools not yet available in kubernetes-mcp-server
- **Git branch**: Feature branch with commits (if user confirmed)
- **PR URL**: Pull request link (if user confirmed)

## Examples

1. **Generate evals from a single doc**:
   ```
   /kubevirt:create-eval-from-docs docs/compute/live_migration.md
   ```
   Reads the live migration doc, extracts workflows (initiate migration, cancel migration, configure migration limits), and generates task files for each.

2. **Generate evals from a feature keyword**:
   ```
   /kubevirt:create-eval-from-docs cpu-hotplug
   ```
   Resolves to `docs/compute/cpu_hotplug.md`, extracts the CPU hotplug workflow, and generates a task file.

3. **Batch-process a category**:
   ```
   /kubevirt:create-eval-from-docs compute
   ```
   Processes all docs in `docs/compute/`, generating tasks for each viable workflow found.

4. **Generate evals from storage docs**:
   ```
   /kubevirt:create-eval-from-docs docs/storage/hotplug_volumes.md
   ```
   Extracts volume hotplug workflows and generates tasks covering disk hotplug, CD-ROM injection, and volume removal.

## Arguments
- `<doc-path-or-feature>`: (Required) One of:
  - Relative path to a user-guide markdown file (e.g., `docs/compute/live_migration.md`)
  - Feature keyword in kebab-case (e.g., `live-migration`, `cpu-hotplug`, `hotplug-volumes`)
  - Category name (e.g., `compute`, `storage`, `network`, `user_workloads`, `cluster_admin`)

## Prerequisites
- The KubeVirt user-guide repository must be available (added via `/add-dir` or present at a known path)
- The kubernetes-mcp-server repository must be available (added via `/add-dir` or present at a known path)
- `kubectl` must be available for generating verify scripts

## See Also
- `/kubevirt:review` - Review local branch changes using KubeVirt best practices
- `/kubevirt:review-ci` - Analyze CI failures for a PR
- MCPChecker [task format](https://github.com/mcpchecker/mcpchecker) - Evaluation task schema reference
- kubernetes-mcp-server [evals](https://github.com/kubernetes-sigs/kubernetes-mcp-server/tree/main/evals) - Existing evaluation tasks
