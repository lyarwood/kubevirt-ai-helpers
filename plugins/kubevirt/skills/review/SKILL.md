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

## GitHub Review Interaction

This section defines how to post review comments to GitHub. Both `/kubevirt:review` and `/kubevirt:review-pr` follow these rules when posting comments.

### Offering to Post Comments

After presenting the review report, determine which findings would result in new inline comments not already covered by existing PR discussion. If there are no new comments to add, state that all points have already been covered and skip the rest of this process.

If there are new comments to add, offer to add them as inline review comments on GitHub as a **pending review** (NOT submitted). Wait for the user to explicitly agree before proceeding.

### Checking for Existing Pending Reviews

**CRITICAL: Existing pending comments are sacred and MUST be preserved exactly as-is.**

The user may have manually written or edited pending review comments before invoking this command. These comments represent the user's own review work and MUST NOT be modified, reworded, dropped, or reordered under any circumstances.

Before adding comments, check if there is already a pending review from the current user:
1. Use `gh api repos/<owner>/<repo>/pulls/<number>/reviews` to list all reviews
2. Filter for reviews with `state: "PENDING"` and authored by the current user (use `gh api user` to get the current username)
3. If a pending review exists:
   - Retrieve existing pending comments with `gh api repos/<owner>/<repo>/pulls/<number>/reviews/<review-id>/comments`
   - Collect all existing comments and **preserve every single one exactly as-is** - do NOT alter the body text, file path, line number, or any other field of existing comments
   - Delete the existing pending review: `gh api repos/<owner>/<repo>/pulls/<number>/reviews/<review-id> --method DELETE`
   - Combine old comments with new comments, placing preserved old comments first, then appending new comments
   - When deduplicating by file path and line number, always keep the **existing** comment (the user's version) and discard the new AI-generated one - never replace a user's comment with an AI-generated alternative
4. If no pending review exists, proceed directly to creating one with the new comments

### Filtering Out Already-Discussed Points

Before building the comment list, cross-reference your review findings against ALL existing comments on the PR (from the existing discussion phase and from any existing pending review):
- Do NOT add a comment for a point that has already been raised by any reviewer on the same file and line or on the same topic
- Compare by substance, not just file path and line number - if someone already commented about the same issue even on a different line, do not duplicate it
- Only add comments that raise genuinely new points not yet discussed on the PR

### Creating the Review with All Comments

All comments must be added in a single `POST /repos/.../pulls/.../reviews` call using the `comments` array in the JSON body. Do NOT use a separate per-comment endpoint.

**IMPORTANT**: Preserved existing comments MUST appear with their original body text verbatim - do not rephrase, summarize, fix typos, or "improve" them in any way.

1. Build a JSON body with all comments (preserved old comments first, then new ones):
   ```
   gh api repos/<owner>/<repo>/pulls/<number>/reviews \
     --method POST \
     --input - <<'EOF'
   {
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
3. Do NOT include a `body` field - it does not pre-fill the submission dialog on GitHub
4. For findings that span multiple lines, use `start_line` and `line` to create multi-line comments
5. For general findings not tied to a specific line, add them as a single comment on a relevant file

### Important: Do NOT Submit the Review

- The review MUST remain in PENDING state after adding comments
- Do NOT call the submit review endpoint (`POST /repos/.../pulls/.../reviews/.../events`)
- Do NOT use `gh pr review --approve/--request-changes/--comment` as this submits immediately
- Inform the user that the review is pending and they can go to the PR page to review comments and submit manually
- Suggest a short review summary the user can paste into the submission dialog when submitting

## References

- KubeVirt [Coding Conventions](https://github.com/kubevirt/kubevirt/blob/main/docs/coding-conventions.md)
- KubeVirt [Reviewer Guide](https://github.com/kubevirt/kubevirt/blob/main/docs/reviewer-guide.md)
