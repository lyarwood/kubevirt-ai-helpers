---
description: Get a TL;DR summary of a specific VEP and its current state
argument-hint: <vep-number>
---

## Name
kubevirt:vep-summary

## Synopsis
```
/kubevirt:vep-summary <vep-number>
```

## Description
The `kubevirt:vep-summary` command provides a concise TL;DR summary of a specific KubeVirt Enhancement Proposal (VEP). It fetches the VEP content, tracking issue, GitHub Project data, and associated PRs to give maintainers and contributors a quick understanding of what the VEP proposes and its current implementation status.

### Data Sources

1. **kubevirt/enhancements repository**: VEP tracking issues and proposal PRs
2. **KubeVirt Enhancement Tracking Projects**: GitHub Projects with release tracking data
3. **kubevirt/kubevirt repository**: Implementation PRs

### What it Provides

1. **Overview**: A 2-3 sentence summary of what the VEP proposes
2. **Motivation**: Why this enhancement is needed
3. **Current State** (from GitHub Project):
   - **Status**: Proposed, Tracked, At Risk, Complete, Removed from Milestone
   - **Target Stage**: Alpha, Beta, Stable, Deprecation/Removal
   - **Promotion Phase**: Net New, Remaining, Graduating, Deprecation
   - **Target Release**: Which release this VEP is tracked for
   - **Code Freeze Exception**: If an exception was requested/granted
4. **Key Design Decisions**: The main technical approach
5. **Progress Tracking**:
   - VEP PRs in kubevirt/enhancements
   - Code PRs in kubevirt/kubevirt (from tracking issue)
   - Docs PRs in kubevirt/user-guide
   - All code PRs merged status
6. **Ownership**:
   - Owning SIG
   - Assignee/Primary contact
   - VEP reviewer and approver (if assigned)

## Implementation

1. **Find VEP in Projects**: Search enhancement tracking projects for the VEP:
   ```bash
   gh project item-list 19 --owner kubevirt --format json | jq '.items[] | select(.title | contains("VEP <number>"))'
   gh project item-list 21 --owner kubevirt --format json | jq '.items[] | select(.title | contains("VEP <number>"))'
   ```

2. **Fetch Tracking Issue**: Get the VEP tracking issue:
   ```bash
   gh issue view <number> --repo kubevirt/enhancements --json title,body,labels,state,assignees,comments,url
   ```

3. **Fetch VEP PR**: Find and fetch the VEP proposal PR:
   ```bash
   gh pr list --repo kubevirt/enhancements --search "VEP <number>" --json number,title,body,state,labels,url
   ```

4. **Fetch VEP Content**: If merged, fetch from the repository:
   ```bash
   gh api repos/kubevirt/enhancements/contents/veps/sig-<sig>/<number>-<slug>/vep.md
   ```

5. **Parse Tracking Issue**: Extract linked PRs from the tracking issue body:
   - VEP PRs (enhancements repo)
   - Code PRs (kubevirt/kubevirt)
   - Docs PRs (kubevirt/user-guide)
   - Timeline and graduation checklist

6. **Generate Summary**: Produce a concise summary combining all sources

## Return Value
A structured summary containing:

```
## VEP <number>: <title>

### TL;DR
<2-3 sentence summary of what this VEP proposes>

### Release Tracking
- **Release**: <1.8, 1.9, etc.>
- **Status**: <Proposed|Tracked|At Risk|Complete|Removed>
- **Target Stage**: <Alpha|Beta|Stable>
- **Promotion Phase**: <Net New|Remaining|Graduating>
- **All Code PRs Merged**: <Yes|No>
- **Exception Status**: <None|Pending|Accepted|Rejected>

### Ownership
- **SIG**: <sig-compute|sig-network|sig-storage>
- **Assignee**: <@username>
- **VEP Reviewer**: <@username or unassigned>
- **VEP Approver**: <@username or unassigned>

### Motivation
<Brief explanation of why this is needed>

### Key Design Points
- <Main technical decision 1>
- <Main technical decision 2>
- <Main technical decision 3>

### Progress
| Phase | VEP PR | Code PRs | Docs PR | Status |
|-------|--------|----------|---------|--------|
| Alpha | #XX    | #YY, #ZZ | -       | Done   |
| Beta  | -      | #AA      | #BB     | WIP    |
| GA    | -      | -        | -       | -      |

### Links
- Tracking Issue: <link>
- VEP PR: <link>
- Project Board: <link to project view>

### Next Steps
<What needs to happen next for this VEP to progress>
```

## Examples

1. **Get summary of VEP 190**:
   ```
   /kubevirt:vep-summary 190
   ```
   Returns a TL;DR of the "Kubevirt structured plugins" VEP with project tracking data.

2. **Get summary of a tracked VEP**:
   ```
   /kubevirt:vep-summary 10
   ```
   Returns summary of "Support GPU DRA devices" including release tracking status.

3. **Get summary of a VEP at risk**:
   ```
   /kubevirt:vep-summary 62
   ```
   Returns summary highlighting the at-risk status and what's needed.

## Arguments
- `<vep-number>`: (Required) The VEP number to summarize (e.g., `190`, `172`, `10`)

## See Also
- `/kubevirt:vep-list` - List all open VEPs
- `/kubevirt:vep-groom` - Review a VEP proposal against requirements
- [VEP Template](https://github.com/kubevirt/enhancements/blob/main/veps/NNNN-vep-template/vep.md)
- [KubeVirt Enhancement Projects](https://github.com/orgs/kubevirt/projects)
