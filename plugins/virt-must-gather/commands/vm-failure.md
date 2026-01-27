---
description: Quick analysis of specific VM failure from must-gather
argument-hint: <vm-name> <path>
---

## Name
virt-must-gather:vm-failure

## Synopsis
```
/virt-must-gather:vm-failure <vm-name> <path>
```

## Description
The `virt-must-gather:vm-failure` command provides focused, rapid analysis of a specific virtual machine failure within a KubeVirt must-gather archive. It's optimized for quickly diagnosing individual VM issues without analyzing the entire cluster.

This command examines:
- VM and VMI resource definitions and status
- Events related to the specific VM
- virt-launcher pod logs for the VM
- virt-handler logs on the node hosting the VM
- virt-controller logs mentioning the VM
- Related migration resources if applicable
- Node conditions and resource availability

The command provides:
- Quick root cause identification for VM failures
- Timeline of events specific to the VM
- Relevant log excerpts filtered for the VM
- Resource and scheduling issues
- Configuration problems
- Targeted remediation steps

This is ideal when:
- You know which VM failed and want quick diagnosis
- You want to avoid analyzing the entire cluster
- You need to triage multiple VM failures individually
- You want to share focused analysis for a single VM

## Implementation
- Searches must-gather archive for VM and VMI resources matching `<vm-name>`
- Extracts VM/VMI YAML and status information
- Filters events for the specific VM
- Locates and analyzes virt-launcher pod logs for the VM
- Identifies hosting node and retrieves relevant virt-handler logs
- Searches virt-controller logs for VM-specific entries
- Builds timeline of VM lifecycle events
- Provides focused root cause analysis

The command uses grep, jq, and other tools to efficiently filter large must-gather archives for VM-specific data.

## Return Value
- **Claude agent analysis**: Focused VM failure report including:
  - VM status and current/last known phase
  - Timeline of VM-specific events
  - Relevant log excerpts from virt-launcher
  - virt-handler logs related to this VM
  - virt-controller entries mentioning the VM
  - Root cause analysis
  - Configuration or resource issues
  - Specific remediation steps for this VM
  - Related debugging information

## Examples

1. **Analyze specific VM failure**:
   ```
   /virt-must-gather:vm-failure my-failed-vm /path/to/must-gather
   ```
   Quickly analyzes why "my-failed-vm" failed.

2. **Analyze VM in must-gather archive**:
   ```
   /virt-must-gather:vm-failure problematic-vm /tmp/must-gather.local.1234567890
   ```
   Analyzes "problematic-vm" from timestamped must-gather.

3. **Triage multiple VM failures**:
   ```
   /virt-must-gather:vm-failure vm-1 /path/to/must-gather
   /virt-must-gather:vm-failure vm-2 /path/to/must-gather
   /virt-must-gather:vm-failure vm-3 /path/to/must-gather
   ```
   Individually analyzes three different VM failures from the same must-gather.

## Arguments
- `<vm-name>`: (Required) Name of the VirtualMachine to analyze
- `<path>`: (Required) Path to must-gather directory or archive file

## See Also
- `/virt-must-gather:analyze` - Comprehensive cluster-wide analysis
- `/kubevirt:vm-lifecycle-debug` - Debug VM in live cluster
- `/kubevirt:vm-migration-debug` - Debug VM migration issues
