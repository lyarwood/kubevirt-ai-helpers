# Available Plugins

This document lists all available Claude Code plugins and their commands in the ai-helpers repository.

- [Hello World](#hello-world-plugin)
- [Kubevirt](#kubevirt-plugin)
- [Virt Must Gather](#virt-must-gather-plugin)

### Hello World Plugin

A hello world plugin

**Commands:**
- **`/hello-world:echo` `[name]`** - Hello world plugin implementation

See [plugins/hello-world/README.md](plugins/hello-world/README.md) for detailed documentation.

### Kubevirt Plugin

Core KubeVirt workflows for VM lifecycle debugging and component analysis

**Commands:**
- **`/kubevirt:analyze-virt-components` `[namespace]`** - Analyze virt-handler, virt-launcher, and virt-controller logs
- **`/kubevirt:vm-lifecycle-debug` `<vm-name> [namespace]`** - Debug VM creation, startup, and lifecycle issues
- **`/kubevirt:vm-migration-debug` `<vm-name> [namespace]`** - Debug VM migration failures and issues

See [plugins/kubevirt/README.md](plugins/kubevirt/README.md) for detailed documentation.

### Virt Must Gather Plugin

Analyze KubeVirt must-gather archives for VM diagnostics and troubleshooting

**Commands:**
- **`/virt-must-gather:analyze` `<path>`** - Analyze KubeVirt must-gather archives
- **`/virt-must-gather:vm-failure` `<vm-name> <path>`** - Quick analysis of specific VM failure from must-gather

See [plugins/virt-must-gather/README.md](plugins/virt-must-gather/README.md) for detailed documentation.
