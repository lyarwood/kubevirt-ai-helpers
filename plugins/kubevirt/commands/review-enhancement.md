---
description: Review a KubeVirt enhancement proposal for process compliance and technical quality
argument-hint: <vep-number>
---

## Name
kubevirt:review-enhancement

## Synopsis
```
/kubevirt:review-enhancement <vep-number>
```

## Description
The `kubevirt:review-enhancement` command performs a comprehensive review of a KubeVirt Enhancement Proposal (VEP) combining process compliance checks with a multi-pass technical content review. It takes a VEP number, automatically resolves the tracking issue, proposal PRs, project board data, and implementation PRs, then evaluates the enhancement from both a process and technical reviewer perspective.

This command uses the `review-enhancement` skill for detailed implementation guidance. See `plugins/kubevirt/skills/review-enhancement/SKILL.md`.

### Data Sources

1. **Tracking Issue**: VEP tracking issue in kubevirt/enhancements
2. **Proposal PR(s)**: VEP proposal PRs in kubevirt/enhancements
3. **GitHub Projects**: Enhancement tracking projects for release planning
4. **Implementation PRs**: Code PRs in kubevirt/kubevirt and other repos
5. **VEP Template**: The official template for section completeness

### Review Passes

The review is structured in two parts:

#### Part A: Process & Template Compliance

Checks that the VEP follows the kubevirt/enhancements process:

- **Template Completeness**: All 16 required sections are present and filled
- **Tracking Issue Quality**: Primary contact, feature stage, timeline, linked PRs
- **Project Board Status**: Added to release project, status set, target stage, SIG, assignee
- **Process Compliance**: SIG label, DCO sign-off, PR description format

#### Part B: Technical Content Review

A multi-pass review evaluating the proposal's technical merit:

1. **Design Coherence Pass**
   - Does the design follow logically from the motivation and goals?
   - Are non-goals clearly scoped to prevent scope creep?
   - Is the design internally consistent across sections?
   - Are there unstated assumptions that should be made explicit?

2. **API Surface Pass**
   - Are API examples concrete with complete YAML/JSON manifests?
   - Are new CRD fields and types well-defined with validation rules?
   - Do API changes follow KubeVirt conventions (labels, annotations, status conditions)?
   - Is backwards compatibility of API changes addressed?
   - Are defaulting and validation semantics specified?

3. **Migration & Upgrade Pass**
   - Is the update/rollback procedure clearly described?
   - Is the feature gate strategy sound (alpha gated, beta opt-out, GA always-on)?
   - Are data migration requirements identified?
   - What is the impact on existing running workloads during upgrade?
   - Are there multi-version skew concerns (virt-handler vs virt-controller)?

4. **Scalability & Performance Pass**
   - Does the scalability section address realistic production scenarios?
   - Are resource consumption implications quantified or estimated?
   - What is the impact at scale (1000+ VMs, large clusters)?
   - Are there new watch/list/API call patterns that could stress the API server?
   - Does the design introduce new controllers or reconcile loops?

5. **Testing & Graduation Pass**
   - Is the functional testing approach specific enough to implement?
   - Are graduation criteria clear and measurable for each phase (alpha/beta/GA)?
   - Are E2E test expectations defined?
   - Does the testing strategy cover upgrade, rollback, and failure scenarios?

6. **Implementation Feasibility Pass**
   - Are the listed repos correct and complete?
   - Is there cross-repo coordination complexity (kubevirt, CDI, common-instancetypes)?
   - Is the timeline realistic given the scope?
   - Are there dependencies on external projects (Kubernetes, libvirt, QEMU)?

### Review Categories
Issues are categorized by severity:
1. **Required**: Must be addressed before the VEP can be approved
2. **Recommended**: Should be addressed for completeness and clarity
3. **Suggestions**: Minor improvements or considerations for the author

## Implementation

This command uses the `review-enhancement` skill for detailed step-by-step implementation guidance. Below is the high-level flow.

### Skill Reference
The detailed implementation logic is in `plugins/kubevirt/skills/review-enhancement/SKILL.md`, which covers:
- Data gathering across all sources
- How to perform each technical review pass
- Specific patterns to look for in each VEP section
- Cross-referencing design claims against implementation PRs
- Severity classification guidelines

### High-Level Steps

1. **Resolve VEP Data**: Fetch the tracking issue, find proposal PRs, query project board:
   ```bash
   # Fetch tracking issue
   gh issue view <vep-number> --repo kubevirt/enhancements --json number,title,body,labels,assignees,state,comments,url

   # Find proposal PRs
   gh pr list --repo kubevirt/enhancements --search "VEP <vep-number>" --state all --json number,title,body,labels,state,files,url

   # Discover and query enhancement tracking projects
   gh project list --owner kubevirt --format json | jq '.projects[] | select(.title | contains("Enhancement"))'
   ```

2. **Fetch VEP Content**: Get the full VEP markdown:
   ```bash
   # From PR diff if open
   gh pr diff <pr-number> --repo kubevirt/enhancements

   # From repo if merged
   gh api repos/kubevirt/enhancements/contents/veps/sig-<sig>/<number>-<slug>/vep.md --jq '.content' | base64 -d
   ```

3. **Fetch Implementation PRs**: Extract code PR links from the tracking issue body and check their status:
   ```bash
   gh pr view <pr-number> --repo kubevirt/kubevirt --json state,title,mergedAt,url
   ```

4. **Run Process Compliance Checks**: Verify template sections, tracking issue quality, project board status, labels, and DCO.

5. **Run Technical Review Passes**: Execute each of the 6 technical review passes against the VEP content, cross-referencing with implementation PRs where available.

6. **Generate Review Report**: Produce a structured report combining process and technical findings.

## Return Value
A structured review report:

```
## VEP Enhancement Review: VEP <number> - <title>

### Overall Assessment: <Ready for Approval | Needs Revision | Major Concerns>

---

### Part A: Process & Template Compliance

#### Template Completeness
| Section | Status | Notes |
|---------|--------|-------|
| Overview | OK | |
| Motivation | OK | |
| Goals | Incomplete | Only lists one goal |
| ... | ... | ... |

#### Process Compliance
- [x] Tracking issue exists and linked
- [ ] SIG label applied
- [x] DCO sign-off present

#### Tracking Issue Quality
- [x] Primary contact specified
- [ ] Timeline incomplete (missing Beta target)

#### Release Tracking
- [x] Added to enhancement tracking project
- [x] Status: Tracked
- [ ] Target Stage not set

---

### Part B: Technical Review

#### Design Coherence
- **Required**: The design introduces a new controller but the motivation
  section does not explain why existing controllers cannot be extended.
- **Recommended**: Non-goals should explicitly exclude <related feature>
  to prevent scope creep.

#### API Surface
- **Required**: API examples show the new field but do not include
  validation rules or defaulting behavior.
- **Recommended**: Add a complete VirtualMachine manifest showing the
  new fields in context.

#### Migration & Upgrade
- **Suggestions**: Consider documenting the behavior when a VM is
  live-migrated during the upgrade from a node without the feature gate
  to one with it.

#### Scalability & Performance
- **Required**: The design adds a new watch on all VMI objects from the
  new controller. Describe the expected load at 1000+ VMIs.

#### Testing & Graduation
- **Recommended**: Alpha graduation criteria should specify which E2E
  tests will be added, not just "functional tests will be written."

#### Implementation Feasibility
- **Suggestions**: Timeline targets GA in a single release cycle.
  Consider whether beta feedback period is sufficient.

---

### Summary

| Category | Required | Recommended | Suggestions |
|----------|----------|-------------|-------------|
| Process  | 2        | 1           | 0           |
| Technical| 3        | 2           | 2           |
| **Total**| **5**    | **3**       | **2**       |

### Next Steps
1. Address all Required items before requesting re-review
2. Consider Recommended items for completeness
3. <Specific actionable guidance>
```

## Examples

1. **Review a VEP by number**:
   ```
   /kubevirt:review-enhancement 190
   ```
   Fetches VEP 190's tracking issue, proposal PR, project board data, and
   implementation PRs, then produces a combined process and technical review.

2. **Review a VEP before a SIG meeting**:
   ```
   /kubevirt:review-enhancement 62
   ```
   Generates a review report suitable for discussing the VEP's readiness at
   a SIG meeting.

3. **Re-review after revisions**:
   ```
   /kubevirt:review-enhancement 172
   ```
   Re-runs the full review to check whether previously identified issues
   have been addressed.

## Arguments
- `<vep-number>`: (Required) The VEP number to review (e.g., `190`, `172`, `10`). This is the tracking issue number in kubevirt/enhancements.

## See Also
- `/kubevirt:vep-groom` - Process-focused grooming checklist for VEP PRs
- `/kubevirt:vep-summary` - Get a TL;DR of a specific VEP
- `/kubevirt:vep-list` - List all open VEPs
- `/kubevirt:vep-review-list` - List VEPs assigned to you for review
- `/kubevirt:vep-find-reviewers` - Find potential reviewers for a VEP
- [VEP Template](https://github.com/kubevirt/enhancements/blob/main/veps/NNNN-vep-template/vep.md)
- [VEP Process](https://github.com/kubevirt/enhancements/blob/main/README.md)
- [KubeVirt Enhancement Projects](https://github.com/orgs/kubevirt/projects)
