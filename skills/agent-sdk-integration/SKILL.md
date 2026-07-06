---
name: agent-sdk-integration
description: Set up, improve, or migrate to the Kapa Agent SDK (@kapaai/agent-react or @kapaai/agent-core), also referred to as the Kapa Agent Framework, in a web app. Always use this whenever a developer mentions the Kapa Agent SDK, the Kapa Agent Framework, or the packages @kapaai/agent-react or @kapaai/agent-core, however they phrase it. Also use it when they want to embed a Kapa AI agent, in-product assistant, or support chat into their app, turn their API endpoints into agent tools, add Kapa knowledge base search to their own UI, review or improve an existing setup, or migrate from the Kapa Chat SDK (@kapaai/react-sdk), even if they never say "Agent SDK" explicitly. Covers React and non-React apps, tool discovery, custom instructions, approval and custom rendering, session-token auth, and conversation history.
---

# Kapa Agent SDK integration

Guide a developer through adding the Kapa Agent SDK to their application, improving an existing integration, or migrating from the Kapa Chat SDK. The Agent SDK embeds an AI agent chat that answers from the customer's knowledge base out of the box (built-in server-side knowledge base search) and can call tools that run in the user's browser.

This skill is a collaborative workflow, not a code generator. Propose, explain the trade-offs, and confirm before making changes. The developer knows their product and their users better than you do.

## Golden rules

1. **Work interactively.** At every decision point (which SDK, which tools, approval, history, UI, how the panel opens), present options with a recommendation and a one-line rationale, then let the developer choose. Grouping a few tightly-related quick decisions into one prompt is fine; do not overwhelm with a long chain, and always give concrete defaults.
2. **Ground every API detail in the source of truth.** The SDK evolves. Do not rely on memory for prop names, tool shapes, or endpoints. Before writing integration code:
   - **Ground against the version you will actually ship, and prefer the latest.** For a new setup or a migration, install the current release explicitly (`npm install @kapaai/agent-react@latest`, or the repo's package manager). Do this even when a copy already exists in `node_modules`: a pre-existing install can be stale and older than the current release, and grounding against it produces outdated code. After installing, read that version's types. For an existing-setup review, ground against the version the repo already ships, and see the Improve section for when to suggest an upgrade.
   - **Read the installed package types.** Find each package's type entry from its own `package.json` (the `types` field, or the `types` entries under `exports`). It is commonly `dist/index.d.ts`, `dist/index.d.mts`, or `dist/index.d.cts`, so do not assume a `.d.ts` extension. Read both `@kapaai/agent-react` and `@kapaai/agent-core`.
   - Consult the official docs at `https://docs.kapa.ai/dev/agent` (fetch them if you have web access). See "Reference links" below.
   - If the installed types disagree with this skill or the docs, trust the installed types for the version you are shipping. This skill's embedded details track the 1.0.0 API.
3. **Never invent endpoints, props, or tool APIs.** Only wire up endpoints you have actually found in the codebase. Only pass props that exist in the installed types.
4. **Never expose the API key to the browser.** Session tokens are minted server-side. See `references/auth-and-history.md`.
5. **Keep the tool set small and high-signal.** Fewer reliable tools beat a large grab-bag. Start with the essential ones and expand later.
6. **Make no destructive changes without buy-in.** Show diffs or plans first.

## Reference links (source of truth)

- Overview: `https://docs.kapa.ai/dev/agent`
- React SDK: `https://docs.kapa.ai/dev/agent/react` and provider props at `https://docs.kapa.ai/dev/agent/react/agent-provider`
- Core (JS/TS) SDK: `https://docs.kapa.ai/dev/agent/core`
- Custom tools: `https://docs.kapa.ai/dev/agent/react/custom-tools` and `https://docs.kapa.ai/dev/agent/core/custom-tools`
- Authentication: `https://docs.kapa.ai/dev/agent/guides/authentication`
- Theming: `https://docs.kapa.ai/dev/agent/react/theming`
- Conversation history: `https://docs.kapa.ai/dev/agent/react/conversation-history`
- Migrating from the Chat SDK: `https://docs.kapa.ai/dev/agent/guides/migrating-from-chat-sdk`
- Best practices for in-product agents: `https://docs.kapa.ai/dev/agent/guides/best-practices-in-product-agent`
- Runnable examples: `https://github.com/kapa-ai/agent-sdk-examples`

## Prerequisites and credentials

The integration needs four values: a **Project ID**, an **Integration ID**, the agent **model** id (for example `kapa-agent-1.0`, pin a specific version), and a server-side **API key**. The Project ID and Integration ID come from the Kapa dashboard (Integrations to Agent); the API key from Settings to API Keys.

Confirm these are actually available before writing any code that depends on them:

- Look where the app keeps configuration: `.env`, `.env.local`, `.env.example`, framework env conventions (`VITE_*`, `NEXT_PUBLIC_*`, and similar), the env schema (for example an `env.mjs` or `env.ts` validation file), and any deployment or secret config. Grep for existing related keys (names containing `AGENT` or `KAPA`) and **reuse them**; do not invent new variable names for config the app already defines. Reading the wrong env var name is a silent failure: the provider builds fine but renders nothing.
- **If a required value or its environment variable is missing, stop and ask the developer for it** (or point them to the dashboard). Do not proceed with placeholder or guessed values: the code will build, but the agent will silently fail at runtime, which is hard to debug.
- Keep the **API key server-side only** (for example `KAPA_API_KEY`); never put it in a client-exposed variable. When you introduce new env vars, add them to `.env.example` (or the repo's documented env list) with empty values, and never commit real secrets.

## Step 0: Detect the mode and confirm

Inspect the repo, then confirm the mode with the developer:

- **No Kapa SDK present** and the developer wants an agent: **Setup**.
- **`@kapaai/react-sdk` present** (the Chat SDK) and the developer wants tools or actions: **Migrate**. See `references/migration.md`.
- **`@kapaai/agent-react` or `@kapaai/agent-core` already present**: **Improve**. Review the existing setup against the checklist at the end and `references/*`, and fix gaps.

Check `package.json` dependencies and search the code for `@kapaai/`.

## Step 1: Explore the codebase

Before recommending anything, build a picture of the app. Do this with searches and by reading a few representative files. Work from the current state of the code: do not mine git history or removed branches for a previous integration to copy, since a prior or deleted setup may be outdated or intentionally gone.

1. **Framework and rendering model.** Read `package.json`. Look for `react`, `next`, `remix`, `vue`, `svelte`, `@angular/core`, `solid-js`, or none. Note TypeScript vs JavaScript. Note bundler (Vite, Next, webpack).
2. **Where the app mounts its top-level providers** (the root component or layout). The Kapa provider must sit high in the tree and stay mounted.
3. **The data-access layer and every endpoint.** This is the most important exploration step and it has its own playbook: follow `references/tool-discovery.md`. It shows how to detect TanStack Query / React Query, SWR, axios, fetch wrappers, tRPC, GraphQL, and generated OpenAPI clients, and how to enumerate all endpoints so none are missed.
4. **Auth model.** How are API calls authenticated (cookies, bearer token, an `apiClient`, an `authFetch` wrapper)? Tools will reuse this. Is there a backend in this repo or a separate one?
5. **Design system and theming.** Note the color system, fonts, dark/light handling, any component library, and any **icon library** (`@tabler/icons-react`, `lucide-react`, `@heroicons/react`, `react-icons`, and similar) so the agent UI and tool icons can match the app.

Summarize what you found back to the developer before proposing the integration.

## Step 2: Choose the SDK (React vs Core)

Recommend, then confirm:

- **React, Next.js, Remix, or any React-based app: use `@kapaai/agent-react`.** It includes `@kapaai/agent-core` as a dependency. This is true even if the developer wants a fully custom UI: in that case they use the headless `useAgentChat()` hook from `agent-react`, not `agent-core` directly.
- **Non-React app (Vue, Svelte, Angular, vanilla JS, server, edge): use `@kapaai/agent-core`.** You will build the chat UI to match the app. See `references/ui.md`.

Within React, decide the UI approach (see `references/ui.md`):
- **Built-in UI** (`AgentChat` or the slide-in `AgentPanel`): fastest, themed, full-featured. Recommend this unless the developer needs deep UI control. If you use `AgentPanel`, ask how they want to open it (a floating action button, a fixed button in the header or nav, a command-menu entry, or other): the trigger is yours to build, not the SDK's. See `references/ui.md`.
- **Headless** (`AgentProvider` + `useAgentChat()`): full control, they build every element.

## Step 3: Session authentication and (optionally) history

Every integration needs a server-side session endpoint. If the backend is in this repo (or this repo is the backend), scaffold the endpoint for the detected framework. Then decide with the developer whether to enable conversation history, which requires a stable per-user owner id in the session request. Follow `references/auth-and-history.md`.

## Step 4: Design the tools

Using the endpoint inventory from Step 1, decide together which endpoints become tools and why. Design tools around the questions and actions users actually have, not around the API surface. Include discovery/list tools that return IDs so the agent can chain them. Split read-only tools (execute immediately) from write or navigation tools (require approval). Follow `references/tool-discovery.md` for candidate selection and `references/agent-configuration.md` for how to define them, when to require approval, and when to render custom UI.

## Step 5: Draft the custom instructions

Write a `customInstructions` block grounded in what you learned about the product and the tools. It should define domain terms, describe how to chain interdependent tools, and prevent known bad patterns (especially repeating rendered data as text). Follow `references/agent-configuration.md`. Do not write it silently: present the draft to the developer and invite edits before finalizing.

## Step 6: Wire it up and verify

Install the current release of the package (`@latest`; do not rely on whatever is already in `node_modules`, which may be stale), add the provider, add the session endpoint, add tools and instructions, and theme it to match the app. Do not import any CSS from the SDK: its styles load at runtime, and importing a package stylesheet (for example `@kapaai/agent-react/dist/style.css`) breaks the build.

Then verify. Static checks are required; live browser testing is offered, not forced:

1. **Static (required).** Run the project's typecheck, linter, and build. Tools are wired to real endpoints and real app types, so a typecheck catches wrong field names, missing exports, and bad endpoint parameters. Fix everything.
2. **Live (optional, ask first).** A green build is not proof it works: a wrong env var name or a provider that is not mounted passes the build but shows nothing, so exercising the app in a browser is the real check. Not every agent can drive a browser, and the developer may not want it, so offer it and only do it yourself if you are able and the developer agrees. Either way, hand the developer a short checklist to confirm (verify knowledge-base-only behavior first, before tools): the assistant opens; knowledge base answers stream with no custom tools involved; each chosen tool fires; approval prompts appear for write and navigation tools; custom-rendered tools do not duplicate their data as text; and, if enabled, history lists and resumes.

## Improve mode: audit an existing integration

Read the existing provider setup, tools, and instructions, then check against this list and fix gaps with the developer:

- The installed SDK version is current. Compare the installed version (in `node_modules`/`package.json`) against the latest release (for example `npm view @kapaai/agent-react version`). If it is behind, point it out and offer to upgrade, summarizing what changed and any migration needed, but let the developer decide. Do not upgrade without buy-in.
- Provider is mounted high and stays mounted (state resets on unmount).
- `tools` and `context` are stable (memoized in React) so they are not recreated every render.
- Every write, delete, or navigation tool sets `needsApproval: true`; read-only tools do not.
- Tool responses are small (return the minimum the agent needs, with a way to drill deeper).
- Discovery/list tools exist and return IDs for the tools that need them.
- Custom-rendered tools do not cause the agent to restate their data as text (see the anti-duplication section in `references/agent-configuration.md`).
- Custom instructions define domain terms and tool-chaining strategy.
- The API key is never in the browser; the session endpoint is server-side.
- If history is enabled, the session is created with a stable owner id.
- Theming matches the host app.

## Final checklist (all modes)

- [ ] Correct SDK chosen and installed at the current release (`agent-react` for React, `agent-core` otherwise; `@latest` for new setups and migrations); `zod` and `zod-to-json-schema` installed if using Zod schemas.
- [ ] Required credentials and env vars are present (Project ID, Integration ID, model, server-side API key); missing ones were confirmed with the developer, not guessed, and added to `.env.example`.
- [ ] Server-side session endpoint returns `{ session_token, expires_at }`; API key stays on the server.
- [ ] Provider configured with `projectId`, `integrationId`, `model`, and `getSessionToken`.
- [ ] Knowledge base answering verified with zero custom tools.
- [ ] Tool set is small, high-signal, and agreed with the developer; write and navigation tools require approval.
- [ ] The built-in `search_knowledge_base` has a friendly display name via `builtinToolMeta`; tools have display names, and icons where the app has an icon library.
- [ ] `customInstructions` drafted from the codebase and shown to the developer for edits.
- [ ] Custom rendering (if any) does not duplicate data as text.
- [ ] History decision made; owner id wired if enabled.
- [ ] If an active tenant/project/workspace scopes the agent, the conversation resets when it changes (and on logout).
- [ ] UI matches the app (theme for React, hand-built to match for Core).
- [ ] Static checks pass (typecheck, lint, build). Live browser behavior checked where possible (by you with the developer's go-ahead, or by the developer following your checklist): KB answer with no tools, each tool fires, approval prompts, history.
