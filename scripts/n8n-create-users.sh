#!/usr/bin/env bash
# Create n8n owner or member via REST (Community, no license).
# Docs: docs/user-api.md
set -euo pipefail

BASE_URL="${N8N_BASE_URL:-http://localhost:5678}"
BROWSER_ID="${N8N_BROWSER_ID:-$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "lms-$(date +%s)-$$")}"
COOKIE_JAR="$(mktemp)"
trap 'rm -f "$COOKIE_JAR"' EXIT

usage() {
	cat <<'EOF'
Usage:
  n8n-create-users.sh owner --email E --first-name F --last-name L --password P
  n8n-create-users.sh user  --email E --first-name F --last-name L --password P
                            [--owner-email E] [--owner-password P]

Env:
  N8N_BASE_URL          default http://localhost:5678
  N8N_OWNER_EMAIL       owner login for "user" command
  N8N_OWNER_PASSWORD    owner password for "user" command

Password must be ≥8 chars with at least one uppercase letter and one number.
EOF
}

die() { echo "error: $*" >&2; exit 1; }

# Build JSON object from KEY=env-var-name pairs (values read from those env vars).
json_obj() {
	python3 - "$@" <<'PY'
import json, os, sys
out = {}
for arg in sys.argv[1:]:
    key, env = arg.split("=", 1)
    out[key] = os.environ[env]
print(json.dumps(out))
PY
}

http_json() {
	local method="$1"
	local path="$2"
	local data="${3:-}"
	local url="${BASE_URL}${path}"
	local -a args=(-sS -w '\n%{http_code}' -X "$method" "$url"
		-H "Content-Type: application/json"
		-H "browser-id: ${BROWSER_ID}"
		-b "$COOKIE_JAR" -c "$COOKIE_JAR")
	if [[ -n "$data" ]]; then
		args+=(-d "$data")
	fi
	local resp
	resp="$(curl "${args[@]}")"
	local code="${resp##*$'\n'}"
	local body="${resp%$'\n'*}"
	HTTP_CODE="$code"
	HTTP_BODY="$body"
}

require_password() {
	local p="$1"
	[[ ${#p} -ge 8 ]] || die "password must be at least 8 characters"
	[[ "$p" =~ [A-Z] ]] || die "password must include an uppercase letter"
	[[ "$p" =~ [0-9] ]] || die "password must include a number"
}

cmd_owner() {
	local email="" first="" last="" password=""
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--email) email="$2"; shift 2 ;;
			--first-name) first="$2"; shift 2 ;;
			--last-name) last="$2"; shift 2 ;;
			--password) password="$2"; shift 2 ;;
			-h|--help) usage; exit 0 ;;
			*) die "unknown arg: $1" ;;
		esac
	done
	[[ -n "$email" && -n "$first" && -n "$last" && -n "$password" ]] \
		|| die "owner requires --email --first-name --last-name --password"
	require_password "$password"

	export _E="$email" _F="$first" _L="$last" _P="$password"
	local payload
	payload="$(json_obj email=_E firstName=_F lastName=_L password=_P)"

	http_json POST /rest/owner/setup "$payload"
	if [[ "$HTTP_CODE" != "200" ]]; then
		die "owner setup failed (HTTP ${HTTP_CODE}): ${HTTP_BODY}"
	fi

	BASE_URL="$BASE_URL" EMAIL="$email" python3 -c "
import json, os, sys
raw = sys.stdin.read()
d = json.loads(raw) if raw.strip() else {}
inner = d.get('data', d) if isinstance(d, dict) else {}
print(json.dumps({
  'ok': True,
  'email': inner.get('email') or os.environ['EMAIL'],
  'role': inner.get('role') or 'global:owner',
  'message': f\"Owner created; can log in at {os.environ['BASE_URL']}\",
}, indent=2))
" <<<"$HTTP_BODY"
}

cmd_user() {
	local email="" first="" last="" password=""
	local owner_email="${N8N_OWNER_EMAIL:-}"
	local owner_password="${N8N_OWNER_PASSWORD:-}"
	while [[ $# -gt 0 ]]; do
		case "$1" in
			--email) email="$2"; shift 2 ;;
			--first-name) first="$2"; shift 2 ;;
			--last-name) last="$2"; shift 2 ;;
			--password) password="$2"; shift 2 ;;
			--owner-email) owner_email="$2"; shift 2 ;;
			--owner-password) owner_password="$2"; shift 2 ;;
			-h|--help) usage; exit 0 ;;
			*) die "unknown arg: $1" ;;
		esac
	done
	[[ -n "$email" && -n "$first" && -n "$last" && -n "$password" ]] \
		|| die "user requires --email --first-name --last-name --password"
	[[ -n "$owner_email" && -n "$owner_password" ]] \
		|| die "user requires owner credentials (--owner-email/--owner-password or N8N_OWNER_EMAIL/N8N_OWNER_PASSWORD)"
	require_password "$password"

	# 1) login as owner
	export _OE="$owner_email" _OP="$owner_password"
	local login_payload
	login_payload="$(json_obj emailOrLdapLoginId=_OE password=_OP)"
	http_json POST /rest/login "$login_payload"
	if [[ "$HTTP_CODE" != "200" ]]; then
		die "owner login failed (HTTP ${HTTP_CODE}): ${HTTP_BODY}"
	fi

	# 2) invite
	export _E="$email"
	local invite_payload
	invite_payload="$(python3 -c 'import json,os; print(json.dumps([{"email": os.environ["_E"], "role": "global:member"}]))')"
	http_json POST /rest/invitations "$invite_payload"
	if [[ "$HTTP_CODE" != "200" ]]; then
		die "invite failed (HTTP ${HTTP_CODE}): ${HTTP_BODY}"
	fi

	local user_id invite_url token
	read -r user_id invite_url < <(python3 -c '
import json, sys
raw = sys.stdin.read()
d = json.loads(raw)
items = d.get("data", d) if isinstance(d, dict) else d
if not isinstance(items, list) or not items:
    raise SystemExit("empty invite response")
row = items[0]
if isinstance(row, dict) and row.get("error"):
    raise SystemExit(row["error"])
u = row.get("user", row) if isinstance(row, dict) else row
uid = (u or {}).get("id") or ""
url = (u or {}).get("inviteAcceptUrl") or ""
print(uid, url)
' <<<"$HTTP_BODY") || die "could not parse invite response: ${HTTP_BODY}"

	# 3) invite link if URL missing
	if [[ -z "$invite_url" ]]; then
		[[ -n "$user_id" ]] || die "invite returned no user id and no inviteAcceptUrl: ${HTTP_BODY}"
		http_json POST "/rest/users/${user_id}/invite-link"
		if [[ "$HTTP_CODE" != "200" ]]; then
			die "invite-link failed (HTTP ${HTTP_CODE}): ${HTTP_BODY}"
		fi
		invite_url="$(python3 -c '
import json, sys
d = json.loads(sys.stdin.read())
inner = d.get("data", d) if isinstance(d, dict) else {}
print((inner or {}).get("link") or "")
' <<<"$HTTP_BODY")"
	fi
	[[ -n "$invite_url" ]] || die "could not obtain invite URL"

	token="$(python3 -c '
from urllib.parse import urlparse, parse_qs
import sys
q = parse_qs(urlparse(sys.argv[1]).query)
t = (q.get("token") or [""])[0]
if not t:
    raise SystemExit("no token in invite URL")
print(t)
' "$invite_url")" || die "bad invite URL: ${invite_url}"

	# 4) accept
	export _T="$token" _F="$first" _L="$last" _P="$password"
	local accept_payload
	accept_payload="$(json_obj token=_T firstName=_F lastName=_L password=_P)"
	http_json POST /rest/invitations/accept "$accept_payload"
	if [[ "$HTTP_CODE" != "200" ]]; then
		die "accept invite failed (HTTP ${HTTP_CODE}): ${HTTP_BODY}"
	fi

	BASE_URL="$BASE_URL" EMAIL="$email" python3 -c "
import json, os
print(json.dumps({
  'ok': True,
  'email': os.environ['EMAIL'],
  'role': 'global:member',
  'message': 'User created; can log in at ' + os.environ['BASE_URL'],
}, indent=2))
"
}

main() {
	[[ $# -ge 1 ]] || { usage; exit 1; }
	local cmd="$1"; shift
	case "$cmd" in
		owner) cmd_owner "$@" ;;
		user) cmd_user "$@" ;;
		-h|--help) usage ;;
		*) die "unknown command: $cmd (use owner|user)" ;;
	esac
}

main "$@"
