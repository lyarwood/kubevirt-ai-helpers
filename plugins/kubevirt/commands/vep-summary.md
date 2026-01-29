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
The `kubevirt:vep-summary` command provides a concise TL;DR summary of a specific KubeVirt Enhancement Proposal (VEP). It fetches the VEP content, tracking issue, and associated PRs to give maintainers and contributors a quick understanding of what the VEP proposes and its current implementation status.

### What it Provides

1. **Overview**: A 2-3 sentence summary of what the VEP proposes
2. **Motivation**: Why this enhancement is needed
3. **Current State**:
   - Proposal status (draft, under review, approved, merged)
   - Implementation phase (alpha, beta, GA)
   - Target release version
4. **Key Design Decisions**: The main technical approach
5. **Progress Tracking**:
   - Related PRs in kubevirt/kubevirt
   - Open blockers or issues
   - Graduation criteria status
6. **SIG Ownership**: Which SIG owns this VEP

## Implementation

1. **Find VEP Sources**: Search for the VEP by number in both issues and PRs:
   ```bash
   gh issue view <number> --repo kubevirt/enhancements --json title,body,labels,state,comments,url
   gh pr list --repo kubevirt/enhancements --search "<number>" --json number,title,body,state,labels,url
   ```

2. **Fetch VEP Content**: If a PR exists, fetch the VEP markdown file:
   ```bash
   gh pr view <pr-number> --repo kubevirt/enhancements --json files
   gh api repos/kubevirt/enhancements/contents/veps/sig-<sig>/<number>-<slug>/vep.md
   ```

3. **Parse VEP Sections**: Extract key sections from the VEP markdown:
   - Overview
   - Motivation
   - Goals/Non-Goals
   - Design summary
   - Graduation Requirements
   - Implementation History

4. **Check Implementation Status**: Search for related PRs in kubevirt/kubevirt:
   ```bash
   gh pr list --repo kubevirt/kubevirt --search "VEP <number>" --json number,title,state,url
   ```

5. **Generate Summary**: Produce a concise summary with:
   - TL;DR (2-3 sentences)
   - Current state and next steps
   - Links to tracking issue, VEP PR, and implementation PRs

## Return Value
A structured summary containing:

```
## VEP <number>: <title>

### TL;DR
<2-3 sentence summary of what this VEP proposes>

### Status
- **Proposal**: <draft|under review|approved|merged>
- **Implementation**: <not started|alpha|beta|GA>
- **Target Release**: <version or TBD>
- **Owning SIG**: <sig-compute|sig-network|sig-storage>

### Motivation
<Brief explanation of why this is needed>

### Key Design Points
- <Main technical decision 1>
- <Main technical decision 2>
- <Main technical decision 3>

### Progress
- Tracking Issue: <link>
- VEP PR: <link and status>
- Implementation PRs: <count and links>
- Blockers: <any open blockers>

### Next Steps
<What needs to happen next for this VEP to progress>
```

## Examples

1. **Get summary of VEP 190**:
   ```
   /kubevirt:vep-summary 190
   ```
   Returns a TL;DR of the "Kubevirt structured plugins" VEP.

2. **Get summary of a merged VEP**:
   ```
   /kubevirt:vep-summary 10
   ```
   Returns summary including implementation status and graduation state.

## Arguments
- `<vep-number>`: (Required) The VEP number to summarize (e.g., `190`, `172`, `10`)

## See Also
- `/kubevirt:vep-list` - List all open VEPs
- `/kubevirt:vep-groom` - Review a VEP proposal against requirements
- [VEP Template](https://github.com/kubevirt/enhancements/blob/main/veps/NNNN-vep-template/vep.md)
