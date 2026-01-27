---
description: Debug VM migration failures and issues
argument-hint: <vm-name> [namespace]
---

## Name
kubevirt:vm-migration-debug

## Synopsis
```
/kubevirt:vm-migration-debug <vm-name> [namespace]
```

## Description
The `kubevirt:vm-migration-debug` command analyzes and troubleshoots virtual machine migration failures in a KubeVirt environment. It investigates issues related to live migration, including migration timeouts, failures, and performance problems.

This command provides comprehensive analysis of:
- VirtualMachineInstanceMigration (VMIM) resource status
- Migration phase, conditions, and events
- Source and target virt-launcher pod logs
- virt-handler logs on both source and target nodes
- Migration method (live migration vs. block migration)
- Network connectivity between nodes
- Storage configuration and compatibility
- Resource availability on target node

The command follows a systematic troubleshooting approach:
1. Identify active or recent migration attempts
2. Check VMIM resource status and conditions
3. Analyze migration timeline and phase transitions
4. Examine virt-launcher logs on source and target nodes
5. Review virt-handler logs for migration orchestration
6. Check network and storage prerequisites
7. Identify common migration blockers

## Implementation
- Uses `kubectl get vmim -n <namespace>` to find migration resources for the VM
- Uses `kubectl describe vmim` to get detailed migration events and conditions
- Identifies source and target virt-launcher pods
- Retrieves logs from both source and target virt-launcher pods
- Identifies source and target nodes and retrieves virt-handler logs
- Checks for migration prerequisites (shared storage, network configuration)
- Analyzes migration method and configuration
- Presents findings with root cause analysis and remediation steps

The command correlates information across multiple resources to identify why migrations fail or perform poorly.

## Return Value
- **Claude agent analysis**: Comprehensive migration report including:
  - Migration status and current phase
  - Migration timeline with phase transitions
  - Source and target node information
  - Critical log excerpts from virt-launcher and virt-handler
  - Network and storage configuration analysis
  - Identified blockers or performance issues
  - Root cause analysis
  - Recommended remediation steps
  - Related debugging commands

## Examples

1. **Debug migration in default namespace**:
   ```
   /kubevirt:vm-migration-debug my-vm
   ```
   Analyzes migration status for "my-vm" in the default namespace.

2. **Debug migration in specific namespace**:
   ```
   /kubevirt:vm-migration-debug my-vm production
   ```
   Analyzes migration for "my-vm" in the "production" namespace.

3. **Debug stuck or failed migration**:
   ```
   /kubevirt:vm-migration-debug failing-migration test-ns
   ```
   Investigates why migration for "failing-migration" is stuck or failed.

## Arguments
- `<vm-name>`: (Required) Name of the VirtualMachine or VirtualMachineInstance being migrated
- `[namespace]`: (Optional) Kubernetes namespace containing the VM. Defaults to current context namespace or "default"

## See Also
- `/kubevirt:vm-lifecycle-debug` - Debug VM creation and startup issues
- `/kubevirt:analyze-virt-components` - Analyze KubeVirt component health
- `/virt-must-gather:vm-failure` - Analyze VM failures from must-gather
