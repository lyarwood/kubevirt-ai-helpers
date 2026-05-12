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

This command simulates a thorough code review following the KubeVirt multi-pass review approach. Read the shared review checklist at `plugins/kubevirt/skills/review/SKILL.md` for the full list of review areas, conventions, and output formatting rules.

### Review Passes
1. **PR Metadata Pass**: Evaluate PR title, description, labels, and overall scope
2. **General Design Pass**: Verify the overall design makes sense and code structure is consistent with the project
3. **Detailed Code Pass**: In-depth analysis of the implementation via the diff
4. **Standards Compliance Pass**: Check adherence to KubeVirt coding conventions
5. **Commit History Pass**: Review commit structure and messages

## Implementation

### Phase 1: Gather PR Metadata
1. Parse the PR argument to extract the PR number and repository (defaults to `kubevirt/kubevirt`)
2. Use `gh pr view <pr-number> --repo <repo> --json number,title,body,labels,author,reviewRequests,assignees,baseRefName,headRefName,additions,deletions,changedFiles,commits,comments,reviews,state,isDraft` to get full PR metadata
3. Evaluate PR title, description, size, and draft status using the PR Metadata checklist from the shared review skill
4. Flag PRs that are too large (>500 lines changed across many files) and suggest splitting

### Phase 2: Fetch PR Diff and Changed Files
1. Use `gh pr diff <pr-number> --repo <repo>` to get the full diff
2. Use `gh pr view <pr-number> --repo <repo> --json files` to get the list of changed files with per-file stats
3. Prioritize files for review using the file priority order from the shared review checklist

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
1. Perform the multi-pass review against the diff following the methodology in the shared review checklist:
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
1. Create a structured review report following the output formatting rules from the shared review checklist
2. Present the report to the user before proceeding to Phase 7

### Phase 7: Offer to Add Review Comments on GitHub
IMPORTANT: After presenting the review report, you MUST proceed to Phase 7. Do not wait for the user to ask.

Follow the GitHub Review Interaction process defined in `plugins/kubevirt/skills/review/SKILL.md` to offer, prepare, and post review comments.

#### Re-verify Line Numbers (REQUIRED before posting)
Before building the review payload, re-derive and verify every line number for new comments using the same procedure as Phase 5b. For each new comment:
1. Re-derive the source line number from the diff hunk header (count context and added lines, skip removed lines, compute `new_start + (count - 1)`).
2. Verify by running:
   ```
   gh api repos/<owner>/<repo>/contents/<path>?ref=<head-sha> \
     -q '.content' | base64 -d | sed -n '<source_line>p'
   ```
   The output MUST match the code the comment refers to. If it does not, recount from the hunk header until it does. Do NOT post a comment with an unverified line number.

The `line` field must use verified source file line numbers from Phase 5b.

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
- `/kubevirt:review` - Review local branch changes (auto-detects associated PR)
- `/kubevirt:review-ci` - Review CI failures for a given PR
- `/kubevirt:lint` - Lint a path and generate a plan to fix issues
- KubeVirt [Coding Conventions](https://github.com/kubevirt/kubevirt/blob/main/docs/coding-conventions.md)
- KubeVirt [Reviewer Guide](https://github.com/kubevirt/kubevirt/blob/main/docs/reviewer-guide.md)
