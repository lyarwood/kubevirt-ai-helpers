# Create Eval from Docs - ACP Workflow

This workflow generates MCPChecker evaluation tasks from KubeVirt user-guide documentation for the kubernetes-mcp-server project.

## Repository Layout

This workflow expects two repositories in the workspace:

- **user-guide**: KubeVirt user-facing documentation at `docs/` (compute, storage, network, user_workloads, cluster_admin, debug_virt_stack)
- **kubernetes-mcp-server**: Target repo for generated eval tasks at `evals/tasks/kubevirt/`

Find these repos under `/workspace/repos/`. If either is missing, ask the user to add them.

## Input

Accept one of:
- Path to a user-guide markdown file (e.g., `docs/compute/live_migration.md`)
- Feature keyword (e.g., `live-migration`, `cpu-hotplug`)
- Category name (e.g., `compute`, `storage`) to batch-process all docs in a category

## Workflow Steps

### 1. Resolve Input to Doc Files

**Path**: resolve relative to the user-guide repo root.

**Keyword**: convert kebab-case to snake_case, search `docs/**/*.md`.

| Keyword | File |
|---------|------|
| `live-migration` | `docs/compute/live_migration.md` |
| `cpu-hotplug` | `docs/compute/cpu_hotplug.md` |
| `memory-hotplug` | `docs/compute/memory_hotplug.md` |
| `hotplug-volumes` | `docs/storage/hotplug_volumes.md` |
| `run-strategies` | `docs/compute/run_strategies.md` |
| `instancetypes` | `docs/user_workloads/instancetypes.md` |
| `snapshots` | `docs/storage/snapshot_restore_api.md` |
| `clone` | `docs/storage/clone_api.md` |
| `disks` | `docs/storage/disks_and_volumes.md` |

**Category**: list all `.md` files in `docs/<category>/`, skip `index.md`.

### 2. Read and Classify Each Doc

Read the full content and classify:

| Category | Indicators | Action |
|----------|-----------|--------|
| Procedural | Step-by-step instructions, imperative verbs, numbered lists | HIGH - generate tasks |
| Declarative | API references, YAML field descriptions, config tables | MEDIUM - generate if clear workflows exist |
| Conceptual | Explanatory prose, architecture descriptions, no commands | LOW - skip, note in report |

Extract:
- YAML resource examples (look for `kind:`, `apiVersion:` in code blocks)
- kubectl/virtctl commands
- Feature gates and prerequisites
- Step-by-step procedures
- Expected outcomes

### 3. Map Workflows to MCP Tools

| Doc Action | MCP Tool |
|-----------|----------|
| `kubectl create/apply` for VirtualMachine | `vm_create` (simple) or `resources_create_or_update` (custom YAML) |
| `kubectl create/apply` for other resources | `resources_create_or_update` |
| `kubectl get` | `resources_get` or `resources_list` |
| `kubectl delete` | `resources_delete` |
| `kubectl patch` | `resources_create_or_update` (read-modify-write) |
| `virtctl start/stop/restart` | `vm_lifecycle` |
| `virtctl migrate` | `resources_create_or_update` (create VirtualMachineInstanceMigration) |
| `virtctl addvolume` | `resources_create_or_update` (patch VM spec) |
| `virtctl ssh/console/port-forward` | **GAP** - no MCP tool equivalent |
| `kubectl logs` | `pods_log` |
| `kubectl exec` | `pods_exec` |
| `kubectl get events` | `events_list` |

Record any gaps: what the workflow needs, what MCP tool would satisfy it, whether the gap blocks the task.

### 4. Assess Tier and Difficulty

| Tier | Difficulty | Criteria |
|------|-----------|----------|
| 1 | easy/medium | Clear steps, no special hardware, all actions map to MCP tools |
| 2 | medium/hard | Needs new verify helpers, complex setup, or cluster-level config |
| 3 | hard/skip | Requires special hardware (SR-IOV, GPU, hugepages) or missing MCP tools |

### 5. Check for Existing Tasks

Before generating, list existing tasks in the kubernetes-mcp-server repo:
```bash
ls evals/tasks/kubevirt/
```

Skip any workflow already covered by an existing task. Note skips in the report.

### 6. Generate Task YAML Files

Write to: `<kubernetes-mcp-server>/evals/tasks/kubevirt/<task-name>/task.yaml`

Use v1alpha2 format:

```yaml
kind: Task
apiVersion: mcpchecker/v1alpha2
metadata:
  labels:
    suite: kubevirt
    requires: kubevirt
    source-doc: <relative-path-in-user-guide>
  name: "<task-name>"
  difficulty: easy|medium|hard
spec:
  requires:
    - extension: kubernetes
      as: k8s
  setup:
    - k8s.delete:
        apiVersion: v1
        kind: Namespace
        metadata:
          name: vm-test
        ignoreNotFound: true
    - k8s.create:
        apiVersion: v1
        kind: Namespace
        metadata:
          name: vm-test
  verify:
    - script:
        inline: |-
          #!/usr/bin/env bash
          source ../helpers/verify-vm.sh
          NS="vm-test"
          # Assertions here
  cleanup:
    - k8s.delete:
        apiVersion: kubevirt.io/v1
        kind: VirtualMachine
        metadata:
          name: <vm-name>
          namespace: vm-test
        ignoreNotFound: true
    - k8s.delete:
        apiVersion: v1
        kind: Namespace
        metadata:
          name: vm-test
        ignoreNotFound: true
  prompt:
    inline: "<natural-language task description>"
```

**Conventions**:
- Always use `vm-test` namespace
- Always clean namespace in setup (delete + create)
- Use `ignoreNotFound: true` on all cleanup deletes
- Reuse `verify-vm.sh` functions where applicable
- Prompts must be natural-language (no kubectl commands)
- Label with `source-doc` for provenance tracking
- Use well-known container disk images (quay.io/containerdisks/fedora:latest, etc.)

### 7. Generate Verify Helpers (if needed)

If verification requires logic not in `verify-vm.sh`, create new helpers:
- Place in `evals/tasks/kubevirt/helpers/verify-<feature>.sh`
- Follow existing function pattern: `verify_<what>() { local vm_name="$1"; ... }`
- Exit 0 on success, 1 on failure with descriptive echo messages

### 8. Generate Report

Print a summary table per doc:

```markdown
## <doc-filename>

Classification: Procedural|Declarative|Conceptual

| Workflow | Tier | Difficulty | MCP Tools | Gaps | Generated File |
|----------|------|-----------|-----------|------|----------------|
| ... | ... | ... | ... | ... | ... |
```

End with:
- Total tasks generated, skipped (existing/conceptual/gaps)
- MCP tool gap list with suggested tool names
- New verify helpers created
- Effort estimate per tier

### 9. Commit, Push, and Create PR

After generating files, offer to commit and push for review. Each step requires explicit user confirmation.

**9a. Create a feature branch** in the kubernetes-mcp-server repo:
```bash
git checkout -b evals/kubevirt/<feature-or-category> main
```

**9b. Commit** the generated files:
- Single doc: one commit with all task files and helpers
- Batch (category): one commit per doc for granular review
- Message format: `feat(evals): add kubevirt <feature> eval tasks from user-guide`

**9c. Ask the user which remote to push to**:
```bash
git remote -v
```
List the available remotes and ask the user to pick one. Do not push without confirmation.

**9d. Push the branch**:
```bash
git push -u <chosen-remote> evals/kubevirt/<feature-or-category>
```

**9e. Offer to create a PR** against upstream. Include the summary report in the PR body with a task table, MCP gap list, and source doc references. If declined, report the branch name for manual PR creation later.

Never push or create PRs without explicit user confirmation at each step.

## Existing Verify Helpers Reference

Functions available in `evals/tasks/kubevirt/helpers/verify-vm.sh`:

| Function | Purpose |
|----------|---------|
| `verify_vm_exists` | Wait for VM creation (30s default) |
| `verify_container_disk` | Check VM uses specific OS disk |
| `verify_run_strategy` | Verify runStrategy is set |
| `verify_no_deprecated_running_field` | Ensure 'running' field not used |
| `verify_instancetype` | Check instancetype reference |
| `verify_instancetype_contains` | Match instancetype by substring |
| `verify_no_direct_resources` | Verify VM uses instancetype |
| `verify_has_resources_or_instancetype` | Check either present |
| `verify_cpu_cores` | Validate CPU core count |
| `verify_memory_increased` | Verify memory was increased |
| `verify_multus_secondary_network` | Check secondary network |
