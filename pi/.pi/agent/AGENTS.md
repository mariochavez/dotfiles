# User Instructions

## Web Search
- Always use `workflow: "none"` for web_search to suppress browser opening
- Only use `workflow: "summary-review"` if the user specifically asks for interactive browser

## Vision / Image Analysis

The default model (`ollama/kimi-k3:cloud`) accepts images, so screenshots,
UI captures and diagrams can be read directly.

The GLM models (`ollama/glm-5.2:cloud`, `ollama/glm-5.3:cloud`) are text-only.
The subagents are pinned to glm-5.2, so delegate image work to a subagent with
a vision model instead:

```
subagent({ agent: "delegate", model: "ollama/gemma4:cloud", task: "Read /path/to/image.png and describe what you see" })
```

Models declare their support in `~/.pi/agent/models.json` via
`"input": ["text", "image"]`.

## Project Instructions
- If `./.claude/CLAUDE.md` exists, **always load it with the `read` tool at the start of every conversation** to get project-specific instructions.
- Follow the instructions in CLAUDE.md when working on this project.
