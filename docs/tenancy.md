# Tenancy notes (later)

v0 is one shared n8n + Postgres. No tenant logic anywhere in the workflows — that is deliberate, so nothing here needs to change when we go multi-tenant.

## Strategy: compose-per-tenant

When we need isolation (per school/org), do **not** shard one database. Duplicate the whole stack:

```bash
# per tenant
TENANT=school-a
docker compose -p "lms-$TENANT" --env-file "env/$TENANT.env" up -d
```

Each tenant gets:

- its own n8n container, Postgres container, and named volumes (`lms-school-a_postgres_data`, ...)
- its own port mapping (`5678` → e.g. `5681`, `5682`) or its own subdomain behind a reverse proxy
- its own `.env`: separate `OPENROUTER_API_KEY` (per-school quota/billing) and `N8N_ENCRYPTION_KEY`

Isolation is total (process + data + key), at the cost of one container pair per tenant — acceptable at school scale, and simple to reason about.

## What stays shared

- The `workflows/*.json` lesson files (import into each tenant's n8n)
- The compose file itself
- The runbook

## Deferred decisions (don't build yet)

- A reverse proxy + `school-a.lms.example.com` routing
- Automated provisioning (script that creates env file + brings the stack up)
- Central usage/billing aggregation
- Auth beyond n8n's built-in owner/user management

## If we ever outgrow compose-per-tenant

n8n Enterprise has projects/roles for shared instances. Only consider it if container-per-tenant ops becomes the bottleneck — not before.
