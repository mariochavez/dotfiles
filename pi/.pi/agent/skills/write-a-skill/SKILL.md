---
name: write-a-skill
description: Create, update, or audit agent skills with proper structure, progressive disclosure, and bundled resources. Use when user wants to create, write, build, update, or improve a skill.
disable-model-invocation: true
---

# Writing Skills

## Process

1. **Gather requirements** - ask user about:
   - What task/domain does the skill cover?
   - What specific use cases should it handle?
   - Does it need executable scripts or just instructions?
   - Any reference materials to include?

2. **Draft the skill** - create:
   - SKILL.md with concise instructions
   - Additional reference files if SKILL.md exceeds 100 lines
   - Utility scripts if deterministic operations needed

3. **Review with user** - present draft and ask:
   - Does this cover your use cases?
   - Anything missing or unclear?
   - Should any section be more/less detailed?

## Skill Structure

```
skill-name/
├── SKILL.md           # Main instructions (required)
├── REFERENCE.md       # Detailed docs (if needed)
├── EXAMPLES.md        # Usage examples (if needed)
└── scripts/           # Utility scripts (if needed)
    └── helper.js
```

## SKILL.md Template & Description Format

The description is the only thing your agent sees when deciding which skill to load. Strong descriptions state what the skill does, then "Use when [specific triggers]". For the full SKILL.md template and description examples, see [REFERENCE.md](REFERENCE.md).

## Deciding How the Skill Triggers

Pick the invocation model deliberately:

- **Model-invoked** (default): the description sits in the agent's context forever. The model decides when to load SKILL.md. Cost: higher context load on every request, more unpredictability.
- **User-invoked** (`disable-model-invocation: true`): invisible to the agent until the developer triggers it. Keeps context lightweight and behavior predictable; cost: user must remember it exists.
- **Router skill**: if you build many user-invoked skills, add one router skill whose only job is listing the others and when to reach for them.

## Structuring Content

- **Keep SKILL.md small.** Smaller skills are easier to audit and save tokens.
- **Progressive disclosure:** SKILL.md is a ladder. Push heavy reference material into linked files; the agent fetches them only when a branch requires it.
- **Co-location:** keep a concept's definition, rules, and caveats under a single heading.
- **Split when:** SKILL.md exceeds 100 lines, content spans distinct domains (finance vs sales schemas), or features are rarely needed.

## Steering Agent Behavior

- **Use leading words:** pack meaning into short, universally understood phrases (e.g. "Vertical Slice" instead of "Don't code layer by layer"). The agent repeats them in its reasoning, aligning behavior.
- **Avoid negation:** don't steer by prohibition. State the exact target behavior instead — banned behaviors become more prominent when named.
- **Increase leg work:** if agents skip early steps (e.g. "ask clarifying questions") to rush to the goal, split phases into separate skills so the agent only sees one step at a time.

## Pruning

Massive skills signal poor design. Prune aggressively:

- **DRY:** every instruction has a single source of truth.
- **Remove sediment:** shared skills accumulate edge-case additions from many contributors; regularly restructure or delete stale parts.
- **Eliminate no-ops:** if removing a paragraph doesn't change the agent's output, delete it permanently.

## When to Add Scripts

Add utility scripts when:

- Operation is deterministic (validation, formatting)
- Same code would be generated repeatedly
- Errors need explicit handling

Scripts save tokens and improve reliability vs generated code.

## Exposing via MCP

Skills map naturally onto MCP:

- **Model-invoked skills → MCP tools:** the skill description becomes the tool description; the tool fetches the underlying SKILL.md.
- **User-invoked reference material → MCP resources:** heavy guidelines/templates are injected into context manually, only when needed.

## Review Checklist

After drafting, verify:

- [ ] Description includes triggers ("Use when...")
- [ ] Invocation model chosen deliberately (model vs user-invoked; router if needed)
- [ ] SKILL.md under 100 lines; heavy material pushed to linked files
- [ ] Each concept's definition, rules, caveats co-located under one heading
- [ ] Steering uses leading words and positive instructions (no negation)
- [ ] No duplicated guidance, stale sediment, or no-op paragraphs
- [ ] No time-sensitive info
- [ ] Consistent terminology
- [ ] Concrete examples included
- [ ] References one level deep
