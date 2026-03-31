---
description: Intelligent CI failure triage with root cause analysis and prioritized recommendations
argument-hint: <job-or-category> [--context <context>]
---

## Name
kubevirt:ci-triage

## Synopsis
```
/kubevirt:ci-triage <job-or-category> [--context <context>] [--deep-analysis]
```

## Description
The `kubevirt:ci-triage` command performs intelligent CI failure triage using AI-powered analysis capabilities from the healthcheck MCP server. It goes beyond simple failure counting to provide root cause analysis, impact assessment, and prioritized recommendations for addressing CI failures.

This command leverages multiple healthcheck MCP tools to:
1. Fetch comprehensive failure data for the target job or category
2. Analyze failure trends and detect flakiness patterns
3. Perform cross-job correlation to identify systemic issues
4. Assess business impact based on context (production, development, pre-release)
5. Generate prioritized triage recommendations with resource allocation guidance

### Advanced Analysis Features

#### Root Cause Analysis
- Parse failure logs and stack traces
- Identify common error patterns
- Distinguish infrastructure vs code issues
- Extract file locations and error messages
- Generate GitHub URLs for source code review

#### Trend & Flakiness Detection
- Historical trend analysis (improving, stable, degrading)
- Flakiness scoring (10-90% failure rate patterns)
- Frequency analysis over time
- Regression detection

#### Cross-Job Correlation
- Identify failures affecting multiple jobs
- Environment-specific patterns (ARM64 vs x86)
- Kubernetes version correlation
- Resource issue detection (CPU, memory, disk)

#### Impact Assessment
- Context-aware prioritization (production vs development)
- Business impact scoring (critical path vs edge cases)
- Urgency classification (urgent, normal, low)
- Resource allocation recommendations (senior engineer vs standard triage)

#### Quarantine Intelligence
- Effectiveness scoring for current quarantines
- Recommendations for quarantine decisions (add, remove, extend)
- Active vs stale quarantine identification
- CI health impact analysis

## Implementation

### Phase 1: Data Collection
1. Determine target scope (specific job or category)
2. Fetch failure data using appropriate healthcheck command:
   ```bash
   # For specific job
   healthcheck lane <job-name> --since 7d --output json

   # For category
   healthcheck merge <category> --output json
   ```
3. Parse JSON output for baseline analysis

### Phase 2: Deep Analysis (uses healthcheck MCP server)
1. **Fetch detailed logs for top failures**:
   - Use `fetch_job_run_logs` to get junit and build logs
   - Parse stack traces and error messages
   - Generate source code links with `get_failure_source_context`

2. **Analyze trends**:
   - Call `analyze_failure_trends` with 14-30 day period
   - Detect flaky tests and regression patterns
   - Identify trend direction

3. **Perform correlation analysis**:
   - Use `analyze_failure_correlation` across related jobs
   - Identify systemic issues
   - Detect environment-specific problems

4. **Assess impact**:
   - Call `assess_failure_impact` with context parameter
   - Get business impact scores
   - Receive triage priority recommendations

5. **Review quarantine status**:
   - Use `analyze_quarantine_intelligence` for affected tests
   - Get effectiveness scores
   - Receive quarantine action recommendations

### Phase 3: Root Cause Investigation
For each top failure:
1. Extract error messages and stack traces
2. Identify file locations (file:line patterns)
3. Generate GitHub source URLs
4. Classify failure type:
   - Infrastructure (timeout, OOM, disk space, image pull)
   - Code bug (assertion failure, panic, logic error)
   - Flaky test (intermittent, timing-dependent)
   - Environment-specific (ARM64, K8s version)

### Phase 4: Generate Triage Report
Create comprehensive triage report with:

1. **Executive Summary**
   - CI health status for target scope
   - Total failures and urgency level
   - Top 3 priority actions
   - Resource allocation recommendation

2. **Prioritized Failure List**
   - Sorted by: impact × frequency × urgency
   - For each failure:
     - Test name and failure count
     - Priority (urgent, normal, low)
     - Root cause hypothesis
     - Affected jobs and environments
     - Source code locations with GitHub links
     - Recommended action and assignee level

3. **Trend Analysis**
   - Overall health direction (improving/stable/degrading)
   - Regression detection
   - Flaky test identification with scores
   - Historical context

4. **Correlation Findings**
   - Systemic issues affecting multiple jobs
   - Environment-specific patterns
   - Resource-related failures
   - Infrastructure problems

5. **Quarantine Recommendations**
   - Tests to quarantine (with effectiveness prediction)
   - Quarantines to remove (stable tests)
   - Quarantines to extend (still problematic)

6. **Action Plan**
   - Immediate actions (urgent priority)
   - Short-term tasks (this sprint)
   - Long-term improvements (technical debt)
   - Resource requirements

7. **Debug Resources**
   - Failed run URLs
   - Source code links
   - Related issues
   - Documentation references

## Return Value
A comprehensive triage report containing:
- **Summary**: Health status, priority assessment, resource needs
- **Prioritized Failures**: Sorted by impact with root cause analysis
- **Trend Analysis**: Direction, regression detection, flakiness scores
- **Correlation Findings**: Systemic issues and environment patterns
- **Quarantine Intelligence**: Effectiveness and recommendations
- **Action Plan**: Prioritized tasks with resource allocation
- **Debug Resources**: Links to logs, source code, and documentation

## Examples

1. **Triage a specific job**:
   ```
   /kubevirt:ci-triage pull-kubevirt-e2e-k8s-1.34-sig-compute
   ```
   Comprehensive triage for the compute test suite.

2. **Triage with production context**:
   ```
   /kubevirt:ci-triage pull-kubevirt-e2e-k8s-1.34-sig-compute --context production
   ```
   Higher urgency prioritization for production-bound failures.

3. **Triage pre-release context**:
   ```
   /kubevirt:ci-triage main --context pre-release
   ```
   Triage main branch failures with release-blocking focus.

4. **Triage a SIG category**:
   ```
   /kubevirt:ci-triage compute
   ```
   Analyzes all compute-related jobs for systemic issues.

5. **Deep analysis with full MCP capabilities**:
   ```
   /kubevirt:ci-triage pull-kubevirt-unit-test-arm64 --deep-analysis
   ```
   Performs extensive correlation and trend analysis.

6. **Triage network tests for development**:
   ```
   /kubevirt:ci-triage network --context development
   ```
   Standard priority for development context.

## Arguments
- `<job-or-category>`: (Required) Specific job name or category (compute, network, storage, operator, main, release version)
- `--context <context>`: (Optional) Triage context for prioritization:
  - `production`: Highest urgency, blocking production deployments
  - `pre-release`: High urgency, blocking release candidates
  - `development`: Standard urgency (default)
- `--deep-analysis`: (Optional) Enable full correlation and trend analysis across related jobs

## Prerequisites
- The healthcheck CLI tool must be installed and available in PATH
- For deep analysis, the healthcheck MCP server capabilities are used
- Internet connectivity to fetch CI data
- GitHub API access for source code link generation

## Output Location
Write the triage report to `artifacts/kubevirt-ci-triage/triage-<target>-<timestamp>.md`

## Performance Considerations
- Basic triage: Fast (1-2 minutes)
- Deep analysis: Slower (3-5 minutes) due to MCP tool invocations
- Large time windows increase analysis time
- Consider starting with recent data (7d) then expanding if needed

## See Also
- `/kubevirt:ci-lane` - Analyze a specific job lane
- `/kubevirt:ci-health` - Overall CI health overview
- `/kubevirt:ci-search` - Search for specific failure patterns
- `/kubevirt:ci-report` - Generate stakeholder reports
- `/kubevirt:review-ci` - Review CI failures for a PR
- [Healthcheck MCP Tools](https://github.com/lyarwood/healthcheck#mcp-command)
