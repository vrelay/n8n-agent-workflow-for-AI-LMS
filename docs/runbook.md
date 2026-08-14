# Runbook — Homework Helper (v0)

## Start the stack

**First:** make sure `n8n/` is present (required submodule). Fresh clone:

```bash
git clone --recurse-submodules <parent-repo-url>
```

Already cloned with an empty `n8n/`?

```bash
git submodule update --init --recursive
cd n8n && git checkout ai-lms && cd ..
```

```bash
cp .env.example .env
```

Edit `.env` and set:

- `OPENROUTER_API_KEY=sk-or-...` (your OpenRouter key)
- `GEMINI_API_KEY=...` (your Google AI Studio / Gemini API key — optional if you use OpenRouter only)
- `N8N_ENCRYPTION_KEY=` — set any long random string (needed so credentials stay valid across restarts)

### Production (image built from local `./n8n` submodule)

Requires the submodule and a one-time (or after UI changes) image build:

```bash
./docker/build-prod-image.sh   # pnpm build:n8n → docker compose build → ai-lms/n8n:$N8N_VERSION
docker compose up -d
```

Editor: http://localhost:5678

The prod image includes the same LMS editor strip-down as the submodule (`ai-lms` branch). Re-run `./docker/build-prod-image.sh` after UI patches you want baked into prod.

### Development (local `n8n/` submodule — includes UI patches)

```bash
docker compose -f docker-compose.dev.yml up --build
```

First boot may run `pnpm install` / `pnpm build` inside the container if those aren’t already present under `n8n/` (slow). After that it reuses the mounted source.

Editor: http://localhost:5678

On first open, n8n asks you to **create an owner account** — this is mandatory since n8n 1.0 and cannot be disabled. The session persists across restarts (stored in the `n8n_data` Docker volume).

To create the owner (or extra members) **via API** instead of the UI, see [`docs/user-api.md`](./user-api.md) and `./scripts/n8n-create-users.sh`.

### Fast UI refresh after editing `editor-ui`

Dev compose serves the **built** editor (`pnpm start`), so Vue/TS edits need a rebuild. Build **inside the running container** (recommended — avoids root-owned `node_modules` / `EACCES` on the host):

```bash
docker compose -f docker-compose.dev.yml exec n8n pnpm --filter n8n-editor-ui build
docker compose -f docker-compose.dev.yml restart n8n
```

Hard-refresh http://localhost:5678. Full agent notes (find UI, `LMS:` inventory, allowlist, git): [`AGENTS.md`](../AGENTS.md).

**Host alternative** (after `pnpm install` in `n8n/` on the host): same filter from `n8n/`, then restart compose as above. If you get `EACCES` on `.vite-temp`, run `sudo chown -R "$USER:$USER" n8n/`.

Dev UI is the **stripped student editor** (no main sidebar, flat `+` node allowlist, tabbed NDV, slim header/⋯ menus). Prod compose builds the same fork into `ai-lms/n8n` via `./docker/build-prod-image.sh`.

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

## Build-along lesson guides

**One-click demo link** (viewer must be logged in):

```text
http://localhost:5678/workflow/new?lesson=notes-helper
```

Opens a fresh empty workflow and auto-starts the Homework Helper build-along. External sites can use the same URL on an “Open demo” button (`target="_blank"`).

Students can also import a guided lesson on an **empty** workflow manually:

1. Create a new workflow (empty canvas)
2. Workflow header **⋯ → Import lesson guide...** → pick `lessons/notes-helper.guide.json`
3. A step-by-step panel fixed on the **left edge** walks them through building the full **Homework Helper** flow: Manual Trigger → My Notes → Helper (OpenRouter) → Show Answer. Each step lists numbered actions; **Next** unlocks when `waitFor` checks pass (node added, connected, URL filled, etc.)

Guide files are plain JSON (`version: 1`, `steps[]` with `highlight`, `waitFor`, optional `actions[]` and `placement`). Bundled copies for deep-links live under `n8n/.../features/lms/guide/lessons/` — copy from parent `lessons/` when the guide changes. After changing anything under `n8n/packages/frontend/editor-ui`, rebuild and restart:

```bash
docker compose -f docker-compose.dev.yml exec n8n pnpm --filter n8n-editor-ui build
docker compose -f docker-compose.dev.yml restart n8n
```

## Set the OpenRouter key

The `Helper (OpenRouter)` node sends the key from the environment:

```text
Authorization: Bearer {{ $env.OPENROUTER_API_KEY }}
```

## Set the Gemini key (optional)

For workflows that call Google Gemini directly (instead of OpenRouter), set `GEMINI_API_KEY` in `.env`. Compose also maps it to `GOOGLE_GENERATIVE_AI_API_KEY` for n8n’s built-in Google/Gemini integrations.

Example HTTP Request node:

```text
POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent
Header: x-goog-api-key: {{ $env.GEMINI_API_KEY }}
Header: Content-Type: application/json
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
| 401 / 403 from Gemini | `GEMINI_API_KEY` missing/wrong in `.env`; recreate n8n |
| `Helper` node red, timeout | Check the machine has internet access; raise node timeout |
| Empty `answer` | Model returned an error object — check the `Helper` node's raw output JSON |
| Editor asks for owner again | `N8N_ENCRYPTION_KEY` changed or the `n8n_data` / `postgres_data` volume was wiped |
| UI patch missing in prod | Re-run `./docker/build-prod-image.sh` then `docker compose up -d` (prod bakes `./n8n`, not Hub) |
| Wrong n8n version (prod) | Set `N8N_VERSION=2.34.4` in `.env`, rebuild: `./docker/build-prod-image.sh && docker compose up -d` |
| `EACCES … /home/node/.n8n/config` | Prod image runs as uid 1000; volume was written as root by old dev mounts. Fix: `docker run --rm -v <project>_n8n_data:/data alpine chown -R 1000:1000 /data` (dev now uses `n8n_data_dev`) |
| `EACCES … editor-ui/node_modules/.vite-temp` | Dev container runs as root; host can't write bind-mounted files. Build in container (see **Fast UI refresh** above) or `sudo chown -R "$USER:$USER" n8n/` |
| `compiled/` missing on `docker compose build` | Run `./docker/build-prod-image.sh` first (creates `n8n/compiled`) |

## Stop / reset

```bash
docker compose down                              # prod: stop, keep volumes
docker compose -f docker-compose.dev.yml down    # dev: stop, keep volumes
docker compose down -v                           # also DELETE DB + n8n_data
```
