---
description: Find potential reviewers for a VEP based on SIG ownership and recent code activity
argument-hint: <vep-number-or-sig> [--repo <repo>] [--months <n>]
---

## Name
kubevirt:vep-find-reviewers

## Synopsis
```
/kubevirt:vep-find-reviewers <vep-number-or-sig> [--repo <repo>] [--months <n>]
```

## Description
The `kubevirt:vep-find-reviewers` command identifies potential reviewers for a KubeVirt Enhancement Proposal (VEP) by combining two sources:

1. **OWNERS_ALIASES**: SIG-based reviewer and approver lists from the kubevirt/kubevirt repository
2. **Recent git activity**: Contributors who have recently modified code in areas relevant to the VEP

This helps VEP authors and SIG leads find the right people to review a proposal or its implementation PRs, especially when the VEP spans multiple areas or when the OWNERS_ALIASES lists are stale.

### Input Modes

- **VEP number**: Looks up the VEP's SIG from the enhancement tracking project, then finds reviewers for that SIG. If the VEP proposal names specific packages or directories, those are used to scope the git history search.
- **SIG name**: Directly looks up reviewers for the given SIG (e.g., `compute`, `network`, `storage`).

### What it Shows

For each candidate reviewer:
- **Username**: GitHub handle
- **Source**: How they were identified (OWNERS_ALIASES, git activity, or both)
- **Role**: Reviewer or approver (from OWNERS_ALIASES)
- **Recent activity**: Number of commits and PRs merged in the relevant area within the lookback window
- **Last active**: Date of most recent merge in the area

### Skill Reference

This command uses the `vep-find-reviewers` skill for detailed implementation guidance on parsing OWNERS_ALIASES files and analyzing git history. See `plugins/kubevirt/skills/vep-find-reviewers/SKILL.md`.

## Implementation

1. **Resolve Input**: Determine whether the argument is a VEP number or SIG name:
   - If numeric, fetch the VEP from the enhancement tracking project to get its SIG and identify affected code areas from the VEP proposal content
   - If a SIG name (compute, network, storage), use it directly

2. **Fetch OWNERS_ALIASES**: Retrieve the OWNERS_ALIASES file from kubevirt/kubevirt:
   ```bash
   gh api repos/kubevirt/kubevirt/contents/OWNERS_ALIASES --jq '.content' | base64 -d
   ```
   Parse the YAML to extract members of relevant aliases (e.g., `sig-compute-reviewers`, `sig-compute-approvers`). See the `vep-find-reviewers` skill for the full alias naming conventions and parsing details.

3. **Fetch directory-level OWNERS files** (optional, when code areas are known): If the VEP proposal or its tracking issue references specific packages or directories, fetch OWNERS files from those paths:
   ```bash
   gh api repos/kubevirt/kubevirt/contents/<path>/OWNERS --jq '.content' | base64 -d
   ```
   This narrows the reviewer pool to people with direct ownership of the affected code.

4. **Analyze recent git activity**: For the target repository, find contributors with recent commits in relevant areas:
   ```bash
   gh api "repos/kubevirt/kubevirt/commits?path=<path>&since=<date>&per_page=100" \
     --jq '.[].author.login'
   ```
   Aggregate by author, counting commits and finding the most recent activity date. See the `vep-find-reviewers` skill for details on path heuristics and SIG-to-directory mappings.

5. **Cross-reference and rank**: Merge the two sources:
   - People appearing in both OWNERS_ALIASES and recent git history are ranked highest
   - OWNERS_ALIASES members without recent activity are flagged as potentially stale
   - Active contributors not in OWNERS_ALIASES are flagged as emerging experts
   - Sort by combined signal strength (role weight + activity recency + commit count)

6. **Format output**: Present results as a ranked table with source attribution.

## Return Value
A structured report of potential reviewers:

```
## Potential Reviewers for VEP <number>: <title>

**SIG**: sig-<name>
**Affected areas**: <pkg/path1>, <pkg/path2> (if known)
**Lookback window**: <n> months

### Recommended Reviewers

| Rank | Username | Source | Role | Commits (<n>mo) | Last Active |
|------|----------|--------|------|------------------|-------------|
| 1 | @user1 | OWNERS + git | approver | 23 | 2026-04-01 |
| 2 | @user2 | OWNERS + git | reviewer | 15 | 2026-03-28 |
| 3 | @user3 | git only | - | 12 | 2026-04-10 |
| 4 | @user4 | OWNERS only | reviewer | 0 | - |

### OWNERS_ALIASES Members (sig-<name>)

**Approvers**: @user1, @user5, @user6
**Reviewers**: @user2, @user4, @user7

### Active Contributors (not in OWNERS_ALIASES)

| Username | Commits (<n>mo) | Last Active | Areas |
|----------|-----------------|-------------|-------|
| @user3 | 12 | 2026-04-10 | pkg/virt-controller |
| @user8 | 8 | 2026-03-15 | pkg/virt-handler |

### Suggestions

- @user1 and @user2 are the strongest candidates (active + OWNERS role)
- @user3 has significant recent activity but is not in OWNERS_ALIASES
- @user4 is listed in OWNERS_ALIASES but has no recent commits in this area
```

If no reviewers are found, report:
```
No reviewers found for SIG <name>. Check that the SIG name is correct and that OWNERS_ALIASES exists in the target repository.
```

## Examples

1. **Find reviewers for a specific VEP**:
   ```
   /kubevirt:vep-find-reviewers 190
   ```
   Looks up VEP 190's SIG and affected areas, then finds matching reviewers.

2. **Find reviewers by SIG**:
   ```
   /kubevirt:vep-find-reviewers compute
   ```
   Lists reviewers and active contributors for sig-compute.

3. **Search a different repository**:
   ```
   /kubevirt:vep-find-reviewers network --repo kubevirt/containerized-data-importer
   ```

4. **Extend the lookback window**:
   ```
   /kubevirt:vep-find-reviewers 62 --months 12
   ```
   Looks at 12 months of git history instead of the default 6.

## Arguments
- `<vep-number-or-sig>`: (Required) Either a VEP number (e.g., `190`) or a SIG name (`compute`, `network`, `storage`)
- `[--repo <repo>]`: (Optional) Target repository for git history analysis. Defaults to `kubevirt/kubevirt`
- `[--months <n>]`: (Optional) Number of months of git history to analyze. Defaults to `6`

## See Also
- `/kubevirt:vep-list` - List all open VEPs with status and filtering
- `/kubevirt:vep-summary` - Get detailed summary of a specific VEP
- `/kubevirt:vep-review-list` - List VEPs assigned to you for review
- `/kubevirt:review-list` - List PRs pending your review
- [KubeVirt OWNERS_ALIASES](https://github.com/kubevirt/kubevirt/blob/main/OWNERS_ALIASES)
- [KubeVirt Enhancements Repository](https://github.com/kubevirt/enhancements)
