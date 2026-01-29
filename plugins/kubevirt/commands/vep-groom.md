---
description: Review a VEP proposal against template requirements and process guidelines
argument-hint: <vep-pr-number>
---

## Name
kubevirt:vep-groom

## Synopsis
```
/kubevirt:vep-groom <vep-pr-number>
```

## Description
The `kubevirt:vep-groom` command helps maintainers and SIG leads review a VEP proposal PR against the official template requirements, process guidelines, and release tracking requirements. It identifies missing sections, incomplete content, process compliance issues, and project tracking gaps.

### Data Sources

1. **VEP PR**: The proposal PR in kubevirt/enhancements
2. **Tracking Issue**: The associated VEP tracking issue
3. **GitHub Projects**: Enhancement tracking projects for release planning
4. **VEP Template**: The official template requirements

### What it Checks

#### Template Compliance
Verifies all required sections from the VEP template are present and filled:
- [ ] Release Signoff Checklist
- [ ] Overview
- [ ] Motivation
- [ ] Goals
- [ ] Non Goals
- [ ] Definition of Users
- [ ] User Stories
- [ ] Repos
- [ ] Design
- [ ] API Examples
- [ ] Alternatives
- [ ] Scalability
- [ ] Update/Rollback Compatibility
- [ ] Functional Testing Approach
- [ ] Implementation History
- [ ] Graduation Requirements (Alpha/Beta/GA)

#### Process Compliance
Checks VEP follows the kubevirt/enhancements process:
- [ ] Tracking issue exists and is linked in PR description
- [ ] SIG label is applied (`sig/compute`, `sig/network`, `sig/storage`)
- [ ] PR description follows the expected format (VEP Metadata section)
- [ ] DCO sign-off is present

#### Tracking Issue Quality
Checks the tracking issue has required information:
- [ ] Primary contact (assignee) specified
- [ ] Current Feature Stage documented
- [ ] Feature Gate name (if applicable)
- [ ] Responsible SIGs listed
- [ ] Enhancement link to VEP PR
- [ ] Timeline with Alpha/Beta/GA targets
- [ ] Links to Code PRs and Docs PRs

#### Release Tracking
Checks project board status:
- [ ] VEP is added to a release enhancement tracking project
- [ ] Status is set (Proposed, Tracked, etc.)
- [ ] Target Stage is specified (Alpha, Beta, Stable)
- [ ] SIG field is set in the project
- [ ] Assignee is set in the project

#### Content Quality
Reviews the content for common issues:
- Sections with only placeholder text or "N/A" where content is expected
- Missing concrete API examples
- Vague or incomplete user stories
- Missing graduation criteria for each phase
- No implementation history entries
- Incomplete timeline in tracking issue

### Review Categories
Issues are categorized by severity:
1. **Required**: Must be addressed before approval
2. **Recommended**: Should be addressed for clarity
3. **Suggestions**: Minor improvements

## Implementation

1. **Fetch PR Details**: Get the VEP PR information:
   ```bash
   gh pr view <pr-number> --repo kubevirt/enhancements --json title,body,labels,files,state,url
   ```

2. **Fetch VEP Content**: Get the VEP markdown file from the PR:
   ```bash
   gh pr diff <pr-number> --repo kubevirt/enhancements
   ```

3. **Extract VEP Number**: Parse the VEP number from the PR title (e.g., "VEP 190: ...")

4. **Check Tracking Issue**: Verify a tracking issue exists and fetch it:
   ```bash
   gh issue view <vep-number> --repo kubevirt/enhancements --json number,title,body,labels,assignees,url
   ```

5. **Check Project Tracking**: Search for VEP in enhancement tracking projects:
   ```bash
   gh project item-list 21 --owner kubevirt --format json | jq '.items[] | select(.title | contains("VEP <number>"))'
   gh project item-list 19 --owner kubevirt --format json | jq '.items[] | select(.title | contains("VEP <number>"))'
   ```

6. **Parse Template Sections**: Check each required section in the VEP:
   - Is the section present?
   - Is it filled with actual content (not just template placeholders)?
   - Does it meet minimum quality standards?

7. **Parse Tracking Issue**: Check required fields:
   - Primary contact
   - Feature Stage
   - Feature Gate
   - SIGs
   - Timeline with phase targets

8. **Check Labels and Process**:
   - Verify SIG label is present
   - Check DCO sign-off label
   - Verify PR description format

9. **Generate Review Report**: Produce a structured review

## Return Value
A structured review report:

```
## VEP Grooming Report: VEP <number> - <title>

### Overall Status: <Ready for Review | Needs Work | Major Issues>

### Template Compliance
| Section | Status | Notes |
|---------|--------|-------|
| Overview | OK | |
| Motivation | OK | |
| Goals | Missing | Section not found |
| ... | ... | ... |

### Process Compliance
- [x] Tracking issue linked
- [ ] SIG label applied
- [x] DCO sign-off present
- [ ] PR description follows format

### Tracking Issue Quality
- [x] Primary contact specified
- [x] Feature Stage documented
- [ ] Timeline incomplete (missing Beta/GA targets)
- [ ] Code PRs not linked

### Release Tracking
- [ ] Not added to any enhancement tracking project
- [ ] No target release specified

### Required Changes
1. Add missing "Goals" section
2. Fill in "API Examples" with concrete examples
3. Apply SIG label (/sig compute)
4. Add VEP to KubeVirt 1.9 Enhancements Tracking project
5. Complete timeline in tracking issue

### Recommended Changes
1. Expand user stories with specific scenarios
2. Add implementation history entry for initial proposal
3. Link expected Code PRs in tracking issue

### Suggestions
1. Consider adding more detail to scalability section
2. Clarify rollback procedure in Update/Rollback Compatibility

### Next Steps
<What the VEP author should do to address the findings>
```

## Examples

1. **Groom a new VEP PR**:
   ```
   /kubevirt:vep-groom 191
   ```
   Reviews PR #191 against template, process, and project tracking requirements.

2. **Groom a VEP after updates**:
   ```
   /kubevirt:vep-groom 185
   ```
   Re-reviews to check if previous issues have been addressed.

3. **Groom a VEP before SIG meeting**:
   ```
   /kubevirt:vep-groom 182
   ```
   Prepares a review summary for discussion in SIG meeting.

## Arguments
- `<vep-pr-number>`: (Required) The PR number for the VEP proposal to review

## See Also
- `/kubevirt:vep-list` - List all open VEPs
- `/kubevirt:vep-summary` - Get a TL;DR of a specific VEP
- [VEP Template](https://github.com/kubevirt/enhancements/blob/main/veps/NNNN-vep-template/vep.md)
- [VEP Process](https://github.com/kubevirt/enhancements/blob/main/README.md)
- [KubeVirt Enhancement Projects](https://github.com/orgs/kubevirt/projects)
