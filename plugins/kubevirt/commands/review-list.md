---
description: List open PRs pending your review, filterable by user, SIG, or repo
argument-hint: [username] [--sig <sig>] [--repo <repo>]
---

## Name
kubevirt:review-list

## Synopsis
```
/kubevirt:review-list [username] [--sig <sig>] [--repo <repo>]
```

## Description
The `kubevirt:review-list` command lists open pull requests where a user has been requested as a reviewer or is assigned, across KubeVirt organization repositories. It helps reviewers see their pending review queue at a glance.

If no username is provided, the command defaults to the current user's GitHub handle (via `gh api user`).

### What it Shows
For each PR pending review:
- **PR Number**: With repository prefix
- **Title**: Brief description of the change
- **Author**: Who opened the PR
- **SIG**: SIG labels on the PR (sig/compute, sig/network, sig/storage, etc.)
- **Size**: Lines added/deleted and files changed
- **Age**: How long the PR has been open
- **Draft**: Whether the PR is a draft
- **Labels**: All labels on the PR
- **Link**: URL to the PR

### Filtering Options
- `[username]`: GitHub username to look up (defaults to current user)
- `--sig`: Filter by SIG label (compute, network, storage, etc.)
- `--repo`: Filter by repository (defaults to `kubevirt/kubevirt`; use `all` for all kubevirt org repos, or specify e.g. `kubevirt/containerized-data-importer`)
## Implementation

1. **Resolve GitHub Username**: Determine the reviewer's GitHub handle:
   ```bash
   # If no username argument provided, get the current user
   gh api user --jq '.login'
   ```

2. **Determine Target Repositories**: Based on `--repo` flag:
   - Default (no flag): `kubevirt/kubevirt`
   - `--repo all`: Query all major kubevirt org repos: `kubevirt/kubevirt`, `kubevirt/containerized-data-importer`, `kubevirt/kubevirt.github.io`, `kubevirt/enhancements`, `kubevirt/community`
   - `--repo <owner/repo>`: Use the specified repository

3. **Fetch PRs Pending Review**: For each target repository, use `gh` to find open PRs where the user is a requested reviewer:
   ```bash
   gh pr list --repo <repo> --search "review-requested:<username>" --state open \
     --json number,title,author,labels,additions,deletions,changedFiles,createdAt,isDraft,url,headRefName \
     --limit 100
   ```
   Also fetch PRs where the user is an assignee but not yet reviewed:
   ```bash
   gh pr list --repo <repo> --assignee <username> --state open \
     --json number,title,author,labels,additions,deletions,changedFiles,createdAt,isDraft,url,headRefName \
     --limit 100
   ```
   Merge and deduplicate the two result sets by PR number.

4. **Apply SIG Filter**: If `--sig` is specified, filter the results to only include PRs that have a matching `sig/<value>` label. The user provides the short name (e.g., `compute`) and the command matches against labels like `sig/compute`.

5. **Format Output**: Present the results as a table grouped by repository, sorted by age (oldest first) to highlight PRs that have been waiting longest:

   ```
   ## PRs Pending Review for @<username>

   ### <repo> (<N> PRs)

   | PR | Title | Author | SIG | Size | Age | Draft |
   |----|-------|--------|-----|------|-----|-------|
   | #123 | Fix migration ... | @author | compute | +50/-10 (3 files) | 3d | No |

   ### Summary
   | Metric | Count |
   |--------|-------|
   | Total PRs pending review | <N> |
   | Draft PRs | <N> |
   | PRs older than 7 days | <N> |
   ```

## Return Value
A formatted report listing all open PRs pending review for the user:

- **Per-repository table** with PR number, title, author, SIG labels, size, age, and draft status
- **Summary statistics**: total PRs, drafts, and PRs older than 7 days
- If no PRs are found, report: `No open PRs pending review for @<username>.`

## Examples

1. **List your own pending reviews** (defaults to kubevirt/kubevirt):
   ```
   /kubevirt:review-list
   ```

2. **List pending reviews for a specific user**:
   ```
   /kubevirt:review-list jdoe
   ```

3. **Filter by SIG**:
   ```
   /kubevirt:review-list --sig compute
   ```
   Shows only PRs with the `sig/compute` label.

4. **Search across all kubevirt repos**:
   ```
   /kubevirt:review-list --repo all
   ```

6. **Combine filters**:
   ```
   /kubevirt:review-list jdoe --sig storage --repo kubevirt/kubevirt
   ```

## Arguments
- `[username]`: (Optional) GitHub username to look up. Defaults to the current authenticated user via `gh api user`
- `[--sig <sig>]`: (Optional) Filter by SIG label: `compute`, `network`, `storage`, `scale`, `ci`, `observability`, etc.
- `[--repo <repo>]`: (Optional) Target repository. Defaults to `kubevirt/kubevirt`. Use `all` for all major kubevirt org repos, or specify a full `owner/repo` path
## See Also
- `/kubevirt:review-pr` - Review a specific PR against KubeVirt best practices
- `/kubevirt:review` - Review local branch changes
- `/kubevirt:vep-review-list` - List VEP review assignments from the enhancement tracking project
