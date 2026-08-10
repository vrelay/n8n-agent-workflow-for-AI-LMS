# AI LMS — Agentic Workflow Learning Platform

A learning platform for **class 6–8 students** to learn **agentic AI** by building simple workflows — watch a tutorial, redo it hands-on with guidance, then create their own.

Lessons are **n8n workflows**, imported and executed in n8n. We constrain the student experience by using only a small set of nodes — not by modifying n8n's behaviour.

---

## Why this exists

Students learn agentic AI best by **doing**, not only watching videos. The product loop is:

1. **Watch** — short tutorial video (separate content track)
2. **Guided** — recreate the same example with click-by-click help on a premade path
3. **Free build** — make their own workflow with the same allowed modules

Only the modules that teach clear ideas (trigger → agent → output, tools later) are used. Complex n8n surfaces (OAuth, arbitrary HTTP, dense ops) stay out of lessons for now.

---

## Current scope (v0 / starter)

**Goal:** one golden lesson running end-to-end in a shared n8n instance.

| Item | Detail |
|------|--------|
| Lesson | **Homework Helper** — answer a question using only the student's pasted notes |
| Workflow | Manual Trigger → `My Notes` (Set) → `Helper` (HTTP to OpenRouter) → response shown in n8n execution output |
| Engine | n8n **from source** (cloned monorepo in `n8n/`), Postgres in Docker |
| LLM | OpenRouter via HTTP Request node (key from env / operator) |
| Auth | n8n's built-in owner account (mandatory since n8n 1.0) |
| Tenancy | One shared n8n + Postgres. Per-tenant = duplicate this setup later |
| Video LMS | Out of scope |

### Success for the starter

- Postgres is up (`docker compose up -d`) and n8n runs from source
- Import `workflows/homework-helper.json`
- Edit the `My Notes` node (or Set nodes) with notes + question
- **Execute** — the final node's output shows a short answer grounded in the notes

---

## Golden lesson (v0)

**Name:** Homework Helper

**Pitch:** Build a mini homework helper that only answers from your notes.

**Flow:**

1. **My Notes** (Set node) — `notes` and `question` fields
2. **Helper** (HTTP Request node) — POST to OpenRouter with a fixed system prompt: answer only from notes, short, easy English
3. **Result** — read the answer in the n8n execution panel (no extra UI in v0)

**Pass criteria:** Execute completes and the last node's JSON contains an answer that uses the notes.

Lesson 2 candidate (same nodes): **Quiz Coach** — notes in → three easy Q&As out.

---

## n8n from source

The platform runs the **official n8n editor from a cloned source tree**, so UI changes can be made directly in n8n's own frontend packages.

- **Pinned version:** `n8n@2.34.4` (latest stable, tag `n8n@2.34.4`, shallow-cloned into `n8n/`)
- **UI package to edit:** `n8n/packages/frontend/editor-ui` (the Vue workflow editor; the full monorepo is required — editor-ui does not run standalone)
- **Requirements:** Node >= 22.22 (we use Node 24 via nvm) and pnpm >= 10.22 (via corepack)
- **Update n8n later:** `cd n8n && git fetch --depth 1 origin tag n8n@<new-version> && git switch --detach n8n@<new-version>` then reinstall/build

## Repo layout

```
n8n-agent-workflow-for-AI-LMS/
  README.md
  docker-compose.yml          # Postgres only (n8n runs from source)
  .env.example                # OPENROUTER_API_KEY, DB creds, n8n env
  n8n/                        # official n8n monorepo @ 2.34.4 (gitignored, local checkout)
    packages/frontend/editor-ui/   # editor UI — edit here for UI changes
  workflows/
    homework-helper.json      # the golden lesson, import into n8n
  docs/
    runbook.md                # start, import, set key, verify
    tenancy.md                # per-tenant strategy (later)
```

---

## Quick start

```bash
cp .env.example .env
# edit .env: set OPENROUTER_API_KEY and N8N_ENCRYPTION_KEY
docker compose up -d          # Postgres on :5432

cd n8n
corepack enable               # pnpm 10.32.1
pnpm install && pnpm build
set -a && source ../.env && set +a
pnpm start                    # editor at http://localhost:5678
```

Then:

1. Open http://localhost:5678 — create the owner account (one-time; login is mandatory since n8n 1.0)
2. **Workflows → Import from File** → pick `workflows/homework-helper.json`
3. **Execute workflow** — the answer appears in the output panel

Full details in `docs/runbook.md`.

---

## Out of scope (for now)

- Auth/accounts beyond n8n's built-in owner
- Custom nodes / custom canvas
- Video hosting
- Multi-tenant automation

---

## Status

- [x] Product framing
- [x] n8n-from-source starter: Postgres compose + Homework Helper workflow
- [ ] Guided mode (UI edits live in `n8n/packages/frontend/editor-ui`)
- [ ] Multi-tenant compose-per-tenant — later
