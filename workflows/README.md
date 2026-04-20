# Ambient Workflows

These workflows wrap the KubeVirt Claude Code plugin commands for use on the [Ambient Code Platform](https://github.com/ambient-code). Each workflow can be attached to an Ambient session to provide a guided, structured experience.

## Available Workflows

| Workflow | Description |
|----------|-------------|
| `kubevirt-dev` | Complete development workflow with automated sensor feedback loops |
| `kubevirt-review` | Review branch changes using KubeVirt coding conventions |
| `kubevirt-lint` | Run golangci-lint and fix issues with separate commits per linter |
| `kubevirt-review-ci` | Analyze CI failures for a KubeVirt PR |
| `kubevirt-vep-list` | List VEPs with filtering by SIG, release, or status |
| `kubevirt-vep-summary` | Get a TL;DR summary of a specific VEP |
| `kubevirt-vep-groom` | Review a VEP PR against template and process requirements |
| `kubevirt-ci-lane` | Analyze specific CI job lane with failure patterns and statistics |
| `kubevirt-ci-health` | Quick overview of CI health across all merge-time jobs |
| `kubevirt-ci-search` | Search for specific test failures across all CI jobs |
| `kubevirt-ci-triage` | Intelligent CI failure triage with root cause analysis |
| `kubevirt-ci-report` | Generate comprehensive CI health reports for stakeholders |

## Usage

When creating an Ambient session, specify the workflow:

```
workflow_git_url: https://github.com/lyarwood/kubevirt-ai-helpers.git
workflow_path: workflows/kubevirt-review
workflow_branch: main
```

Or use the ACP API:

```bash
curl -X POST "$BASE_URL/projects/$PROJECT/agentic-sessions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $BOT_TOKEN" \
  -d '{
    "sessionName": "review-my-pr",
    "displayName": "KubeVirt Code Review",
    "repos": [{"url": "https://github.com/kubevirt/kubevirt", "branch": "my-feature-branch"}],
    "workflowGitUrl": "https://github.com/lyarwood/kubevirt-ai-helpers.git",
    "workflowPath": "workflows/kubevirt-review",
    "workflowBranch": "main"
  }'
```

## Structure

Each workflow contains:

```
workflows/<name>/
├── .ambient/
│   └── ambient.json    # Workflow config (name, description, systemPrompt, startupPrompt)
└── CLAUDE.md           # Optional behavioral guidelines
```

The `systemPrompt` in each `ambient.json` references the corresponding command definition in `plugins/kubevirt/commands/` for the full methodology. The kubevirt-ai-helpers repository should be added alongside the target repository so the agent can read these definitions.

## Relationship to Plugin Commands

These workflows are Ambient-native wrappers around the same commands available as Claude Code plugins:

| Workflow | Plugin Command |
|----------|---------------|
| `kubevirt-dev` | `/kubevirt:dev` |
| `kubevirt-review` | `/kubevirt:review` |
| `kubevirt-lint` | `/kubevirt:lint` |
| `kubevirt-review-ci` | `/kubevirt:review-ci` |
| `kubevirt-vep-list` | `/kubevirt:vep-list` |
| `kubevirt-vep-summary` | `/kubevirt:vep-summary` |
| `kubevirt-vep-groom` | `/kubevirt:vep-groom` |
| `kubevirt-ci-lane` | `/kubevirt:ci-lane` |
| `kubevirt-ci-health` | `/kubevirt:ci-health` |
| `kubevirt-ci-search` | `/kubevirt:ci-search` |
| `kubevirt-ci-triage` | `/kubevirt:ci-triage` |
| `kubevirt-ci-report` | `/kubevirt:ci-report` |
