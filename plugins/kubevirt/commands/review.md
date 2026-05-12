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
The `kubevirt:review` command performs a comprehensive code review of changes on the current local branch compared to a base branch, applying KubeVirt project coding conventions and reviewer guidelines.

If the current branch has an open pull request on GitHub, the command also evaluates PR metadata (title, description, labels, size), reads existing review discussion to avoid duplicating points, and offers to post inline review comments as a PENDING GitHub review.

This command simulates a thorough code review following the KubeVirt multi-pass review approach. Read the shared review checklist at `plugins/kubevirt/skills/review/SKILL.md` for the full list of review areas, conventions, and output formatting rules.

### Review Passes
1. **General Design Pass**: Verify the overall design makes sense and code structure is consistent with the project
2. **Detailed Code Pass**: In-depth analysis of the implementation
3. **Standards Compliance Pass**: Check adherence to KubeVirt coding conventions
4. **Commit History Pass**: Review commit structure and messages
5. **PR Metadata Pass** (when PR detected): Evaluate PR title, description, labels, and overall scope

## Implementation

### Phase 1: Gather Changes
1. Determine the base branch (defaults to `main`, falls back to `master`)
2. Run `git diff <base-branch>...HEAD` to get all changes on the current branch
3. Run `git log <base-branch>...HEAD` to understand commit history and structure
4. Prioritize files for review using the file priority order from the shared review checklist

### Phase 1b: Detect Associated PR
1. Check if the current branch has an open pull request:
   ```
   gh pr list --head $(git branch --show-current) \
     --json number,title,body,labels,state,isDraft,additions,deletions,changedFiles,comments,reviews \
     --jq '.[0]'
   ```
2. If a PR exists:
   - Record the PR number and metadata for use in later phases
   - Evaluate PR metadata (title, description, labels, size, draft status) using the PR Metadata checklist from the shared skill
   - Flag PRs that are too large (>500 lines changed across many files) and suggest splitting
   - Fetch existing discussion:
     - Use `gh api repos/<owner>/<repo>/pulls/<number>/comments` to read all inline review comments with file paths, line numbers, and body text
     - Read and understand the substance of each comment - do not just note that comments exist
     - When generating the review report, do NOT duplicate points already raised in existing comments
     - Note which existing comments have been addressed by subsequent commits and which remain unresolved
3. If no PR exists:
   - Skip PR metadata evaluation
   - Note in the report that PR metadata could not be evaluated (no open PR found for this branch)

### Phase 2: Analyze Changes (Multi-Pass)
1. Perform the multi-pass review against the diff following the methodology in the shared review checklist:
   - **General Design Pass**: Overall design and architecture
   - **Detailed Code Pass**: Line-by-line implementation review, considering context of surrounding code. Use the Read tool to read full files when the diff alone does not provide enough context.
   - **Standards Compliance Pass**: KubeVirt coding conventions
2. For each issue found, note the file path and relevant diff context
3. Categorize findings by severity

### Phase 3: Review Commit History
1. Evaluate commit messages for clarity and conventional format
2. Check for problematic patterns (fixup commits, merge commits, WIP commits)
3. Assess whether changes are in scope or should be split into separate PRs

### Phase 4: Generate Review Report
1. Create a structured review report following the output formatting rules from the shared review checklist
2. Organize feedback by severity: Critical Issues, Suggestions, Nitpicks, Positive Observations
3. If a PR was detected in Phase 1b:
   - Include PR Overview (title, author, size stats, draft status, labels)
   - Include Existing Discussion Summary (key points from prior reviews)
   - Include Verdict (recommended action: approve, request changes, or comment)

### Phase 5: Offer to Add Review Comments on GitHub
This phase only applies when a PR was detected in Phase 1b. If no PR was found, skip this phase entirely.

IMPORTANT: After presenting the review report, you MUST proceed to Phase 5. Do not wait for the user to ask.

Follow the GitHub Review Interaction process defined in `plugins/kubevirt/skills/review/SKILL.md` to offer, prepare, and post review comments. The `line` field must use source file line numbers from the git diff.

## Return Value
A structured code review report containing:

- **Summary**: Overview of the changes and general assessment
- **Critical Issues**: Problems that must be addressed before merge
- **Suggestions**: Recommended improvements
- **Nitpicks**: Minor style or convention issues
- **Positive Observations**: Good practices worth noting
- **Commit History Feedback**: Commit organization and message quality

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
- `[base-branch]`: (Optional) Branch to compare against. Defaults to `main`, falls back to `master` if main doesn't exist.

## See Also
- `/kubevirt:review-pr` - Review a remote GitHub PR by number or URL (no local checkout required)
- `/kubevirt:lint` - Lint a path and generate a plan to fix issues
- KubeVirt [Coding Conventions](https://github.com/kubevirt/kubevirt/blob/main/docs/coding-conventions.md)
- KubeVirt [Reviewer Guide](https://github.com/kubevirt/kubevirt/blob/main/docs/reviewer-guide.md)
