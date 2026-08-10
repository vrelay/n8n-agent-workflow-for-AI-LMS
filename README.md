# AI LMS — Agentic Workflow Learning Platform

A learning platform for **class 6–8 students** to learn **agentic AI** by building simple workflows — watch a tutorial, redo it hands-on with guidance, then create their own.

The platform is **stock n8n**, self-hosted. No fork, no custom UI, no custom nodes. Lessons are **n8n workflows** imported and executed in n8n. We constrain the student experience by using only a small set of nodes — not by modifying n8n.

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
| Lesson | **Homework Helper** — answer a question using only the student’s pasted notes |
| Workflow | Manual Trigger → `My Notes` (Set) → `Helper` (HTTP to OpenRouter) → response shown in n8n execution output |
| Engine | n8n’s own runner, in Docker |
| LLM | OpenRouter via HTTP Request node (key from env / operator) |
| Auth | None (single shared instance, local/demo) |
| Tenancy | One shared n8n + Postgres. Per-tenant = duplicate this compose stack later |
| Video LMS | Out of scope |

### Success for the starter

- `docker compose up` brings up n8n
- Import `workflows/homework-helper.json`
- Edit the `My Notes` node (or Set nodes) with notes + question
- **Execute** — the final node’s output shows a short answer grounded in the notes

---

## Golden lesson (v0)

**Name:** Homework Helper

**Pitch:** Build a mini homework helper that only answers from your notes.

**Flow:**

1. **My Notes** (Set node) — `notes` and `question` fields
2. **Helper** (HTTP Request node) — POST to OpenRouter with a fixed system prompt: answer only from notes, short, easy English
3. **Result** — read the answer in the n8n execution panel (no extra UI in v0)

**Pass criteria:** Execute completes and the last node’s JSON contains an answer that uses the notes.

Lesson 2 candidate (same nodes): **Quiz Coach** — notes in → three easy Q&As out.

---

## Future goals

- Full lesson catalog (workflow thinking → agent + tool → plan/act → approval)
- Guided mode (likely an n8n fork for editor constraints — decided only after the plain workflow proves the pedagogy)
- Teacher/classroom views, progress, saved workflows
- Safe tool nodes, auth
- **Multi-tenant**: one Docker stack per tenant (see `docs/tenancy.md`)

---

## Design principles

1. **Curriculum first** — nodes appear because a lesson needs them
2. **No custom anything in v0** — stock n8n, workflows as the deliverable
3. **Docker is the unit** — shared stack now; per-tenant stack later (no shared-DB tenancy gymnastics)
4. **Kid-safe defaults** — fixed prompts and models inside workflows; keys only in env
5. **Avoid hybrid** — do not build a separate canvas that calls n8n’s API with partial graphs

---

## Repo layout

```
n8n-agent-workflow-for-AI-LMS/
  README.md
  docker-compose.yml          # n8n + postgres (shared)
  .env.example                # OPENROUTER_API_KEY, DB creds
  workflows/
    homework-helper.json      # the golden lesson, import into n8n
  docs/
    runbook.md                # start, import, set key, verify
    tenancy.md                # per-tenant compose strategy (later)
```

---

## Quick start

```bash
cp .env.example .env
# edit .env: set OPENROUTER_API_KEY
docker compose up -d
```

Then open http://localhost:5678, import `workflows/homework-helper.json`, and follow `docs/runbook.md`.

---

## Out of scope (for now)

- Auth, accounts, SSO
- Custom n8n fork / custom nodes / custom canvas
- Video hosting
- Multi-tenant automation

---

## Status

- [x] Product framing
- [x] Stock-n8n starter: compose + Homework Helper workflow
- [ ] Guided mode decision (fork vs. overlay) — only after v0 proves out
- [ ] Multi-tenant compose-per-tenant — later
