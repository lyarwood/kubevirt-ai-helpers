---
name: KubeVirt Dev Workflow
description: Detailed implementation guide for the /kubevirt:dev command - a harness-style development workflow with feedforward guides, feedback sensors, and an iterative agent loop
---

# KubeVirt Dev Workflow

This skill provides the detailed implementation logic for the `/kubevirt:dev` command. It covers how to load feedforward context (guides), run feedback checks (sensors), and orchestrate the iterative agent loop that drives implementation to convergence.

## When to Use This Skill

- When executing the `/kubevirt:dev` command
- When a user wants to implement a feature, fix a bug, or refactor code in kubevirt/kubevirt with automated quality gates
- When a user provides a GitHub issue, Jira ticket, or free-text task description and wants a complete development session

## Prerequisites

1. **Go toolchain**: Must be installed (`go version`)
2. **make lint**: Must be functional (`make lint` wraps golangci-lint with the project's configuration)
3. **gh CLI**: Must be installed and authenticated (`gh auth status`) - required for GitHub issue input
4. **make**: Must be available for running build, test, and generate targets
5. **Clean branch**: The working directory should be on a feature branch with no uncommitted changes

## Concepts

### The Harness Pattern

This workflow implements the harness pattern: Agent = Model + Harness, where the harness is everything except the model itself.

**Guides (feedforward controls)** are loaded once before implementation begins. They prevent errors proactively by giving the agent the right context, conventions, and patterns upfront. Without guides, the agent would make avoidable mistakes that sensors would later catch, wasting iteration budget.

**Sensors (feedback controls)** run after each implementation pass. They detect errors that guides could not prevent - compilation failures, test regressions, lint violations, convention drift. Each sensor produces structured error output that the agent can act on.

**The agent loop** connects guides and sensors. It iterates: implement, sense, fix, sense again. It terminates when all sensors pass or when any sensor exhausts its iteration cap (3 attempts). This bounded iteration prevents infinite loops while giving the agent enough attempts to converge on a correct solution.

### Why This Order Matters

Sensors run in dependency order - each sensor gates the next:

1. **Generate** first: if generated code is stale, everything downstream (build, test, lint) may fail for the wrong reasons
2. **Build** second: if code does not compile, tests and lint cannot run meaningfully
3. **Unit test** third: if logic is wrong, lint and review feedback would be noise
4. **Lint** fourth: once code is correct, clean up style and static analysis issues
5. **Self-review** last: a final convention check on code that is already compiling, passing tests, and lint-clean

Running them out of order wastes iteration budget on cascading failures.

## Implementation Steps

### Step 1: Parse Task Input

Determine the input type and extract the task intent.

**GitHub issue URL**:
```bash
# Full URL
gh issue view 12345 --repo kubevirt/kubevirt --json title,body,labels,comments --jq '{title, body, labels: [.labels[].name], comments: [.comments[] | {author: .author.login, body: .body}]}'

# owner/repo#number format - parse the components first
gh issue view <number> --repo <owner>/<repo> --json title,body,labels,comments
```

Extract from the issue:
- Title and body as the primary intent
- Labels for SIG mapping (e.g., `sig/compute`, `sig/network`, `kind/bug`, `kind/feature`)
- Comments for additional context and acceptance criteria

**Jira ticket**:
```bash
# Using Jira REST API via curl or a Jira CLI
# Extract summary, description, acceptance criteria, fix version
```

Extract from the ticket:
- Summary and description as intent
- Acceptance criteria as requirements
- Component and fix version for scoping

**Free-text description**: Use the text directly as intent. Identify keywords that map to KubeVirt components (e.g., "VMI status" maps to `staging/src/kubevirt.io/api/core/` and `pkg/virt-controller/`).

### Step 2: Identify Affected Areas

From the task intent, determine which packages and components will need changes.

**Keyword-to-package mapping** (common patterns):

| Keywords | Likely Packages |
|----------|----------------|
| VM, VirtualMachine, vm controller | `pkg/virt-controller/watch/vm/`, `staging/src/kubevirt.io/api/core/` |
| VMI, VirtualMachineInstance, vmi controller | `pkg/virt-controller/watch/vmi/`, `staging/src/kubevirt.io/api/core/` |
| migration, live migration | `pkg/virt-controller/watch/migration/`, `pkg/virt-handler/migration/` |
| network, interface, binding | `pkg/network/`, `pkg/virt-launcher/virtwrap/network/` |
| storage, volume, disk, PVC | `pkg/storage/`, `pkg/container-disk/` |
| API, webhook, admission | `pkg/virt-api/`, `pkg/virt-api/webhooks/` |
| virtctl, CLI | `pkg/virtctl/` |
| virt-handler, node agent | `pkg/virt-handler/` |
| virt-launcher, domain | `pkg/virt-launcher/` |
| operator, install | `pkg/virt-operator/` |
| RBAC, permissions | `pkg/virt-controller/rbac/`, `pkg/virt-operator/rbac/` |
| condition, status | `staging/src/kubevirt.io/api/core/`, `pkg/virt-controller/watch/` |

**SIG-to-directory mapping**:

| SIG | Primary Directories |
|-----|-------------------|
| compute | `pkg/virt-controller/`, `pkg/virt-handler/`, `pkg/virt-launcher/`, `pkg/virt-api/`, `staging/src/kubevirt.io/api/core/` |
| network | `pkg/network/`, `pkg/virt-launcher/virtwrap/network/` |
| storage | `pkg/storage/`, `pkg/container-disk/`, `pkg/virtctl/imageupload/` |

### Step 3: Load Ownership Context

Fetch OWNERS information for the affected areas.

```bash
# Fetch OWNERS_ALIASES
gh api repos/kubevirt/kubevirt/contents/OWNERS_ALIASES --jq '.content' | base64 -d
```

Parse the YAML to identify:
- Which SIG owns the affected directories
- Who the approvers and reviewers are (this informs whose patterns to follow)

```bash
# Fetch directory-level OWNERS for each affected path
gh api repos/kubevirt/kubevirt/contents/<path>/OWNERS --jq '.content' | base64 -d
```

Walk up the directory tree if OWNERS is not found at the exact path (e.g., `pkg/virt-controller/watch/vm/` -> `pkg/virt-controller/watch/` -> `pkg/virt-controller/`).

### Step 4: Study Existing Patterns

Read neighbouring code to understand local conventions. This is critical - different packages within kubevirt/kubevirt have subtly different patterns.

```bash
# List files in the target package
ls <target-package>/

# Read 2-3 representative files (prefer files similar to what will be modified)
# Look for: error handling style, test structure, comment style, naming
```

```bash
# Check recent commit history for the area
git log --oneline -20 -- <target-path>
```

**What to look for**:
- How errors are wrapped (fmt.Errorf with %w? dedicated error types?)
- How tests are structured (Describe/Context/It nesting, DescribeTable usage, test helpers)
- How controllers are structured (reconcile function patterns, event handling)
- Import ordering and grouping
- Comment density and style

### Step 5: Load Coding Conventions

The following conventions should be internalized before writing code. They come from the `/kubevirt:review` checklist:

**Error handling**:
- Reasonable error messages with context
- Early returns to avoid nesting
- Proper error wrapping with `fmt.Errorf("context: %w", err)`

**Testing**:
- Unit tests for all new code
- E2E tests for new features and bug fixes (core case must be tested)
- Use `Eventually` for async operations (no arbitrary `time.Sleep`)
- Use `DescribeTable` for test matrices
- Use decorators instead of `Skip` in tests

**Architecture**:
- Use informers in virt-controller and virt-operator; use direct GETs in virt-api
- Use PATCH when the controller does not own the object; UPDATE when it does
- Protect map access with locks in reconcile loops
- Keep RBAC permissions separated by concern
- Fire events on state transitions, not on every reconcile
- Keep privileged operations in virt-handler, not virt-launcher
- Use hash maps to avoid nested loops (O(n) instead of O(n^2))

**Go conventions**:
- Prefer initialization statements (inline err checks)
- Use switch-cases for long if/else chains
- Declare empty slices with `var` syntax
- Use `kubevirt.io/kubevirt/pkg/pointer` for pointer operations
- Avoid global variables, long files, utility file sprawl

**Naming**:
- Package names match directory names, no uppercase, underscores, or dashes
- Command-line flags use dashes
- Locks named `lock` or with distinct names
- Interface names avoid redundancy with package name

### Step 6: Plan the Change

Before writing code, produce a plan:

1. List files to create, modify, or delete
2. Describe the approach and how it fits the existing architecture
3. Define the test strategy (which unit tests, which e2e tests)
4. Identify risk areas (API changes, backwards compatibility, RBAC)
5. Define the commit strategy (separate commits for API, implementation, tests)

**Present the plan to the user and wait for confirmation.** Do not proceed until the user approves or adjusts the plan.

### Step 7: Implement

Execute the approved plan:

1. Make code changes following loaded conventions and patterns
2. Write unit tests alongside the implementation
3. Write e2e tests if applicable
4. Run `make generate` if API types were modified
5. Stage changes logically

### Step 8: Run the Sensor Loop

Execute sensors in order. Each sensor is described below with its exact commands, output parsing, and failure handling.

#### Sensor 1: Generate

**Purpose**: Detect stale generated code (deepcopy functions, client-gen, mock generation).

**When to run**: Always - even if no API types were modified, other generators may be affected.

```bash
cd /path/to/kubevirt
make generate
```

**Success check**:
```bash
# Check if make generate modified any files
git diff --name-only
```

If files were modified by `make generate`:
- This means the generated code was stale
- Stage the generated files
- Record that generated code needed updating
- This counts as a pass (the sensor caught the issue and it was auto-resolved)

If `make generate` itself fails (non-zero exit):
- Extract the error output
- Common failures:
  - Missing deepcopy-gen markers on new types
  - Invalid API type definitions
  - Missing required interface implementations
- Feed the error back and return to Step 7 to fix the root cause
- Increment iteration counter for this sensor

**Iteration cap**: 3 attempts. If `make generate` still fails after 3 fix attempts, halt and report.

#### Sensor 2: Build

**Purpose**: Verify the code compiles.

```bash
cd /path/to/kubevirt
make build
```

**Success check**: Exit code 0.

**On failure**:
- Extract compilation errors from output
- Parse lines matching the pattern: `<file>:<line>:<col>: <error message>`
- Group errors by file
- Feed back the specific errors and return to Step 7
- Focus fixes narrowly on the compilation errors - do not re-examine the full implementation

**Common build failures**:
- Undefined variables or functions (typo, missing import)
- Type mismatches (wrong argument type, missing conversion)
- Missing interface implementations (new method added to interface)
- Import cycle (new dependency creates a cycle)

**Iteration cap**: 3 attempts.

#### Sensor 3: Unit Test

**Purpose**: Verify logic correctness in changed packages.

**Determine changed packages**:
```bash
# Get changed files relative to base branch
git diff --name-only <base-branch>...HEAD

# Convert file paths to Go package paths
# Example: pkg/virt-controller/watch/vm/vm.go -> kubevirt.io/kubevirt/pkg/virt-controller/watch/vm
```

**Run targeted tests**:
```bash
cd /path/to/kubevirt
make test GO_TEST_PACKAGES="<package1> <package2> ..."
```

If `make test` does not support `GO_TEST_PACKAGES`, fall back to:
```bash
go test -count=1 -v <package-paths>
```

**Success check**: Exit code 0, all tests pass.

**On failure**:
- Extract failed test information:
  - Test name (from `--- FAIL: TestName`)
  - Assertion message (from Gomega matchers: `Expected ... to equal ...`)
  - Panic traces if any
- Feed back the specific test failures
- Common causes:
  - New code path not covered by existing test expectations
  - Mock expectations not updated for new behavior
  - Race condition in test setup
- Return to Step 7 to fix

**Iteration cap**: 3 attempts.

#### Sensor 4: Lint

**Purpose**: Catch style, static analysis, and security issues.

**Run linter**:
```bash
cd /path/to/kubevirt
make lint
```

`make lint` wraps golangci-lint with the project's configuration (`hack/linter/.golangci.yml`) and runs it against the paths listed in `hack/linter/lint-paths.txt`. It handles test file linting (including ginkgolinter) automatically.

**Success check**: Exit code 0 (no lint violations).

**On failure**:
- Parse JSON output: extract file, line, linter name, and message for each issue
- Filter to only issues in files changed by this branch
- Group issues by linter type
- Apply fixes following the `/kubevirt:lint` categorization:
  - Auto-fixable (gofmt, gofumpt, goimports, misspell): apply directly
  - Manual fix: use the error description to guide the fix
- Return to Step 7 to apply fixes

**Iteration cap**: 3 attempts.

#### Sensor 5: Self-Review

**Purpose**: Final quality gate checking adherence to KubeVirt coding conventions.

**Run a review pass** over the diff:
```bash
git diff <base-branch>...HEAD
```

**Review checklist** (from `/kubevirt:review`):
- Error handling: reasonable messages, early returns, proper wrapping
- Tests: unit tests present, e2e for features/bugs, Eventually for async, DescribeTable for matrices
- Architecture: informers vs GET/LIST, PATCH vs UPDATE, thread safety, RBAC, event patterns
- Go conventions: init statements, switch-cases, var for empty slices, no globals
- Naming: package names, lock names, interface names
- Commit structure: clean messages, in-scope changes

**Success check**: No critical or suggestion-level issues found.

**On failure**:
- List each issue with file path, line, and what convention it violates
- Fix each issue
- Re-run the review pass
- The self-review sensor may also trigger re-running previous sensors if fixes were substantial (e.g., if fixing an architecture issue requires changing the implementation, re-run build and test)

**Iteration cap**: 3 attempts.

### Step 9: Convergence and Commit Preparation

When all 5 sensors pass:

1. **Stage changes** according to the planned commit structure from Step 6
2. **Draft commit messages** using Conventional Commits:
   - `feat(<scope>): <description>` for new features
   - `fix(<scope>): <description>` for bug fixes
   - `refactor(<scope>): <description>` for refactoring
   - `test(<scope>): <description>` for test-only changes
   - `chore(<scope>): <description>` for maintenance
3. **Generate a session summary**:
   - Task: what was requested
   - Implementation: what was done
   - Sensor results: pass/fail counts and iteration totals
   - Commits: proposed messages
   - Follow-ups: e2e tests needing a cluster, manual testing steps, etc.
4. **Present the summary to the user and wait for confirmation** before creating commits

### Step 10: Handling Sensor Exhaustion

If any sensor exhausts its 3-iteration cap:

1. **Stop the loop** - do not proceed to the next sensor or to commit preparation
2. **Report clearly**:
   - Which sensor failed
   - What the remaining errors are (full error output)
   - What was attempted in each iteration (what was changed and why it did not resolve the issue)
   - A suggestion for what the user might try manually
3. **Preserve the work** - do not revert changes. The partial implementation may still be useful as a starting point

## Error Handling

| Error | Recovery |
|-------|----------|
| Task input not parseable | Ask the user to clarify the task or provide a different format |
| GitHub issue not found | Report 404. Check the repo and issue number. Offer to proceed with a free-text description instead |
| Jira ticket not accessible | Report the access error. Offer to proceed with a free-text description |
| `make generate` not available | Skip the generate sensor with a warning. Note that generated code may be stale |
| `make lint` fails with missing tool | Try `hack/dockerized make lint` as fallback. If that also fails, skip lint sensor with a warning |
| `make test` hangs | Use a timeout (10 minutes). If exceeded, kill the process and report the timeout |
| Base branch not found | Try `main`, then `master`. If neither exists, ask the user to specify |
| No Go files in changed paths | Skip the lint and test sensors (they have nothing to check) |

## Examples

### Example 1: Feature from GitHub Issue

```
/kubevirt:dev https://github.com/kubevirt/kubevirt/issues/12345
```

1. Fetches issue #12345 - title: "Add GuestOSInfo condition to VMI status"
2. Identifies affected areas: `staging/src/kubevirt.io/api/core/`, `pkg/virt-controller/watch/vmi/`, `pkg/virt-handler/`
3. Loads OWNERS for compute SIG, reads neighbouring controller code
4. Plans: add condition type, update controller to set it, add unit tests, add e2e test
5. Implements the changes
6. Sensor loop:
   - Generate: pass (deepcopy updated automatically)
   - Build: pass
   - Unit test: fail (iteration 1) - missing mock expectation, fixed, pass (iteration 2)
   - Lint: pass
   - Self-review: pass
7. Presents summary with 2 commits: API change + implementation, tests

### Example 2: Bug Fix from Jira

```
/kubevirt:dev CNV-54321
```

1. Fetches CNV-54321 - "VM fails to start when memory hotplug is enabled with hugepages"
2. Identifies affected areas: `pkg/virt-controller/watch/vm/`, `pkg/virt-handler/`
3. Studies the hotplug code path and hugepages validation
4. Plans: fix the validation logic, add a unit test for the edge case
5. Implements the fix
6. Sensor loop: all sensors pass on first iteration
7. Presents summary with 1 commit: `fix(virt-controller): handle hugepages with memory hotplug`

### Example 3: Free-Text Task

```
/kubevirt:dev "Refactor the migration controller to use a workqueue instead of polling"
```

1. Parses the free-text description
2. Identifies affected area: `pkg/virt-controller/watch/migration/`
3. Studies the current polling implementation and workqueue patterns in other controllers
4. Plans: replace polling loop with workqueue, update tests, preserve existing behavior
5. Implements the refactor
6. Sensor loop:
   - Generate: pass
   - Build: fail (iteration 1) - missing interface method, fixed, pass (iteration 2)
   - Unit test: fail (iteration 1) - test relied on polling interval, rewritten, pass (iteration 2)
   - Lint: pass
   - Self-review: found nested loop (O(n^2)), refactored to hashmap, re-ran build+test, pass
7. Presents summary with 2 commits: refactor + test updates
