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
The `kubevirt:review` command reviews the changes on the current local branch against a base branch, applying KubeVirt coding conventions and reviewer guidelines.

If the branch has an open pull request, the command also evaluates PR metadata, reads the existing discussion to avoid repeating points, and offers to add inline comments as a PENDING review. Comments can only be posted when the PR is open and the local HEAD is the PR head, so the line numbers match.

The workflow is defined in the `review-workflow` skill of this plugin (`kubevirt:review-workflow`, file `skills/review-workflow/SKILL.md` in the plugin). Load that skill first. Its helper script does all fetching, filtering, line mapping and posting, so you only do the review itself.

## Implementation

1. **Load the `review-workflow` skill** and follow it.
2. **Fetch**: `HELPER fetch --local [--base <base-branch>]` as described in the skill, run from the repository root, passing `--root` when your environment provides a scratch directory. Without `--base`, the PR merge base is used, otherwise the most recent of `upstream`, `origin` and local `main` or `master`. Note the printed `dir`.
3. **Read** `meta.md`, `checks.md`, `discussion.md` (only when a PR exists), `vep.md` (if present), both docs and `diff.patch`, in the order the skill gives. Read local files directly when the diff lacks context.
4. **Review** with the three passes and the VEP cross-reference from the skill. Skip points already raised in `discussion.md`.
5. **Report** using the skill's categories and ASCII rules, including the "Not Reviewed Line by Line" section. Without a PR, note that PR metadata could not be evaluated.
6. **Offer comments**: only when a PR exists and `meta.md` does not say `no posting`. IMPORTANT - after the report, continue to this step without waiting to be asked. If there are new inline comments, offer to add them as a pending review and wait for agreement.
7. **Post** after agreement: write `findings.json`, run `resolve` until it passes, then `post`. Never submit the review.

## Return Value
A structured code review report containing:

- **Summary**: Overview of the changes and general assessment
- **Critical Issues**: Problems that must be addressed before merge
- **Suggestions**: Recommended improvements
- **Nitpicks**: Minor style or convention issues
- **Positive Observations**: Good practices worth noting
- **Commit History Feedback**: Commit organization and message quality
- **Not Reviewed Line by Line**: Generated or bulk files only seen as a summary

When a PR is detected, the report also includes:

- **PR Overview**: Title, author, size stats, draft status, labels
- **Existing Discussion Summary**: Key points from prior reviews
- **Verdict**: Recommended action (approve, request changes, or comment)
- **Pending Review Status**: Whether comments were added to GitHub and how to submit

## Examples

1. **Review against main branch**:
   ```
   /kubevirt:review
   ```
   Reviews all changes on the current branch compared to `main`. If an open PR exists for the branch, also evaluates PR metadata and offers to post review comments.

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
- `[base-branch]`: (Optional) Branch to compare against. Defaults to the merge base of the branch's PR, otherwise the most recent of `upstream/main`, `origin/main` and `main` (then the same for `master`).

## See Also
- `/kubevirt:review-pr` - Review a remote GitHub PR by number or URL (no local checkout required)
- `/kubevirt:lint` - Lint a path and generate a plan to fix issues
- KubeVirt [Coding Conventions](https://github.com/kubevirt/kubevirt/blob/main/docs/coding-conventions.md)
- KubeVirt [Reviewer Guide](https://github.com/kubevirt/kubevirt/blob/main/docs/reviewer-guide.md)
