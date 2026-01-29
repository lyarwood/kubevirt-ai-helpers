# KubeVirt Plugin

KubeVirt development workflows for code review, linting, and enhancement proposals (VEPs).

## Commands

### Code Quality

#### `/kubevirt:review`

Review local branch changes using KubeVirt project coding conventions and reviewer guidelines. Performs a multi-pass code review checking design, implementation details, and standards compliance.

**Usage:**
```bash
/kubevirt:review [base-branch]
```

#### `/kubevirt:lint`

Lint a path in the KubeVirt codebase and generate a plan to fix all issues. Creates separate commits per linter type (formatting, error handling, static analysis, etc.) for easy review and bisection.

**Usage:**
```bash
/kubevirt:lint <path>
```

### VEP Management

Commands for working with KubeVirt Enhancement Proposals (VEPs) in the [kubevirt/enhancements](https://github.com/kubevirt/enhancements) repository and [KubeVirt Enhancement Tracking Projects](https://github.com/orgs/kubevirt/projects).

These commands integrate data from:
- **kubevirt/enhancements**: VEP proposals and tracking issues
- **GitHub Projects**: Release-specific enhancement tracking (status, target stage, promotion phase)
- **kubevirt/kubevirt**: Implementation PRs

#### `/kubevirt:vep-list`

List VEPs with release tracking status, SIG ownership, and project data. Filter by SIG, release, or status.

**Usage:**
```bash
/kubevirt:vep-list [--sig <sig>] [--release <version>] [--status <status>]
```

#### `/kubevirt:vep-summary`

Get a TL;DR summary of a specific VEP including release tracking data, ownership, progress across phases, and next steps.

**Usage:**
```bash
/kubevirt:vep-summary <vep-number>
```

#### `/kubevirt:vep-groom`

Review a VEP proposal PR against template requirements, process guidelines, and release tracking. Checks tracking issue quality and project board status.

**Usage:**
```bash
/kubevirt:vep-groom <vep-pr-number>
```

## Installation

```bash
/plugin install kubevirt@kubevirt-ai-helpers
```

## Common Workflows

### Reviewing changes before submitting a PR
```bash
git checkout feature/my-new-feature
/kubevirt:review main
```

### Linting code before committing
```bash
/kubevirt:lint pkg/virt-controller/watch
```

### Checking open VEPs for a SIG meeting
```bash
/kubevirt:vep-list --sig compute
```

### Understanding a VEP before reviewing
```bash
/kubevirt:vep-summary 190
```

### Grooming a VEP proposal
```bash
/kubevirt:vep-groom 191
```

## See Also

For complete command documentation, see the individual command files in the `commands/` directory.
