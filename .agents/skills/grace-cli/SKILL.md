---
name: grace-cli
description: "Operate the optional `grace` CLI against a GRACE project. Use when you want to lint GRACE artifacts, explain/remediate lint issues, check autonomy readiness, inspect project or module health, inspect verification entries, resolve modules from names or file paths, inspect shared/public module context, or inspect file-local/private markup through `grace lint`, `grace status`, `grace module`, `grace verification`, and `grace file show`."
---

Use the optional `grace` CLI as a fast GRACE-aware read/query layer.

## Prerequisites

- The `grace` binary must be installed and available on `PATH`
- The target repository should already use GRACE artifacts and markup
- Prefer `--path <project-root>` unless you are already in the project root

If the CLI is missing, or the repository is not a GRACE project, say so and fall back to reading the relevant docs and code directly.

## Choose the Right Command

- `grace lint --path <project-root>`
  Use for a fast integrity snapshot across semantic markup, XML artifacts, and export/map drift.
- `grace lint --profile autonomous --path <project-root>`
  Use before long agent runs to verify that operational packets, verification entries, and observable evidence are strong enough for autonomous execution.
- `grace lint --explain <code>`
  Use when a lint code appears in CI or review and you want the built-in explanation plus remediation guidance.
- `grace status --path <project-root>`
  Use for a one-shot health report: artifact presence, codebase metrics, integrity snapshot, autonomy gate, recent changes, and the next safe action.
- `grace status --with modules --path <project-root>`
  Use when you also want per-module health summaries in the same report.
- `grace module find <query> --path <project-root>`
  Use to resolve module IDs from names, paths, dependencies, annotations, verification refs, or file-local `LINKS`.
- `grace module show <id-or-path> --path <project-root>`
  Use to read the shared/public module view from `development-plan.xml`, `knowledge-graph.xml`, implementation steps, and linked files.
- `grace module show <id> --with verification --path <project-root>`
  Use when you also need the module's verification excerpt.
- `grace module health <id-or-path> --path <project-root>`
  Use for one module's implementation coverage, verification health, autonomy readiness, blockers, and next action.
- `grace verification find <query> --path <project-root>`
  Use to search verification entries by ID, module, priority, scenarios, test files, log markers, or commands.
- `grace verification show <V-M-id-or-module> --path <project-root>`
  Use to read one verification entry with its linked module context.
- `grace file show <path> --path <project-root>`
  Use to read file-local/private `MODULE_CONTRACT`, `MODULE_MAP`, and `CHANGE_SUMMARY`.
- `grace file show <path> --contracts --blocks --path <project-root>`
  Use when you also need function/type contracts and semantic block navigation.

## Recommended Workflow

Use grep or exact-text search first when the target is still broad, then use the CLI for the narrowed shared/public and file-local/private views.

Canonical anchors to search for when narrowing scope:

- `M-` for module IDs
- `V-M-` for verification IDs
- `CrossLink` for graph edges
- `START_MODULE_CONTRACT`
- `START_MODULE_MAP`
- `START_CONTRACT:`
- `START_BLOCK_`
- `START_CHANGE_SUMMARY`
- `LINKS:`

Copy-paste grep recipes:

```text
grep -R -n -E '\bM-[A-Z0-9]+(-[A-Z0-9]+)*\b' docs/development-plan.xml docs/knowledge-graph.xml
grep -R -n -E '\bV-M-[A-Z0-9]+(-[A-Z0-9]+)*\b' docs/verification-plan.xml docs/knowledge-graph.xml
grep -R -n 'LINKS:' src tests
grep -R -n 'START_MODULE_CONTRACT\|START_MODULE_MAP\|START_CHANGE_SUMMARY' src tests
grep -R -n 'START_CONTRACT:\|START_BLOCK_' src tests
grep -R -n 'M-XXX' docs src tests
grep -R -n 'V-M-XXX\|M-XXX' docs src tests
```

Normalization rules:

- assume module IDs use exact `M-<UPPER-KEBAB>` form
- assume verification IDs use exact `V-M-<UPPER-KEBAB>` form
- assume field labels and anchor prefixes are canonical and should not be aliased

1. Run `grace status` when you first need to understand the current project state.
2. Run `grace status --with modules` when project-level health is not enough and you need module summaries.
3. Run `grace lint` when integrity or drift matters.
4. Run `grace lint --profile autonomous` before long autonomous execution.
5. Run `grace lint --explain <code>` when one issue needs targeted remediation guidance.
6. Use grep or exact-text search to narrow the target module, verification entry, file path, or semantic anchor.
7. Run `grace module find` to resolve the target module from the user's words, a stack trace, or a changed path.
8. Run `grace module show`, `grace module health`, and `grace verification show` for the narrowed shared/public truth.
9. Run `grace file show` for the file-local/private truth.
10. Read the underlying XML or source files only for the narrowed scope that still needs deeper evidence.

## Output Guidance

- Use default text output for quick review and direct user-facing summaries.
- Use `--json` when another tool, script, or agent step needs machine-readable output.
- Use `--fail-on warnings` or `--fail-on errors` when the CLI output should gate CI.
- Treat CLI output as navigation help, not as a replacement for the real XML and source files when exact evidence is required.

## Public/Private Rule

- `grace module show` is for shared/public module context.
- `grace file show` is for file-local/private implementation context.
- If shared docs and file-local markup disagree, call out the drift instead of silently trusting one side.

## Important

- The CLI is a companion to the GRACE skills, not a replacement for them.
- Prefer this skill when the task is to inspect, navigate, or lint a GRACE project quickly through the CLI.
- For methodology design, execution planning, refresh, review, or fixes, route to the appropriate `grace-*` skill after using the CLI to narrow scope.
