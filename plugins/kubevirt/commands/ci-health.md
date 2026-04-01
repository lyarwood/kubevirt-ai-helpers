---
description: Analyze overall CI health across merge-time jobs with failure trending
argument-hint: [category] [--since <period>]
---

## Name
kubevirt:ci-health

## Synopsis
```
/kubevirt:ci-health [category] [--since <period>]
```

## Description
The `kubevirt:ci-health` command provides a quick overview of CI health across all merge-time jobs using pre-aggregated data from the kubevirt/ci-health project. It identifies trending failures, highlights quarantined tests, and helps prioritize CI maintenance work.

This command uses the `healthcheck merge` tool to:
1. Fetch aggregated failure data from ci-health API
2. Filter by job category (compute, network, storage, operator, release)
3. Count and rank test failures across jobs
4. Identify quarantined tests and their effectiveness
5. Detect failure patterns and trends

### Key Capabilities

#### Fast Aggregated Analysis
- Uses pre-computed ci-health data for speed
- Covers all merge-time jobs (main, release branches)
- No heavy Prow crawling required
- Limited to recent data (typically last 48 hours)

#### Failure Categorization
- Group by SIG area (compute, network, storage, operator)
- Filter by release branch (main, 1.6, 1.5, 1.4)
- Identify cross-job failures
- Detect systematic issues

#### Quarantine Intelligence
- Highlight quarantined tests
- Assess quarantine effectiveness
- Identify candidates for quarantine removal
- Track quarantine staleness

## Implementation

### Phase 1: Parse Arguments
1. Determine category filter (default: all jobs)
   - Aliases: `compute`, `network`, `storage`, `operator`, `main`, `1.6`, `1.5`, `1.4`
   - Custom regex patterns supported
2. Parse time period (default: all available ci-health data)

### Phase 2: Fetch CI Health Data
1. Run healthcheck merge command:
   ```bash
   healthcheck merge <category> --count --quarantine --output json
   ```
2. Parse JSON output containing:
   - Test failure counts grouped by test name
   - Failed job URLs
   - Quarantine status
   - Failure details with context

### Phase 3: Analyze Patterns
1. **Rank failures by frequency**
   - Sort tests by occurrence count
   - Identify top 10 most frequent failures
   - Calculate failure distribution

2. **Categorize failures**
   - Parse test names for SIG tags ([sig-compute], [sig-network], etc.)
   - Group by component (migration, storage, operator, networking)
   - Detect infrastructure patterns

3. **Assess quarantine status**
   - Identify quarantined tests still failing
   - Find tests that should be quarantined
   - Suggest quarantine removals for stable tests

4. **Cross-job correlation**
   - Find tests failing across multiple jobs
   - Identify environment-specific failures (ARM64 vs x86, K8s versions)
   - Detect systemic issues

### Phase 4: Generate Health Report
Create a comprehensive CI health report with:

1. **Executive Summary**
   - Overall CI health status
   - Total unique failures
   - Most impacted job categories
   - Quarantine effectiveness score

2. **Top Failures**
   - List top 10 most frequent failures
   - Occurrence count and affected jobs
   - Component categorization
   - Priority assessment

3. **Failure Distribution**
   - Breakdown by SIG/component
   - Percentage distribution chart
   - Concentration vs diversity analysis

4. **Quarantine Analysis**
   - Active quarantine count
   - Quarantined tests still failing
   - Suggestions for quarantine optimization

5. **Actionable Recommendations**
   - Prioritized list of actions
   - Tests to investigate immediately
   - Quarantine decisions to make
   - Infrastructure issues to address

## Return Value
A CI health overview report containing:
- **Health Status**: Overall health assessment (healthy, unstable, unhealthy, critical)
- **Summary Statistics**: Total failures, unique tests, affected jobs
- **Top Failures**: Most frequent failing tests with counts and URLs
- **Category Breakdown**: Failures grouped by SIG/component
- **Quarantine Report**: Active quarantines and effectiveness
- **Recommendations**: Prioritized action items
- **Trend Indicators**: Health direction (improving, stable, degrading)

## Examples

1. **Overall CI health check**:
   ```
   /kubevirt:ci-health
   ```
   Analyzes failures across all merge-time jobs.

2. **Compute SIG health**:
   ```
   /kubevirt:ci-health compute
   ```
   Focuses on sig-compute related jobs.

3. **Network SIG with quarantine analysis**:
   ```
   /kubevirt:ci-health network
   ```
   Analyzes network tests and quarantine effectiveness.

4. **Release 1.6 branch health**:
   ```
   /kubevirt:ci-health 1.6
   ```
   Checks health of release-1.6 jobs.

5. **Main branch health**:
   ```
   /kubevirt:ci-health main
   ```
   Analyzes main branch merge jobs.

6. **Storage jobs on ARM64**:
   ```
   /kubevirt:ci-health "sig-storage.*arm64"
   ```
   Custom regex to filter ARM64 storage jobs.

7. **Time-filtered health check**:
   ```
   /kubevirt:ci-health compute --since 24h
   ```
   Last 24 hours of compute job failures (limited by ci-health data availability).

## Arguments
- `[category]`: (Optional) Job category filter. Can be:
  - Predefined aliases: `compute`, `network`, `storage`, `operator`, `main`, `1.6`, `1.5`, `1.4`
  - Custom regex pattern (e.g., `"sig-compute.*arm64"`)
  - Default: all jobs (regex: `".*"`)
- `--since <period>`: (Optional) Time period filter (e.g., `24h`, `48h`). Note: Limited to available ci-health data

## Prerequisites
- The healthcheck CLI tool must be installed and available in PATH
- Internet connectivity to access kubevirt/ci-health API

## Output Location
Write the health report to `artifacts/kubevirt-ci-health/health-<category>-<timestamp>.md`

## See Also
- `/kubevirt:ci-lane` - Deep dive analysis of a specific job lane
- `/kubevirt:ci-search` - Search for specific failure patterns across jobs
- `/kubevirt:ci-triage` - Intelligent failure triage and root cause analysis
- `/kubevirt:ci-report` - Generate comprehensive stakeholder reports
- [KubeVirt CI Health](https://github.com/kubevirt/ci-health)
- [Healthcheck Tool](https://github.com/lyarwood/healthcheck)
