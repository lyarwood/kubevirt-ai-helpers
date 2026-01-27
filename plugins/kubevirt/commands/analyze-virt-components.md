---
description: Analyze virt-handler, virt-launcher, and virt-controller logs
argument-hint: [namespace]
---

## Name
kubevirt:analyze-virt-components

## Synopsis
```
/kubevirt:analyze-virt-components [namespace]
```

## Description
The `kubevirt:analyze-virt-components` command performs comprehensive analysis of KubeVirt virtualization component logs and health status. It examines the three core KubeVirt components:

- **virt-controller**: Cluster-wide VM lifecycle management and orchestration
- **virt-handler**: Node-level VM management daemon (DaemonSet)
- **virt-launcher**: Per-VM pod that manages individual VM processes

This command provides:
- Health status of all KubeVirt components
- Recent error and warning messages from component logs
- Component restart counts and crash loops
- Resource usage patterns
- Version information and component readiness
- Cross-component correlation of issues

The analysis helps identify:
- Component failures or degraded states
- Configuration issues
- Resource exhaustion
- Network or storage problems affecting virtualization
- Version mismatches or upgrade issues

## Implementation
- Uses `kubectl get pods -n <namespace>` to list all KubeVirt component pods
- Retrieves logs from virt-controller deployment
- Retrieves logs from all virt-handler DaemonSet pods
- Retrieves logs from virt-launcher pods if present
- Filters for ERROR, WARN, and FATAL messages
- Analyzes pod restart counts and status
- Checks resource limits and actual usage
- Presents consolidated findings with timeline correlation

The command intelligently filters noise and highlights actionable issues.

## Return Value
- **Claude agent analysis**: Detailed report including:
  - Component health summary (running/failed/degraded)
  - Critical error messages from each component
  - Pod restart history and crash loop analysis
  - Resource constraint warnings
  - Network or API connectivity issues
  - Recommended actions to resolve identified problems
  - Commands for deeper investigation

## Examples

1. **Analyze components in kubevirt namespace**:
   ```
   /kubevirt:analyze-virt-components kubevirt
   ```
   Analyzes all KubeVirt components in the "kubevirt" namespace.

2. **Analyze components in default installation namespace**:
   ```
   /kubevirt:analyze-virt-components
   ```
   Analyzes components in the default or current namespace context.

3. **Investigate cluster-wide virtualization issues**:
   ```
   /kubevirt:analyze-virt-components openshift-cnv
   ```
   Analyzes OpenShift CNV virtualization components.

## Arguments
- `[namespace]`: (Optional) Kubernetes namespace where KubeVirt is installed. Common values: "kubevirt", "openshift-cnv". Defaults to current context namespace.

## See Also
- `/kubevirt:vm-lifecycle-debug` - Debug specific VM lifecycle issues
- `/kubevirt:vm-migration-debug` - Debug VM migration failures
- `/virt-must-gather:analyze` - Analyze complete must-gather archive
