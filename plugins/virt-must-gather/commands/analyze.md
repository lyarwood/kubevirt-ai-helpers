---
description: Analyze KubeVirt must-gather archives
argument-hint: <path>
---

## Name
virt-must-gather:analyze

## Synopsis
```
/virt-must-gather:analyze <path>
```

## Description
The `virt-must-gather:analyze` command performs comprehensive analysis of KubeVirt must-gather diagnostic archives. It examines the collected data to identify virtualization issues, component failures, and configuration problems.

A must-gather archive typically contains:
- KubeVirt resource definitions (VMs, VMIs, VMIMs)
- KubeVirt component logs (virt-controller, virt-handler, virt-launcher)
- KubeVirt operator and configuration
- Related pod logs and events
- Node information and resource usage
- Network and storage configuration

This command provides:
- Cluster-wide virtualization health assessment
- Failed or problematic VMs identification
- Component error analysis across all namespaces
- Configuration issues and misconfigurations
- Resource constraint analysis
- Timeline of events leading to issues

The analysis helps:
- Identify root causes of virtualization failures
- Detect patterns across multiple VMs or nodes
- Find configuration drift or version mismatches
- Highlight resource exhaustion or capacity issues
- Provide actionable remediation steps

## Implementation
- Extracts and navigates must-gather archive structure
- Identifies KubeVirt-specific directories (namespaces, logs, resources)
- Parses VM/VMI/VMIM resource YAML files
- Analyzes virt-controller, virt-handler, virt-launcher logs
- Examines pod events and status
- Checks operator configuration and status
- Correlates events across components and namespaces
- Generates prioritized findings with severity levels
- Provides remediation recommendations

The command intelligently filters large log volumes to surface critical issues.

## Return Value
- **Claude agent analysis**: Comprehensive report including:
  - Executive summary of virtualization cluster health
  - List of failed or degraded VMs with root causes
  - Component-level issues (controller, handler, launcher)
  - Configuration problems and recommendations
  - Resource constraint warnings
  - Timeline of critical events
  - Prioritized remediation steps
  - Related log excerpts and evidence
  - Follow-up investigation commands

## Examples

1. **Analyze extracted must-gather directory**:
   ```
   /virt-must-gather:analyze /path/to/must-gather
   ```
   Analyzes a must-gather archive extracted to `/path/to/must-gather`.

2. **Analyze must-gather with timestamp directory**:
   ```
   /virt-must-gather:analyze /tmp/must-gather.local.1234567890
   ```
   Analyzes a must-gather with typical timestamped directory structure.

3. **Analyze compressed must-gather**:
   ```
   /virt-must-gather:analyze /downloads/must-gather.tar.gz
   ```
   Automatically extracts and analyzes compressed must-gather archive.

## Arguments
- `<path>`: (Required) Path to must-gather directory or archive file (.tar.gz, .tgz). Can be absolute or relative path.

## See Also
- `/virt-must-gather:vm-failure` - Quick analysis of specific VM failure
- `/kubevirt:vm-lifecycle-debug` - Debug live cluster VM issues
- `/kubevirt:analyze-virt-components` - Analyze live cluster components
