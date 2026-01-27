---
description: Lint a path and generate a plan to fix issues with separate commits per linter
argument-hint: <path>
---

## Name
kubevirt:lint

## Synopsis
```
/kubevirt:lint <path>
```

## Description
The `kubevirt:lint` command runs golangci-lint on a specified path within the KubeVirt codebase and generates an actionable plan to fix all linting issues. Each type of linting failure is addressed in a separate commit, making the changes easy to review and bisect.

This command:
1. Runs golangci-lint with KubeVirt's configuration
2. Groups issues by linter type
3. Generates a plan with one task per linter type
4. Executes fixes with individual commits for each linter category

### Commit Strategy
Issues are fixed in separate commits organized by linter type, following the [Conventional Commits](https://www.conventionalcommits.org/) specification:

| Category | Linters | Commit Format |
|----------|---------|---------------|
| Formatting | `gofmt`, `gofumpt`, `goimports` | `style(<path>): fix formatting issues` |
| Spelling | `misspell` | `style(<path>): fix spelling errors` |
| Error handling | `errcheck`, `bodyclose`, `noctx` | `fix(<path>): handle unchecked errors` |
| Static analysis | `govet`, `staticcheck`, `ineffassign`, `unused` | `refactor(<path>): fix static analysis issues` |
| Style | `lll`, `goconst`, `nakedret`, `whitespace` | `style(<path>): fix line length and style issues` |
| Complexity | `gocyclo`, `funlen`, `dupl` | `refactor(<path>): reduce function complexity` |
| Security | `gosec` | `fix(<path>): address security issues` |
| Tests | `ginkgolinter` | `test(<path>): fix ginkgo linter issues` |
| lint-paths.txt | N/A | `chore(lint): add <path> to lint-paths.txt` |

### Linting Configuration
KubeVirt uses golangci-lint with configuration at `hack/linter/.golangci.yml`. Key linters:

| Category | Linters | Auto-fixable |
|----------|---------|--------------|
| Formatting | `gofmt`, `gofumpt`, `goimports` | Yes |
| Spelling | `misspell` | Yes |
| Error Handling | `errcheck`, `bodyclose`, `noctx` | Manual |
| Static Analysis | `govet`, `staticcheck`, `ineffassign`, `unused` | Manual |
| Style | `lll`, `goconst`, `nakedret`, `whitespace` | Partial |
| Complexity | `gocyclo`, `funlen`, `dupl` | Manual |
| Security | `gosec` | Manual |

### lint-paths.txt
The file `hack/linter/lint-paths.txt` contains directories linted in CI. If the target path is not listed, the plan will include adding it.

## Implementation

### Phase 1: Analysis
1. Validate the provided path exists in the KubeVirt codebase
2. Check if the path is listed in `hack/linter/lint-paths.txt`
3. Run golangci-lint with JSON output:
   ```bash
   cd /path/to/kubevirt
   golangci-lint run --config hack/linter/.golangci.yml --timeout 10m --out-format=json <path>/... 2>/dev/null
   ```
4. If path contains test files, also run ginkgolinter:
   ```bash
   golangci-lint run --default=none --enable=ginkgolinter --timeout 5m --no-config --out-format=json <path>/...
   ```
5. Parse JSON output and group issues by linter name

### Phase 2: Plan Generation
Generate a task list with one task per linter type that has issues. All commits follow [Conventional Commits](https://www.conventionalcommits.org/) format:

1. **Formatting issues** (if any `gofmt`/`gofumpt`/`goimports` issues):
   - Run `gofumpt -w` and `goimports -w` on affected files
   - Commit: `style(<path>): fix formatting issues`

2. **Spelling issues** (if any `misspell` issues):
   - Apply spelling corrections
   - Commit: `style(<path>): fix spelling errors`

3. **Error handling issues** (if any `errcheck`/`bodyclose`/`noctx` issues):
   - Add error checks, close bodies, add context
   - Commit: `fix(<path>): handle unchecked errors`

4. **Static analysis issues** (if any `govet`/`staticcheck`/`ineffassign`/`unused` issues):
   - Fix shadowed variables, remove ineffective assignments, remove unused code
   - Commit: `refactor(<path>): fix static analysis issues`

5. **Style issues** (if any `lll`/`goconst`/`nakedret`/`whitespace` issues):
   - Break long lines, extract constants, add explicit returns
   - Commit: `style(<path>): fix line length and style issues`

6. **Complexity issues** (if any `gocyclo`/`funlen`/`dupl` issues):
   - Refactor complex functions, extract helpers, reduce duplication
   - Commit: `refactor(<path>): reduce function complexity`

7. **Security issues** (if any `gosec` issues):
   - Address security concerns
   - Commit: `fix(<path>): address security issues`

8. **Test issues** (if any `ginkgolinter` issues):
   - Fix Ginkgo/Gomega patterns
   - Commit: `test(<path>): fix ginkgo linter issues`

9. **Add to lint-paths.txt** (if path not already listed):
   - Add path to `hack/linter/lint-paths.txt`
   - Commit: `chore(lint): add <path> to lint-paths.txt`

### Phase 3: Execution
For each task in the plan:
1. Display the issues to be fixed
2. Apply fixes (auto-fix where possible, manual fixes otherwise)
3. Stage only the affected files
4. Create a commit with the appropriate message
5. Verify the specific linter passes before proceeding

## Return Value
An executable plan containing:
- **Analysis Summary**: Issue counts grouped by linter
- **Task List**: Ordered tasks with one commit per linter category
- **Execution**: Fixes applied with individual commits

## Examples

1. **Lint and fix a package**:
   ```
   /kubevirt:lint pkg/virt-controller/watch
   ```
   Analyzes the package, generates a plan, and creates commits like:
   - `style(pkg/virt-controller/watch): fix formatting issues`
   - `fix(pkg/virt-controller/watch): handle unchecked errors`
   - `refactor(pkg/virt-controller/watch): fix static analysis issues`

2. **Lint a new package not in lint-paths.txt**:
   ```
   /kubevirt:lint pkg/virt-handler/cgroup
   ```
   Fixes issues and adds a final commit:
   - `chore(lint): add pkg/virt-handler/cgroup to lint-paths.txt`

3. **Lint test code**:
   ```
   /kubevirt:lint tests/libvmops
   ```
   Includes ginkgolinter fixes:
   - `test(tests/libvmops): fix ginkgo linter issues`

## Arguments
- `<path>`: (Required) Relative path within the KubeVirt codebase to lint and fix

## Prerequisites
- The KubeVirt codebase must be available (added via `/add-dir`)
- `golangci-lint` must be installed (or use containerized via `hack/dockerized`)
- Working directory should be clean (no uncommitted changes)

## See Also
- `/kubevirt:review` - Review local branch changes using KubeVirt best practices
- KubeVirt [golangci-lint configuration](https://github.com/kubevirt/kubevirt/blob/main/hack/linter/.golangci.yml)
- KubeVirt [lint-paths.txt](https://github.com/kubevirt/kubevirt/blob/main/hack/linter/lint-paths.txt)
