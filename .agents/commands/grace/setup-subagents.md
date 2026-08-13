---
description: "Scaffold GRACE worker and reviewer agent presets for the current shell"
---

Load the `grace-setup-subagents` skill and create subagent presets.

This creates GRACE-specific worker and reviewer agent files in the correct directory for the current shell (ZCode, Claude Code, OpenCode, etc.).

Process:
1. Read the `grace-setup-subagents` SKILL.md from `.agents/skills/grace-setup-subagents/`
2. Detect current shell type
3. Scaffold worker agent preset (expects compact execution packets, one-module ownership)
4. Scaffold reviewer agent preset (read-only validation of contract compliance)
5. Print summary of created files
