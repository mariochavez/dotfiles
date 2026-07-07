---
name: spec-driven-development
description: A Rails-focused spec-driven development workflow for building features with AI agents. Use this skill when users want to plan features, write specs, create task breakdowns, or generate implementation prompts for Rails apps. Triggers on "sdd", "spec-driven", "shape spec", "create tasks", "initialize SDD", "feature planning", "implementation prompts", or any request to systematically plan and implement a Rails feature. Also triggers when moving from MVP documentation to implementation planning.
---

# Spec-Driven Development

A lightweight workflow for building production-quality Rails features with AI agents through systematic planning and self-contained specs.

Each spec is designed to be **picked up and executed independently** by Claude Code or a subagent — no extra context needed beyond the spec folder itself.

## Setup

Run this once per Rails project:

```bash
cd /path/to/your-rails-app
bash ~/.pi/agent/skills/spec-driven-development/scripts/init_sdd.sh my-project-name
```

This creates the `sdd/` directory with:
- Pre-built Rails standards (global, backend, frontend, testing)
- `sdd/standards/index.yml` catalog
- `sdd/progress.yml` detailed progress tracker

## Directory Structure

```
sdd/
├── progress.yml                    ← Detailed progress tracker (8 phases)
├── product/
│   ├── mission.md                  ← Product vision, users, problems
│   ├── roadmap.md                  ← Feature priorities with effort estimates
│   └── tech-stack.md               ← Technology decisions and deviations
├── standards/
│   ├── index.yml                   ← Catalog of all standards (auto-maintained)
│   ├── global/
│   │   └── rails-stack.md
│   ├── backend/
│   │   └── rails-patterns.md
│   ├── frontend/
│   │   ├── hotwire.md
│   │   └── components.md
│   └── testing/
│       └── minitest.md
└── specs/
    └── YYYY-MM-DD-feature-name/
        ├── planning/
        │   ├── requirements.md     ← Gathered requirements
        │   └── visuals/            ← Mockups/wireframes
        ├── spec.md                 ← Formal specification
        ├── references.md           ← Existing code to reuse/follow
        ├── standards.md            ← Standards injected for this feature
        ├── tasks.md                ← Task groups with self-contained prompts
        └── verification/
            └── screenshots/        ← Verification screenshots
```

## Standards System

Standards are short `.md` files. Every word costs tokens — keep them **concise and scannable**.

### index.yml — The Standards Catalog

`sdd/standards/index.yml` is the master catalog. Always read it before shaping a spec to know what's available. Always update it when adding new standards.

```yaml
# sdd/standards/index.yml
global:
  rails-stack:
    file: global/rails-stack.md
    description: "Rails 8 stack: Hotwire, Tailwind 4, maquina_components, Solid trifecta, Kamal"
    applies_to: all

backend:
  rails-patterns:
    file: backend/rails-patterns.md
    description: "Rich models, CRUD resources, no service objects, money as cents, state as records"
    applies_to: [models, controllers, routes]

frontend:
  hotwire:
    file: frontend/hotwire.md
    description: "Turbo Drive/Frames/Streams, morph pattern, Stimulus teardown, common pitfalls"
    applies_to: [views, javascript, turbo, stimulus]
  components:
    file: frontend/components.md
    description: "maquina_components usage, Tailwind CSS 4 @theme config, anti-patterns"
    applies_to: [views, partials, forms]

testing:
  minitest:
    file: testing/minitest.md
    description: "No mocks/stubs, test outcomes, happy path, WebMock for APIs, fixtures"
    applies_to: all
```

### Rails Standards (Auto-Bootstrapped on Init)

`bash scripts/init_sdd.sh` writes all standards files and `index.yml` automatically.

Read `references/rails-standards.md` for the full content of each file.

| File | Summary |
|------|---------|
| `standards/global/rails-stack.md` | Rails 8, Hotwire, Tailwind 4, maquina_components, SQLite/Postgres, Solid trifecta, Kamal |
| `standards/backend/rails-patterns.md` | Rich models, CRUD resources, no service objects, money as cents, state as records |
| `standards/frontend/hotwire.md` | Turbo Drive/Frames/Streams, morph, Stimulus patterns and teardown |
| `standards/frontend/components.md` | maquina_components, Tailwind 4 CSS-first config |
| `standards/testing/minitest.md` | No mocks/stubs, test outcomes, happy path, WebMock |

### Discovering Additional Standards (Existing Apps)

When adding SDD to an existing app, analyze the codebase for tribal knowledge to supplement the bootstrapped standards:

1. Read 5–10 representative files per area (models, controllers, views, tests)
2. Look for patterns that are **opinionated, tribal, or non-obvious** — not standard Rails behavior
3. For each pattern: ask the user *why* it exists, then draft a concise standard
4. Write to `standards/[area]/[name].md` and add an entry to `index.yml`

**Only document what a new developer wouldn't know without being told.** Rails defaults don't need documenting.

---

## Phase 1: Product Planning (Once per project)

> Skip for existing apps — go to Phase 2.

### From MVP Creator Docs

If MVP docs exist (`docs/MVP_BUSINESS_PLAN.md`, `docs/TECHNICAL_GUIDE.md`):

1. Extract `sdd/product/mission.md` — vision, personas, problems
2. Extract `sdd/product/roadmap.md` — feature list, effort estimates (XS/S/M/L/XL)
3. Extract `sdd/product/tech-stack.md` — stack decisions + any deviations from default

→ See `references/document-templates.md` for file templates.

### From Scratch

Ask one at a time:
1. What problem does this solve?
2. Who is the primary user? Geographic/language focus?
3. What are the must-have features for launch?
4. Any deviations from the standard Rails stack?

Then create the three files in `sdd/product/` and update `sdd/progress.yml`:
```yaml
product_planning:
  status: complete
  mission: true
  roadmap: true
  tech_stack: true
```

---

## Phase 2: Shape Spec (Per feature)

**This is the most important phase.** Shape well and the Claude Code handoff is seamless.

### Step 1: Create spec folder

```bash
bash ~/.pi/agent/skills/spec-driven-development/scripts/new_spec.sh feature-name
```

Or create manually:
```
sdd/specs/YYYY-MM-DD-feature-name/
```

### Step 2: Ask focused questions (4–6 max)

- What is the user trying to accomplish? What's the happy path?
- Any edge cases needed in v1?
- What does success look like? (redirect, message, UI change?)
- Any existing models/controllers/views to reuse?

### Step 3: Search the codebase for reference code

**Always search before speccing new code:**

```bash
grep -r "class.*ApplicationRecord" app/models/ | grep -i [domain]
ls app/controllers/ | grep -i [domain]
find app/views -name "*[domain]*"
```

Write findings to `specs/[name]/references.md`:

```markdown
# References: [Feature Name]

## Existing Models
- `app/models/appointment.rb` — has status pattern to follow

## Existing Controllers
- `app/controllers/appointments_controller.rb` — follow this CRUD structure

## Reusable Partials
- `app/views/shared/_status_badge.html.erb` — reuse for status display
```

### Step 4: Check for visuals

Ask if mockups exist. If none and the feature has meaningful UI:
- Use the `frontend-design` skill to create an HTML mockup
- Or describe the expected layout in spec.md

### Step 5: Inject relevant standards

Read `sdd/standards/index.yml`. Based on what the feature touches, select the applicable standards.

Present selection to the user:
```
Based on this feature, these standards apply:
- global/rails-stack (always)
- backend/rails-patterns (models + controller)
- frontend/hotwire (Turbo + Stimulus)
- frontend/components (maquina_components views)
- testing/minitest (always)

Any additions or removals?
```

Write `specs/[name]/standards.md` by copying the **full file content** of each confirmed standard. This makes the spec folder **self-contained** — a Claude Code agent or subagent can implement with zero dependencies outside this folder.

### Step 6: Write spec.md

→ See `references/document-templates.md` for template.

Structure:
- **Goal** — one sentence
- **User Stories** — As a [user], I want [action] so that [outcome]
- **Requirements** — functional only, no implementation details
- **Visual Design** — mockup link or layout description
- **Out of Scope** — explicitly what's NOT in v1

Update `sdd/progress.yml`:
```yaml
current_spec:
  name: "YYYY-MM-DD-feature-name"
  path: "sdd/specs/YYYY-MM-DD-feature-name"
  phases:
    shape_spec:
      status: complete
      requirements_gathered: true
      visuals_analyzed: true
    write_spec:
      status: in_progress
```

---

## Phase 3: Write Spec

Formalize the spec from gathered requirements. Create `sdd/specs/[folder]/spec.md` with:

```markdown
# [Feature Name]

## Goal
[One sentence: what this feature enables the user to do]

## User Stories

- As a [user], I want to [action] so that [outcome]
- As a [user], I want to [action] so that [outcome]

## Requirements

### Functional
- [Requirement 1]
- [Requirement 2]

### Business Rules
- [Rule: e.g., "A provider can have at most 1 appointment per 30-min slot"]

## Visual Design

[Link to mockup OR brief layout description]

## Out of Scope (v1)

- [Thing we're NOT building yet]
- [Another exclusion]
```

Update `sdd/progress.yml`:
```yaml
current_spec:
  phases:
    write_spec:
      status: complete
      spec_created: true
```

---

## Phase 4: Verify Spec

Before implementation, validate the spec against requirements:

1. Check scope creep — does spec.md include anything not in requirements.md?
2. Verify business rules are complete
3. Ensure visual design is referenced
4. Confirm out-of-scope items are explicitly excluded

Write findings to `sdd/specs/[folder]/verification/spec-verification.md`:

```markdown
# Spec Verification: [Feature Name]

## Verified Against
- `sdd/specs/[folder]/planning/requirements.md`

## Issues Found
- [Issue 1 — severity: high/medium/low]
- [Issue 2]

## Status
- [ ] Approved for implementation
- [ ] Needs revision
```

Update `sdd/progress.yml`:
```yaml
current_spec:
  phases:
    verify_spec:
      status: complete
      verified: true
      issues_found: 0
```

---

## Phase 5: Create Tasks (Per feature)

Break the spec into task groups: **Database → Backend → Frontend → Testing**

Each group is **self-contained** and designed to be executed by Claude Code or a subagent independently.

### Task Group Structure

Each group:
- Lists specific, actionable tasks
- Writes tests first (2–5 tests per group)
- Ends with a verify command

### Standard Rails Task Groups

```markdown
## Group 1: Database
- [ ] Migration: `bin/rails g migration [name]`
- [ ] Model validations and associations
- [ ] Fixtures: `test/fixtures/[model].yml`

Tests: `bin/rails test test/models/[model]_test.rb`

## Group 2: Backend
- [ ] Routes (CRUD + sub-resources only)
- [ ] Controller with CRUD actions
- [ ] Model business logic methods/scopes
- [ ] Authorization if needed

Tests: `bin/rails test test/controllers/[name]_test.rb`

## Group 3: Frontend
- [ ] Views/partials using maquina_components
- [ ] Turbo/Hotwire behavior
- [ ] Stimulus controller if needed
- [ ] i18n translations (es/en)

Tests: `bin/rails test test/system/[name]_test.rb`

## Group 4: Integration
- [ ] End-to-end happy path test
- [ ] Critical edge case if any

Tests: `bin/rails test`
```

**Test count:** 2–5 per group, 10–20 total per feature. Never more than 8 per group.

### Self-Contained Claude Code Prompts

For each task group, generate a prompt in `tasks.md` that a Claude Code agent can execute with **zero additional context** — everything it needs is embedded:

1. The task checklist
2. Full content of `standards.md` (already scoped to this feature)
3. File paths from `references.md`
4. Test verify command

This design means you can hand off each group to Claude Code independently, or run all groups sequentially in a single Claude Code session.

→ See `references/document-templates.md` for the self-contained prompt format.

Update `sdd/progress.yml`:
```yaml
current_spec:
  phases:
    create_tasks:
      status: complete
      tasks_created: true
      task_count: 12
```

---

## Phase 6: Generate Prompts (Optional)

If you want to use other AI tools (Cursor, Copilot, etc.), generate implementation prompts:

1. Read `sdd/specs/[folder]/tasks.md`
2. For each task group, extract the self-contained prompt
3. Write to `sdd/specs/[folder]/implementation/prompts/[N]-[group-name].md`

Update `sdd/progress.yml`:
```yaml
current_spec:
  phases:
    generate_prompts:
      status: complete
      prompts_generated: true
      prompt_count: 4
```

---

## Phase 7: Implement

### Hand-off pattern

The spec folder is the complete hand-off package:

```
sdd/specs/2025-03-06-appointment-booking/
├── spec.md         → What to build
├── references.md   → What code to follow
├── standards.md    → How to build it (Rails patterns, testing rules, Hotwire)
└── tasks.md        → Step-by-step with self-contained prompts
```

**Option A — Full session:** Feed Claude Code the spec folder, then work through task groups sequentially in one session.

**Option B — Group by group:** Copy each group's self-contained prompt into a fresh Claude Code session. Good for complex features or parallel work.

### Required skills during implementation

| When | Use skill |
|------|-----------|
| Before writing any Stimulus controller | `better-stimulus` — targets, values, connect/disconnect, teardown |
| For all view/component work | `maquina-ui-standards` — correct maquina_components usage |
| After implementing any model or controller | `rails-simplifier` — review for Rails idioms, CRUD patterns, rich model |
| Any Turbo/Hotwire behavior | Read `references/hotwire-patterns.md` first |

### Implementation cycle (per group)

1. Run tests → fail (expected)
2. Implement
3. Run tests → pass
4. Run `rails-simplifier` on anything that feels complex
5. Mark tasks `[x]` → next group

Update `sdd/progress.yml` as you go:
```yaml
current_spec:
  phases:
    implement:
      status: in_progress
      mode: simple
      tasks_completed: 3
      tasks_total: 12
```

---

## Phase 8: Final Verification

After all groups are implemented:

1. Run full test suite: `bin/rails test`
2. Verify all acceptance criteria from spec.md are met
3. Write verification report to `sdd/specs/[folder]/verification/final-verification.md`
4. Update roadmap.md if features shipped
5. Move spec to completed_specs in progress.yml

Update `sdd/progress.yml`:
```yaml
current_spec:
  phases:
    verify_final:
      status: complete
      tests_passed: true
      roadmap_updated: true

completed_specs:
  - name: "2025-03-06-appointment-booking"
    completed_date: "2025-03-08T10:30:00Z"

current_spec:
  name: null
  status: null
```

---

## Testing Standards (Non-Negotiable)

These are also in `standards/testing/minitest.md` — repeated here because they're critical.

- **No mocks or stubs** — test real objects against the real database
- **Test outcomes, not implementation** — assert what changed, not how
- **Happy path focus** — full coverage of the main flow; edge cases only for critical validations
- **WebMock for external HTTP** — stub all outbound calls; never hit real APIs
- **Fixtures over factories** — Rails fixtures only
- **Simple tests** — one clear assertion per test

```ruby
# ✅ Tests outcome
test "appointment confirmed after payment" do
  appointment = appointments(:pending)
  appointment.confirm_payment!
  assert appointment.confirmed?
  assert_equal 1, appointment.payments.count
end

# ❌ Tests implementation
test "appointment calls PaymentService" do
  mock = Minitest::Mock.new
  mock.expect(:process, true)
  PaymentService.stub(:new, mock) { appointment.confirm_payment! }
  mock.verify
end
```

---

## Commands Reference

| Command | Action |
|---------|--------|
| `bash scripts/init_sdd.sh [name]` | Bootstrap sdd/ with Rails standards + index.yml + progress tracker |
| `bash scripts/new_spec.sh <name>` | Create new spec folder with planning/ and verification/ dirs |
| `bash scripts/status.sh` | Show progress.yml summary and next suggested action |
| `/skill:spec-driven-development plan` | Create/update product planning docs |
| `/skill:spec-driven-development shape` | Shape spec: questions → codebase search → inject standards → write spec.md |
| `/skill:spec-driven-development tasks` | Create task groups with self-contained prompts |
| `/skill:spec-driven-development status` | Show current progress |
| `/skill:spec-driven-development discover` | Extract tribal knowledge from existing codebase into new standards |

---

## Related Skills

| Skill | When |
|-------|------|
| `mvp-creator` | Before SDD — product vision, brand guide, technical architecture |
| `frontend-design` | During shaping — UI mockups when none exist |
| `rails-simplifier` | After implementing models/controllers — Rails idiom review |
| `better-stimulus` | Before any Stimulus controller |
| `maquina-ui-standards` | All UI work with maquina_components |
