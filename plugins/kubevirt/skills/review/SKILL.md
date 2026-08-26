---
name: review
description: Shared review checklist, conventions, and multi-pass methodology. Use when running /kubevirt:review or /kubevirt:review-pr to review KubeVirt code changes.
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

Apply the KubeVirt coding conventions and reviewer guidelines from the upstream documentation. These docs are the authoritative source - read them in full before starting the review.

### Locating the Convention Docs

**Local reviews** (`/kubevirt:review`): Read the following files from the KubeVirt repo (typically the current working directory):
- `docs/coding-conventions.md`
- `docs/reviewer-guide.md`

**Remote PR reviews** (`/kubevirt:review-pr`): Fetch the docs from the PR's target repository using `gh api`:
```
gh api repos/<owner>/<repo>/contents/docs/coding-conventions.md -q '.content' | base64 -d
gh api repos/<owner>/<repo>/contents/docs/reviewer-guide.md -q '.content' | base64 -d
```

If the target repo does not contain these files (e.g. sub-projects like containerized-data-importer), fetch from `kubevirt/kubevirt` instead.

### What to Check

Read both docs thoroughly and apply all conventions they describe. Key review areas include:
- Code quality, style consistency, and readability
- Testing requirements (unit tests, E2E tests, Eventually patterns)
- Architecture patterns (informers vs GET/LIST, PATCH vs UPDATE, RBAC, thread safety)
- Go conventions (imports, naming, interfaces, error handling)
- PR structure (commit messages, scope, rebase preference)
- Dependencies (trusted sources, maintenance)

## VEP Cross-Reference

If the PR is associated with a VEP, fetch the proposal and use it as additional review context.

### Detecting VEP Association

Check the PR title and body for VEP references:
- Title matching `VEP <number>` (e.g. "VEP 190: Plugin CRD, feature gate, RBAC")
- Body links to `kubevirt/enhancements/issues/<number>` or `kubevirt/enhancements/pull/<number>`

If no VEP is detected, skip this section.

### Fetching VEP Content

1. Fetch the tracking issue:
   ```
   gh issue view <number> --repo kubevirt/enhancements --json title,body,labels,state
   ```

2. Fetch the VEP proposal content. If the proposal PR is merged, fetch from the repo:
   ```
   gh api repos/kubevirt/enhancements/contents/veps/ -q '.[].name' | grep "^<number>-"
   ```
   Then fetch the `vep.md` from the matching directory. If not yet merged, fetch from the open PR body.

### Cross-Referencing

With the VEP content in hand, evaluate:
- Does the implementation match the design described in the VEP?
- Are the API changes consistent with the API examples in the proposal?
- Is the scope of the PR consistent with the VEP's stated goals and non-goals?
- Does the PR description reference the tracking issue?
- If the VEP defines graduation criteria, does the PR advance toward them?

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
