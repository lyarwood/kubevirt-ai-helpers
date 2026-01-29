# Available Plugins

This document lists all available Claude Code plugins and their commands in the ai-helpers repository.

- [Hello World](#hello-world-plugin)
- [Kubevirt](#kubevirt-plugin)

### Hello World Plugin

A hello world plugin

**Commands:**
- **`/hello-world:echo` `[name]`** - Hello world plugin implementation

See [plugins/hello-world/README.md](plugins/hello-world/README.md) for detailed documentation.

### Kubevirt Plugin

KubeVirt development workflows for code review, linting, and enhancement proposals (VEPs)

**Commands:**
- **`/kubevirt:lint` `<path>`** - Lint a path and generate a plan to fix issues with separate commits per linter
- **`/kubevirt:review` `[base-branch]`** - Review local branch changes using KubeVirt project best practices
- **`/kubevirt:vep-groom` `<vep-pr-number>`** - Review a VEP proposal against template requirements and process guidelines
- **`/kubevirt:vep-list` `[--sig <sig>] [--release <version>] [--status <status>]`** - List open KubeVirt Enhancement Proposals (VEPs) with status and filtering
- **`/kubevirt:vep-summary` `<vep-number>`** - Get a TL;DR summary of a specific VEP and its current state

See [plugins/kubevirt/README.md](plugins/kubevirt/README.md) for detailed documentation.
