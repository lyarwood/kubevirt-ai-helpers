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
The `kubevirt:review-pr` command reviews a GitHub pull request against KubeVirt coding conventions and reviewer guidelines, without a local checkout, and offers to add inline comments as a PENDING review that the user submits.

The workflow is defined in this plugin's `review-workflow` skill (`kubevirt:review-workflow`, file `skills/review-workflow/SKILL.md` in the plugin), whose helper script does all fetching, filtering, line mapping and posting.

## Implementation

1. **Load the `review-workflow` skill** and follow it.
2. **Fetch**: `HELPER fetch <pr>` as described in the skill, passing `--root` when your environment provides a scratch directory. Note the printed `dir`.
3. **Read** `meta.md`, `checks.md`, `discussion.md`, `vep.md` (if present), both docs and `diff.patch`, in the order the skill gives. Use `show` only when the diff lacks context.
4. **Review** with the three passes and the VEP cross-reference from the skill. Skip points already raised in `discussion.md`.
5. **Report** using the skill's categories and ASCII rules, including the "Not Reviewed Line by Line" section.
6. **Offer comments**: IMPORTANT - after the report, always continue to this step without waiting to be asked. Only when `meta.md` does not say `no posting`. If there are new inline comments, offer to add them as a pending review and wait for agreement.
7. **Post** after agreement: write `findings.json`, run `resolve` until it passes, then `post`. Never submit the review.

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
- **Not Reviewed Line by Line**: Generated or bulk files only seen as a summary
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
