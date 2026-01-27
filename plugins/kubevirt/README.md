# KubeVirt Plugin

Core KubeVirt workflows for debugging VM lifecycle issues, analyzing virtualization components, and troubleshooting migrations.

## Commands

### `/kubevirt:vm-lifecycle-debug`

Debug VM creation, startup, shutdown, and lifecycle issues. Analyzes VM/VMI resources, virt-launcher pods, virt-handler logs, and virt-controller orchestration.

**Usage:**
```bash
/kubevirt:vm-lifecycle-debug <vm-name> [namespace]
```

### `/kubevirt:analyze-virt-components`

Analyze health and logs of KubeVirt virtualization components (virt-controller, virt-handler, virt-launcher). Identifies component failures, resource issues, and configuration problems.

**Usage:**
```bash
/kubevirt:analyze-virt-components [namespace]
```

### `/kubevirt:vm-migration-debug`

Debug VM migration failures, timeouts, and performance issues. Analyzes migration resources, source/target node logs, network connectivity, and storage configuration.

**Usage:**
```bash
/kubevirt:vm-migration-debug <vm-name> [namespace]
```

## Installation

```bash
/plugin install kubevirt@kubevirt-ai-helpers
```

## Common Workflows

### Troubleshooting a VM that won't start
```bash
/kubevirt:vm-lifecycle-debug my-vm production
```

### Investigating cluster-wide virtualization issues
```bash
/kubevirt:analyze-virt-components kubevirt
```

### Debugging a failed live migration
```bash
/kubevirt:vm-migration-debug my-vm production
```

## See Also

For complete command documentation, see the individual command files in the `commands/` directory.
