# Same-site auto-login to n8n editor

Goal: LMS click **Open editor** → new tab opens editor already logged in.  
Approach: serve LMS + n8n under **one parent host**, bounce through a launch URL that sets `n8n-auth`, then redirect into the editor.

---

## 1. Reverse proxy

```
https://app.example.com/          → LMS
https://app.example.com/n8n/      → n8n
```

n8n env (minimum):

```bash
N8N_HOST=app.example.com
N8N_PROTOCOL=https
N8N_PATH=/n8n/
N8N_EDITOR_BASE_URL=https://app.example.com/n8n/
N8N_SECURE_COOKIE=true
N8N_SAMESITE_COOKIE=lax
WEBHOOK_URL=https://app.example.com/n8n/
```

Proxy must forward `Host`, `X-Forwarded-Proto`, `X-Forwarded-For`, and cookies. Strip or keep `/n8n` consistently with `N8N_PATH`.

---

## 2. User provisioning (once per LMS user)

Before first Open, ensure an n8n member exists (Community invite+accept). See [`user-api.md`](./user-api.md) / `scripts/n8n-create-users.sh`.

Store on LMS side: n8n email + password (or password vault). Owner credentials only for invite; students use member accounts.

---

## 3. Launch endpoint (LMS backend)

**Link in LMS UI**

```html
<a href="https://app.example.com/api/n8n/launch?return=/home/workflows"
   target="_blank" rel="noopener">Open editor</a>
```

Do **not** link straight to `/n8n/`. Always go through launch.

**Handler** (`GET /api/n8n/launch`) — same origin as the proxy:

1. Require LMS session (who is clicking).
2. Resolve that user’s n8n email/password.
3. Server-side login to n8n:

```http
POST https://app.example.com/n8n/rest/login
Content-Type: application/json
browser-id: <stable-uuid-per-user-or-device>

{"emailOrLdapLoginId":"<email>","password":"<password>"}
```

4. Read `Set-Cookie: n8n-auth=…` from the response.
5. Respond to the browser:

```http
302 Found
Location: https://app.example.com/n8n/<return path>
Set-Cookie: n8n-auth=<token>; Path=/n8n; HttpOnly; Secure; SameSite=Lax
```

Use the return path from query (allowlist prefixes like `/home`, `/workflow` only — block `//` / external URLs).

Optional: mint a short-lived one-time token in the link (`?t=…`) so the launch URL itself isn’t a long-lived session; exchange `t` → LMS user → login as above.

---

## 4. Cookie rules

| Item | Value |
|------|--------|
| Name | `n8n-auth` |
| Path | `/n8n` (or `/` if you prefer host-wide) |
| HttpOnly | yes |
| Secure | yes (HTTPS) |
| SameSite | `Lax` (fine for top-level new tab) |
| Domain | omit (host-only `app.example.com`) |

Only this cookie is required for editor session. Do not try to set it from a different site — the launch bounce on `app.example.com` is what makes it work.

`browser-id`: if you send it on login, the JWT may bind to it. Either:

- omit / don’t bind for launch, or  
- set the same id in a way the editor will reuse (editor normally keeps a UUID in `localStorage` and sends header `browser-id`).

If login works but API calls 401 immediately, mismatch on `browser-id` is a common cause — align launch login with what the editor sends, or issue without binding.

---

## 5. Checklist for a dev

- [ ] Proxy `/n8n` → n8n with path + env above  
- [ ] Create member via invite/accept API when LMS user is provisioned  
- [ ] Implement `GET /api/n8n/launch` (auth → n8n login → Set-Cookie → 302)  
- [ ] LMS button opens **launch URL** in `target=_blank`  
- [ ] Verify: new tab lands in editor with no login screen  
- [ ] Verify: logout in editor clears session; Open again re-logins via launch  

---

## Out of scope here

- Cross-domain cookie planting (won’t work)  
- Enterprise token-exchange / embed (`/rest/auth/embed`) — optional later, not required for this path  
- Forging JWTs with n8n’s secret — avoid; always obtain `n8n-auth` via `/rest/login`
