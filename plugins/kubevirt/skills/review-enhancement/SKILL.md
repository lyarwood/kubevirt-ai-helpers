---
name: Review Enhancement
description: Detailed implementation guide for reviewing KubeVirt enhancement proposals for process compliance and technical quality
---

# Review Enhancement

This skill provides the detailed implementation logic for the `/kubevirt:review-enhancement` command. It covers how to gather all VEP data sources, perform process compliance checks, execute multi-pass technical review, and produce a structured review report.

## When to Use This Skill

- When executing the `/kubevirt:review-enhancement` command
- When a user asks for a comprehensive review of a VEP proposal
- When preparing review feedback for a VEP before a SIG meeting or approval decision

## Prerequisites

1. **gh CLI**: Must be installed and authenticated (`gh auth status`)
2. **Network access**: Requires access to the GitHub API for fetching VEP content, tracking issues, project data, and implementation PRs

## Implementation Steps

### Step 1: Resolve VEP Data

Given a VEP number, gather all associated resources.

#### 1a: Fetch the Tracking Issue

```bash
gh issue view <vep-number> --repo kubevirt/enhancements --json number,title,body,labels,assignees,state,comments,url
```

Parse the tracking issue body to extract:
- **Primary contact**: The assignee
- **Feature Stage**: Look for "Feature Stage:" or a stage table (Alpha/Beta/GA)
- **Feature Gate name**: Look for "Feature Gate:" or gate references
- **Responsible SIGs**: Look for "SIG:" or SIG references
- **Timeline**: Look for target release versions next to Alpha/Beta/GA
- **Linked PRs**: Extract PR URLs from the body, categorized as:
  - VEP/Enhancement PRs (kubevirt/enhancements)
  - Code PRs (kubevirt/kubevirt or other repos)
  - Docs PRs (kubevirt/user-guide)

If the tracking issue does not exist (404), report this as a Required finding and continue with whatever data is available.

#### 1b: Find Proposal PRs

```bash
gh pr list --repo kubevirt/enhancements --search "VEP <vep-number>" --state all --json number,title,body,labels,state,files,url
```

There may be multiple PRs (initial proposal, updates, graduation). Identify:
- The primary proposal PR (usually the earliest, or the one adding the VEP directory)
- Any update PRs (modifying the VEP content)

#### 1c: Query Project Board

Discover enhancement tracking projects dynamically:
```bash
gh project list --owner kubevirt --format json | jq '.projects[] | select(.title | contains("Enhancement")) | select(.title | startswith("[TEMPLATE]") | not)'
```

For each matching project, search for the VEP using GraphQL:
```bash
gh api graphql -f query='
{
  organization(login: "kubevirt") {
    projectV2(number: <project-number>) {
      items(first: 100) {
        nodes {
          content {
            ... on Issue {
              number
              title
            }
          }
          fieldValues(first: 30) {
            nodes {
              ... on ProjectV2ItemFieldSingleSelectValue {
                name
                field { ... on ProjectV2SingleSelectField { name } }
              }
              ... on ProjectV2ItemFieldTextValue {
                text
                field { ... on ProjectV2Field { name } }
              }
              ... on ProjectV2ItemFieldUserValue {
                users(first: 5) { nodes { login } }
                field { ... on ProjectV2Field { name } }
              }
            }
          }
        }
      }
    }
  }
}'
```

Match the item whose issue number equals the VEP number. Extract fields:
- **Status**: Proposed, Tracked, At Risk, Complete, Removed from Milestone
- **Target Stage**: Alpha, Beta, Stable, Deprecation/Removal
- **Promotion Phase**: Net New, Remaining, Graduating, Deprecation
- **SIG**: sig-compute, sig-network, sig-storage
- **Assignee**: GitHub username
- **VEP Reviewer**: May contain comma-separated usernames
- **VEP Approver**: May contain comma-separated usernames
- **Code Freeze Exception**: Yes/No/Pending

If the VEP is not found in any project, report this as a Required finding.

### Step 2: Fetch VEP Content

Get the full VEP markdown document for technical review.

**If the proposal PR is open**, fetch the diff:
```bash
gh pr diff <pr-number> --repo kubevirt/enhancements
```
Extract the added VEP content from the diff (lines starting with `+`).

**If the proposal PR is merged**, fetch from the repository:
```bash
# Determine the VEP path from the PR's changed files
gh pr view <pr-number> --repo kubevirt/enhancements --json files --jq '.files[].path' | grep 'vep.md'

# Fetch the content
gh api repos/kubevirt/enhancements/contents/<path-to-vep.md> --jq '.content' | base64 -d
```

**If no proposal PR exists**, check if the VEP directory exists in the repo:
```bash
gh api repos/kubevirt/enhancements/contents/veps --jq '.[].name' | grep '<vep-number>'
```

### Step 3: Fetch Implementation PR Status

For each code PR linked in the tracking issue body:

```bash
gh pr view <pr-number> --repo <owner/repo> --json number,title,state,mergedAt,url,additions,deletions,changedFiles
```

Track:
- How many code PRs exist
- How many are merged vs open vs closed
- Which repos they target
- Total scope (additions/deletions)

This data feeds into the Implementation Feasibility pass.

### Step 4: Run Process Compliance Checks

#### 4a: Template Section Completeness

Parse the VEP markdown content and check for each required section. A section is present if a heading matching the name exists. A section is filled if it contains substantive content beyond template placeholders.

**Required sections** (check for headings):
1. Release Signoff Checklist
2. Overview
3. Motivation
4. Goals
5. Non Goals (or Non-Goals)
6. Definition of Users
7. User Stories
8. Repos
9. Design
10. API Examples
11. Alternatives (or Alternative Considered)
12. Scalability
13. Update/Rollback Compatibility
14. Functional Testing Approach
15. Implementation History
16. Graduation Requirements (look for Alpha, Beta, GA subsections)

**Placeholder detection**: Flag sections containing only:
- `TODO`, `TBD`, `N/A`, `TBA`
- Template boilerplate text like "Describe..." or "List..."
- Fewer than 2 substantive sentences

#### 4b: Tracking Issue Quality

Check the tracking issue body for:
- [ ] Primary contact (assignee) specified
- [ ] Current Feature Stage documented
- [ ] Feature Gate name (if applicable, i.e., introduces new behavior)
- [ ] Responsible SIGs listed
- [ ] Enhancement link to VEP PR
- [ ] Timeline with Alpha/Beta/GA target releases
- [ ] Links to Code PRs
- [ ] Links to Docs PRs

#### 4c: Project Board Status

Check project data for:
- [ ] VEP is added to a release enhancement tracking project
- [ ] Status is set (not empty)
- [ ] Target Stage is specified
- [ ] SIG field is set
- [ ] Assignee is set

#### 4d: Labels and Process

Check the proposal PR for:
- [ ] SIG label is present (`sig/compute`, `sig/network`, `sig/storage`)
- [ ] DCO sign-off (check for `dco-signoff: yes` label or commits)
- [ ] PR description follows expected format

### Step 5: Run Technical Review Passes

Execute each pass against the VEP content. For each finding, classify as Required, Recommended, or Suggestion.

#### Pass 1: Design Coherence

Read the Motivation, Goals, Non-Goals, and Design sections together. Check:

- **Motivation → Goals alignment**: Every goal should trace back to a stated motivation. Flag goals that appear unrelated to the motivation.
- **Goals → Design alignment**: The design should address every stated goal. Flag goals with no corresponding design section.
- **Non-Goals scoping**: Non-goals should explicitly exclude closely related features that a reader might assume are in scope. Flag if non-goals are absent or only contain trivial exclusions.
- **Internal consistency**: Check that claims in one section are not contradicted in another (e.g., "minimal API changes" in overview but extensive new types in design).
- **Unstated assumptions**: Flag design decisions that depend on assumptions not documented in the proposal (e.g., assuming a specific Kubernetes version, assuming libvirt feature availability).

#### Pass 2: API Surface

Read the API Examples, Design, and any CRD/type definitions. Check:

- **Completeness**: API examples should include complete YAML manifests, not just field snippets. The reader should be able to copy-paste and understand the full resource shape.
- **New fields/types**: Every new CRD field should specify:
  - Type (string, int, bool, object, enum)
  - Whether required or optional
  - Default value (if optional)
  - Validation rules (min/max, regex, allowed values)
  - Whether mutable or immutable after creation
- **KubeVirt conventions**:
  - Labels follow `kubevirt.io/` prefix convention
  - Annotations follow `kubevirt.io/` prefix convention
  - Status conditions use standard Kubernetes condition format
  - New status fields are read-only and set by controllers
- **Backwards compatibility**:
  - Existing API fields are not removed or have their semantics changed
  - New required fields have defaults for existing resources
  - API version strategy (v1alpha1 → v1beta1 → v1) is documented
- **Defaulting and validation**:
  - Webhook validation rules are specified
  - Mutating webhook defaults are documented
  - Interaction with existing validation rules is considered

#### Pass 3: Migration & Upgrade

Read Update/Rollback Compatibility and graduation sections. Check:

- **Upgrade path**: What happens to existing VMs/VMIs when the feature is enabled?
- **Rollback safety**: What happens if the feature gate is disabled after being enabled?
- **Data migration**: Are there any stored data format changes? If so, is migration documented?
- **Feature gate strategy**:
  - Alpha: Feature gate disabled by default, no graduation criteria that imply it should be enabled
  - Beta: Feature gate enabled by default, rollback is safe
  - GA: Feature gate removed, behavior is always active
- **Version skew**: In a rolling update, virt-handler and virt-controller may be at different versions. Does the design handle this?
- **Running workload impact**: Does enabling/disabling affect VMs that are currently running, or only new VMs?

#### Pass 4: Scalability & Performance

Read the Scalability section and relevant design details. Check:

- **Quantitative claims**: Are scalability claims backed by numbers or estimates? "This scales well" is insufficient; "This adds O(1) API calls per VM start" is better.
- **Resource consumption**: Does the feature add:
  - New controllers with watches (CPU/memory)
  - Additional API calls per reconcile loop
  - New storage requirements (PVCs, ConfigMaps)
  - Network overhead (new services, webhooks)
- **Scale scenarios**: Is behavior at scale described?
  - 100+ VMs per node (virt-handler impact)
  - 1000+ VMs per cluster (virt-controller impact)
  - Large objects (status size, annotation size)
- **API server impact**: Does the design add new list/watch operations? Are they filtered or unfiltered?
- **New reconcile loops**: If a new controller is introduced, what is its reconcile frequency and scope?

#### Pass 5: Testing & Graduation

Read the Functional Testing Approach and graduation requirements. Check:

- **Testing specificity**: The testing approach should describe specific test scenarios, not just "tests will be written." Look for:
  - What is being tested (specific functionality)
  - How it is tested (unit, integration, E2E)
  - Edge cases considered
- **Graduation criteria clarity**:
  - Alpha: What must be true before promoting to beta?
  - Beta: What feedback/data is needed? What stability bar?
  - GA: What proves the feature is production-ready?
- **Missing test scenarios**: Based on the design, are there obvious scenarios not covered?
  - Negative tests (what happens when input is invalid)
  - Upgrade/rollback tests
  - Scale tests
  - Failure/recovery tests
- **E2E test expectations**: Are specific E2E test files or suites mentioned?

#### Pass 6: Implementation Feasibility

Cross-reference the design against implementation PRs and timeline. Check:

- **Repo completeness**: Are all affected repos listed? Common omissions:
  - `kubevirt/kubevirt` (core)
  - `kubevirt/containerized-data-importer` (storage features)
  - `kubevirt/common-instancetypes` (instance type changes)
  - `kubevirt/user-guide` (documentation)
  - `kubevirt/api` or `staging/src/kubevirt.io/api` (API types)
- **Cross-repo coordination**: If changes span multiple repos, is the order of operations documented?
- **External dependencies**: Does the feature depend on:
  - Specific Kubernetes version or feature gates
  - libvirt/QEMU capabilities
  - External projects (Multus, OVN, etc.)
- **Timeline realism**: Compare the scope of design changes against the target release timeline. Flag if:
  - Large scope targets a single release for GA
  - Alpha has no implementation PRs with a close target date
  - Multiple repos need coordinated changes with no sequencing plan
- **Implementation progress** (if code PRs exist):
  - Do merged PRs match the design?
  - Are there design divergences between proposal and implementation?

### Step 6: Generate Review Report

Compile all findings into the structured report format defined in the command's Return Value section.

**Ordering**:
1. Overall assessment (Ready for Approval / Needs Revision / Major Concerns)
2. Part A: Process & Template Compliance (tables and checklists)
3. Part B: Technical Review (findings grouped by pass)
4. Summary table (counts by category and severity)
5. Next Steps (actionable guidance)

**Overall assessment heuristic**:
- **Ready for Approval**: 0 Required findings, ≤3 Recommended
- **Needs Revision**: 1-3 Required findings, or >5 Recommended
- **Major Concerns**: >3 Required findings, or fundamental design issues

**Formatting rules**:
- ASCII-only output, no Unicode characters
- Each finding starts with its severity in bold: **Required**, **Recommended**, or **Suggestion**
- Findings include specific references to VEP sections
- Where possible, suggest what the author should add or change

## Error Handling

| Error | Recovery |
|-------|----------|
| Tracking issue not found (404) | Report as Required finding. Continue review with whatever data is available from PRs and project board. |
| No proposal PR found | Check if the VEP directory exists in the repo (may be merged). If not found at all, report that the VEP content could not be located and provide only process review. |
| VEP not found in any project | Report as Required finding for release tracking. Continue with template and technical review. |
| GitHub API rate limited | Report the rate limit error. Suggest the user wait or authenticate with a higher-limit token. |
| VEP content too large for context | Focus technical review on the Design, API Examples, Scalability, and Update/Rollback sections. Note that a full review was not possible. |
| Implementation PRs in external repos | Attempt to fetch PR metadata. If the repo is not accessible, note this and skip implementation progress checks. |

## Examples

### Example 1: Review a Tracked VEP

```
/kubevirt:review-enhancement 190
```

1. Fetches tracking issue #190 from kubevirt/enhancements
2. Finds proposal PR(s) matching "VEP 190"
3. Queries enhancement tracking projects for VEP 190 project board data
4. Fetches VEP markdown content from the proposal PR
5. Extracts linked code PRs from the tracking issue and checks their status
6. Runs all process compliance checks
7. Runs all 6 technical review passes
8. Produces a combined review report with findings and next steps

### Example 2: Review a VEP With No Project Board Entry

```
/kubevirt:review-enhancement 195
```

1. Fetches tracking issue #195
2. Finds proposal PR
3. Searches projects but finds no entry -- reports as Required finding
4. Continues with template and technical review
5. Report highlights missing project tracking as a key gap
