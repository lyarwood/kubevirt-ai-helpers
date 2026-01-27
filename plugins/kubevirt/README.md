# KubeVirt Plugin

Core KubeVirt development workflows for code review and linting.

## Commands

### `/kubevirt:review`

Review local branch changes using KubeVirt project coding conventions and reviewer guidelines. Performs a multi-pass code review checking design, implementation details, and standards compliance.

**Usage:**
```bash
/kubevirt:review [base-branch]
```

### `/kubevirt:lint`

Lint a path in the KubeVirt codebase and generate a plan to fix all issues. Creates separate commits per linter type (formatting, error handling, static analysis, etc.) for easy review and bisection.

**Usage:**
```bash
/kubevirt:lint <path>
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

## See Also

For complete command documentation, see the individual command files in the `commands/` directory.
