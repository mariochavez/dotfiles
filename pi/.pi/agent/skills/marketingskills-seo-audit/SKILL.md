---
name: marketingskills-seo-audit-skill
description: Provides specialized capabilities from the Marketingskills marketplace plugin for SEO audits. Use this skill when you need to invoke logic related to SEO auditing standards for Pathos Teatro.
---

# Marketingskills SEO Audit Plugin Wrapper

This skill acts as a gateway to the external 'seo-audit' plugin located in the Marketingskills marketplace directory.

## Setup

No setup is required for the skill itself, but ensure the underlying plugin is accessible via the system path if necessary.

## Usage

To utilize the functionality, you must explicitly call the underlying logic. Since this skill wraps an external file, you should use the `/skill:` command followed by an instruction that directs the agent to read or execute the content of the external file.

For example, to read the contents of the plugin file:
`/skill:marketingskills-seo-audit-skill read ~/.claude/plugins/marketplaces/marketingskills/skills/seo-audit`

To perform a specific task defined by the plugin, consult the original plugin documentation and instruct the agent accordingly.
