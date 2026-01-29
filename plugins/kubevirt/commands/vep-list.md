---
description: List open KubeVirt Enhancement Proposals (VEPs) with status and filtering
argument-hint: [--sig <sig>] [--release <version>] [--status <status>]
---

## Name
kubevirt:vep-list

## Synopsis
```
/kubevirt:vep-list [--sig <sig>] [--release <version>] [--status <status>]
```

## Description
The `kubevirt:vep-list` command lists KubeVirt Enhancement Proposals (VEPs) from the kubevirt/enhancements repository and the KubeVirt GitHub Projects. It combines data from tracking issues, proposal PRs, and release enhancement tracking projects to provide a comprehensive view.

### Data Sources

1. **kubevirt/enhancements repository**: Issues and PRs containing VEP proposals
2. **KubeVirt Enhancement Tracking Projects**: GitHub Projects that track VEPs per release
   - Project 21: KubeVirt 1.9 Enhancements Tracking
   - Project 19: KubeVirt 1.8 Enhancements Tracking
   - Project 18: KubeVirt 1.7 Enhancements Tracking
   - Project 15: KubeVirt 1.6 Enhancements Tracking

### What it Shows
For each VEP, the command displays:
- **VEP Number**: The VEP identifier (e.g., VEP 190)
- **Title**: Brief description of the enhancement
- **SIG**: The owning SIG (compute, network, storage)
- **Status**: From project tracking (Proposed, Tracked, At Risk, Complete, Removed)
- **Target Stage**: Alpha, Beta, Stable, or Deprecation/Removal
- **Promotion Phase**: Net New, Remaining, Graduating, or Deprecation
- **Assignee**: Who is responsible for the VEP
- **Release**: Which release the VEP is tracked for

### Filtering Options
- `--sig`: Filter by SIG (compute, network, storage)
- `--release`: Filter by target release (1.8, 1.9, etc.)
- `--status`: Filter by tracking status (tracked, at-risk, complete, proposed)

## Implementation

1. **Fetch Enhancement Projects**: List available enhancement tracking projects:
   ```bash
   gh project list --owner kubevirt --format json | jq '.projects[] | select(.title | contains("Enhancement"))'
   ```

2. **Fetch Project Items**: Get VEPs from the relevant project(s):
   ```bash
   gh project item-list <project-number> --owner kubevirt --format json
   ```

3. **Fetch VEP Issues**: Get tracking issues from kubevirt/enhancements:
   ```bash
   gh issue list --repo kubevirt/enhancements --state open --label kind/enhancement --json number,title,author,assignees,labels,url
   ```

4. **Merge and Enrich Data**: Combine project tracking data with issue/PR data:
   - Match by VEP number
   - Add project fields (Status, Target Stage, Promotion Phase)
   - Include assignees and SIG information

5. **Format Output**: Present as a table grouped by status or SIG:
   - Highlight "At Risk" VEPs
   - Show progress indicators for tracked VEPs
   - Include links to tracking issues and projects

## Return Value
A formatted list of VEPs with:
- Summary statistics (total tracked, by status, by SIG)
- Grouped or filtered VEP list with project tracking data
- Links to tracking issues and project views

## Examples

1. **List all VEPs for current release**:
   ```
   /kubevirt:vep-list --release 1.8
   ```
   Shows all VEPs tracked for the 1.8 release with their status.

2. **List VEPs for sig-compute**:
   ```
   /kubevirt:vep-list --sig compute
   ```
   Shows only VEPs owned by sig-compute across all releases.

3. **List at-risk VEPs**:
   ```
   /kubevirt:vep-list --status at-risk
   ```
   Shows VEPs that are flagged as at risk and need attention.

4. **List all tracked VEPs**:
   ```
   /kubevirt:vep-list --status tracked
   ```
   Shows all VEPs currently being tracked for any release.

## Arguments
- `[--sig <sig>]`: (Optional) Filter by SIG: `compute`, `network`, or `storage`
- `[--release <version>]`: (Optional) Filter by release version: `1.8`, `1.9`, etc.
- `[--status <status>]`: (Optional) Filter by status: `proposed`, `tracked`, `at-risk`, `complete`, `removed`

## See Also
- `/kubevirt:vep-summary` - Get detailed summary of a specific VEP
- `/kubevirt:vep-groom` - Review a VEP proposal against requirements
- [KubeVirt Enhancements Repository](https://github.com/kubevirt/enhancements)
- [KubeVirt 1.8 Enhancements Project](https://github.com/orgs/kubevirt/projects/19)
- [KubeVirt 1.9 Enhancements Project](https://github.com/orgs/kubevirt/projects/21)
