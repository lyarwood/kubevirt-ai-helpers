---
description: Development workflow for kubevirt/kubevirt with automated sensor feedback loops
argument-hint: <task-description-or-url>
---

## Name
kubevirt:dev

## Synopsis
```
/kubevirt:dev <task-description-or-url>
```

## Description
The `kubevirt:dev` command implements a complete development workflow for the kubevirt/kubevirt codebase. It combines feedforward guides (conventions, patterns, ownership context) with feedback sensors (build, test, lint, review) in an iterative agent loop that continues until all sensors pass or the iteration cap is reached.

This command follows the harness pattern: guides prevent errors before they happen, sensors detect errors after each change, and the agent loop iterates until convergence.

### Workflow Phases

```
Guides (loaded once)        Agent Loop (iterates)         Gate (runs once)
--------------------        --------------------         ----------------
Conventions                 Plan change                  Self-review
OWNERS context       --->   Implement              ,--> Commit preparation
Existing patterns           Run sensors ---fail?--'     Summary
Task intent                 All pass? ------yes-------->
```

### Guides (Feedforward Controls)
Context loaded before coding begins to prevent common mistakes:
- KubeVirt coding conventions and reviewer checklist
- OWNERS and OWNERS_ALIASES for the affected SIG and packages
- Existing code patterns in the target packages
- Task intent from the provided issue, ticket, or description

### Sensors (Feedback Controls)
Automated checks that run after each implementation pass:

| Sensor | What it runs | What it catches |
|--------|-------------|-----------------|
| Generate | `make generate` | Stale deepcopy, client-gen, mocks |
| Build | `make build` | Compilation errors |
| Unit test | `make test` (targeted) | Logic errors in changed packages |
| Lint | `make lint` on changed paths | Style, static analysis, security |
| Self-review | Review pass against conventions | Architecture, naming, test patterns |

Each sensor is mandatory. On failure, the sensor output is fed back into the agent loop for self-correction. The maximum iteration count per sensor is 3 - if a sensor still fails after 3 attempts, the workflow halts and reports the remaining issues to the user.

### Task Input
The command accepts any of the following as task input:
- A free-text description of the task
- A GitHub issue URL (e.g., `https://github.com/kubevirt/kubevirt/issues/12345`)
- A GitHub issue in owner/repo#number format (e.g., `kubevirt/kubevirt#12345`)
- A Jira ticket URL (e.g., `https://issues.redhat.com/browse/CNV-12345`)
- A Jira ticket ID (e.g., `CNV-12345`)

## Implementation

Refer to the detailed implementation guide in `plugins/kubevirt/skills/dev/SKILL.md` for step-by-step instructions on each phase.

### Phase 1: Context Loading (Guides)

Load feedforward context to inform the implementation. This phase runs once before coding begins.

1. **Parse task input**:
   - If a GitHub issue URL or reference: fetch the issue body, labels, and comments using `gh issue view`
   - If a Jira ticket: fetch the ticket summary, description, and acceptance criteria using the Jira API
   - If free text: use the description as-is
   - Extract the intent: what needs to change, why, and any acceptance criteria

2. **Identify affected areas**:
   - From the task description, identify which packages, components, or APIs are likely affected
   - Map affected areas to SIGs using the standard mapping:
     | SIG | Primary Directories |
     |-----|-------------------|
     | compute | `pkg/virt-controller/`, `pkg/virt-handler/`, `pkg/virt-launcher/`, `pkg/virt-api/`, `staging/src/kubevirt.io/api/core/` |
     | network | `pkg/network/`, `pkg/virt-launcher/virtwrap/network/` |
     | storage | `pkg/storage/`, `pkg/container-disk/`, `pkg/virtctl/imageupload/` |

3. **Load ownership context**:
   - Fetch `OWNERS_ALIASES` from kubevirt/kubevirt to understand SIG membership
   - Fetch `OWNERS` files from the affected directories
   - This informs whose conventions and patterns to follow

4. **Study existing patterns**:
   - Read 2-3 neighbouring files in the target package to understand local conventions
   - Look at recent commits in the affected area (`git log --oneline -20 -- <path>`)
   - Identify patterns: error handling style, test structure, naming conventions, comment style

5. **Load coding conventions**:
   - The review checklist from `/kubevirt:review` serves as the convention reference
   - Key areas: error handling, informers vs GET/LIST, PATCH vs UPDATE, test patterns (Eventually, DescribeTable), naming, RBAC, thread safety

### Phase 2: Planning

Before writing code, produce a brief plan covering:

1. **What changes are needed**: list files to create, modify, or delete
2. **Approach**: how the change fits into existing architecture
3. **Test strategy**: what unit tests and e2e tests are needed
4. **Risk areas**: backwards compatibility, API changes, RBAC implications
5. **Commit strategy**: how to structure commits (e.g., API change, implementation, tests)

Present the plan to the user and wait for confirmation before proceeding. If the user requests changes to the plan, update it and confirm again.

### Phase 3: Implementation

Execute the plan:

1. Make the code changes following the loaded conventions and patterns
2. Include unit tests for new or modified code
3. Include e2e tests for new features or bug fixes (the core case must be tested)
4. Run `make generate` if API types, deepcopy, or client code were modified
5. Stage changes logically for the planned commit structure

### Phase 4: Sensor Loop

Run all sensors in sequence. On the first failure, feed the error output back and return to Phase 3 to fix the issue. Track iteration count per sensor.

**Sensor execution order** (each sensor gates the next):

#### Sensor 1: Generate
```bash
make generate
```
- Check if any files were modified by `make generate` that are not already staged
- If files changed: the generated code was stale - stage the generated files and record as a fix
- If `make generate` fails: feed the error output back, return to Phase 3
- Iteration cap: 3

#### Sensor 2: Build
```bash
make build
```
- If compilation fails: extract error messages (file:line: error text), feed back, return to Phase 3
- Focus fixes on the specific compilation errors rather than re-examining the full implementation
- Iteration cap: 3

#### Sensor 3: Unit Test
```bash
# Target only the changed packages
make test GO_TEST_PACKAGES="<changed-package-paths>"
```
- Determine changed packages from `git diff --name-only` against the base branch
- Convert file paths to Go package paths (e.g., `pkg/virt-controller/watch/vm.go` becomes `kubevirt.io/kubevirt/pkg/virt-controller/watch`)
- If tests fail: extract the test name, assertion message, and expected vs actual values, feed back, return to Phase 3
- If a test is missing: write the test, then re-run
- Iteration cap: 3

#### Sensor 4: Lint
```bash
make lint
```
- `make lint` wraps golangci-lint with the project's configuration and lint-paths
- If issues found: fix them following the `/kubevirt:lint` categorization approach, feed back, return to fix
- For auto-fixable linters (gofmt, gofumpt, goimports, misspell): apply fixes directly
- For manual-fix linters: apply the fix based on the error description
- Iteration cap: 3

#### Sensor 5: Self-Review
Perform a review pass against the KubeVirt coding conventions checklist (from `/kubevirt:review`):
- Check error handling patterns
- Check test coverage and patterns (Eventually for async, DescribeTable for matrices)
- Check architecture patterns (informers vs GET/LIST, PATCH vs UPDATE)
- Check naming conventions
- Check for unnecessary complexity or missing early returns
- If issues found: fix them, then re-run the review pass
- Iteration cap: 3

**Loop termination**:
- All 5 sensors pass: proceed to Phase 5
- Any sensor exhausts its 3-iteration cap: halt and report the remaining failures to the user with full context (error messages, what was tried, why it could not be resolved automatically)

### Phase 5: Commit Preparation

Once all sensors pass:

1. **Stage changes** according to the planned commit structure
2. **Write commit messages** following Conventional Commits format:
   - Use the appropriate prefix: `feat`, `fix`, `refactor`, `test`, `chore`, `docs`
   - Include the scope (affected package or component)
   - Write a clear description of what changed and why
3. **Present a summary** to the user containing:
   - What was implemented
   - Which sensors passed and how many iterations each required
   - The planned commits with their messages
   - Any caveats or follow-up items
4. **Wait for user confirmation** before creating the commits

Do NOT create commits automatically. Present the summary and wait for the user to confirm or request changes.

## Output Formatting Rules

### ASCII-Only Requirement
All output text MUST use plain ASCII characters only:
- Do NOT use Unicode symbols, special characters, or emojis
- Do NOT prepend tag prefixes like `[ISSUE]`, `[NIT]`, `[PASS]`, `[FAIL]` to output lines
- Use markdown headers `#`/`##`/`###` for section breaks
- Prefer single dashes `-` over double dashes `--` in prose

## Return Value
A development session report containing:

- **Task Summary**: What was requested and what was implemented
- **Sensor Results**: Pass/fail status and iteration counts for each sensor
- **Changes Made**: List of files created, modified, or deleted
- **Commit Plan**: Proposed commits with messages
- **Follow-up Items**: Anything that could not be addressed automatically (e.g., e2e tests that need a running cluster, manual testing steps)

## Examples

1. **Develop from a GitHub issue**:
   ```
   /kubevirt:dev https://github.com/kubevirt/kubevirt/issues/12345
   ```
   Fetches the issue, loads context, plans the implementation, codes it, and runs all sensors until they pass.

2. **Develop from a Jira ticket**:
   ```
   /kubevirt:dev CNV-12345
   ```
   Fetches the Jira ticket, extracts requirements, and runs the full development workflow.

3. **Develop from a free-text description**:
   ```
   /kubevirt:dev "Add a new condition to VMI status that tracks when the guest agent is connected"
   ```
   Uses the description as intent, identifies affected packages (API types, virt-controller, virt-handler), and runs the workflow.

4. **Develop from a GitHub issue reference**:
   ```
   /kubevirt:dev kubevirt/kubevirt#12345
   ```
   Same as the URL form, using the shorthand reference.

## Arguments
- `<task-description-or-url>`: (Required) The task to implement. Accepts:
  - Free-text description
  - GitHub issue URL
  - GitHub issue reference (owner/repo#number)
  - Jira ticket URL
  - Jira ticket ID (e.g., CNV-12345)

## Prerequisites
- The kubevirt/kubevirt codebase must be available (added via `/add-dir`)
- `go` toolchain must be installed for build and test
- `make lint` must be functional (uses golangci-lint under the hood via the project Makefile)
- `gh` CLI must be installed and authenticated (for GitHub issue input)
- Working directory should be on a clean feature branch

## See Also
- `/kubevirt:lint` - Lint and fix a path with separate commits per linter
- `/kubevirt:review` - Review local branch changes using KubeVirt best practices
- `/kubevirt:review-ci` - Analyze CI failures for a PR after pushing
- KubeVirt [Coding Conventions](https://github.com/kubevirt/kubevirt/blob/main/docs/coding-conventions.md)
- KubeVirt [Getting Started](https://github.com/kubevirt/kubevirt/blob/main/docs/getting-started.md)
