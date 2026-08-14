# n8n user APIs (Community, no license)

Create users **without the dashboard**. Community edition only — no Enterprise public-API user create.

Password rules (n8n): **≥ 8 chars**, at least **one uppercase** and **one number**.

Default base URL: `http://localhost:5678`  
Override with `N8N_BASE_URL`.

**Helper script:** [`scripts/n8n-create-users.sh`](../scripts/n8n-create-users.sh) — prefer this over raw curls.

---

## 1. Create owner (one-time)

Only works when the instance has **no owner yet**. After this, log in with the same email/password.

### Script

```bash
./scripts/n8n-create-users.sh owner \
  --email owner@example.com \
  --first-name Admin \
  --last-name User \
  --password 'OwnerPass1'
```

### API

```http
POST /rest/owner/setup
Content-Type: application/json

{
  "email": "owner@example.com",
  "firstName": "Admin",
  "lastName": "User",
  "password": "OwnerPass1"
}
```

No auth. Cookie may be set on success; you can ignore it and use `/rest/login` later.

---

## 2. Create a normal user (invite + accept simulated)

There is **no** single Community endpoint that creates a ready-to-login member. n8n’s flow is:

1. Owner logs in  
2. Invite → pending user shell (`POST /rest/invitations`)  
3. Get invite JWT (from invite response URL, or `POST /rest/users/:id/invite-link`)  
4. Accept → set name + password (`POST /rest/invitations/accept`)  

After step 4 the user can log in. The script does all of this and prints success JSON.

### Script

Pass the **new user’s** details. Owner credentials are used only to invite (env or flags).

```bash
export N8N_OWNER_EMAIL='owner@example.com'
export N8N_OWNER_PASSWORD='OwnerPass1'

./scripts/n8n-create-users.sh user \
  --email student@example.com \
  --first-name Stu \
  --last-name Dent \
  --password 'StudentPass1'
```

Or:

```bash
./scripts/n8n-create-users.sh user \
  --email student@example.com \
  --first-name Stu \
  --last-name Dent \
  --password 'StudentPass1' \
  --owner-email owner@example.com \
  --owner-password 'OwnerPass1'
```

**Success output (example):**

```json
{
  "ok": true,
  "email": "student@example.com",
  "role": "global:member",
  "message": "User created; can log in at http://localhost:5678"
}
```

Then open the editor and log in with that email/password.

### APIs used (under the hood)

Send a stable `browser-id` header on authenticated calls (same value for login + invite), and keep the session cookie.

| Step | Method | Path | Auth |
|------|--------|------|------|
| Login as owner | `POST` | `/rest/login` | none → cookie |
| Invite | `POST` | `/rest/invitations` | owner cookie |
| Invite link (if needed) | `POST` | `/rest/users/:id/invite-link` | owner cookie |
| Accept | `POST` | `/rest/invitations/accept` | none (JWT in body) |

**Login body:**

```json
{ "emailOrLdapLoginId": "owner@example.com", "password": "OwnerPass1" }
```

**Invite body** (array; Community role = `global:member`):

```json
[{ "email": "student@example.com", "role": "global:member" }]
```

**Accept body** (`token` = JWT from `…/signup?token=…`):

```json
{
  "token": "<JWT>",
  "firstName": "Stu",
  "lastName": "Dent",
  "password": "StudentPass1"
}
```

---

## Limits / notes

- **Owner first** — invites fail until `/rest/owner/setup` (or UI setup) has run.
- **User quota** — Community has a max user count; over quota → invite fails.
- **`global:admin`** invites need a license; use **`global:member`**.
- **SSO** — if SSO is enabled, invite/accept are blocked.
- Public API `POST /api/v1/users` is **Enterprise** — not used here.

---

## Related

- Same-site LMS → editor auto-login (reverse proxy + launch bounce): [`same-site-auto-login.md`](./same-site-auto-login.md)
