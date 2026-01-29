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
The `kubevirt:vep-groom` command helps maintainers and SIG leads review a VEP proposal PR against the official template requirements and process guidelines. It identifies missing sections, incomplete content, and process compliance issues.

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
- [ ] PR description follows the expected format
- [ ] DCO sign-off is present

#### Content Quality
Reviews the content for common issues:
- Sections with only placeholder text or "N/A" where content is expected
- Missing concrete API examples
- Vague or incomplete user stories
- Missing graduation criteria for each phase
- No implementation history entries

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
   Or fetch the file directly from the PR branch.

3. **Check Tracking Issue**: Verify a tracking issue exists:
   ```bash
   gh issue list --repo kubevirt/enhancements --search "VEP <number>" --json number,title,url
   ```

4. **Parse Template Sections**: Check each required section:
   - Is the section present?
   - Is it filled with actual content (not just template placeholders)?
   - Does it meet minimum quality standards?

5. **Check Labels and Process**:
   - Verify SIG label is present
   - Check DCO sign-off label
   - Verify PR description format

6. **Generate Review Report**: Produce a structured review with:
   - Checklist of template sections (complete/incomplete)
   - Process compliance issues
   - Content quality suggestions
   - Overall readiness assessment

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

### Required Changes
1. Add missing "Goals" section
2. Fill in "API Examples" with concrete examples
3. Apply SIG label (/sig compute)

### Recommended Changes
1. Expand user stories with specific scenarios
2. Add implementation history entry for initial proposal

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
   Reviews PR #191 against template and process requirements.

2. **Groom a VEP after updates**:
   ```
   /kubevirt:vep-groom 185
   ```
   Re-reviews to check if previous issues have been addressed.

## Arguments
- `<vep-pr-number>`: (Required) The PR number for the VEP proposal to review

## See Also
- `/kubevirt:vep-list` - List all open VEPs
- `/kubevirt:vep-summary` - Get a TL;DR of a specific VEP
- [VEP Template](https://github.com/kubevirt/enhancements/blob/main/veps/NNNN-vep-template/vep.md)
- [VEP Process](https://github.com/kubevirt/enhancements/blob/main/README.md)
