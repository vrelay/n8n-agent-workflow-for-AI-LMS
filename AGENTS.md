# AGENTS.md — AI LMS / n8n customization guide

Guidance for humans and coding agents working on this repo. Read this before changing n8n UI or the Docker setup.

## What this repo is

Parent product repo that embeds **n8n as a git submodule** and strips/adapts the editor for an AI LMS (students build simple agentic workflows).

| Piece | Location |
|-------|----------|
| Parent (compose, docs, lesson workflows) | this repo root |
| n8n source (all UI/backend edits) | `n8n/` submodule |
| Fork remote | `https://github.com/vrelay/n8n.git` (`origin`) |
| Upstream official n8n | `https://github.com/n8n-io/n8n.git` (`upstream` inside `n8n/`) |
| Working branch in fork | `ai-lms` |
| Editor UI package | `n8n/packages/frontend/editor-ui/` |

Submodule URL/branch: see `.gitmodules`.

---

## Customization rules (important)

We will comment out / hide a **lot** of stock n8n chrome over time. Keep diffs small and reversible.

1. **Prefer comment-out over delete** for UI we may want back later.
2. Mark every LMS change with a short comment: `LMS:` (JS/TS) or `<!-- LMS: … -->` (template).
3. **Do not invent parallel apps** — change the existing Vue views/layouts in `editor-ui`.
4. Change **as little as possible**. Find the narrowest component (layout → view → slot) and comment there.
5. After commenting template usage, **comment unused imports** too so lint/build stays clean.
6. Commit in the **submodule first**, push `ai-lms`, then bump the submodule SHA in the parent and commit the parent.

### Comment style example

```vue
<!-- LMS: hide Overview header / ProjectTabs / Insights -->
<!--
<template #header>
  <ProjectHeader ... />
</template>
-->
```

```ts
// LMS: hide main sidebar — uncomment to restore stock chrome
// import AppSidebar from '@/app/components/app/AppSidebar.vue';
```

---

## How to find UI fast

Stock n8n editor is Vue. Typical path for a browser URL:

```
URL path
  → router (projects.routes.ts / router.ts)
  → view (*.vue under app/views or features/)
  → layout (DefaultLayout / WorkflowLayout / BaseLayout)
  → slots (#header, #sidebar, #callout, …)
```

### Search playbook

| Goal | Where to look |
|------|----------------|
| Route for `/home/workflows` | `n8n/packages/frontend/editor-ui/src/features/collaboration/projects/projects.routes.ts` |
| Main router | `n8n/packages/frontend/editor-ui/src/app/router.ts` |
| View name constants | `n8n/packages/frontend/@n8n/frontend-constants/src/views.ts` |
| Workflows list page | `n8n/packages/frontend/editor-ui/src/app/views/WorkflowsView.vue` |
| Overview tabs / create / title | `.../projects/components/ProjectHeader.vue`, `ProjectTabs.vue` |
| List chrome (search/sort/filters) | `.../app/components/layouts/ResourcesListLayout.vue` |
| App shell (sidebar) | `.../app/layouts/DefaultLayout.vue` |
| Canvas / editor shell | `.../app/layouts/WorkflowLayout.vue` |
| Workflow header / ⋯ menu | `.../app/components/MainHeader/MainHeader.vue`, `WorkflowDetails.vue`, `ActionsDropdownMenu.vue`, `WorkflowHeaderDraftPublishActions.vue` |
| Node creator (+) allowlist | `.../app/constants/nodeCreator.ts` (`LMS_ALLOWED_NODE_TYPES`), `.../features/shared/nodeCreator/` |
| Canvas node ⋯ menu | `.../features/shared/contextMenu/composables/useContextMenuItems.ts` |
| Node details (NDV) | `.../features/ndv/shared/views/NodeDetailsViewV2.vue`, `.../ndv/panel/components/NDVHeader.vue` |
| Version history UI | `.../features/workflows/workflowHistory/` |
| Global banners/modals/chat | `.../app/App.vue` |

Useful ripgrep patterns from repo root:

```bash
rg -n "path: '/home" n8n/packages/frontend/editor-ui
rg -n "WorkflowsView|VIEWS.WORKFLOWS|ProjectTabs" n8n/packages/frontend/editor-ui/src
rg -n "LMS_ALLOWED_NODE_TYPES|LMS:" n8n/packages/frontend/editor-ui   # allowlist + all patches
```

### Already customized (LMS work so far)

Search for `LMS:` markers under `editor-ui`. Inventory (comment-outs / slimmed menus — restore from git if needed):

**Layouts / chrome**
- `DefaultLayout.vue` — main sidebar (Overview / Projects / Templates / …) commented out
- `WorkflowLayout.vue` — sidebar + AI assistant/chat overlays commented out

**Workflows list (`/home/workflows`)**
- `WorkflowsView.vue` — overview header / ProjectTabs / Insights / callouts / onboarding empty / template recs / stock filters panel hidden; funnel toggles archived; list + search/sort remain
- `WorkflowCard.vue` — Share + Favorite removed from card ⋮; Personal/ownership badge hidden

**Workflow editor header**
- `MainHeader.vue` — Editor / Executions / Evaluations tab bar hidden
- `WorkflowDetails.vue` — Personal/folder breadcrumbs, tags, production checklist badge hidden (title edit + actions remain)
- `WorkflowHeaderDraftPublishActions.vue` — Publish + version chevron hidden; history + ⋯ kept
- `ActionsDropdownMenu.vue` — student ⋯ only: edit description, duplicate, download, import file, archive/delete (Share / owner / rename / favorite / import URL / push / settings … commented)
- `DuplicateWorkflowDialog.vue` — tag picker hidden on duplicate

**Version history**
- `WorkflowHistoryButton.vue` — text “Versions” label instead of history icon
- `WorkflowHistory.vue` — Versions only (Publish Timeline tab hidden); version ⋯ keeps open / download / restore
- `WorkflowHistoryUpgradeFooter.vue` — upgrade-plan CTA hidden

**Canvas / node picker**
- `nodeCreator.ts` — `LMS_ALLOWED_NODE_TYPES` flat allowlist (Agent, Chat/Manual/Schedule triggers, Set, HTTP Request (+ tool), If/Switch/Merge/Wait/NoOp, Simple Memory, Calculator/Think/Code tools). OpenRouter Chat Model omitted (use HTTP + `$env.OPENROUTER_API_KEY`)
- `viewsData.ts` / `NodeCreator.vue` — flat A–Z allowlist; stock Trigger/Regular nesting removed; search + AI pickers filter to allowlist
- `NodeCreation.vue` — command-bar (Cmd+K) + focus/side-panel canvas buttons hidden
- `useContextMenuItems.ts` — node ⋯ keeps Open / Rename / Replace / Copy / Duplicate; advanced items (pin, tidy, extract, group, …) dropped

**Node details view (NDV)**
- `NodeDetailsViewV2.vue` — Input / Config / Output **tabs** (one panel at a time) instead of stock 3-column resize layout; defaults to Config
- `NDVHeader.vue` — Docs link hidden

---


## Dev container / refresh workflow

**Use this for UI work:**

```bash
docker compose -f docker-compose.dev.yml up --build
```

- Mounts `./n8n` → `/app` in the container
- Entrypoint: `docker/dev-entrypoint.sh` (install/build only if missing, then `pnpm start`)
- Editor: http://localhost:5678
- **Important:** `pnpm start` serves the **built** editor (`editor-ui` dist), not Vite HMR by default. Source edits do **not** appear until you rebuild `n8n-editor-ui`.

### Fast UI refresh (after editing Vue/TS under editor-ui)

On the **host** (Node ≥ 22 preferred; this machine uses nvm Node 24):

```bash
export PATH="$HOME/.nvm/versions/node/v24.15.0/bin:$PATH"   # adjust if needed
cd n8n
pnpm --filter n8n-editor-ui build
cd ..
docker compose -f docker-compose.dev.yml restart n8n
```

Then hard-refresh the browser (cache can stick).

Rebuild **inside** the container only if host Node/deps match; host rebuild is usually faster and more reliable when `./n8n` is bind-mounted.

### Optional Vite HMR (live UI without full rebuild)

With the stack already up on `:5678`:

```bash
# from compose comments / runbook
docker compose -f docker-compose.dev.yml run --rm -p 8080:8080 n8n \
  pnpm --filter n8n-editor-ui dev -- --host 0.0.0.0
```

Or on host: `cd n8n/packages/frontend/editor-ui && pnpm dev` (port 8080). Backend still on 5678.

### Other useful commands

```bash
# Status
docker compose -f docker-compose.dev.yml ps
docker compose -f docker-compose.dev.yml logs n8n --tail 50

# Full first-time / dirty reset of install+build (slow)
docker compose -f docker-compose.dev.yml exec n8n pnpm install
# or delete n8n/node_modules + dist and restart compose so entrypoint rebuilds

# Prod (image from local ./n8n — LMS UI included)
./docker/build-prod-image.sh
docker compose up -d
```

---

## Git / submodule workflow

```bash
# 1) Edit and commit inside the fork checkout
cd n8n
git checkout ai-lms
# ... edits ...
git add -p
git commit -m "LMS: <what and why>"
git push origin ai-lms

# 2) Point parent at new SHA
cd ..
git add n8n
git commit -m "chore: bump n8n submodule for <change>"
```

Pull upstream later (when intentional):

```bash
cd n8n
git fetch upstream
git merge upstream/master   # or rebase; resolve carefully
```

---

## Product constraints (keep in mind)

- Students use a **small set of nodes** (`LMS_ALLOWED_NODE_TYPES`); we constrain UX, not invent a new engine.
- Prefer hiding chrome (sidebar, tabs, publish/share/tags, callouts, AI overlays, 3-column NDV) over rewriting business logic.
- Lesson workflows live in parent `workflows/` (e.g. `homework-helper.json`), not only inside the submodule.
- When you land new LMS patches, update the inventory above and keep `README.md` / `docs/runbook.md` aligned if behaviour changes for operators.
- More context: `README.md`, `docs/runbook.md`.
