---
name: maquina-better-stimulus-skill
description: Provides specialized capabilities from the Maquina marketplace plugin for better-stimulus tasks. Use this skill when you need to invoke logic related to better-stimulus standards for Pathos Teatro.
---

# Maquina Better-Stimulus Plugin Wrapper

This skill acts as a gateway to the external 'better-stimulus' plugin located in the Claude marketplace directory.

## Setup

No setup is required for the skill itself, but ensure the underlying plugin is accessible via the system path if necessary.

## Usage

To utilize the functionality, you must explicitly call the underlying logic. Since this skill wraps an external file, you should use the `/skill:` command followed by an instruction that directs the agent to read or execute the content of the external file.

For example, to read the contents of the plugin file:
`/skill:maquina-better-stimulus-skill read ~/.claude/plugins/marketplaces/maquina/better-stimulus`

To perform a specific task defined by the plugin, consult the original plugin documentation, including the content of ~/.claude/plugins/marketplaces/maquina/better-stimulus/agents/better-stimulus.md and files in ~/.claude/plugins/marketplaces/maquina/better-stimulus/references/, and instruct the agent accordingly.
