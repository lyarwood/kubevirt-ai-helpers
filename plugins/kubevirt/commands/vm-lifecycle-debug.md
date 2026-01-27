---
description: Debug VM creation, startup, and lifecycle issues
argument-hint: <vm-name> [namespace]
---

## Name
kubevirt:vm-lifecycle-debug

## Synopsis
```
/kubevirt:vm-lifecycle-debug <vm-name> [namespace]
```

## Description
The `kubevirt:vm-lifecycle-debug` command analyzes and debugs virtual machine lifecycle issues in a KubeVirt environment. It investigates problems related to VM creation, startup, shutdown, and general lifecycle management.

This command provides comprehensive analysis of:
- VM and VMI (VirtualMachineInstance) resource status and events
- virt-launcher pod status and logs
- virt-handler logs on the node where the VM is scheduled
- virt-controller logs related to the VM
- Resource allocation and scheduling issues
- Node readiness and kubevirt component health

The command follows a systematic troubleshooting approach:
1. Verify VM and VMI resource existence and current state
2. Check events on VM, VMI, and related pods
3. Analyze virt-launcher pod logs for startup/runtime issues
4. Examine virt-handler logs on the hosting node
5. Review virt-controller logs for orchestration issues
6. Identify common problems (resource constraints, image pull failures, network issues)

## Implementation
- Uses `kubectl get vm <vm-name> -n <namespace>` to retrieve VM status
- Uses `kubectl get vmi <vm-name> -n <namespace>` to retrieve VMI status
- Uses `kubectl describe vm/vmi` to get detailed events
- Identifies virt-launcher pod with `kubectl get pods -l kubevirt.io/vm=<vm-name>`
- Retrieves virt-launcher logs with `kubectl logs`
- Identifies the node running the VM and retrieves virt-handler logs
- Analyzes virt-controller logs for orchestration issues
- Presents findings with actionable recommendations

The command synthesizes information from multiple sources to identify root causes and suggest remediation steps.

## Return Value
- **Claude agent analysis**: Comprehensive report including:
  - Current VM/VMI state and phase
  - Recent events timeline
  - Critical log excerpts from virt-launcher, virt-handler, virt-controller
  - Identified issues and root cause analysis
  - Recommended remediation steps
  - Related troubleshooting commands

## Examples

1. **Debug VM in default namespace**:
   ```
   /kubevirt:vm-lifecycle-debug my-vm
   ```
   Analyzes the VM named "my-vm" in the default namespace.

2. **Debug VM in specific namespace**:
   ```
   /kubevirt:vm-lifecycle-debug my-vm production
   ```
   Analyzes the VM named "my-vm" in the "production" namespace.

3. **Debug VM failing to start**:
   ```
   /kubevirt:vm-lifecycle-debug failing-vm test-ns
   ```
   Investigates why "failing-vm" in "test-ns" namespace is not starting.

## Arguments
- `<vm-name>`: (Required) Name of the VirtualMachine resource to debug
- `[namespace]`: (Optional) Kubernetes namespace containing the VM. Defaults to current context namespace or "default"

## See Also
- `/kubevirt:analyze-virt-components` - Analyze KubeVirt component logs
- `/kubevirt:vm-migration-debug` - Debug VM migration issues
- `/virt-must-gather:vm-failure` - Analyze VM failures from must-gather archive
