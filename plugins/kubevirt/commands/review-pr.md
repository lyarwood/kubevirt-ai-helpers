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
1. Use `gh pr view <pr-number> --repo <repo> --json comments,reviews` to get existing review metadata
2. Fetch actual inline review comment content using `gh api repos/<owner>/<repo>/pulls/<pr-number>/comments` to read all PR review comments with their file paths, line numbers, and body text
3. For each review listed, also fetch per-review comments if needed: `gh api repos/<owner>/<repo>/pulls/<pr-number>/reviews/<review-id>/comments`
4. Read and understand the substance of each comment from the fetched API text - do not just note that comments exist or rely on assumptions about what they say
5. When generating the review report, do NOT duplicate points already raised in existing comments
6. Note which existing comments have been addressed by subsequent commits and which remain unresolved

### Phase 5: Analyze Changes
1. Perform the multi-pass review against the diff:
   - **General Design Pass**: Overall design and architecture
   - **Detailed Code Pass**: Line-by-line implementation review
   - **Standards Compliance Pass**: KubeVirt coding conventions
2. For each issue found, note the file path. Do NOT record line numbers yet - they will be computed and verified in Phase 5b.
3. Categorize findings by severity.

### Phase 5b: Derive Line Numbers from Hunk Headers (REQUIRED gate before Phase 6)
Line numbers MUST always be derived from diff hunk headers so they match the actual source file. The Read tool prepends its own sequential line numbers to output - these are NOT source file line numbers and MUST NEVER be used.

For EVERY finding, derive the correct source line number as follows:
1. Locate the nearest hunk header above the target line in the diff: `@@ -<old_start>,<old_count> +<new_start>,<new_count> @@`
2. Starting from the first line after that header, count only context lines (` ` prefix) and added lines (`+` prefix) down to your target line. Skip removed lines (`-` prefix) - they do not exist in the new file.
3. Compute: `source_line = new_start + (count - 1)`. This formula works for all cases including new files (`@@ -0,0 +1,N @@` where `new_start = 1`).
4. Verify EACH computed line number by running:
   ```
   gh api repos/<owner>/<repo>/contents/<path>?ref=<head-sha> \
     -q '.content' | base64 -d | sed -n '<source_line>p'
   ```
   If the output does not match the code you intend to reference, the line number is wrong - recount from the hunk header.

Do NOT proceed to Phase 6 until every finding has a verified source line number.

### Phase 6: Generate Review Report
1. Create a structured review report using plain ASCII characters only
2. Present the report to the user before proceeding to Phase 7

### Phase 7: Offer to Add Review Comments on GitHub
IMPORTANT: After presenting the review report, you MUST proceed to Phase 7. Do not wait for the user to ask.

First, determine which review findings would result in new inline comments (findings that are not already covered by existing PR comments). If there are no new comments to add, state that all points have already been covered in existing discussion and skip the rest of Phase 7.

If there are new comments to add, offer to add them as inline review comments on GitHub as a **pending review** (NOT submitted). This allows the user to review the comments before submitting.

1. Ask the user if they want to add the new review comments to the PR on GitHub
2. If the user agrees, proceed with adding comments as described below

#### Checking for Existing Pending Reviews

**CRITICAL: Existing pending comments are sacred and MUST be preserved exactly as-is.**

The user may have manually written or edited pending review comments before invoking this command. These comments represent the user's own review work and MUST NOT be modified, reworded, dropped, or reordered under any circumstances.

Before adding comments, check if there is already a pending review from the current user:
1. Use `gh api repos/<owner>/<repo>/pulls/<pr-number>/reviews` to list all reviews
2. Filter for reviews with `state: "PENDING"` and authored by the current user (use `gh api user` to get the current username)
3. If a pending review exists:
   - Retrieve existing pending comments with `gh api repos/<owner>/<repo>/pulls/<pr-number>/reviews/<review-id>/comments`
   - Collect all existing comments and **preserve every single one exactly as-is** - do NOT alter the body text, file path, line number, or any other field of existing comments
   - Delete the existing pending review: `gh api repos/<owner>/<repo>/pulls/<pr-number>/reviews/<review-id> --method DELETE`
   - Combine old comments with new comments, placing preserved old comments first, then appending new comments
   - When deduplicating by file path and line number, always keep the **existing** comment (the user's version) and discard the new AI-generated one - never replace a user's comment with an AI-generated alternative
4. If no pending review exists, proceed directly to creating one with the new comments

#### Filtering Out Already-Discussed Points
Before building the comment list, cross-reference your review findings against ALL existing comments on the PR (from Phase 4 and from any existing pending review):
- Do NOT add a comment for a point that has already been raised by any reviewer on the same file and line or on the same topic
- Compare by substance, not just file path and line number - if someone already commented about the same issue even on a different line, do not duplicate it
- Only add comments that raise genuinely new points not yet discussed on the PR

#### Re-verify Line Numbers (REQUIRED before posting)
Before building the review payload, re-derive and verify every line number for new comments using the same procedure as Phase 5b. For each new comment:
1. Re-derive the source line number from the diff hunk header (count context and added lines, skip removed lines, compute `new_start + (count - 1)`).
2. Verify by running:
   ```
   gh api repos/<owner>/<repo>/contents/<path>?ref=<head-sha> \
     -q '.content' | base64 -d | sed -n '<source_line>p'
   ```
   The output MUST match the code the comment refers to. If it does not, recount from the hunk header until it does. Do NOT post a comment with an unverified line number.

#### Creating the Review with All Comments
All comments must be added in a single `POST /repos/.../pulls/.../reviews` call using the `comments` array in the JSON body. Do NOT use a separate per-comment endpoint.

**IMPORTANT**: Preserved existing comments MUST appear with their original body text verbatim - do not rephrase, summarize, fix typos, or "improve" them in any way.

1. Build a JSON body with all comments (preserved old comments first, then new ones):
   ```
   gh api repos/<owner>/<repo>/pulls/<pr-number>/reviews \
     --method POST \
     --input - <<'EOF'
   {
     "body": "Review summary text here",
     "comments": [
       {
         "path": "pkg/example/file.go",
         "line": 42,
         "side": "RIGHT",
         "body": "Comment text here"
       },
       {
         "path": "pkg/example/other.go",
         "start_line": 10,
         "line": 15,
         "side": "RIGHT",
         "body": "Multi-line comment here"
       }
     ]
   }
   EOF
   ```
2. Do NOT include an `event` field - omitting it creates the review in PENDING state by default
3. For findings that span multiple lines, use `start_line` and `line` to create multi-line comments
4. For general findings not tied to a specific line, add them as a single comment on a relevant file
5. The `line` field must use verified source file line numbers from Phase 5b

#### Important: Do NOT Submit the Review
- The review MUST remain in PENDING state after adding comments
- Do NOT call the submit review endpoint (`POST /repos/.../pulls/.../reviews/.../events`)
- Do NOT use `gh pr review --approve/--request-changes/--comment` as this submits immediately
- Inform the user that the review is pending and they can go to the PR page to review comments and submit manually

## Output Formatting Rules

### ASCII-Only Requirement
All output text, review comments, and GitHub review comments MUST use plain ASCII characters only:
- Do NOT use Unicode symbols, special characters, or emojis (no checkmarks, crosses, arrows, bullets, stars, warning signs, etc.)
- Do NOT prepend tag prefixes like `[ISSUE]`, `[NIT]`, `[CRITICAL]`, `[WARNING]`, `[NOTE]`, `[OK]`, or similar to comments - write the comment text directly
- Prefer single dashes `-` over double dashes `--` in prose and commentary text
- Section headers should use plain text markers like `===`, `---`, or markdown `#`/`##`/`###`
- This rule applies to ALL output: the terminal report, GitHub review comments, and any other generated text

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
- **Pending Review Status**: Whether comments were added to GitHub and how to submit

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

## Arguments
- `<pr-number-or-url>`: (Required) The PR to review. Can be:
  - A simple PR number (e.g., `12345`) - assumes kubevirt/kubevirt
  - A full GitHub URL (e.g., `https://github.com/kubevirt/kubevirt/pull/12345`)
  - An owner/repo#number format (e.g., `kubevirt/kubevirt#12345`)

## See Also
- `/kubevirt:review` - Review local branch changes using KubeVirt project best practices
- `/kubevirt:review-ci` - Review CI failures for a given PR
- `/kubevirt:lint` - Lint a path and generate a plan to fix issues
- KubeVirt [Coding Conventions](https://github.com/kubevirt/kubevirt/blob/main/docs/coding-conventions.md)
- KubeVirt [Reviewer Guide](https://github.com/kubevirt/kubevirt/blob/main/docs/reviewer-guide.md)
