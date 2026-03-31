---
description: Search for specific test failures and patterns across all CI jobs
argument-hint: <pattern> [--max-age <period>] [--job <regex>]
---

## Name
kubevirt:ci-search

## Synopsis
```
/kubevirt:ci-search <pattern> [--max-age <period>] [--job <regex>] [--exclude-job <regex>]
```

## Description
The `kubevirt:ci-search` command searches for specific test failures and error patterns across all KubeVirt CI jobs using the search.ci.kubevirt.io service. It's ideal for investigating recurring failures, understanding failure scope, and finding related issues across different job types.

This command uses the `healthcheck search` tool to:
1. Query the search.ci.kubevirt.io service with regex patterns
2. Find matching failures across presubmit, batch, periodic, and postsubmit jobs
3. Provide statistics on failure frequency and distribution
4. Identify which jobs are most affected
5. Generate actionable insights for debugging

### Search Capabilities

#### Pattern Matching
- Regex support for flexible pattern matching
- Search in test names, failure messages, or both
- Case-insensitive matching
- Multiple search types (junit, bug reports, build logs)

#### Job Filtering
- Filter by job name regex
- Exclude specific jobs or patterns
- Focus on specific job types (periodic, presubmit, batch)
- Target specific SIG areas or Kubernetes versions

#### Time Range Control
- Default: last 14 days
- Configurable periods (hours, days, weeks)
- Balance between coverage and performance
- Historical trend analysis

#### Impact Analysis
- Total runs vs matching runs
- Failure rate calculations
- Per-job impact scoring
- Overall CI health metrics

## Implementation

### Phase 1: Parse Search Parameters
1. Extract search pattern (required)
2. Parse optional filters:
   - `--max-age`: Time range (default: 14 days)
   - `--job`: Job name filter regex
   - `--exclude-job`: Jobs to exclude
   - `--type`: Search type (junit, bug, build-log, all)

### Phase 2: Execute Search
1. Run healthcheck search command:
   ```bash
   healthcheck search "<pattern>" --max-age <period> --job "<regex>" --summary --stats --output json
   ```
2. Parse JSON output containing:
   - Total matches across all jobs
   - Per-job statistics (runs, failures, matches)
   - Test names and failure details
   - Job URLs for debugging
   - Overall statistics (when --stats is used)

### Phase 3: Analyze Results
1. **Impact Assessment**
   - Calculate match percentage per job
   - Identify most affected jobs
   - Determine overall failure rate
   - Score business impact

2. **Pattern Recognition**
   - Detect if pattern is widespread or localized
   - Identify environment-specific occurrences
   - Find correlations with job types or configurations

3. **Root Cause Indicators**
   - Extract common failure contexts
   - Identify file locations from junit output
   - Parse error messages for clues
   - Detect infrastructure vs code issues

### Phase 4: Generate Search Report
Create a detailed search results report with:

1. **Search Summary**
   - Pattern searched and time range
   - Total matches and affected jobs
   - Match rate (percentage of runs affected)
   - Overall health impact

2. **Most Affected Jobs**
   - Top 10 jobs by match count
   - Failure rate and match percentage
   - Impact score
   - Links to failing runs

3. **Failure Analysis**
   - Common failure messages
   - File locations and line numbers
   - Test categories affected
   - Pattern distribution

4. **Environmental Factors**
   - ARM64 vs x86 differences
   - Kubernetes version patterns
   - Job type distribution (periodic vs presubmit)

5. **Recommendations**
   - Investigation priorities
   - Potential root causes
   - Tests to review or quarantine
   - Next debugging steps

6. **Debugging Resources**
   - Direct links to failed runs
   - Web search URL for browser viewing
   - Related GitHub issues (if found)
   - Documentation references

## Return Value
A comprehensive search results report containing:
- **Search Metadata**: Pattern, time range, total matches
- **Overall Statistics**: Total runs, failure rates, match rates
- **Job Breakdown**: Per-job statistics with impact scores
- **Failure Details**: Test names, URLs, failure contexts
- **Pattern Analysis**: Distribution, environmental factors
- **Recommendations**: Prioritized action items
- **Debug Links**: URLs to failures and search interface

## Examples

1. **Search for migration failures**:
   ```
   /kubevirt:ci-search "migration"
   ```
   Finds all migration-related failures in the last 14 days.

2. **Search for timeouts in the last week**:
   ```
   /kubevirt:ci-search "timeout" --max-age 168h
   ```
   Searches for timeout failures in the last 7 days (168 hours).

3. **Search for operator issues in periodic jobs**:
   ```
   /kubevirt:ci-search "Operator should reconcile" --job "periodic.*"
   ```
   Filters to only periodic jobs for operator reconciliation issues.

4. **Search excluding ARM64 jobs**:
   ```
   /kubevirt:ci-search "disk" --exclude-job ".*arm64.*"
   ```
   Searches for disk-related failures, excluding ARM64 jobs.

5. **Search for network issues in recent runs**:
   ```
   /kubevirt:ci-search "network" --max-age 24h
   ```
   Finds network failures in the last 24 hours.

6. **Search for specific test**:
   ```
   /kubevirt:ci-search "VirtualMachinePool should respect maxUnavailable"
   ```
   Finds occurrences of a specific test failure.

7. **Search in build logs (not just junit)**:
   ```
   /kubevirt:ci-search "panic" --type build-log --max-age 72h
   ```
   Searches build logs for panics in the last 3 days.

8. **Comprehensive search for flaky test**:
   ```
   /kubevirt:ci-search "should boot VMI" --max-age 336h
   ```
   14-day search to assess flakiness patterns.

## Arguments
- `<pattern>`: (Required) Regex pattern to search for in test names or failure messages
- `--max-age <period>`: (Optional) How far back to search (e.g., `24h`, `7d`, `336h`). Default: `336h` (14 days)
- `--job <regex>`: (Optional) Filter results to jobs matching this regex
- `--exclude-job <regex>`: (Optional) Exclude jobs matching this regex
- `--type <search-type>`: (Optional) Search type: `junit` (default), `bug`, `build-log`, `bug+junit`, `all`

## Prerequisites
- The healthcheck CLI tool must be installed and available in PATH
- Internet connectivity to access search.ci.kubevirt.io service

## Output Location
Write the search report to `artifacts/kubevirt-ci-search/search-<pattern-sanitized>-<timestamp>.md`

## Performance Considerations
- Longer time ranges (--max-age) increase search time
- Broader patterns return more results (slower)
- Job filtering reduces result set (faster)
- Consider starting with recent data (24h-48h) then expanding if needed

## See Also
- `/kubevirt:ci-lane` - Deep analysis of a specific job lane
- `/kubevirt:ci-health` - Overall CI health across all jobs
- `/kubevirt:ci-triage` - Intelligent triage with root cause analysis
- [Search CI Interface](https://search.ci.kubevirt.io)
- [Healthcheck Tool](https://github.com/lyarwood/healthcheck)
