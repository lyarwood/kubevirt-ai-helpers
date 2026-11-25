---
description: Review a GitHub PR or GitLab MR using gh or glab, applying KubeVirt project best practices
argument-hint: <pr-or-mr-number-or-url>
---

## Name
kubevirt:review-pr

## Synopsis
```
/kubevirt:review-pr <pr-or-mr-number-or-url>
```

## Description
The `kubevirt:review-pr` command reviews a GitHub pull request or a GitLab merge request (including self-hosted GitLab instances) against KubeVirt coding conventions and reviewer guidelines, without a local checkout, and offers to add inline comments as a PENDING GitHub review or as GitLab draft notes that the user submits.

The workflow is defined in this plugin's `review-workflow` skill (`kubevirt:review-workflow`, file `skills/review-workflow/SKILL.md` in the plugin), whose helper script does all fetching, filtering, line mapping and posting.

## Implementation

1. **Load the `review-workflow` skill** and follow it.
2. **Fetch**: `HELPER fetch <pr>` as described in the skill, passing `--root` when your environment provides a scratch directory. Note the printed `dir`.
3. **Read** `meta.md`, `checks.md`, `discussion.md`, `vep.md` (if present), both docs and `diff.patch`, in the order the skill gives. Use `show` only when the diff lacks context.
4. **Review** with the three passes and the VEP cross-reference from the skill. Skip points already raised in `discussion.md`.
5. **Report** using the skill's categories and ASCII rules, including the "Not Reviewed Line by Line" section.
6. **Offer comments**: IMPORTANT - after the report, always continue to this step without waiting to be asked. Only when `meta.md` does not say `no posting`. If there are new inline comments, offer to add them as a pending review and wait for agreement.
7. **Post** after agreement: write `findings.json`, run `resolve` until it passes, then `post`. Never submit the review or publish draft notes.

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
- **Pending Review Status**: Whether comments were added as a pending GitHub review or GitLab draft notes, and how to submit

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

4. **Review a GitLab MR**, also on a self-hosted instance:
   ```
   /kubevirt:review-pr https://gitlab.example.com/group/project/-/merge_requests/42
   ```

5. **Review a GitLab MR on glab's default host**:
   ```
   /kubevirt:review-pr group/subgroup/project!42
   ```

## Arguments
- `<pr-or-mr-number-or-url>`: (Required) The PR or MR to review. Can be:
  - A simple PR number (e.g., `12345`) - assumes kubevirt/kubevirt on GitHub
  - A full GitHub URL (e.g., `https://github.com/kubevirt/kubevirt/pull/12345`)
  - An owner/repo#number format (e.g., `kubevirt/kubevirt#12345`)
  - A full GitLab MR URL on any host (e.g., `https://gitlab.example.com/group/project/-/merge_requests/42`)
  - A group/project!number format (e.g., `group/subgroup/project!42`), on glab's default host (`GITLAB_HOST` or `glab config get host`)

## See Also
- `/kubevirt:review` - Review local branch changes (auto-detects associated PR)
- `/kubevirt:review-ci` - Review CI failures for a given PR
- `/kubevirt:lint` - Lint a path and generate a plan to fix issues
- KubeVirt [Coding Conventions](https://github.com/kubevirt/kubevirt/blob/main/docs/coding-conventions.md)
- KubeVirt [Reviewer Guide](https://github.com/kubevirt/kubevirt/blob/main/docs/reviewer-guide.md)
