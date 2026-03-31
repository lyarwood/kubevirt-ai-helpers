---
description: Generate comprehensive CI health reports for stakeholders
argument-hint: [--scope <scope>] [--format <format>]
---

## Name
kubevirt:ci-report

## Synopsis
```
/kubevirt:ci-report [--scope <scope>] [--format <format>] [--recipient <audience>]
```

## Description
The `kubevirt:ci-report` command generates comprehensive CI health reports optimized for different stakeholders and purposes. It consolidates data from multiple sources to provide executive summaries, detailed analyses, and actionable insights for CI/CD pipeline health management.

This command leverages healthcheck MCP tools to:
1. Aggregate CI health data across all relevant jobs
2. Generate trend analysis and health metrics
3. Identify critical issues and recommendations
4. Format reports for different audiences (executives, engineers, release managers)
5. Provide actionable next steps with prioritization

### Report Capabilities

#### Multiple Formats
- **Summary**: Concise overview with key metrics (1-2 pages)
- **Detailed**: Comprehensive analysis with all findings (5-10 pages)
- **Executive**: High-level status for leadership (1 page)
- **Release**: Pre-release health assessment (3-5 pages)

#### Flexible Scopes
- **Daily**: Last 24 hours of CI activity
- **Weekly**: 7-day rolling health report
- **Release**: Health assessment for upcoming release
- **Custom Job**: Focus on specific job or category

#### Stakeholder Optimization
- **Engineering teams**: Technical details, root causes, debug links
- **Management**: Executive summaries, trend indicators, resource needs
- **Release managers**: Blocking issues, risk assessment, go/no-go recommendations
- **SRE teams**: Infrastructure issues, capacity problems, monitoring gaps

### Report Sections

#### Executive Summary
- Overall CI health status (healthy, unstable, unhealthy, critical)
- Key metrics dashboard (failure rates, test counts, job stability)
- Top 3 priority issues requiring attention
- Trend indicator (improving, stable, degrading)
- Recommended actions and resource allocation

#### Health Metrics
- Total jobs monitored
- Overall pass/fail rates
- Failure rate trends (vs previous period)
- Quarantine effectiveness
- Infrastructure issue counts

#### Category Breakdown
- Health by SIG (compute, network, storage, operator)
- Per-category failure rates
- Top failing tests per category
- Category-specific trends

#### Critical Issues
- Failures blocking merges or releases
- High-frequency failures (> 10 occurrences)
- New regressions
- Infrastructure problems
- Security or compliance concerns

#### Trend Analysis
- Week-over-week health changes
- Improving areas
- Degrading areas
- Flaky test evolution
- Quarantine changes

#### Quarantine Report
- Active quarantines count
- Quarantine effectiveness scores
- Recommendations for quarantine changes
- Tests approaching quarantine threshold

#### Action Items
- Immediate actions (urgent priority)
- This week's tasks (normal priority)
- Ongoing improvements (long-term)
- Resource requirements

#### Appendices (Detailed format only)
- Full failure lists with URLs
- Stack traces and error messages
- Source code links
- Related GitHub issues

## Implementation

### Phase 1: Define Report Scope
1. Parse scope parameter:
   - `daily`: Last 24 hours
   - `weekly`: Last 7 days
   - `release`: All blocking jobs, extended time window
   - `<job-name>`: Specific job or category
2. Determine target audience and format
3. Calculate time windows for trend comparison

### Phase 2: Collect Data
1. **Current period data**:
   ```bash
   healthcheck merge ".*" --output json > current.json
   ```

2. **Historical data for trends**:
   ```bash
   # For weekly report, get previous week
   healthcheck lane <critical-jobs> --since 14d --output json > historical.json
   ```

3. **Use MCP tools for advanced analysis**:
   - `generate_failure_report` with appropriate scope
   - `analyze_failure_trends` for key jobs
   - `analyze_quarantine_intelligence` for quarantine status
   - `analyze_failure_correlation` for systemic issues

### Phase 3: Analyze and Synthesize
1. **Calculate health metrics**:
   - Aggregate pass/fail rates
   - Compute trend percentages
   - Determine health status (critical < 50%, unhealthy < 70%, unstable < 85%, healthy >= 85%)

2. **Identify critical issues**:
   - Failures with > 10 occurrences
   - New failures (not in previous period)
   - Blocking jobs with failures
   - Infrastructure issues

3. **Generate trend analysis**:
   - Compare current vs previous period
   - Calculate percentage changes
   - Identify improving/degrading areas
   - Detect regressions

4. **Prioritize action items**:
   - Score by: impact × frequency × urgency
   - Categorize: urgent, this-week, ongoing
   - Assign resource recommendations

### Phase 4: Format for Audience
1. **Executive format**:
   - Lead with health status and trend
   - 3-5 key metrics only
   - Top 3 issues with one-line descriptions
   - Go/no-go recommendation (for release scope)
   - Resource request summary

2. **Summary format**:
   - 1-2 page overview
   - Health metrics dashboard
   - Top 10 issues
   - Action items
   - Minimal technical details

3. **Detailed format**:
   - Full analysis with all sections
   - Technical deep-dives
   - Complete failure lists
   - Stack traces and logs
   - Source code links

4. **Release format**:
   - Focus on blocking issues
   - Risk assessment
   - Comparison to previous releases
   - Go/no-go recommendation with reasoning
   - Mitigation strategies

### Phase 5: Generate Output
1. Write formatted report to artifacts
2. Create summary markdown
3. Optionally generate JSON for automation
4. Provide shareable links

## Return Value
A comprehensive CI health report containing:
- **Executive Summary**: Status, trends, top issues, recommendations
- **Health Metrics**: Pass/fail rates, job counts, trend indicators
- **Category Breakdown**: Per-SIG analysis
- **Critical Issues**: Prioritized problem list
- **Trend Analysis**: Historical comparisons
- **Quarantine Report**: Active quarantines and recommendations
- **Action Items**: Prioritized tasks with resource needs
- **Appendices**: Detailed data (detailed format only)

## Examples

1. **Daily health report**:
   ```
   /kubevirt:ci-report --scope daily --format summary
   ```
   Quick morning health check for the team.

2. **Weekly executive report**:
   ```
   /kubevirt:ci-report --scope weekly --format executive --recipient management
   ```
   High-level status for engineering leadership.

3. **Pre-release health assessment**:
   ```
   /kubevirt:ci-report --scope release --format release --recipient release-team
   ```
   Comprehensive release readiness report.

4. **Detailed weekly analysis for engineers**:
   ```
   /kubevirt:ci-report --scope weekly --format detailed --recipient engineering
   ```
   Full technical report with all details.

5. **Compute SIG health report**:
   ```
   /kubevirt:ci-report --scope compute --format summary
   ```
   Focus on compute-related jobs.

6. **Monthly trend report**:
   ```
   /kubevirt:ci-report --scope "30d" --format detailed
   ```
   Long-term trend analysis.

## Arguments
- `--scope <scope>`: (Optional) Report scope. Options:
  - `daily`: Last 24 hours (default)
  - `weekly`: Last 7 days
  - `release`: All blocking jobs for upcoming release
  - `<job-name>`: Specific job or category
  - `<period>`: Custom time period (e.g., `30d`, `2w`)
- `--format <format>`: (Optional) Report format:
  - `summary`: Concise overview (default)
  - `detailed`: Comprehensive analysis
  - `executive`: High-level status
  - `release`: Release readiness assessment
- `--recipient <audience>`: (Optional) Target audience:
  - `engineering`: Technical teams (default)
  - `management`: Engineering leadership
  - `release-team`: Release managers
  - `sre`: Infrastructure teams

## Prerequisites
- The healthcheck CLI tool must be installed and available in PATH
- For advanced features, healthcheck MCP server capabilities are used
- Internet connectivity to fetch CI data

## Output Location
- Report: `artifacts/kubevirt-ci-report/report-<scope>-<timestamp>.md`
- JSON data: `artifacts/kubevirt-ci-report/report-<scope>-<timestamp>.json`
- Summary: `artifacts/kubevirt-ci-report/summary-<scope>-<timestamp>.txt`

## Automation Use Cases
- Scheduled daily health checks (cron + `/kubevirt:ci-report --scope daily`)
- Pre-release go/no-go reports
- Weekly stakeholder updates
- SIG-specific health tracking
- Trend monitoring dashboards

## See Also
- `/kubevirt:ci-triage` - Intelligent failure triage
- `/kubevirt:ci-health` - Quick CI health overview
- `/kubevirt:ci-lane` - Deep dive into specific jobs
- `/kubevirt:ci-search` - Search for failure patterns
- [Healthcheck MCP Tools](https://github.com/lyarwood/healthcheck#mcp-command)
