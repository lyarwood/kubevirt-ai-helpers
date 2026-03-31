---
description: Analyze recent runs and failure patterns for a specific CI job lane
argument-hint: <job-name> [--since <period>]
---

## Name
kubevirt:ci-lane

## Synopsis
```
/kubevirt:ci-lane <job-name> [--since <period>] [--type <job-type>]
```

## Description
The `kubevirt:ci-lane` command analyzes recent job runs for a specific CI lane by crawling live Prow data. It provides real-time failure analysis, pattern detection, and comprehensive statistics to help understand job stability and identify problematic tests.

This command uses the `healthcheck lane` tool to:
1. Fetch recent runs for the specified job from Prow
2. Parse JUnit test results and build logs
3. Identify failure patterns and trends
4. Categorize failures by type (infrastructure, test, flaky)
5. Provide actionable insights and recommendations

### Analysis Capabilities

#### Failure Pattern Detection
- Groups failures by test name to identify recurring issues
- Calculates failure frequency and rates
- Detects flaky tests (intermittent failures)
- Categorizes by component (migration, storage, compute, network, operator)

#### Statistics & Metrics
- Total runs analyzed with success/failure breakdown
- Failure rate percentage
- Job type distribution (presubmit, batch, periodic, postsubmit)
- Per-job-type failure rates
- Unique test failure counts

#### Time-Based Analysis
- Flexible time ranges (hours, days, weeks)
- Automatic pagination to fetch all results in period
- Trend detection (improving, stable, degrading)
- Duration calculations

## Implementation

### Phase 1: Prerequisites Check
1. Verify healthcheck CLI is available:
   ```bash
   which healthcheck || echo "healthcheck not found - install from repos/healthcheck"
   ```
2. Validate job name argument provided

### Phase 2: Fetch and Analyze Data
1. Run healthcheck lane command with summary mode:
   ```bash
   healthcheck lane <job-name> --since <period> --summary --output json
   ```
2. Parse JSON output containing:
   - Run statistics (total, successful, failed, unknown)
   - Failure rate and job type breakdown
   - Test failure counts and patterns
   - Individual run details with URLs

### Phase 3: Generate Report
Create a structured analysis report with:

1. **Executive Summary**
   - Job name and time range analyzed
   - Overall health status (healthy, unstable, unhealthy, critical)
   - Failure rate with trend indicator
   - Total runs vs failed runs

2. **Failure Analysis**
   - Most frequent failing tests (top 5-10)
   - Failure categories (migration, storage, compute, etc.)
   - Infrastructure vs test failures
   - Flaky test detection

3. **Pattern Recognition**
   - Identify if failures are concentrated or diverse
   - Detect systematic issues affecting multiple tests
   - Recognize infrastructure patterns (timeouts, OOM, disk space)

4. **Recommendations**
   - Prioritized action items
   - Tests to quarantine (if consistently flaky)
   - Infrastructure issues to address
   - Areas needing investigation

5. **Useful Links**
   - Failed job run URLs for debugging
   - Prow job history page
   - Related GitHub issues (if detected)

## Return Value
A comprehensive CI lane analysis report containing:
- **Summary**: Health status, failure rate, time range
- **Statistics**: Run counts, job type breakdown, failure metrics
- **Top Failures**: Most frequent failing tests with occurrence counts
- **Failure Categories**: Breakdown by component area
- **Pattern Analysis**: Flakiness detection, trend analysis
- **Recommendations**: Actionable next steps
- **Debug Links**: URLs to failed runs and relevant resources

## Examples

1. **Analyze recent runs (default last 10)**:
   ```
   /kubevirt:ci-lane pull-kubevirt-unit-test-arm64
   ```
   Analyzes the 10 most recent runs of the unit test job.

2. **Analyze last 24 hours**:
   ```
   /kubevirt:ci-lane pull-kubevirt-e2e-k8s-1.34-sig-compute --since 24h
   ```
   Fetches all runs from the last 24 hours with comprehensive analysis.

3. **Analyze last week for trending**:
   ```
   /kubevirt:ci-lane pull-kubevirt-e2e-k8s-1.32-sig-network --since 7d
   ```
   Provides weekly trend analysis for the network test suite.

4. **Filter by job type (batch jobs only)**:
   ```
   /kubevirt:ci-lane pull-kubevirt-e2e-k8s-1.34-sig-compute-arm64 --since 7d --type batch
   ```
   Analyzes only batch job runs for the specified period.

5. **Deep analysis of ARM64 stability**:
   ```
   /kubevirt:ci-lane pull-kubevirt-unit-test-arm64 --since 30d
   ```
   Month-long analysis to identify ARM64-specific issues.

## Arguments
- `<job-name>`: (Required) Name of the CI job to analyze (e.g., `pull-kubevirt-e2e-k8s-1.34-sig-compute`)
- `--since <period>`: (Optional) Time period to analyze (e.g., `24h`, `7d`, `30d`). Default: last 10 runs
- `--type <job-type>`: (Optional) Filter by job type: `batch`, `presubmit`, `periodic`, `postsubmit`

## Prerequisites
- The healthcheck CLI tool must be installed and available in PATH
- Internet connectivity to fetch data from Prow and ci-health sources

## Output Location
Write the analysis report to `artifacts/kubevirt-ci-lane/<job-name>-<timestamp>.md`

## See Also
- `/kubevirt:ci-health` - Overall CI health across all jobs
- `/kubevirt:ci-search` - Search for specific failure patterns
- `/kubevirt:ci-triage` - Intelligent failure triage with root cause analysis
- `/kubevirt:review-ci` - Review CI failures for a specific PR
- [Healthcheck Documentation](https://github.com/lyarwood/healthcheck)
