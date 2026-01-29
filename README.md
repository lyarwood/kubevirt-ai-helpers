# KubeVirt AI Helpers

A collection of Claude Code plugins to automate and assist with KubeVirt development workflows.

## Overview

This project provides Claude Code plugins for KubeVirt development, including code review and linting workflows. For general Kubernetes, CI/CD, and development workflows, use the [OpenShift AI Helpers](https://github.com/openshift-eng/ai-helpers).

## Installation

### From the Claude Code Plugin Marketplace

1. **Add the marketplace:**
   ```bash
   /plugin marketplace add lyarwood/kubevirt-ai-helpers
   ```

2. **Install a plugin:**
   ```bash
   /plugin install kubevirt@kubevirt-ai-helpers
   ```

3. **Use the commands:**
   ```bash
   /kubevirt:review
   /kubevirt:lint pkg/virt-controller/watch
   /kubevirt:vep-list --release 1.9
   ```

## Related Helpers

This project is modeled after the [OpenShift AI Helpers](https://github.com/openshift-eng/ai-helpers) and focuses on KubeVirt-specific workflows.

### When to Use OpenShift AI Helpers

Use OpenShift AI Helpers for:
- **Jira workflows**: `/jira:solve`, `/jira:create`
- **Git operations**: `/git:commit-suggest`, `/git:branch-cleanup`
- **CI/CD**: `/ci:trigger-periodic`, `/prow-job:analyze-test-failure`
- **Generic must-gather**: `/must-gather:analyze`
- **Session management**: `/session:start`, `/session:resume`

### When to Use KubeVirt AI Helpers

Use KubeVirt AI Helpers for:
- **Code review**: Review local branch changes using KubeVirt project best practices
- **Linting**: Run golangci-lint and generate a plan to fix issues with separate commits per linter
- **VEP management**: List, summarize, and groom KubeVirt Enhancement Proposals (VEPs)

### Using Both Together

```bash
# Add both marketplaces
/plugin marketplace add openshift-eng/ai-helpers
/plugin marketplace add lyarwood/kubevirt-ai-helpers

# Install plugins from both
/plugin install jira@ai-helpers
/plugin install kubevirt@kubevirt-ai-helpers

# Use commands from both
/jira:solve OCPBUGS-12345 origin
/kubevirt:review
```

## Available Plugins

For a complete list of all available plugins and commands, see **[PLUGINS.md](PLUGINS.md)**.

## Plugin Development

Want to contribute or create your own plugins? Check out the `plugins/` directory for examples.
Make sure your commands and agents follow the conventions for the Sections structure presented in the hello-world reference implementation plugin (see [`hello-world:echo`](plugins/hello-world/commands/echo.md) for an example).

### Ethical Guidelines

Plugins, commands, skills, and hooks must NEVER reference real people by name, even as stylistic examples (e.g., "in the style of <specific human>").

**Ethical rationale:**
1. **Consent**: Individuals have not consented to have their identity or persona used in AI-generated content
2. **Misrepresentation**: AI cannot accurately replicate a person's unique voice, style, or intent
3. **Intellectual Property**: A person's distinctive style may be protected
4. **Dignity**: Using someone's identity without permission diminishes their autonomy

**Instead, describe specific qualities explicitly**

Good examples:

* "Write commit messages that are direct, technically precise, and focused on the rationale behind changes"
* "Explain using clear analogies, a sense of wonder, and accessible language for non-experts"
* "Code review comments that are encouraging, constructive, and focus on collaborative improvement"

When you identify a desirable characteristic (clarity, brevity, formality, humor, etc.), describe it explicitly rather than using a person as proxy.

### Adding New Commands

When contributing new commands:

1. **If your command fits an existing plugin**: Add it to the appropriate plugin's `commands/` directory
2. **If your command doesn't have a clear parent plugin**: Add it to the **utils plugin** (`plugins/utils/commands/`)
   - The utils plugin serves as a catch-all for commands that don't fit existing categories
   - Once we accumulate several related commands in utils, they can be segregated into a new targeted plugin

### Creating a New Plugin

If you're contributing several related commands that warrant their own plugin:

1. Create a new directory under `plugins/` with your plugin name
2. Create the plugin structure:
   ```
   plugins/your-plugin/
   ├── .claude-plugin/
   │   └── plugin.json
   └── commands/
       └── your-command.md
   ```
3. Register your plugin in `.claude-plugin/marketplace.json`

### Validating Plugins

This repository uses [claudelint](https://github.com/stbenjam/claudelint) to validate plugin structure:

```bash
make lint
```

### Updating Plugin Documentation

After adding or modifying plugins, regenerate the PLUGINS.md file:

```bash
make update
```

This automatically scans all plugins and regenerates the complete plugin/command documentation in PLUGINS.md.

## Additional Documentation

- **[PLUGINS.md](PLUGINS.md)** - Complete list of all available plugins and commands (auto-generated)
- **[AGENTS.md](AGENTS.md)** - Complete guide for AI agents working with this repository

## License

See [LICENSE](LICENSE) for details.
