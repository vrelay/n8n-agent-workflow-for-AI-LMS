# Runbook — Homework Helper (v0)

## Start the stack

```bash
cp .env.example .env
```

Edit `.env` and set:

- `OPENROUTER_API_KEY=sk-or-...` (your OpenRouter key)
- `N8N_ENCRYPTION_KEY=` — set any long random string (needed so credentials stay valid across restarts)

Start Postgres (the only Docker service; n8n itself runs from source):

```bash
docker compose up -d
```

## Run n8n from source

The official n8n monorepo is cloned into `n8n/`, pinned to tag **`n8n@2.34.4`**. Requires Node >= 22.22 (use Node 24 via `nvm use 24`) and pnpm (via `corepack enable`).

```bash
cd n8n
pnpm install && pnpm build    # first run is slow
set -a && source ../.env && set +a
pnpm start
```

Editor: http://localhost:5678

On first open, n8n asks you to **create an owner account** — this is mandatory since n8n 1.0 and cannot be disabled (`N8N_USER_MANAGEMENT_DISABLED` was removed; do not set it). The session persists across restarts.

For UI development with hot reload, run instead:

```bash
cd n8n/packages/frontend/editor-ui
pnpm dev                      # frontend dev server on :8080
```

Keep `pnpm start` (backend, :5678) running in another terminal.

## Import the lesson

1. Open http://localhost:5678 (n8n editor)
2. **Workflows → Import from File** → pick `workflows/homework-helper.json`
3. You should see 4 nodes: **Start → My Notes → Helper (OpenRouter) → Show Answer**

## Set the OpenRouter key

The `Helper (OpenRouter)` node sends the key from the environment:

```text
Authorization: Bearer {{ $env.OPENROUTER_API_KEY }}
```

`.env` sets `N8N_BLOCK_ENV_ACCESS_IN_NODE=false` because recent n8n versions block `$env` in expressions by default — without it you get "access to env denied" at execution. Always start n8n with the env loaded (`set -a && source ../.env && set +a`).

If you changed `.env`, restart the n8n process.

## Run and verify

1. Open the workflow, click **Execute workflow** (or execute the `Start` node)
2. Watch the run: all 4 nodes should turn green
3. Click **Show Answer** — the output panel should show:

```json
{
  "answer": "Clouds form when ...",
  "question": "Why do clouds form?"
}
```

4. Change `notes` / `question` in the **My Notes** node and run again — this is the "free build" step for the student.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `pnpm install` fails with `Unsupported engine` | Node too old — n8n 2.34.x needs Node >= 22.22. Use `nvm use 24` |
| n8n can't reach Postgres | Postgres must be up (`docker compose up -d`) and `.env` must point at `localhost:5432` |
| `Access to env denied` | n8n blocks `$env` in expressions by default — start n8n with `N8N_BLOCK_ENV_ACCESS_IN_NODE=false` (it is in `.env`) |
| 401 from OpenRouter | `OPENROUTER_API_KEY` missing/wrong in `.env`; restart n8n |
| `Helper` node red, timeout | Check the machine has internet access; raise node timeout |
| Empty `answer` | Model returned an error object — check the `Helper` node's raw output JSON |
| Editor asks for owner again | `N8N_ENCRYPTION_KEY` changed or `~/.n8n` / the DB was wiped |
| Wrong n8n version | `cd n8n && git fetch --depth 1 origin tag n8n@<version> && git switch --detach n8n@<version>`, then `pnpm install && pnpm build` |

## Stop / reset

```bash
docker compose down            # stop Postgres, keep data
docker compose down -v         # stop and DELETE the database (fresh start)
```

n8n local state (encryption key if not set in `.env`, settings) lives in `~/.n8n` — delete it for a fully fresh start.
