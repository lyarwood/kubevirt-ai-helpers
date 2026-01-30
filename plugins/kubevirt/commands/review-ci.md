---
description: Review CI failures for a given PR and provide analysis with remediation suggestions
argument-hint: <pr-number-or-url>
---

## Name
kubevirt:review-ci

## Synopsis
```
/kubevirt:review-ci <pr-number-or-url>
```

## Description
The `kubevirt:review-ci` command analyzes CI failures for a KubeVirt pull request, providing structured analysis of failed jobs, root cause identification, and remediation suggestions.

This command is designed to help developers quickly understand and address CI failures by:

### Analysis Capabilities
1. **Job Status Overview**: Summarize all CI jobs and their current status
2. **Failure Categorization**: Group failures by type (build, unit test, e2e test, lint, etc.)
3. **Root Cause Analysis**: Extract relevant error messages and stack traces from logs
4. **Flaky Test Detection**: Identify tests with known flaky behavior patterns
5. **Remediation Suggestions**: Provide actionable steps to address each failure type

### Failure Categories
The command categorizes failures into these types:

#### Build Failures
- Compilation errors
- Dependency resolution issues
- Container image build failures

#### Unit Test Failures
- Test assertion failures
- Test timeouts
- Missing test dependencies

#### E2E Test Failures
- Infrastructure issues (cluster provisioning, network)
- Test timeouts and flaky tests
- Actual test assertion failures
- Resource cleanup failures

#### Lint/Static Analysis Failures
- golangci-lint violations
- gofmt/goimports issues
- shellcheck failures

#### Other Failures
- Prow infrastructure issues
- Quota/resource exhaustion
- Network connectivity problems

## Implementation

### Phase 1: Gather CI Status
1. Parse the PR argument to extract the PR number and repository (defaults to `kubevirt/kubevirt`)
2. Use `gh pr view <pr-number> --repo <repo> --json statusCheckRollup,commits,headRefName` to get:
   - All CI check statuses
   - The head commit SHA for linking to specific job runs
   - The branch name for context
3. Identify all failed checks from the status check rollup
4. For each failed check, extract the job name and failure context

### Phase 2: Fetch Failure Logs
1. For GitHub Actions workflows:
   - Use `gh run list --repo <repo> --branch <branch> --json databaseId,name,status,conclusion` to find failed runs
   - Use `gh run view <run-id> --repo <repo> --log-failed` to get failure logs
2. For Prow jobs (detected by check context containing "prow.ci.openshift.org"):
   - Extract the Prow job URL from the check details URL
   - Fetch the build-log.txt from the GCS artifacts bucket
   - Parse the Prow job metadata for job type and parameters
3. Limit log fetching to the most recent failed run per job type to avoid excessive API calls

### Phase 3: Analyze Failures
1. Parse log output to extract:
   - Error messages and stack traces
   - Failed test names and assertion messages
   - Build error locations (file:line)
   - Timeout information
2. Categorize each failure:
   - Match against known error patterns
   - Identify infrastructure vs. code issues
   - Detect flaky test signatures (intermittent failures, timing-related errors)
3. Cross-reference with:
   - Previous runs of the same job (for flakiness detection)
   - Known issues in kubevirt/kubevirt repository
   - Recent infrastructure incidents

### Phase 4: Generate Report
1. Create structured output with:
   - Executive summary (pass/fail counts, blocking issues)
   - Detailed breakdown by failure category
   - Specific error messages and locations
   - Remediation steps for each issue
   - Links to full logs and relevant documentation
2. Prioritize issues by:
   - Required jobs blocking merge
   - Ease of remediation
   - Likelihood of being a real vs. flaky failure

## Return Value
A structured CI failure analysis report containing:

- **Summary**: Overview of CI status (X passed, Y failed, Z pending)
- **Blocking Issues**: Required jobs that are failing and must be fixed
- **Non-Blocking Issues**: Optional jobs that failed but don't block merge
- **Failure Analysis**: For each failed job:
  - Job name and type
  - Failure category
  - Root cause (extracted error message)
  - Affected files/tests
  - Remediation suggestion
  - Link to full log
- **Flaky Test Warnings**: Tests that may be flaky based on patterns
- **Infrastructure Issues**: Any detected infrastructure problems
- **Next Steps**: Prioritized list of actions to fix failures

## Examples

1. **Review CI for a PR by number**:
   ```
   /kubevirt:review-ci 12345
   ```
   Analyzes CI failures for PR #12345 in kubevirt/kubevirt.

2. **Review CI using full PR URL**:
   ```
   /kubevirt:review-ci https://github.com/kubevirt/kubevirt/pull/12345
   ```
   Same as above, extracted from URL.

3. **Review CI for a PR in a different repo**:
   ```
   /kubevirt:review-ci kubevirt/containerized-data-importer#5678
   ```
   Analyzes CI for PR #5678 in the CDI repository.

## Arguments
- `<pr-number-or-url>`: (Required) The PR to analyze. Can be:
  - A simple PR number (e.g., `12345`) - assumes kubevirt/kubevirt
  - A full GitHub URL (e.g., `https://github.com/kubevirt/kubevirt/pull/12345`)
  - An owner/repo#number format (e.g., `kubevirt/kubevirt#12345`)

## See Also
- `/kubevirt:review` - Review local branch changes using KubeVirt project best practices
- `/kubevirt:lint` - Lint a path and generate a plan to fix issues
- KubeVirt [CI Documentation](https://github.com/kubevirt/kubevirt/blob/main/docs/getting-started.md#ci)
- Prow [Job Configuration](https://github.com/kubevirt/project-infra)
