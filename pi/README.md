# pi configuration

Configuration for [pi](https://github.com/earendil-works/pi-coding-agent), the coding
agent harness.

This package is managed with [stow](https://www.gnu.org/software/stow/). From the
`.dotfiles` directory run:

```bash
stow pi
```

This symlinks `~/.pi/agent/{AGENTS.md,settings.json,models.json,statusbar.json,statusbar-theme.json,package.json}`,
the `themes/`, the custom `extensions/*.ts`, and the custom `skills/` back into `~/.pi/`.

## What is tracked

- `agent/AGENTS.md` — global user instructions
- `agent/settings.json` — default model/provider, thinking level, subagent overrides
- `agent/models.json` — custom local model providers (only placeholder `apiKey`
  values for local servers; no real secrets)
- `agent/statusbar.json`, `agent/statusbar-theme.json` — status bar layout and theme
- `agent/themes/catppuccin-macchiato.json` — color theme
- `agent/extensions/{answer,git-status-widget,whimsical}.ts` — custom extensions
- `agent/skills/{handoff,recuerd0,maquina-better-stimulus,maquina-ui-standards,marketingskills-seo-audit,rails-simplifier,spec-driven-development,write-a-skill}` — custom skills

## What is NOT tracked (kept local per machine)

- `agent/auth.json` — pi authentication tokens
- `web-search.json` — provider API keys (Exa, Perplexity, Gemini)
- `agent/trust.json` — machine-specific trusted directory list
- `agent/sessions/`, `agent/run-history.jsonl`, `agent/intercom/` — runtime state
- `agent/npm/`, `agent/package-lock.json` — regenerable from the package list below
- `agent/extensions/pi-statusbar/`, `agent/git/` — installed via `git:`/`npm:` packages
- `agent/skills/herdr` — standalone clone of `github.com/ogulcancelik/herdr.git` (~60M, has its own `.git`)
- `agent/skills/find-skills` — symlink to `~/.agents/skills/find-skills`
- `agent/skills/skills.tar.gz` — build artifact
- `*.bak` files, `.DS_Store`, `exa-usage.json`

## Extensions and packages to install

The `packages` array in `agent/settings.json` lists the pi packages that must be
installed (via `pi`'s package manager) on a fresh machine. They are **not** tracked
here because they are installed from npm/Git and are regenerable.

Install them with:

```bash
pi extensions install npm:pi-web-access
pi extensions install npm:pi-subagents
pi extensions install npm:pi-mcp-adapter
pi extensions install npm:pi-intercom
pi extensions install npm:@spences10/pi-lsp
pi extensions install npm:pi-ollama-cloud
pi extensions install git:github.com/kreeger/pi-statusbar
```

| Package | Provides |
| --- | --- |
| `npm:pi-web-access` | web search/fetch tools and the `librarian` skill |
| `npm:pi-subagents` | subagent delegation and the `pi-subagents` skill |
| `npm:pi-mcp-adapter` | MCP gateway integration |
| `npm:pi-intercom` | cross-session intercom and the `pi-intercom` skill |
| `npm:@spences10/pi-lsp` | language-server diagnostics/hover/definitions tools |
| `npm:pi-ollama-cloud` | Ollama Cloud provider (web search/fetch) |
| `git:github.com/kreeger/pi-statusbar` | the `pi-statusbar` extension (status bar widgets) |

Custom extensions tracked in this repo (`answer.ts`, `git-status-widget.ts`,
`whimsical.ts`) are symlinked in directly and need no install step.

The `herdr` skill is a standalone clone (not a pi package) and is not tracked. Restore
it with:

```bash
git clone https://github.com/ogulcancelik/herdr.git ~/.pi/agent/skills/herdr
```

After installing the packages above, restore the local-only secrets manually:

- `~/.pi/agent/auth.json` — run `pi auth login` (or your provider's auth flow)
- `~/.pi/web-search.json` — add your `exaApiKey` (and optionally Perplexity/Gemini keys)

## Notes

- `models.json` only contains placeholder `apiKey` strings (`local-ai`, `ollama`)
  for local self-hosted servers; no real credentials are stored in this repo.
- `stow` is run with the default target (`$HOME`); the literal `.pi/` directory
  inside this package maps to `~/.pi/`.