---
description: Review local branch changes using KubeVirt project best practices
argument-hint: [base-branch]
---

## Name
kubevirt:review

## Synopsis
```
/kubevirt:review [base-branch]
```

## Description
The `kubevirt:review` command performs a comprehensive code review of changes on the current local branch compared to a base branch, applying KubeVirt project coding conventions and reviewer guidelines.

This command simulates a thorough code review following the KubeVirt multi-pass review approach:

### Review Passes
1. **General Design Pass**: Verify the overall design makes sense and code structure is consistent with the project
2. **Detailed Code Pass**: In-depth analysis of the implementation
3. **Standards Compliance Pass**: Check adherence to KubeVirt coding conventions
4. **Commit History Pass**: Review commit structure and messages

### Review Checklist
The review evaluates changes against KubeVirt's established standards:

#### Code Quality
- User input validation
- Reasonable error messages and info messages
- Elegant, cohesive, and easily readable code
- Early returns to avoid nesting and complexity
- Consistent coding style throughout files
- Constants/variables for documenting value meanings
- Uniform import order and naming conventions

#### Testing Requirements
- Unit tests for new code
- E2E tests for new features and bug fixes (core case must be tested)
- Proper use of `Eventually` for async operations (no arbitrary waits)
- Table-driven tests using Ginkgo's `DescribeTable` for test matrices
- Proper use of decorators instead of `Skip` in tests

#### Architecture
- Informers vs GET/LIST usage (informers for virt-controller/virt-operator, GETs for virt-api)
- PATCH vs UPDATE operations (PATCH when controller doesn't own the object)
- Thread safety in reconcile loops (map access protected by locks)
- Appropriate RBAC permissions (separation of concerns)
- Update path considerations (backwards compatibility impact)
- Event firing patterns (avoid firing on every reconcile)
- List ordering preservation on CRD APIs
- Privileged operations in virt-handler, not virt-launcher
- Avoid nested loops (use hash maps for O(n) instead of O(n^2))
- Avoid adding informers to node-level components like virt-handler

#### Go Conventions
- Prefer initialization statements (inline err checks)
- Use switch-cases for long if/else chains
- Use interfaces for polymorphism and behavior definition
- Avoid global variables (use structs with receiver methods)
- Avoid long files and utility file sprawl
- Avoid returning too many values from functions
- Prefer function body variables over named return values
- Use closures with caution
- Declare empty slices with var syntax
- Use helpers/builders instead of `fmt.Sprintf` for complex objects
- Use `kubevirt.io/kubevirt/pkg/pointer` for pointer operations
- Keep function signatures lean

#### Naming Conventions
- Package names match directory names
- No uppercase, underscores, or dashes in package names
- Command-line flags use dashes
- Locks named `lock` or with distinct names (`stateLock`, `mapLock`)
- Interface names avoid redundancy with package name

#### PR Structure
- Commits should make sense (no "Fix reviewer comments", "wip" commits)
- Changes should be in scope (out-of-scope changes belong in separate PRs)
- Rebase preferred over merge commits

#### Dependencies
- New dependencies from trusted, well-established organizations
- Dependencies should be well-maintained with active repositories

## Implementation

### Phase 1: Gather Changes
1. Determine the base branch (defaults to `main`, falls back to `master`)
2. Run `git diff <base-branch>...HEAD` to get all changes on the current branch
3. Run `git log <base-branch>...HEAD` to understand commit history and structure
4. For large changesets, prioritize reviewing:
   - API changes (`staging/src/kubevirt.io/api/`)
   - Core logic changes (`pkg/`)
   - Test changes (`tests/`)
   - Generated code changes (flag but don't deeply review)

### Phase 2: Analyze Changes (Multi-Pass)
1. Perform the multi-pass review against the diff:
   - **General Design Pass**: Overall design and architecture
   - **Detailed Code Pass**: Line-by-line implementation review, considering context of surrounding code
   - **Standards Compliance Pass**: KubeVirt coding conventions
2. For each issue found, note the file path and relevant diff context
3. Categorize findings by severity

### Phase 3: Review Commit History
1. Evaluate commit messages for clarity and conventional format
2. Check for problematic patterns (fixup commits, merge commits, WIP commits)
3. Assess whether changes are in scope or should be split into separate PRs

### Phase 4: Generate Review Report
1. Create a structured review report using plain ASCII characters only
2. Organize feedback by severity:
   - Critical issues (must fix)
   - Suggestions (should consider)
   - Nitpicks (minor improvements)
   - Positive observations (good practices observed)

## Output Formatting Rules

### ASCII-Only Requirement
All output text MUST use plain ASCII characters only:
- Do NOT use Unicode symbols, special characters, or emojis (no checkmarks, crosses, arrows, bullets, stars, warning signs, etc.)
- Use plain text alternatives: `[OK]`, `[ISSUE]`, `[WARNING]`, `[NOTE]`, `[NIT]`, `[CRITICAL]`, `*`, `-`, `->`, `>>` instead
- Prefer single dashes `-` over double dashes `--` in prose and commentary text
- Section headers should use plain text markers like `===`, `---`, or markdown `#`/`##`/`###`
- This rule applies to ALL output: the terminal report and any other generated text

## Return Value
A structured code review report containing:
- **Summary**: Overview of the changes and general assessment
- **Critical Issues**: Problems that must be addressed before merge
- **Suggestions**: Recommended improvements
- **Nitpicks**: Minor style or convention issues
- **Positive Observations**: Good practices worth noting
- **Commit History Feedback**: Commit organization and message quality
- **PR Structure Feedback**: Scope assessment

## Examples

1. **Review against main branch**:
   ```
   /kubevirt:review
   ```
   Reviews all changes on the current branch compared to `main`.

2. **Review against specific branch**:
   ```
   /kubevirt:review release-1.2
   ```
   Reviews changes compared to the `release-1.2` branch.

3. **Review feature branch**:
   ```
   git checkout feature/new-vm-option
   /kubevirt:review main
   ```
   Reviews the feature branch changes against main.

## Arguments
- `[base-branch]`: (Optional) Branch to compare against. Defaults to `main`, falls back to `master` if main doesn't exist.

## See Also
- `/kubevirt:lint` - Lint a path and generate a plan to fix issues
- KubeVirt [Coding Conventions](https://github.com/kubevirt/kubevirt/blob/main/docs/coding-conventions.md)
- KubeVirt [Reviewer Guide](https://github.com/kubevirt/kubevirt/blob/main/docs/reviewer-guide.md)
