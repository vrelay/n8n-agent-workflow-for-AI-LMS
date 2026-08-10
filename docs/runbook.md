# Runbook — Homework Helper (v0)

## Start the stack

```bash
cp .env.example .env
```

Edit `.env` and set:

- `OPENROUTER_API_KEY=sk-or-...` (your OpenRouter key)
- `N8N_ENCRYPTION_KEY=` — set any long random string (needed so credentials stay valid across restarts)

### Production (official n8n image)

```bash
docker compose up -d
```

Editor: http://localhost:5678

### Development (local `n8n/` submodule — includes UI patches)

Requires the submodule:

```bash
git submodule update --init
```

```bash
docker compose -f docker-compose.dev.yml up --build
```

First boot may run `pnpm install` / `pnpm build` inside the container if those aren’t already present under `n8n/` (slow). After that it reuses the mounted source.

Editor: http://localhost:5678

On first open, n8n asks you to **create an owner account** — this is mandatory since n8n 1.0 and cannot be disabled. The session persists across restarts (stored in the `n8n_data` Docker volume).

### Fast UI refresh after editing `editor-ui`

Dev compose serves the **built** editor (`pnpm start`), so Vue/TS edits need a rebuild:

```bash
export PATH="$HOME/.nvm/versions/node/v24.15.0/bin:$PATH"   # Node ≥ 22
cd n8n && pnpm --filter n8n-editor-ui build && cd ..
docker compose -f docker-compose.dev.yml restart n8n
```

Hard-refresh http://localhost:5678. Full agent notes (find UI, `LMS:` inventory, allowlist, git): [`AGENTS.md`](../AGENTS.md).

Dev UI is the **stripped student editor** (no main sidebar, flat `+` node allowlist, tabbed NDV, slim header/⋯ menus). Prod compose still serves the stock `n8nio/n8n` image unless you point it at a custom build.

### Optional: host-side UI hot reload

With the **dev** stack (or any n8n backend) already on `:5678`:

```bash
cd n8n/packages/frontend/editor-ui
pnpm dev                      # Vite on :8080
```

## Import the lesson

1. Open http://localhost:5678 (n8n editor)
2. **Workflows → Import from File** → pick `workflows/homework-helper.json`
3. You should see 4 nodes: **Start → My Notes → Helper (OpenRouter) → Show Answer**

## Set the OpenRouter key

The `Helper (OpenRouter)` node sends the key from the environment:

```text
Authorization: Bearer {{ $env.OPENROUTER_API_KEY }}
```

`.env` sets `N8N_BLOCK_ENV_ACCESS_IN_NODE=false` because recent n8n versions block `$env` in expressions by default — without it you get "access to env denied" at execution. Compose passes `.env` into the n8n container.

If you changed `.env`, recreate the n8n service:

```bash
docker compose up -d          # prod
# or
docker compose -f docker-compose.dev.yml up -d
```

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
| `pnpm install` fails with `Unsupported engine` | Node too old — n8n 2.34.x needs Node >= 22.22. Use Node 24 in Dockerfile.dev / nvm |
| n8n can't reach Postgres | Use Compose (`DB_POSTGRESDB_HOST=postgres`). If running n8n on the host, Postgres must be up and `.env` must use `localhost` |
| Port 5678 already in use | Stop a host `pnpm start` / old container: `docker compose down` |
| `Access to env denied` | Ensure `N8N_BLOCK_ENV_ACCESS_IN_NODE=false` in `.env` and recreate the n8n container |
| 401 from OpenRouter | `OPENROUTER_API_KEY` missing/wrong in `.env`; recreate n8n |
| `Helper` node red, timeout | Check the machine has internet access; raise node timeout |
| Empty `answer` | Model returned an error object — check the `Helper` node's raw output JSON |
| Editor asks for owner again | `N8N_ENCRYPTION_KEY` changed or the `n8n_data` / `postgres_data` volume was wiped |
| UI patch missing in prod | Prod uses `n8nio/n8n` image (stock). Use `docker-compose.dev.yml` for local UI changes |
| Wrong n8n version (prod) | Set `N8N_VERSION=2.34.4` in `.env`, then `docker compose pull && docker compose up -d` |

## Stop / reset

```bash
docker compose down                              # prod: stop, keep volumes
docker compose -f docker-compose.dev.yml down    # dev: stop, keep volumes
docker compose down -v                           # also DELETE DB + n8n_data
```
