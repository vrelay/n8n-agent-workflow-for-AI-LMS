# Runbook — Homework Helper (v0)

## Start the stack

```bash
cp .env.example .env
```

Edit `.env` and set:

- `OPENROUTER_API_KEY=sk-or-...` (your OpenRouter key)
- `N8N_ENCRYPTION_KEY=` — set any long random string (needed so credentials stay valid across restarts)
- `POSTGRES_PASSWORD` — change from the default

```bash
docker compose up -d
docker compose logs -f n8n   # wait until you see the editor URL
```

Open http://localhost:5678 and complete the one-time owner setup (email/password — local only).

## Import the lesson

1. In n8n: **Workflows → Import from File** → pick `workflows/homework-helper.json`
2. You should see 4 nodes: **Start → My Notes → Helper (OpenRouter) → Show Answer**

## Set the OpenRouter key

Note: the compose file sets `N8N_BLOCK_ENV_ACCESS_IN_NODE=false` because recent n8n versions block `$env` in expressions by default — without it you get "access to env denied" at execution.

The `Helper (OpenRouter)` node sends the key from the environment:

```text
Authorization: Bearer {{ $env.OPENROUTER_API_KEY }}
```

If you changed `.env` after the container started:

```bash
docker compose up -d --force-recreate n8n
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
| `Access to env denied` | n8n blocks `$env` in expressions by default — compose sets `N8N_BLOCK_ENV_ACCESS_IN_NODE=false`; recreate the container if you removed it |
| 401 from OpenRouter | `OPENROUTER_API_KEY` missing/wrong in `.env`; recreate the n8n container |
| `Helper` node red, timeout | Check the container has internet access; raise node timeout |
| Empty `answer` | Model returned an error object — check the `Helper` node's raw output JSON |
| Editor asks for owner again | `N8N_ENCRYPTION_KEY` changed or `n8n_data` volume was wiped |

## Stop / reset

```bash
docker compose down            # stop, keep data
docker compose down -v         # stop and DELETE all data (fresh start)
```
