---
name: VEP Find Reviewers
description: Detailed implementation guide for finding VEP reviewers via OWNERS_ALIASES and git history analysis
---

# VEP Find Reviewers

This skill provides the detailed implementation logic for the `/kubevirt:vep-find-reviewers` command. It covers how to parse OWNERS_ALIASES files, map SIGs to code directories, and analyze git history to identify active contributors.

## When to Use This Skill

- When executing the `/kubevirt:vep-find-reviewers` command
- When a user asks who should review a VEP or implementation PR
- When a VEP author needs help finding domain experts for their proposal

## Prerequisites

1. **gh CLI**: Must be installed and authenticated (`gh auth status`)
2. **Network access**: Requires access to the GitHub API for fetching file contents and commit history

## Implementation Steps

### Step 1: Resolve the Input

Determine whether the user provided a VEP number or a SIG name.

**If numeric (VEP number)**:

1. Discover enhancement tracking projects:
   ```bash
   gh project list --owner kubevirt --format json | jq '.projects[] | select(.title | contains("Enhancement")) | select(.title | startswith("[TEMPLATE]") | not)'
   ```

2. Search each project for the VEP using GraphQL to get the SIG field:
   ```bash
   gh api graphql -f query='
   {
     organization(login: "kubevirt") {
       projectV2(number: <project-number>) {
         items(first: 100) {
           nodes {
             content {
               ... on Issue {
                 number
                 title
               }
             }
             fieldValues(first: 30) {
               nodes {
                 ... on ProjectV2ItemFieldSingleSelectValue {
                   name
                   field { ... on ProjectV2SingleSelectField { name } }
                 }
                 ... on ProjectV2ItemFieldTextValue {
                   text
                   field { ... on ProjectV2Field { name } }
                 }
               }
             }
           }
         }
       }
     }
   }'
   ```
   Match the item whose issue number equals the VEP number. Extract the "SIG" field value.

3. Fetch the VEP proposal content to identify affected code areas:
   ```bash
   # Try the tracking issue first for linked code PRs
   gh issue view <vep-number> --repo kubevirt/enhancements --json body --jq '.body'
   ```
   Parse the body for references to specific packages, directories, or components (e.g., `pkg/virt-controller`, `pkg/virt-handler`, `staging/src/kubevirt.io/api`).

4. If the VEP proposal PR exists, fetch its content for more specific path references:
   ```bash
   gh pr list --repo kubevirt/enhancements --search "VEP <number>" --json number,body --jq '.[0].body'
   ```
   Look for code paths mentioned in the "Design Details" or "Implementation" sections.

**If a SIG name** (compute, network, storage):

Use the SIG name directly. Apply the SIG-to-directory mapping from Step 4 to determine which code areas to search.

### Step 2: Parse OWNERS_ALIASES

The OWNERS_ALIASES file in kubevirt/kubevirt is a YAML file that maps alias names to lists of GitHub usernames. Fetch and parse it:

```bash
gh api repos/kubevirt/kubevirt/contents/OWNERS_ALIASES --jq '.content' | base64 -d
```

**Expected YAML structure**:
```yaml
aliases:
  sig-compute-approvers:
    - user1
    - user2
  sig-compute-reviewers:
    - user3
    - user4
  sig-network-approvers:
    - user5
  sig-network-reviewers:
    - user6
  sig-storage-approvers:
    - user7
  sig-storage-reviewers:
    - user8
```

**Alias naming conventions to search for**:
- `sig-<name>-approvers` — people who can `/approve` PRs for this SIG
- `sig-<name>-reviewers` — people who can `/lgtm` PRs for this SIG

Extract both lists for the target SIG. Approvers typically have deeper domain knowledge and are stronger reviewer candidates for VEP proposals.

**Important**: The actual alias names may vary. After fetching the file, list all aliases that contain the SIG name (case-insensitive) to avoid missing variants like `sig-compute-api-reviewers` or component-specific aliases.

### Step 3: Parse Directory-Level OWNERS Files

If specific code paths were identified from the VEP content (Step 1), fetch OWNERS files from those directories for more targeted reviewer lists:

```bash
gh api repos/kubevirt/kubevirt/contents/<path>/OWNERS --jq '.content' | base64 -d
```

**Expected YAML structure**:
```yaml
approvers:
  - user1
  - user2
reviewers:
  - user3
  - user4
```

Some OWNERS files may also contain:
```yaml
filters:
  ".*_test\\.go$":
    reviewers:
      - test-specialist
```

Parse the top-level `approvers` and `reviewers` lists. Filter entries are optional but can provide additional signal for test-heavy VEPs.

**Error handling**: Not every directory has an OWNERS file. If the API returns 404, skip that path and move to the parent directory. Walk up the directory tree until an OWNERS file is found:
```
pkg/virt-controller/watch/snapshot/ → 404
pkg/virt-controller/watch/ → 404
pkg/virt-controller/ → found OWNERS
```

### Step 4: SIG-to-Directory Mapping

When the input is a SIG name (not a VEP number with specific paths), use these heuristic mappings to determine which directories to search for git activity:

| SIG | Primary Directories |
|-----|-------------------|
| compute | `pkg/virt-controller/`, `pkg/virt-handler/`, `pkg/virt-launcher/`, `pkg/virt-api/`, `staging/src/kubevirt.io/api/core/` |
| network | `pkg/network/`, `pkg/virt-launcher/virtwrap/network/`, `staging/src/kubevirt.io/api/core/` (network-related types) |
| storage | `pkg/storage/`, `pkg/container-disk/`, `pkg/virtctl/imageupload/`, `staging/src/kubevirt.io/api/core/` (storage-related types) |

These are heuristics. If the OWNERS_ALIASES or VEP content suggests different paths, prefer those over these defaults.

### Step 5: Analyze Recent Git Activity

For each relevant directory, query the GitHub API for recent commits:

```bash
# Calculate the since date based on --months flag (default 6)
SINCE_DATE=$(date -d "-6 months" -u +"%Y-%m-%dT%H:%M:%SZ")

# Fetch commits for each path
gh api "repos/kubevirt/kubevirt/commits?path=<directory>&since=${SINCE_DATE}&per_page=100" \
  --jq '.[] | {login: .author.login, date: .commit.author.date, sha: .sha}'
```

**Pagination**: The GitHub API returns at most 100 results per page. If 100 results are returned, fetch subsequent pages:
```bash
gh api "repos/kubevirt/kubevirt/commits?path=<directory>&since=${SINCE_DATE}&per_page=100&page=2" ...
```

**Aggregation**: For each author, compute:
- **commit_count**: Total number of commits in the lookback window
- **last_active**: Date of most recent commit
- **areas**: Which directories they were active in

**Deduplication**: If querying multiple directories, the same commit may appear in multiple results. Deduplicate by SHA before counting.

**Bot filtering**: Exclude bot accounts from the results. Common bots to filter:
- `kubevirt-bot`
- `dependabot[bot]`
- `github-actions[bot]`
- Any login ending in `[bot]`

### Step 6: Cross-Reference and Rank

Merge the OWNERS_ALIASES members, directory OWNERS members, and git activity contributors into a single ranked list.

**Scoring heuristic** (higher is better):

| Signal | Weight |
|--------|--------|
| Listed as approver in OWNERS_ALIASES | +30 |
| Listed as reviewer in OWNERS_ALIASES | +20 |
| Listed in directory-level OWNERS | +15 |
| Has recent git activity | +10 |
| Per commit in lookback window | +1 (capped at +20) |
| Active in last 30 days | +10 |
| Active in last 90 days | +5 |

Sort candidates by total score descending. This ranking is a suggestion — present all candidates with their source attribution so the user can make their own judgment.

**Categorize each candidate**:
- **OWNERS + git**: Strongest signal — officially recognized and actively contributing
- **OWNERS only**: Recognized but potentially stale — flag if no commits in the lookback window
- **git only**: Active contributor not yet in OWNERS — potential emerging expert

### Step 7: Format Output

Present the results following the Return Value format defined in the command file. Key formatting rules:

- Use `@username` format for all GitHub handles
- Include the SIG name and affected areas in the header
- Show the lookback window used
- Separate the ranked table from the raw OWNERS_ALIASES listing
- Call out stale OWNERS members and active non-OWNERS contributors explicitly
- End with actionable suggestions about who to reach out to first

## Error Handling

| Error | Recovery |
|-------|----------|
| OWNERS_ALIASES not found | Report that the file doesn't exist in the target repo. Suggest checking the repo manually. Fall back to git-activity-only analysis. |
| VEP not found in any project | Report that the VEP number wasn't found. Suggest using a SIG name directly instead. |
| SIG field empty on project board | Report that the VEP doesn't have a SIG assigned. Ask the user to provide the SIG name manually. |
| GitHub API rate limited | Report the rate limit error. Suggest the user wait or authenticate with a token that has higher limits. |
| No commits found for paths | Report that no recent activity was found. Suggest extending the `--months` window or checking that the paths are correct. |

## Examples

### Example 1: VEP Number Input

```
/kubevirt:vep-find-reviewers 190
```

1. Looks up VEP 190 on the enhancement tracking project → SIG: compute
2. Fetches VEP 190 tracking issue, finds references to `pkg/virt-controller/` and `staging/src/kubevirt.io/api/`
3. Fetches OWNERS_ALIASES → extracts `sig-compute-approvers` and `sig-compute-reviewers`
4. Fetches OWNERS from `pkg/virt-controller/`
5. Queries 6 months of git commits in those paths
6. Merges and ranks candidates

### Example 2: SIG Name Input

```
/kubevirt:vep-find-reviewers network --months 12
```

1. Uses SIG `network` directly
2. Fetches OWNERS_ALIASES → extracts `sig-network-approvers` and `sig-network-reviewers`
3. Uses heuristic directory mapping for network SIG
4. Queries 12 months of git commits in network-related paths
5. Merges and ranks candidates
