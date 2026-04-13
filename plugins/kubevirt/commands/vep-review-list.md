---
description: List VEP proposal and implementation PRs for VEPs you are assigned to review
argument-hint: [username] [--release <version>]
---

## Name
kubevirt:vep-review-list

## Synopsis
```
/kubevirt:vep-review-list [username] [--release <version>]
```

## Description
The `kubevirt:vep-review-list` command lists all VEPs where a user is assigned as a VEP Reviewer on the KubeVirt Enhancement Tracking project board, along with their associated proposal and implementation PRs. Only **open** PRs are shown — merged and closed PRs are filtered out so the reviewer can focus on what still needs attention.

If no username is provided, the command defaults to the current user's GitHub handle (via `gh api user`).

### Data Sources

1. **KubeVirt Enhancement Tracking Projects**: GitHub Projects (discovered dynamically) that track VEPs per release. The project board contains custom fields including "VEP reviewer", "VEP approver", "Proposal PRs", "Impl PRs", "SIG", "Status", "Target Stage", and "Promotion Phase"
2. **kubevirt/enhancements repository**: For checking PR state of proposal PRs
3. **kubevirt/kubevirt repository**: For checking PR state of implementation PRs

### What it Shows
For each VEP assigned to the reviewer:
- **VEP Number**: The VEP identifier (e.g., VEP 190)
- **Title**: Brief description of the enhancement
- **SIG**: The owning SIG (compute, network, storage)
- **Status**: From project tracking (Proposed for consideration, Tracked, At Risk, Complete, Removed from Milestone)
- **Target Stage**: Alpha, Beta, Stable, or Deprecation/Removal
- **Promotion Phase**: Net New, Remaining, Graduating, or Deprecation
- **Assignee**: The VEP author/owner
- **Proposal PRs**: Open VEP PRs in kubevirt/enhancements (merged/closed filtered out)
- **Implementation PRs**: Open code PRs in kubevirt/kubevirt (merged/closed filtered out)

## Implementation

1. **Resolve GitHub Username**: Determine the reviewer's GitHub handle:
   ```bash
   # If no username argument provided, get the current user
   gh api user --jq '.login'
   ```

2. **Discover Enhancement Projects**: List available enhancement tracking projects:
   ```bash
   gh project list --owner kubevirt --format json | jq '.projects[] | select(.title | contains("Enhancement"))'
   ```
   If `--release` is specified, match the project title containing that release version (e.g., "KubeVirt 1.9 Enhancements Tracking"). Otherwise, search all non-template enhancement tracking projects. Skip template projects (titles starting with "[TEMPLATE]").

3. **Query Project Items via GraphQL**: The basic `gh project item-list` JSON format does **not** include custom fields like "VEP reviewer". Use the GraphQL API to fetch items with all custom field values:
   ```bash
   gh api graphql -f query='
   {
     organization(login: "kubevirt") {
       projectV2(number: <project-number>) {
         items(first: 100) {
           nodes {
             id
             content {
               ... on Issue {
                 number
                 title
                 url
                 assignees(first: 5) { nodes { login } }
                 labels(first: 10) { nodes { name } }
               }
             }
             fieldValues(first: 30) {
               nodes {
                 ... on ProjectV2ItemFieldTextValue {
                   text
                   field { ... on ProjectV2Field { name } }
                 }
                 ... on ProjectV2ItemFieldSingleSelectValue {
                   name
                   field { ... on ProjectV2SingleSelectField { name } }
                 }
               }
             }
           }
         }
       }
     }
   }'
   ```

4. **Filter by VEP Reviewer**: From the GraphQL results, select items where the "VEP reviewer" field contains the target username. Note that this field can contain **multiple comma-separated usernames** (e.g., `"vladikr, lyarwood"`), so use a substring/regex match rather than exact equality.

5. **Extract PR Links from Project Fields**: The project board stores PR links directly in the "Proposal PRs" and "Impl PRs" text fields as markdown links (e.g., `[#187](https://github.com/kubevirt/enhancements/pull/187)`). Parse these fields to extract PR numbers and repos. A value of `"-"` means no PRs are linked.

6. **Check PR State and Filter**: For each extracted PR, check whether it is open, merged, or closed. **Only include open PRs in the output**:
   ```bash
   gh pr view <pr-number> --repo <repo> --json number,title,state,url
   ```
   - `state: "OPEN"` → include in output
   - `state: "MERGED"` or `state: "CLOSED"` → omit from output

7. **Format Output**: Present the results grouped per VEP. For each VEP show the project tracking metadata and only the open PRs. If a VEP has no open PRs remaining, still list the VEP with a note that all PRs are merged/closed.

## Return Value
A structured report listing all VEPs assigned to the reviewer:

```
## VEP Review List for @<username>

**Reviewing <N> VEPs on KubeVirt <version> Enhancements Tracking**

---

### VEP <number>: <title>
- **SIG**: <sig-compute|sig-network|sig-storage>
- **Status**: <Proposed for consideration|Tracked|At Risk|Complete|Removed from Milestone>
- **Target Stage**: <Alpha|Beta|Stable> (<Promotion Phase>)
- **Assignee**: @<vep-owner>
- **Tracking Issue**: <link>

#### Open Proposal PRs (kubevirt/enhancements)
| PR | Title | Link |
|----|-------|------|
| #XX | VEP <number>: <title> | <url> |

#### Open Implementation PRs (kubevirt/kubevirt)
| PR | Title | Link |
|----|-------|------|
| #YY | <description> | <url> |

*No open docs PRs*

---

### VEP <number>: <title>
...

---

### Summary
| Metric | Count |
|--------|-------|
| Total VEPs assigned | <N> |
| VEPs with open PRs | <N> |
| Total open proposal PRs | <N> |
| Total open implementation PRs | <N> |
| VEPs with all PRs merged/closed | <N> |
```

If no VEPs are assigned to the reviewer, report:
```
No VEPs found with @<username> as VEP Reviewer on the enhancement tracking project(s).
```

## Examples

1. **List your own VEP review assignments**:
   ```
   /kubevirt:vep-review-list
   ```
   Lists all VEPs where you are assigned as VEP Reviewer, showing only open PRs.

2. **List review assignments for a specific user**:
   ```
   /kubevirt:vep-review-list jdoe
   ```
   Lists all VEPs where `jdoe` is assigned as VEP Reviewer.

3. **List your assignments for a specific release**:
   ```
   /kubevirt:vep-review-list --release 1.9
   ```
   Lists only VEPs tracked for the 1.9 release where you are the reviewer.

4. **List another user's assignments for a specific release**:
   ```
   /kubevirt:vep-review-list jdoe --release 1.9
   ```
   Lists VEPs tracked for 1.9 where `jdoe` is the reviewer.

## Arguments
- `[username]`: (Optional) GitHub username to look up. Defaults to the current authenticated user via `gh api user`
- `[--release <version>]`: (Optional) Filter by release version: `1.8`, `1.9`, etc. If omitted, searches all enhancement tracking projects

## See Also
- `/kubevirt:vep-list` - List all open VEPs with status and filtering
- `/kubevirt:vep-summary` - Get detailed summary of a specific VEP
- `/kubevirt:vep-groom` - Review a VEP proposal against requirements
- [KubeVirt Enhancement Tracking Project](https://github.com/orgs/kubevirt/projects/21)
- [KubeVirt Enhancements Repository](https://github.com/kubevirt/enhancements)
