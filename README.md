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
| Engine | n8n in Docker Compose (prod image or local `n8n/` submodule for UI work) + Postgres |
| LLM | OpenRouter via HTTP Request node (key from env / operator) |
| Auth | n8n's built-in owner account (mandatory since n8n 1.0) |
| Tenancy | One shared n8n + Postgres. Per-tenant = duplicate this setup later |
| Video LMS | Out of scope |

### Success for the starter

- `docker compose up -d` (prod) or `docker compose -f docker-compose.dev.yml up --build` (dev)
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

## Docker Compose

| File | Mode | n8n |
|------|------|-----|
| `docker-compose.yml` | **prod** | official `n8nio/n8n:2.34.4` image |
| `docker-compose.dev.yml` | **dev** | builds `Dockerfile.dev`, mounts `./n8n` (your UI patches) |

Both include Postgres. Editor: http://localhost:5678

- **Pinned version:** `N8N_VERSION=2.34.4` in `.env`
- **UI package to edit (dev):** `n8n/packages/frontend/editor-ui`
- **Update n8n submodule later:** `cd n8n && git fetch --depth 1 origin tag n8n@<new-version> && git switch --detach n8n@<new-version>`

## Repo layout

```
n8n-agent-workflow-for-AI-LMS/
  README.md
  AGENTS.md                   # for agents: find UI, LMS comment style, rebuild cmds
  docker-compose.yml          # prod: Postgres + n8nio/n8n
  docker-compose.dev.yml      # dev: Postgres + local n8n/ mount
  Dockerfile.dev              # Node 24 image for the dev n8n service
  docker/dev-entrypoint.sh    # install/build if needed, then pnpm start
  .env.example                # OPENROUTER_API_KEY, DB creds, n8n env
  n8n/                        # fork submodule (vrelay/n8n, branch ai-lms)
    packages/frontend/editor-ui/   # editor UI — edit here for UI changes
  workflows/
    homework-helper.json      # the golden lesson, import into n8n
  docs/
    runbook.md                # start, import, set key, verify, UI rebuild
    tenancy.md                # per-tenant strategy (later)
```

**Agents / UI customization:** see [`AGENTS.md`](./AGENTS.md) (how we find routes/views, `LMS:` comment-out pattern, fast rebuild).

---

## Quick start

```bash
cp .env.example .env
# edit .env: set OPENROUTER_API_KEY and N8N_ENCRYPTION_KEY

# Production (stock n8n image)
docker compose up -d

# OR development (local n8n/ submodule with UI edits)
git submodule update --init
docker compose -f docker-compose.dev.yml up --build
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
- [x] Docker Compose starter: Postgres + n8n (prod image / dev submodule) + Homework Helper workflow
- [ ] Guided mode (UI edits live in `n8n/packages/frontend/editor-ui`, run via `docker-compose.dev.yml`)
- [ ] Multi-tenant compose-per-tenant — later
