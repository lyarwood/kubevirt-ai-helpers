---
description: Review a KubeVirt enhancement proposal (VEP) PR for process compliance, technical quality, and accuracy against its implementation
argument-hint: "<pr-number-or-url | vep-number>"
---

## Name
kubevirt:review-enhancement

## Synopsis
```
/kubevirt:review-enhancement <pr-number-or-url | vep-number>
```

## Description
The `kubevirt:review-enhancement` command performs a comprehensive review of a KubeVirt Enhancement Proposal (VEP) combining process compliance checks with a multi-pass technical content review. The primary input is an enhancements PR (number or URL); the command resolves the VEP it touches, the tracking issue, project board data, and implementation PRs, then evaluates the enhancement from both a process and technical reviewer perspective. A VEP number is also accepted and disambiguated automatically.

All process and technical checks are grounded in the best practices **codified in the kubevirt/enhancements repository itself**, which the command reads live at review time (rather than relying on a hard-coded snapshot):

- `README.md` -- the VEP process, responsibilities, labels, deadlines, and exceptions
- `docs/feature-lifecycle.md` -- feature gates, graduation phases, and the release stage transition table
- `veps/NNNN-vep-template/vep.md` -- required sections
- `.github/PULL_REQUEST_TEMPLATE.md` -- the expected PR metadata

The command distinguishes between two kinds of PR:

- **New VEP** (the PR adds a new `veps/sig-*/NNNN-*/vep.md`): reviewed for completeness, design quality, and process compliance.
- **Update to an existing VEP** (the PR modifies an existing `vep.md`, e.g. a graduation or design change): in addition to the above, the command reviews the **existing implementation code and PRs** to verify the VEP is still accurate -- that the proposal has not diverged from what was actually built, and that any stage bump (Alpha -> Beta -> GA) is backed by merged implementation as required by the feature lifecycle.

This command uses the `review-enhancement` skill for detailed implementation guidance. See `plugins/kubevirt/skills/review-enhancement/SKILL.md`.

### Data Sources

1. **Enhancements PR**: The VEP proposal/update PR under review in kubevirt/enhancements
2. **Best-Practice Docs (read live)**: `README.md`, `docs/feature-lifecycle.md`, the VEP template, and the PR template from kubevirt/enhancements
3. **Tracking Issue**: VEP tracking issue in kubevirt/enhancements
4. **GitHub Projects**: Enhancement tracking projects for release planning
5. **Implementation PRs and Code**: Code PRs and merged implementation in kubevirt/kubevirt and other repos (used to verify accuracy of VEP updates)

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

7. **VEP Accuracy vs Implementation Pass** (only for updates to existing VEPs)
   - Does the updated VEP still accurately describe what was actually built? The
     README states the VEP is the "single source of truth" and the SIG checklist
     requires verifying the enhancement "is not diverging" and the implementation
     "is not lacking behind the VEP."
   - For a stage bump (Alpha -> Beta -> GA): are the referenced implementation
     PRs actually merged? The feature lifecycle requires all implementation PRs
     to be merged *before* the version-bump PR.
   - Does the feature gate name, API shape, and defaulting in the VEP match the
     merged code? Flag divergence between the proposal and the implementation.
   - Are graduation criteria for the previous stage genuinely met by evidence
     (merged tests, CI gating for Beta/GA, user feedback)?
   - Is the Implementation History section updated to reference the relevant
     implementation and bug-fix PRs?

### Review Categories
Issues are categorized by severity:
1. **Required**: Must be addressed before the VEP can be approved
2. **Recommended**: Should be addressed for completeness and clarity
3. **Suggestions**: Minor improvements or considerations for the author

## Implementation

This command uses the `review-enhancement` skill for detailed step-by-step implementation guidance. Below is the high-level flow.

### Skill Reference
The detailed implementation logic is in `plugins/kubevirt/skills/review-enhancement/SKILL.md`, which covers:
- Resolving the input (enhancements PR or VEP number)
- Reading best practices live from the enhancements repo
- Detecting new-VEP vs update-to-existing-VEP PRs
- Data gathering across all sources
- How to perform each technical review pass
- Verifying VEP accuracy against implementation code and PRs (for updates)
- Severity classification guidelines

### High-Level Steps

See the skill for the exact commands. The flow is:

1. **Resolve Input**: Accept an enhancements PR (number or URL) or a VEP number. From a PR, determine the VEP it touches and whether it is a **new VEP** (adds a `vep.md`) or an **update to an existing VEP** (modifies an existing `vep.md`).
2. **Load Best Practices (live)**: Read `README.md`, `docs/feature-lifecycle.md`, the VEP template, and the PR template from kubevirt/enhancements so checks reflect the current process.
3. **Resolve VEP Data**: Fetch the tracking issue and query the enhancement tracking projects.
4. **Fetch VEP Content**: Get the VEP markdown (and, for updates, the before/after diff).
5. **Fetch Implementation PRs and Code**: Check the status of linked code PRs; for updates, inspect the merged code to verify accuracy.
6. **Run Process Compliance Checks**: Verify template sections, tracking issue quality, project board status, labels, and DCO against the live best-practice docs.
7. **Run Technical Review Passes**: Execute the technical passes against the VEP content. For updates, also run the VEP Accuracy vs Implementation pass.
8. **Generate Review Report**: Produce a structured report combining process, technical, and accuracy findings.

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

#### VEP Accuracy vs Implementation (updates only)
- **Required**: The VEP bumps the stage to Beta, but implementation PR
  kubevirt/kubevirt#12345 is still open. All implementation PRs must be
  merged before the stage bump.
- **Recommended**: The merged code names the feature gate `MyFeature` but
  the VEP still refers to `MyFeatureGate`. Update the VEP to match.

---

### Summary

| Category | Required | Recommended | Suggestions |
|----------|----------|-------------|-------------|
| Process  | 2        | 1           | 0           |
| Technical| 3        | 2           | 2           |
| Accuracy | 1        | 1           | 0           |
| **Total**| **6**    | **4**       | **2**       |

> The Accuracy row is only populated for PRs that update an existing VEP.

### Next Steps
1. Address all Required items before requesting re-review
2. Consider Recommended items for completeness
3. <Specific actionable guidance>
```

## Examples

1. **Review an enhancements PR by number**:
   ```
   /kubevirt:review-enhancement 245
   ```
   Resolves PR #245, determines the VEP it touches and whether it is a new VEP
   or an update, reads the live best-practice docs, and produces a combined
   process, technical, and (for updates) accuracy review.

2. **Review an enhancements PR by URL**:
   ```
   /kubevirt:review-enhancement https://github.com/kubevirt/enhancements/pull/245
   ```
   Same as above, accepting the full PR URL.

3. **Review a graduation (stage-bump) PR**:
   ```
   /kubevirt:review-enhancement 260
   ```
   For a PR that bumps a VEP from Alpha to Beta, verifies that all referenced
   implementation PRs are merged, the feature gate and API match the code, and
   the previous stage's graduation criteria are genuinely met.

4. **Review by VEP number**:
   ```
   /kubevirt:review-enhancement 190
   ```
   Accepts a VEP number, finds its open proposal/update PR(s), and reviews them.

## Arguments
- `<pr-number-or-url | vep-number>`: (Required) Primarily an enhancements PR to review, given as a PR number (e.g., `245`) or full URL (e.g., `https://github.com/kubevirt/enhancements/pull/245`). A VEP number (the tracking issue number, e.g., `190`) is also accepted and disambiguated automatically. When both a PR and a VEP share the same number, the value is treated as a PR unless it is clearly a VEP tracking issue.

## See Also
- `/kubevirt:vep-groom` - Process-focused grooming checklist for VEP PRs
- `/kubevirt:vep-summary` - Get a TL;DR of a specific VEP
- `/kubevirt:vep-list` - List all open VEPs
- `/kubevirt:vep-review-list` - List VEPs assigned to you for review
- `/kubevirt:vep-find-reviewers` - Find potential reviewers for a VEP
- [VEP Template](https://github.com/kubevirt/enhancements/blob/main/veps/NNNN-vep-template/vep.md)
- [VEP Process](https://github.com/kubevirt/enhancements/blob/main/README.md)
- [KubeVirt Enhancement Projects](https://github.com/orgs/kubevirt/projects)
