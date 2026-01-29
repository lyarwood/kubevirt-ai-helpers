---
description: List open KubeVirt Enhancement Proposals (VEPs) with status and filtering
argument-hint: [--sig <sig>] [--state <state>]
---

## Name
kubevirt:vep-list

## Synopsis
```
/kubevirt:vep-list [--sig <sig>] [--state <state>]
```

## Description
The `kubevirt:vep-list` command lists open KubeVirt Enhancement Proposals (VEPs) from the kubevirt/enhancements repository. It shows both tracking issues and proposal PRs, helping maintainers and contributors understand the current state of enhancements.

### What it Shows
For each VEP, the command displays:
- **VEP Number**: The VEP identifier (e.g., VEP 190)
- **Title**: Brief description of the enhancement
- **Type**: Whether it's a tracking issue or proposal PR
- **State**: Open, merged, or closed
- **SIG**: The owning SIG (compute, network, storage)
- **Labels**: Key labels like `lgtm`, `approved`, `needs-approver-review`
- **Author**: Who proposed the VEP
- **Age**: How long ago it was created

### Filtering Options
- `--sig`: Filter by SIG (compute, network, storage)
- `--state`: Filter by state (open, merged, closed)

## Implementation

1. **Fetch VEP Issues**: Use `gh issue list` to get tracking issues from kubevirt/enhancements:
   ```bash
   gh issue list --repo kubevirt/enhancements --state open --label kind/enhancement --json number,title,author,createdAt,labels,url
   ```

2. **Fetch VEP PRs**: Use `gh pr list` to get proposal PRs:
   ```bash
   gh pr list --repo kubevirt/enhancements --state open --json number,title,author,createdAt,labels,url
   ```

3. **Parse and Filter**: Extract SIG from labels (sig/compute, sig/network, sig/storage) and apply filters

4. **Format Output**: Present as a table with key information:
   - Group by SIG if no filter applied
   - Sort by creation date (newest first)
   - Highlight VEPs with `lgtm` + `approved` (ready to merge)
   - Highlight VEPs with `needs-approver-review`

## Return Value
A formatted list of VEPs with:
- Summary statistics (total open, by SIG, ready to merge)
- Grouped or filtered VEP list
- Links to each VEP for easy navigation

## Examples

1. **List all open VEPs**:
   ```
   /kubevirt:vep-list
   ```
   Shows all open VEP issues and PRs grouped by SIG.

2. **List VEPs for sig-compute**:
   ```
   /kubevirt:vep-list --sig compute
   ```
   Shows only VEPs owned by sig-compute.

3. **List VEPs needing review**:
   ```
   /kubevirt:vep-list --state open
   ```
   Shows all open VEPs that need attention.

## Arguments
- `[--sig <sig>]`: (Optional) Filter by SIG: `compute`, `network`, or `storage`
- `[--state <state>]`: (Optional) Filter by state: `open`, `merged`, or `closed`

## See Also
- `/kubevirt:vep-summary` - Get detailed summary of a specific VEP
- `/kubevirt:vep-groom` - Review a VEP proposal against requirements
- [KubeVirt Enhancements Repository](https://github.com/kubevirt/enhancements)
- [VEP Process Documentation](https://github.com/kubevirt/enhancements/blob/main/README.md)
