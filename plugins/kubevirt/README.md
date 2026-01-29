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

Commands for working with KubeVirt Enhancement Proposals (VEPs) in the [kubevirt/enhancements](https://github.com/kubevirt/enhancements) repository.

#### `/kubevirt:vep-list`

List open VEPs with status, SIG ownership, and key labels. Helps maintainers track enhancement activity.

**Usage:**
```bash
/kubevirt:vep-list [--sig <sig>] [--state <state>]
```

#### `/kubevirt:vep-summary`

Get a TL;DR summary of a specific VEP including its current state, motivation, key design points, and implementation progress.

**Usage:**
```bash
/kubevirt:vep-summary <vep-number>
```

#### `/kubevirt:vep-groom`

Review a VEP proposal PR against template requirements and process guidelines. Identifies missing sections, incomplete content, and compliance issues.

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
