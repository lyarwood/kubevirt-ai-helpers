---
name: KubeVirt Review Checklist
description: Shared review checklist, conventions, and multi-pass methodology used by review and review-pr commands
---

# KubeVirt Review Checklist

This skill defines the shared review checklist, multi-pass methodology, and output formatting rules used by both `/kubevirt:review` (local branch) and `/kubevirt:review-pr` (remote GitHub PR) commands.

## Multi-Pass Review Approach

Every review follows three analysis passes applied to the diff:

1. **General Design Pass**: Verify the overall design makes sense and code structure is consistent with the project
2. **Detailed Code Pass**: In-depth, line-by-line analysis of the implementation
3. **Standards Compliance Pass**: Check adherence to KubeVirt coding conventions listed below

For each issue found, note the file path and relevant diff context. Categorize findings by severity.

## Review Checklist

### PR Metadata

- Clear, descriptive PR title following conventional format
- PR description explains the "what" and "why" of the change
- Appropriate labels and reviewers assigned
- Linked issues referenced where applicable
- Reasonable PR size (flag overly large PRs for splitting)

### Code Quality

- User input validation
- Reasonable error messages and info messages
- Elegant, cohesive, and easily readable code
- Early returns to avoid nesting and complexity
- Consistent coding style throughout files
- Constants/variables for documenting value meanings
- Uniform import order and naming conventions

### Testing Requirements

- Unit tests for new code
- E2E tests for new features and bug fixes (core case must be tested)
- Proper use of `Eventually` for async operations (no arbitrary waits)
- Table-driven tests using Ginkgo's `DescribeTable` for test matrices
- Proper use of decorators instead of `Skip` in tests

### Architecture

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

### Go Conventions

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

### Naming Conventions

- Package names match directory names
- No uppercase, underscores, or dashes in package names
- Command-line flags use dashes
- Locks named `lock` or with distinct names (`stateLock`, `mapLock`)
- Interface names avoid redundancy with package name

### PR Structure

- Commits should make sense (no "Fix reviewer comments", "wip" commits)
- Changes should be in scope (out-of-scope changes belong in separate PRs)
- Rebase preferred over merge commits

### Dependencies

- New dependencies from trusted, well-established organizations
- Dependencies should be well-maintained with active repositories

## File Priority Order

For large changesets, prioritize reviewing in this order:

1. API changes (`staging/src/kubevirt.io/api/`)
2. Core logic changes (`pkg/`)
3. Test changes (`tests/`)
4. Generated code changes (flag but don't deeply review)

## Output Formatting Rules

### ASCII-Only Requirement

All output text MUST use plain ASCII characters only:
- Do NOT use Unicode symbols, special characters, or emojis (no checkmarks, crosses, arrows, bullets, stars, warning signs, etc.)
- Do NOT prepend tag prefixes like `[ISSUE]`, `[NIT]`, `[CRITICAL]`, `[WARNING]`, `[NOTE]`, `[OK]`, or similar to comments - write the comment text directly
- Lowercase descriptors like `nit:` are fine
- Prefer single dashes `-` over double dashes `--` in prose and commentary text
- Section headers should use plain text markers like `===`, `---`, or markdown `#`/`##`/`###`
- This rule applies to ALL output: terminal reports, GitHub review comments, and any other generated text

## Severity Categories

Organize findings into these categories:

- **Critical Issues**: Must be addressed before merge (bugs, security, missing error handling)
- **Suggestions**: Recommended improvements (design, better patterns)
- **Nitpicks**: Minor style or convention issues (naming, readability)
- **Positive Observations**: Good practices worth noting

## References

- KubeVirt [Coding Conventions](https://github.com/kubevirt/kubevirt/blob/main/docs/coding-conventions.md)
- KubeVirt [Reviewer Guide](https://github.com/kubevirt/kubevirt/blob/main/docs/reviewer-guide.md)
