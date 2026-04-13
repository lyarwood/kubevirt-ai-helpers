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

KubeVirt development workflows for code review, PR review, linting, CI analysis, and enhancement proposals (VEPs)

**Commands:**
- **`/kubevirt:ci-health` `[category] [--since <period>]`** - Analyze overall CI health across merge-time jobs with failure trending
- **`/kubevirt:ci-lane` `<job-name> [--since <period>]`** - Analyze recent runs and failure patterns for a specific CI job lane
- **`/kubevirt:ci-report` `[--scope <scope>] [--format <format>]`** - Generate comprehensive CI health reports for stakeholders
- **`/kubevirt:ci-search` `<pattern> [--max-age <period>] [--job <regex>]`** - Search for specific test failures and patterns across all CI jobs
- **`/kubevirt:ci-triage` `<job-or-category> [--context <context>]`** - Intelligent CI failure triage with root cause analysis and prioritized recommendations
- **`/kubevirt:lint` `<path>`** - Lint a path and generate a plan to fix issues with separate commits per linter
- **`/kubevirt:review-ci` `<pr-number-or-url>`** - Review CI failures for a given PR and provide analysis with remediation suggestions
- **`/kubevirt:review-list` `[username] [--sig <sig>] [--repo <repo>] [--limit <n>] [--order-by <field>]`** - List open PRs pending your review, filterable by user, SIG, or repo
- **`/kubevirt:review-pr` `<pr-number-or-url>`** - Review a GitHub PR using gh CLI, applying KubeVirt project best practices
- **`/kubevirt:review` `[base-branch]`** - Review local branch changes using KubeVirt project best practices
- **`/kubevirt:vep-groom` `<vep-pr-number>`** - Review a VEP proposal against template requirements and process guidelines
- **`/kubevirt:vep-list` `[--sig <sig>] [--release <version>] [--status <status>]`** - List open KubeVirt Enhancement Proposals (VEPs) with status and filtering
- **`/kubevirt:vep-review-list` `[username] [--release <version>]`** - List VEP proposal and implementation PRs for VEPs you are assigned to review
- **`/kubevirt:vep-summary` `<vep-number>`** - Get a TL;DR summary of a specific VEP and its current state

See [plugins/kubevirt/README.md](plugins/kubevirt/README.md) for detailed documentation.
