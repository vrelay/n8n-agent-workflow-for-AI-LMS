# AI LMS — Agentic Workflow Learning Platform

A learning platform for **class 6–8 students** to learn **agentic AI** by building simple workflows — watch a tutorial, redo it hands-on with guidance, then create their own.

Lessons are **n8n workflows**, imported and executed in n8n. We constrain the student experience by **hiding stock chrome** and **allowlisting nodes** in the forked editor (`n8n/` submodule, branch `ai-lms`) — not by inventing a parallel app or engine.

---

## Why this exists

Students learn agentic AI best by **doing**, not only watching videos. The product loop is:

1. **Watch** — short tutorial video (separate content track)
2. **Guided** — recreate the same example with click-by-click help on a premade path
3. **Free build** — make their own workflow with the same allowed modules

Only the modules that teach clear ideas (trigger → agent → output, tools later) are used. The canvas `+` panel is limited to `LMS_ALLOWED_NODE_TYPES` (see `AGENTS.md`). Complex n8n surfaces (sidebar projects, publish/share, dense NDV columns, OAuth-heavy flows) stay hidden or out of lessons for now.

---

## Current scope (v0 / starter)

**Goal:** one golden lesson running end-to-end in a shared n8n instance.

| Item | Detail |
|------|--------|
| Lesson | **Homework Helper** — answer a question using only the student's pasted notes |
| Workflow | Manual Trigger → `My Notes` (Set) → `Helper` (HTTP to OpenRouter) → response shown in n8n execution output |
| Engine | n8n in Docker Compose (image built from local `n8n/` submodule) + Postgres |
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
| `docker-compose.yml` | **prod** | builds `ai-lms/n8n` from local `./n8n` (LMS UI included) |
| `docker-compose.dev.yml` | **dev** | builds `Dockerfile.dev`, mounts `./n8n` (live UI patches) |

Both include Postgres. Editor: http://localhost:5678

- **Pinned version / image tag:** `N8N_VERSION=2.34.4` in `.env` → `ai-lms/n8n:2.34.4`
- **Prod image build:** `./docker/build-prod-image.sh` (runs `pnpm build:n8n` then `docker compose build`)
- **UI package to edit (dev):** `n8n/packages/frontend/editor-ui`
- **Update n8n submodule later:** `cd n8n && git fetch --depth 1 origin tag n8n@<new-version> && git switch --detach n8n@<new-version>`

## Repo layout

```
n8n-agent-workflow-for-AI-LMS/
  README.md
  AGENTS.md                   # for agents: find UI, LMS comment style, rebuild cmds
  docker-compose.yml          # prod: Postgres + image built from ./n8n
  docker-compose.dev.yml      # dev: Postgres + local n8n/ mount
  Dockerfile.dev              # Node 24 image for the dev n8n service
  docker/build-prod-image.sh  # compile ./n8n → ai-lms/n8n image
  docker/dev-entrypoint.sh    # install/build if needed, then pnpm start
  .env.example                # OPENROUTER_API_KEY, GEMINI_API_KEY, DB creds, n8n env
  n8n/                        # fork submodule (vrelay/n8n, branch ai-lms)
    packages/frontend/editor-ui/   # editor UI — edit here for UI changes
  workflows/
    homework-helper.json      # the golden lesson, import into n8n
  docs/
    runbook.md                # start, import, set key, verify, UI rebuild
    tenancy.md                # per-tenant strategy (later)
    user-api.md               # create owner / member via REST (no dashboard)
  scripts/
    n8n-create-users.sh       # owner + invite/accept helper for user-api.md
```

**Agents / UI customization:** see [`AGENTS.md`](./AGENTS.md) (how we find routes/views, `LMS:` comment-out pattern, fast rebuild).

---

## Clone (required — includes `n8n/` submodule)

The `n8n/` fork is a **required** git submodule. Always clone with submodules:

```bash
git clone --recurse-submodules https://github.com/vrelay/n8n-agent-workflow-for-AI-LMS.git
cd n8n-agent-workflow-for-AI-LMS
```

If you already cloned without submodules (empty `n8n/`):

```bash
git submodule update --init --recursive
```

Then check you can edit the fork:

```bash
cd n8n && git checkout ai-lms && git status && cd ..
# UI edits live under: n8n/packages/frontend/editor-ui/
```

## Quick start

```bash
cp .env.example .env
# edit .env: set OPENROUTER_API_KEY (and/or GEMINI_API_KEY) and N8N_ENCRYPTION_KEY

# Production (n8n image built from local ./n8n submodule)
./docker/build-prod-image.sh   # fails fast if n8n/ is missing
docker compose up -d

# OR development (bind-mounted ./n8n — rebuild UI inside the container after edits)
docker compose -f docker-compose.dev.yml up --build
# after editor-ui changes:
#   docker compose -f docker-compose.dev.yml exec n8n pnpm --filter n8n-editor-ui build
#   docker compose -f docker-compose.dev.yml restart n8n
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
- [x] Docker Compose starter: Postgres + n8n built from `./n8n` (prod image / dev submodule) + Homework Helper workflow
- [x] Student editor strip-down in `n8n/` (`ai-lms`): hide sidebar/tabs/publish/tags; flat node allowlist; tabbed NDV; slim menus — see `AGENTS.md`
- [ ] Guided mode (click-by-click help on a premade path)
- [ ] Multi-tenant compose-per-tenant — later
