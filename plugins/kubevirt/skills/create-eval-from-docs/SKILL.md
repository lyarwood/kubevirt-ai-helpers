---
name: Create Eval from Docs
description: Detailed implementation guide for the /kubevirt:create-eval-from-docs command - generates MCPChecker evaluation tasks from KubeVirt user-guide documentation by extracting workflows, mapping to MCP tools, and producing v1alpha2 task YAML files
---

# Create Eval from Docs

This skill provides the detailed implementation logic for the `/kubevirt:create-eval-from-docs` command. It covers how to read user-guide documentation, extract actionable workflows, map them to available MCP tools, and generate MCPChecker evaluation task files.

## When to Use This Skill

- When executing the `/kubevirt:create-eval-from-docs` command
- When a user wants to generate MCPChecker evaluation tasks from KubeVirt user-guide documentation
- When expanding eval coverage for the kubernetes-mcp-server kubevirt toolset

## Prerequisites

1. **KubeVirt user-guide repo**: Must be available as a working directory. Default path: look for a directory containing `docs/compute/`, `docs/storage/`, `docs/network/` with a `mkdocs.yml` at root. If not found, ask the user for the path.
2. **kubernetes-mcp-server repo**: Must be available as a working directory. Default path: look for a directory containing `evals/tasks/kubevirt/`. If not found, ask the user for the path.
3. **kubectl**: Must be installed (`which kubectl`) for generating verify scripts that validate cluster state.

## Repository Layout Context

### User-Guide Documentation Structure
```
docs/
├── compute/          # Live migration, CPU/memory hotplug, run strategies, NUMA, hugepages, etc.
├── storage/          # Disks, volumes, hotplug, snapshots, clones, CDI
├── network/          # Interfaces, multus, service mesh, network policies
├── user_workloads/   # VM lifecycle, instancetypes, templates, preferences
├── cluster_admin/    # Installation, upgrades, feature gates, migration policies
└── debug_virt_stack/ # Debugging, logging, virsh commands
```

### Existing Eval Task Structure
```
evals/tasks/kubevirt/
├── helpers/
│   └── verify-vm.sh           # Reusable verification functions
├── create-vm-basic/
│   └── task.yaml              # v1alpha2 format
├── troubleshoot-vm/
│   └── task.yaml
└── ...                        # 12 tasks total
```

### Available MCP Tools

**KubeVirt toolset** (dedicated tools):
- `vm_create` - Create VM with instancetype/preference/workload params
- `vm_clone` - Clone VM via VirtualMachineClone resource
- `vm_lifecycle` - Start, stop, or restart a VM (changes runStrategy)

**Core toolset** (generic resource operations - work with any K8s resource including KubeVirt CRDs):
- `resources_create_or_update` - Create or update any resource from YAML/JSON
- `resources_get` - Get a specific resource by apiVersion/kind/namespace/name
- `resources_list` - List resources with optional label/field selectors
- `resources_delete` - Delete a specific resource
- `pods_list`, `pods_list_in_namespace`, `pods_get` - Pod inspection
- `pods_log` - Get container logs (useful for virt-launcher pods)
- `pods_exec` - Execute commands in pods
- `events_list` - List Kubernetes events for debugging

**Prompts** (structured troubleshooting):
- `vm-troubleshoot` - Step-by-step VM diagnostics with resource/log/event analysis

### Existing Verify Helpers

The file `evals/tasks/kubevirt/helpers/verify-vm.sh` provides these reusable functions:

| Function | Purpose | Parameters |
|----------|---------|-----------|
| `verify_vm_exists` | Wait for VM to be created | `<vm-name> <namespace> [timeout]` |
| `verify_container_disk` | Check VM uses specific OS disk | `<vm-name> <namespace> <os-name>` |
| `verify_run_strategy` | Verify runStrategy is set | `<vm-name> <namespace>` |
| `verify_no_deprecated_running_field` | Ensure 'running' field not used | `<vm-name> <namespace>` |
| `verify_instancetype` | Check instancetype reference | `<vm-name> <namespace> [expected] [kind]` |
| `verify_instancetype_contains` | Match instancetype by substring | `<vm-name> <namespace> <substring>` |
| `verify_no_direct_resources` | Verify VM uses instancetype | `<vm-name> <namespace>` |
| `verify_has_resources_or_instancetype` | Check either is present | `<vm-name> <namespace>` |
| `verify_cpu_cores` | Validate CPU core count | `<vm-name> <namespace> <expected-cores>` |
| `verify_memory_increased` | Verify memory was increased | `<vm-name> <namespace> <original-memory>` |
| `verify_multus_secondary_network` | Check secondary network | `<vm-name> <namespace> <network-name>` |

## Implementation Steps

### Step 1: Parse Input

Determine the input type and resolve to one or more user-guide doc file paths.

**Path to a markdown file** (e.g., `docs/compute/live_migration.md`):
- Resolve relative to the user-guide repo root
- Verify the file exists
- Process this single file

**Feature keyword** (e.g., `live-migration`, `cpu-hotplug`):
- Convert kebab-case to snake_case and search for a matching filename
- Search pattern: `docs/**/<keyword-variants>.md`
- Common mappings:

| Keyword | Resolves To |
|---------|------------|
| `live-migration` | `docs/compute/live_migration.md` |
| `cpu-hotplug` | `docs/compute/cpu_hotplug.md` |
| `memory-hotplug` | `docs/compute/memory_hotplug.md` |
| `hotplug-volumes` | `docs/storage/hotplug_volumes.md` |
| `run-strategies` | `docs/compute/run_strategies.md` |
| `instancetypes` | `docs/user_workloads/instancetypes.md` |
| `snapshots` | `docs/storage/snapshot_restore_api.md` |
| `clone` | `docs/storage/clone_api.md` |
| `disks` | `docs/storage/disks_and_volumes.md` |

- If ambiguous, list candidates and ask the user to choose

**Category name** (e.g., `compute`, `storage`):
- List all `.md` files in `docs/<category>/`
- Process each file sequentially
- Skip `index.md` files

### Step 2: Read and Classify Documentation

For each doc file, read the full content and classify it into one of three categories.

**Classification criteria**:

| Category | Indicators | Convertibility |
|----------|-----------|----------------|
| Procedural | Step-by-step instructions, numbered lists, "first... then..." language, imperative verbs ("create", "apply", "run") | HIGH |
| Declarative | API reference style, YAML examples with field descriptions, configuration tables | MEDIUM |
| Conceptual | Explanatory prose, architecture descriptions, comparisons, no actionable commands | LOW |

**Extract from the doc**:

1. **YAML resource examples**: Look for fenced code blocks containing `kind:`, `apiVersion:`. Record the full YAML and what resource type it defines.

2. **kubectl/virtctl commands**: Look for fenced code blocks or inline code containing `kubectl`, `virtctl`. Record the full command and its purpose.

3. **Feature gates**: Look for references to feature gates (e.g., `LiveMigration`, `CPUHotplug`, `DeclarativeHotplugVolumes`). Note whether they are enabled by default and from which version.

4. **Prerequisites**: Look for "prerequisites", "requirements", "before you begin" sections. Note any special hardware requirements (SR-IOV, GPU, hugepages, specific CPU features).

5. **Step-by-step procedures**: Look for numbered lists, ordered sequences of operations, or sections titled "How to...", "Steps", "Procedure". Each procedure is a candidate workflow.

6. **Expected outcomes**: Look for "you should see", "the output will show", "verify by running", status descriptions. These inform verify script logic.

**For LOW convertibility docs**: Report the doc as conceptual-only and skip to the next doc. Do not generate tasks for purely conceptual documentation.

### Step 3: Map Workflows to Available MCP Tools

For each extracted workflow, determine which MCP tools an agent would use to complete it.

**Mapping rules**:

| Doc Command/Action | MCP Tool | Notes |
|-------------------|----------|-------|
| `kubectl create -f <vm.yaml>` or `kubectl apply -f <vm.yaml>` for a VirtualMachine | `vm_create` (if simple) or `resources_create_or_update` (if custom YAML) | Prefer `vm_create` when the doc creates a standard VM with known workload/instancetype |
| `kubectl apply -f <resource.yaml>` for any non-VM resource | `resources_create_or_update` | Covers VirtualMachineInstanceMigration, DataVolume, NetworkAttachmentDefinition, etc. |
| `kubectl get <resource>` | `resources_get` or `resources_list` | |
| `kubectl delete <resource>` | `resources_delete` | |
| `kubectl patch <resource>` | `resources_create_or_update` | Agent reads current state then applies modified version |
| `virtctl start/stop/restart <vm>` | `vm_lifecycle` | Direct mapping |
| `virtctl migrate <vmi>` | `resources_create_or_update` | Create a VirtualMachineInstanceMigration resource |
| `virtctl addvolume` | `resources_create_or_update` | Patch the VM spec to add a volume |
| `virtctl ssh`, `virtctl console`, `virtctl port-forward` | **GAP** | No MCP tool equivalent |
| `kubectl logs <pod>` | `pods_log` | |
| `kubectl exec <pod>` | `pods_exec` | |
| `kubectl get events` | `events_list` | |

**Identify MCP tool gaps**: Any workflow step that requires a tool not available in the kubernetes-mcp-server is a gap. Record gaps with:
- What the workflow needs (e.g., "SSH into VM guest to verify filesystem")
- What MCP tool would satisfy it (e.g., "vm_ssh or vm_exec tool")
- Whether the gap blocks the entire task or just one verification step

### Step 4: Assess Difficulty and Tier

For each extractable workflow, assign a tier and difficulty:

**Tier 1 - easy/medium** (convert with minimal effort):
- Clear procedural steps
- No special hardware requirements
- All actions map to existing MCP tools
- Verify can be done with kubectl/jsonpath assertions
- Examples: VM creation, lifecycle operations, basic migration

**Tier 2 - medium/hard** (needs additional work):
- Requires new verify helper functions
- Complex multi-step setup (e.g., create DataVolume, wait for import, then create VM)
- Needs cluster-level configuration (e.g., set migration policies)
- Examples: CPU hotplug (needs cluster config), volume hotplug (needs running VM + DataVolume), snapshots

**Tier 3 - hard/skip** (requires special cluster features or missing MCP tools):
- Needs hardware not available in standard test clusters (SR-IOV NICs, GPUs, hugepages, specific NUMA topology)
- Core workflow depends on MCP tool gaps (e.g., requires SSH into guest)
- Requires multi-node cluster with specific node labels
- Examples: GPU passthrough, dedicated CPU with NUMA, SR-IOV networking
- **Action**: Generate a skeleton task file with a `# REQUIRES: <prerequisite>` comment and mark difficulty as `hard`. Include the task in the report but flag it as needing special infrastructure.

### Step 5: Generate Task YAML Files

For each viable workflow (Tier 1 and Tier 2), generate a v1alpha2 MCPChecker task file.

**Output path**: `<kubernetes-mcp-server>/evals/tasks/kubevirt/<task-name>/task.yaml`

**Task naming convention**: Use kebab-case descriptive names that indicate the action:
- `migrate-vm` (not `live-migration-test`)
- `hotplug-disk` (not `storage-hotplug-volumes`)
- `cpu-hotplug` (not `compute-cpu-hotplug`)
- `snapshot-vm` (already exists - skip or extend)

**Before generating, check for existing tasks**: Read the existing task directory listing to avoid duplicating tasks that already exist. If an existing task covers the same workflow, skip it and note it in the report.

**Template**:

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
    # Additional setup steps as needed:
    # - Create prerequisite resources (DataVolumes, NetworkAttachmentDefinitions, Secrets)
    # - Create VMs that need to exist before the agent acts
    # - Wait for resources to be ready
  verify:
    - script:
        inline: |-
          #!/usr/bin/env bash
          source ../helpers/verify-vm.sh
          NS="vm-test"

          # Use existing verify helpers where possible
          # Write inline checks for feature-specific verification
          # Exit 0 on success, non-zero on failure
          # Include descriptive echo statements for debugging
  cleanup:
    - k8s.delete:
        apiVersion: kubevirt.io/v1
        kind: VirtualMachine
        metadata:
          name: <vm-name>
          namespace: vm-test
        ignoreNotFound: true
    # Delete any other resources created during setup or by the agent
    - k8s.delete:
        apiVersion: v1
        kind: Namespace
        metadata:
          name: vm-test
        ignoreNotFound: true
  prompt:
    inline: |-
      <Natural-language task description derived from the user-guide workflow.
      Should describe WHAT to do, not HOW (no kubectl commands).
      Should specify resource names, namespaces, and expected outcomes.>
```

**Task generation conventions** (from existing tasks):

1. **Namespace**: Always use `vm-test` for consistency with existing tasks
2. **Setup**: Always start with namespace delete+create to ensure clean state
3. **Cleanup**: Use `ignoreNotFound: true` on all deletes to prevent cleanup failures
4. **Prompt**: Write as a natural-language user request. Do NOT include kubectl/virtctl commands in the prompt - the agent should figure out which MCP tools to use. DO specify concrete names, namespaces, and expected outcomes.
5. **Verify**: Prefer reusing existing `verify-vm.sh` functions. For new checks, follow the same pattern (exit 0 = pass, echo descriptive messages).
6. **Labels**: Always include `suite: kubevirt`, `requires: kubevirt`, and `source-doc: <path>`
7. **Container disks**: Use well-known images:
   - Fedora: `quay.io/containerdisks/fedora:latest`
   - Ubuntu: `quay.io/containerdisks/ubuntu:latest`
   - OpenSUSE: `quay.io/containerdisks/opensuse-leap:latest`

**Prompt writing guidelines**:

Good prompts are specific and outcome-oriented:
```
Create a Fedora virtual machine named test-vm in the vm-test namespace.
```
```
Please pause the virtual machine named paused-vm in the vm-test namespace.
```
```
There is a VirtualMachine named "broken-vm" in the vm-test namespace that is not working correctly.
Please use the vm-troubleshoot prompt to diagnose the issue.
```

Bad prompts are vague or prescriptive:
```
Test live migration.
```
```
Run kubectl apply -f migration.yaml to migrate the VM.
```

### Step 6: Generate or Extend Verify Helpers

If the workflow needs verification logic not covered by existing `verify-vm.sh` functions, generate new helper functions.

**When to create a new helper vs inline verification**:
- **New helper**: If the verification will be reused across multiple tasks (e.g., `verify_migration_completed` for any migration task)
- **Inline**: If the verification is specific to one task and unlikely to be reused

**New helper file convention**:
- Place in `evals/tasks/kubevirt/helpers/`
- Name: `verify-<feature>.sh` (e.g., `verify-migration.sh`, `verify-hotplug.sh`)
- Source from task verify scripts: `source ../helpers/verify-<feature>.sh`

**Helper function pattern** (match existing `verify-vm.sh` style):

```bash
verify_<what_to_check>() {
    local vm_name="$1"
    local namespace="$2"
    # Additional parameters as needed

    echo "Checking <what>..."

    # Use kubectl with jsonpath or jq for assertions
    local actual=$(kubectl get <resource> "$vm_name" -n "$namespace" \
        -o jsonpath='{.<path>}' 2>/dev/null)

    if [[ -z "$actual" ]]; then
        echo "FAIL: <what> not found for $vm_name in $namespace"
        return 1
    fi

    # Compare against expected value
    if [[ "$actual" != "<expected>" ]]; then
        echo "FAIL: Expected <expected>, got $actual"
        return 1
    fi

    echo "OK: <what> verified for $vm_name"
    return 0
}
```

**Candidate new helpers based on user-guide coverage gaps**:

| Helper | Purpose | Used By |
|--------|---------|---------|
| `verify_migration_completed` | Check VirtualMachineInstanceMigration succeeded | migrate-vm, cancel-migration |
| `verify_migration_policy` | Check migration policy is applied to VM | configure-migration-policy |
| `verify_hotplug_disk` | Check disk was hotplugged to running VM | hotplug-disk |
| `verify_hotplug_cpu` | Check CPU sockets changed on running VM | cpu-hotplug |
| `verify_hotplug_memory` | Check memory changed on running VM | memory-hotplug |
| `verify_snapshot_exists` | Check VirtualMachineSnapshot was created | snapshot-vm |
| `verify_vm_restored` | Check VM was restored from snapshot | restore-vm |
| `verify_data_volume_ready` | Check DataVolume import completed | any task using DataVolumes |
| `verify_feature_gate` | Check a feature gate is enabled in KubeVirt CR | tasks needing specific gates |

### Step 7: Generate Summary Report

After processing all docs, output a summary report.

**Per-doc section**:

```markdown
## <doc-filename>

Classification: <Procedural|Declarative|Conceptual>

| Workflow | Tier | Difficulty | MCP Tools | Gaps | Generated File |
|----------|------|-----------|-----------|------|----------------|
| <workflow-name> | 1 | easy | vm_create, resources_get | none | <task-name>/task.yaml |
| <workflow-name> | 2 | medium | resources_create_or_update | none | <task-name>/task.yaml |
| <workflow-name> | 3 | hard | - | vm_ssh needed | SKIPPED |
```

**Summary section**:

```markdown
## Summary

- Total docs processed: <N>
- Procedural: <N>, Declarative: <N>, Conceptual: <N>
- Tasks generated: <N>
- Tasks skipped (already exist): <N>
- Tasks skipped (conceptual doc): <N>
- Tasks skipped (missing MCP tools): <N>
- New verify helpers created: <N>

### MCP Tool Gaps

| Gap | Workflows Affected | Suggested Tool |
|-----|-------------------|----------------|
| No VM guest SSH | cpu-hotplug verify, memory-hotplug verify | vm_exec or vm_ssh |
| No virtctl console | guest OS interaction tasks | vm_console |

### New Verify Helpers

| File | Functions | Used By |
|------|-----------|---------|
| verify-migration.sh | verify_migration_completed, verify_migration_policy | migrate-vm, cancel-migration |

### Effort Estimate

- Tier 1 tasks: <N> tasks, minimal manual curation needed
- Tier 2 tasks: <N> tasks, need verify helper development and setup refinement
- Tier 3 tasks: <N> tasks, blocked on infrastructure or MCP tool development
```

### Step 8: Write Output

Write all generated files to the kubernetes-mcp-server repository:

1. **Task files**: `<k8s-mcp-server>/evals/tasks/kubevirt/<task-name>/task.yaml`
2. **Verify helpers**: `<k8s-mcp-server>/evals/tasks/kubevirt/helpers/verify-<feature>.sh`
3. **Report**: Print to conversation output (do not write to a file)

Before writing, confirm with the user:
- The output directory path
- Whether to overwrite existing tasks if any overlap is detected
- Whether to generate Tier 3 skeleton tasks or skip them entirely

### Step 9: Commit, Push, and Create PR

After writing the generated files, offer to commit and push them for review.

**9a. Create a feature branch**:

```bash
cd <kubernetes-mcp-server>
git checkout -b evals/kubevirt/<feature-or-category> main
```

Branch naming convention: `evals/kubevirt/<source>` where `<source>` is the doc feature name or category (e.g., `evals/kubevirt/live-migration`, `evals/kubevirt/compute`).

**9b. Stage and commit generated files**:

Create one commit per task for easy review, or a single commit if batch-processing:

- **Single doc**: one commit with all generated task files and helpers
  ```
  feat(evals): add kubevirt <feature> eval tasks from user-guide

  Generated from <doc-path> using kubevirt:create-eval-from-docs.

  Tasks added:
  - <task-name-1> (<difficulty>)
  - <task-name-2> (<difficulty>)
  ```

- **Batch (category)**: one commit per doc, so reviewers can accept/reject individually
  ```
  feat(evals): add kubevirt <feature> eval task from <doc-name>

  Generated from <doc-path> using kubevirt:create-eval-from-docs.
  Difficulty: <difficulty>, Tier: <tier>
  ```

**9c. Ask the user for a remote to push to**:

The user may have the kubernetes-mcp-server repo configured with multiple remotes (e.g., `origin` for upstream, a personal fork). Ask which remote to push to:

```
Which remote should I push to for review? Available remotes:
- origin (https://github.com/containers/kubernetes-mcp-server)
- lyarwood (https://github.com/lyarwood/kubernetes-mcp-server)
```

List remotes with `git remote -v` and present the choices. Wait for the user to confirm before pushing.

**9d. Push the branch**:

```bash
git push -u <chosen-remote> evals/kubevirt/<feature-or-category>
```

**9e. Offer to create a PR**:

Ask the user if they want to create a PR. If yes, create it with:

```bash
gh pr create \
  --repo <upstream-repo> \
  --head <user>:evals/kubevirt/<feature> \
  --base main \
  --title "feat(evals): add kubevirt <feature> eval tasks" \
  --body "$(cat <<'EOF'
## Summary

Generated MCPChecker evaluation tasks from KubeVirt user-guide documentation.

**Source doc(s)**: <doc-path(s)>
**Tasks added**: <N>
**New verify helpers**: <N>

### Generated Tasks

| Task | Difficulty | Source Doc |
|------|-----------|-----------|
| <task-name> | <difficulty> | <doc-path> |

### MCP Tool Gaps

<gap list, if any>

---
Generated by `/kubevirt:create-eval-from-docs`
EOF
)"
```

If the user declines the PR, report the branch name so they can create it manually later.

**Important**: Never push or create PRs without explicit user confirmation at each step.

## Error Handling

| Error | Recovery |
|-------|----------|
| User-guide repo not found | Ask the user to add it via `/add-dir <path>` |
| kubernetes-mcp-server repo not found | Ask the user to add it via `/add-dir <path>` |
| Doc file not found | List available docs in the category and ask the user to choose |
| Feature keyword ambiguous | List matching files and ask user to select |
| Doc has no extractable workflows | Report as conceptual-only, skip task generation |
| Existing task already covers workflow | Skip and note in report |
| YAML example in doc is incomplete | Use the example as a starting point and fill in required fields based on KubeVirt API knowledge |
| No git remotes configured | Ask the user to add a remote with `git remote add <name> <url>` |
| Push rejected (no permission) | Suggest the user fork the repo and add their fork as a remote |
| PR creation fails (gh not authenticated) | Ask the user to run `gh auth login` and retry |

## Examples

### Example 1: Single Procedural Doc

```
/kubevirt:create-eval-from-docs docs/compute/live_migration.md
```

1. Reads `live_migration.md` - classifies as Procedural (HIGH convertibility)
2. Extracts 3 workflows:
   - Initiate a live migration (create VirtualMachineInstanceMigration)
   - Cancel a live migration (delete the migration or use virtctl)
   - Configure migration limits (patch KubeVirt CR)
3. Maps to MCP tools:
   - `resources_create_or_update` for creating migration object
   - `resources_delete` for canceling
   - `resources_get` for checking status
4. Generates 2 tasks (skips "configure migration limits" - requires cluster-admin):
   - `migrate-vm/task.yaml` - Tier 1, medium difficulty
   - `cancel-migration/task.yaml` - Tier 1, easy difficulty
5. Creates `verify-migration.sh` with `verify_migration_completed` function
6. Reports: 2 tasks generated, 1 skipped (cluster-admin config), 0 MCP gaps

### Example 2: Batch Processing a Category

```
/kubevirt:create-eval-from-docs compute
```

1. Lists all docs in `docs/compute/`: live_migration.md, cpu_hotplug.md, memory_hotplug.md, run_strategies.md, dedicated_cpu_resources.md, hugepages.md, NUMA.md, node_assignment.md, virtual_hardware.md, ...
2. Processes each doc:
   - `live_migration.md` - Procedural, 2 tasks generated
   - `cpu_hotplug.md` - Procedural, 1 task generated (Tier 2, needs cluster config)
   - `memory_hotplug.md` - Procedural, 1 task generated (Tier 2)
   - `run_strategies.md` - Conceptual, skipped
   - `dedicated_cpu_resources.md` - Procedural, 1 skeleton (Tier 3, needs dedicated CPUs)
   - `hugepages.md` - Procedural, 1 skeleton (Tier 3, needs hugepages)
   - `NUMA.md` - Conceptual, skipped
   - `node_assignment.md` - Declarative, 1 task generated (Tier 1, node affinity)
3. Summary: 6 tasks generated, 2 skipped (conceptual), 2 Tier 3 skeletons

### Example 3: Feature Keyword

```
/kubevirt:create-eval-from-docs hotplug-volumes
```

1. Resolves `hotplug-volumes` to `docs/storage/hotplug_volumes.md`
2. Reads doc - classifies as Declarative+Procedural (MEDIUM-HIGH)
3. Extracts 3 workflows:
   - Hotplug a disk to a running VM (patch VM spec or use virtctl addvolume)
   - Hotplug a CD-ROM (patch VM spec with cdrom disk type)
   - Remove a hotplugged volume (patch VM spec to remove disk+volume)
4. Generates 2 tasks:
   - `hotplug-disk/task.yaml` - Tier 2, medium difficulty (needs running VM + DataVolume setup)
   - `hotplug-cdrom/task.yaml` - Tier 2, medium difficulty
5. Creates `verify-hotplug.sh` with `verify_hotplug_disk` function
6. MCP gap flagged: guest-side verification (verifying disk appears inside VM) requires `vm_exec` or `pods_exec` on virt-launcher
