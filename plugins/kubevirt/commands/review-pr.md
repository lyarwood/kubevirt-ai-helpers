---
description: Review a GitHub PR using gh CLI, applying KubeVirt project best practices
argument-hint: <pr-number-or-url>
---

## Name
kubevirt:review-pr

## Synopsis
```
/kubevirt:review-pr <pr-number-or-url>
```

## Description
The `kubevirt:review-pr` command performs a comprehensive code review of a GitHub pull request using the `gh` CLI, applying KubeVirt project coding conventions and reviewer guidelines. Unlike `/kubevirt:review` (which reviews local branch changes), this command works directly against a remote PR without requiring a local checkout.

This command simulates a thorough code review following the KubeVirt multi-pass review approach:

### Review Passes
1. **PR Metadata Pass**: Evaluate PR title, description, labels, and overall scope
2. **General Design Pass**: Verify the overall design makes sense and code structure is consistent with the project
3. **Detailed Code Pass**: In-depth analysis of the implementation via the diff
4. **Standards Compliance Pass**: Check adherence to KubeVirt coding conventions
5. **Commit History Pass**: Review commit structure and messages

### Review Checklist
The review evaluates changes against KubeVirt's established standards:

#### PR Metadata
- Clear, descriptive PR title following conventional format
- PR description explains the "what" and "why" of the change
- Appropriate labels and reviewers assigned
- Linked issues referenced where applicable
- Reasonable PR size (flag overly large PRs for splitting)

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

### Phase 1: Gather PR Metadata
1. Parse the PR argument to extract the PR number and repository (defaults to `kubevirt/kubevirt`)
2. Use `gh pr view <pr-number> --repo <repo> --json number,title,body,labels,author,reviewRequests,assignees,baseRefName,headRefName,additions,deletions,changedFiles,commits,comments,reviews,state,isDraft` to get full PR metadata
3. Evaluate PR title, description, size, and draft status
4. Flag PRs that are too large (>500 lines changed across many files) and suggest splitting

### Phase 2: Fetch PR Diff and Changed Files
1. Use `gh pr diff <pr-number> --repo <repo>` to get the full diff
2. Use `gh pr view <pr-number> --repo <repo> --json files` to get the list of changed files with per-file stats
3. For large PRs, prioritize reviewing:
   - API changes (`staging/src/kubevirt.io/api/`)
   - Core logic changes (`pkg/`)
   - Test changes (`tests/`)
   - Generated code changes (flag but don't deeply review)

### Phase 3: Fetch Commit History
1. Use `gh pr view <pr-number> --repo <repo> --json commits` to get the commit list
2. Evaluate commit messages for clarity and conventional format
3. Check for problematic patterns (fixup commits, merge commits, WIP commits)

### Phase 4: Review Existing Discussion
1. Use `gh pr view <pr-number> --repo <repo> --json comments,reviews` to get existing review comments
2. Consider existing reviewer feedback to avoid duplicating points already raised
3. Note any unresolved review threads

### Phase 5: Analyze Changes
1. Perform the multi-pass review against the diff:
   - **General Design Pass**: Overall design and architecture
   - **Detailed Code Pass**: Line-by-line implementation review
   - **Standards Compliance Pass**: KubeVirt coding conventions
2. For each issue found, note the file path and relevant diff context
3. Categorize findings by severity

### Phase 6: Generate Review Report
1. Create a structured review report
2. If the `--submit` flag is used, post the review via `gh pr review`:
   - `gh pr review <pr-number> --repo <repo> --comment --body "<review>"` for general feedback
   - `gh pr review <pr-number> --repo <repo> --approve --body "<review>"` to approve
   - `gh pr review <pr-number> --repo <repo> --request-changes --body "<review>"` to request changes

## Return Value
A structured code review report containing:

- **PR Overview**: Title, author, size stats, draft status, labels
- **Summary**: Overview of the changes and general assessment
- **Critical Issues**: Problems that must be addressed before merge
- **Suggestions**: Recommended improvements
- **Nitpicks**: Minor style or convention issues
- **Positive Observations**: Good practices worth noting
- **Commit History Feedback**: Commit organization and message quality
- **Existing Discussion Summary**: Key points from prior reviews
- **Verdict**: Recommended action (approve, request changes, or comment)

## Examples

1. **Review a PR by number** (defaults to kubevirt/kubevirt):
   ```
   /kubevirt:review-pr 12345
   ```

2. **Review using full PR URL**:
   ```
   /kubevirt:review-pr https://github.com/kubevirt/kubevirt/pull/12345
   ```

3. **Review a PR in a different repo**:
   ```
   /kubevirt:review-pr kubevirt/containerized-data-importer#5678
   ```

4. **Review and submit feedback to GitHub**:
   ```
   /kubevirt:review-pr 12345 --submit
   ```
   Posts the review as a comment on the PR.

5. **Review and approve**:
   ```
   /kubevirt:review-pr 12345 --submit --approve
   ```

## Arguments
- `<pr-number-or-url>`: (Required) The PR to review. Can be:
  - A simple PR number (e.g., `12345`) - assumes kubevirt/kubevirt
  - A full GitHub URL (e.g., `https://github.com/kubevirt/kubevirt/pull/12345`)
  - An owner/repo#number format (e.g., `kubevirt/kubevirt#12345`)

## Options
- `--submit`: Post the review as a comment on the GitHub PR
- `--approve`: Used with `--submit` to approve the PR
- `--request-changes`: Used with `--submit` to request changes on the PR

## See Also
- `/kubevirt:review` - Review local branch changes using KubeVirt project best practices
- `/kubevirt:review-ci` - Review CI failures for a given PR
- `/kubevirt:lint` - Lint a path and generate a plan to fix issues
- KubeVirt [Coding Conventions](https://github.com/kubevirt/kubevirt/blob/main/docs/coding-conventions.md)
- KubeVirt [Reviewer Guide](https://github.com/kubevirt/kubevirt/blob/main/docs/reviewer-guide.md)
