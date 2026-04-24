# Evaluation Task Quality Rubric

Use this rubric to assess the quality of generated MCPChecker evaluation tasks.

## Prompt Quality (1-5)

- **5**: Prompts are natural-language, outcome-oriented, specify concrete names/namespaces, and never include kubectl/virtctl commands
- **4**: Prompts are mostly natural-language with minor prescriptiveness
- **3**: Prompts are functional but overly vague or slightly prescriptive
- **2**: Prompts include implementation details or are too ambiguous to act on
- **1**: Prompts are raw kubectl commands or incomprehensible

## Verify Coverage (1-5)

- **5**: Verify scripts check all expected outcomes, use proper exit codes, include descriptive echo messages, and reuse existing helpers where applicable
- **4**: Verify scripts cover primary outcomes with minor gaps
- **3**: Verify scripts check the main outcome but miss edge cases
- **2**: Verify scripts are incomplete or have incorrect assertions
- **1**: Verify scripts are missing or always pass/fail regardless of state

## Setup/Cleanup (1-5)

- **5**: Setup creates clean namespace, provisions all prerequisites idempotently; cleanup uses ignoreNotFound on all deletes and removes the namespace
- **4**: Setup and cleanup are functional with minor ordering issues
- **3**: Setup works but cleanup misses some resources
- **2**: Setup is incomplete or non-idempotent
- **1**: Setup or cleanup is missing

## Convention Adherence (1-5)

- **5**: Tasks follow v1alpha2 format, use vm-test namespace, include all required labels (suite, requires, source-doc), match the style of existing kubevirt eval tasks
- **4**: Tasks follow conventions with minor deviations
- **3**: Tasks are structurally correct but deviate from established patterns
- **2**: Tasks have significant structural issues
- **1**: Tasks do not follow the MCPChecker task format

## MCP Tool Mapping (1-5)

- **5**: All workflow actions correctly mapped to available MCP tools (vm_create, vm_clone, vm_lifecycle, resources_*, pods_*); gaps identified with suggested tool names
- **4**: Most actions mapped correctly with minor misattributions
- **3**: Core actions mapped but some tools overlooked
- **2**: Significant mapping errors or many unidentified gaps
- **1**: MCP tool mapping is missing or incorrect
