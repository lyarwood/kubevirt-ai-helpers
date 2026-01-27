# Virt Must-Gather Plugin

Analyze KubeVirt must-gather diagnostic archives to troubleshoot VM failures, component issues, and configuration problems.

## Commands

### `/virt-must-gather:analyze`

Perform comprehensive analysis of a complete KubeVirt must-gather archive. Examines cluster-wide virtualization health, identifies failed VMs, analyzes component logs, and provides prioritized remediation steps.

**Usage:**
```bash
/virt-must-gather:analyze <path>
```

### `/virt-must-gather:vm-failure`

Quick, focused analysis of a specific VM failure within a must-gather archive. Provides rapid root cause diagnosis without analyzing the entire cluster.

**Usage:**
```bash
/virt-must-gather:vm-failure <vm-name> <path>
```

## Installation

```bash
/plugin install virt-must-gather@kubevirt-ai-helpers
```

## Common Workflows

### Analyze complete must-gather for cluster-wide issues
```bash
/virt-must-gather:analyze /path/to/must-gather
```

### Quick diagnosis of specific VM failure
```bash
/virt-must-gather:vm-failure my-failed-vm /path/to/must-gather
```

### Triage multiple VM failures from same must-gather
```bash
/virt-must-gather:vm-failure vm-1 /path/to/must-gather
/virt-must-gather:vm-failure vm-2 /path/to/must-gather
```

## About Must-Gather Archives

KubeVirt must-gather archives are created using:
```bash
oc adm must-gather --image=quay.io/kubevirt/must-gather
```

Or for OpenShift CNV:
```bash
oc adm must-gather --image=registry.redhat.io/container-native-virtualization/cnv-must-gather-rhel9
```

These archives contain comprehensive diagnostic data including:
- All KubeVirt resources (VMs, VMIs, VMIMs)
- Component logs (virt-controller, virt-handler, virt-launcher)
- Operator configuration and status
- Node information and capacity
- Network and storage configuration
- Events and pod status

## See Also

For complete command documentation, see the individual command files in the `commands/` directory.
