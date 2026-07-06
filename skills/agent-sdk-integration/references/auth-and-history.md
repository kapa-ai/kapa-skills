# Session authentication and conversation history

The SDK runs in the browser and talks to the Kapa API using short-lived **session tokens**. Your server mints a token from your API key; the SDK uses the token for all its calls and refreshes it automatically. The API key never reaches the browser.

Confirm the exact endpoint and payload shape against `https://docs.kapa.ai/dev/agent/guides/authentication`.

## The flow

1. The browser calls your own endpoint (for example `POST /api/session`).
2. Your server calls the Kapa session API with the `X-API-Key` header.
3. Kapa returns `{ session_token, expires_at }` (token valid for about an hour).
4. Your server forwards that response to the browser.
5. The SDK caches the token, refreshes it before expiry, and retries once on a 401.

Kapa session endpoint:

```
POST https://api.kapa.ai/agent/v1/projects/{projectId}/agent/sessions/
Header: X-API-Key: <your server-side API key>
```

## The frontend side

`getSessionToken` points at your endpoint, not at Kapa directly:

```ts
getSessionToken={async () => {
  const res = await fetch('/api/session', { method: 'POST' });
  if (!res.ok) throw new Error('Session creation failed');
  return res.json(); // raw { session_token, expires_at }; see the TypeScript note below
}}
```

At runtime the SDK accepts either the raw Kapa response `{ session_token, expires_at }` or the normalized `{ token, expiresAt }` (where `expiresAt` is a number). Under TypeScript the two packages type this differently: the core `Agent` accepts either shape, but the React `AgentProvider`'s `getSessionToken` prop is typed to return `{ token, expiresAt }`. So in a React plus TypeScript app, either map the response to that shape (for example `{ token: r.session_token, expiresAt: Date.parse(r.expires_at) }`) or return the raw shape with a cast. In plain JavaScript, returning `res.json()` as-is works. The SDK calls `getSessionToken` lazily on the first message, caches the token, and refreshes it about 30 seconds before expiry.

## The backend side: scaffold the endpoint

If the backend is in this repo (or this repo is the backend), create the endpoint for the detected framework. It must keep the API key in a server-side environment variable (for example `KAPA_API_KEY`) and the project id server-side too (for example `KAPA_PROJECT_ID`). If those env vars are not already defined in the repo, ask the developer for the values (or point them to the dashboard), add the keys to `.env.example`, and do not leave the code referencing variables that are never set. Below are minimal, framework-appropriate shapes. Adapt them to the repo's conventions (error handling, auth middleware, logging).

**Next.js App Router** (`app/api/session/route.ts`):

```ts
import { NextResponse } from 'next/server';

export async function POST() {
  const res = await fetch(
    `https://api.kapa.ai/agent/v1/projects/${process.env.KAPA_PROJECT_ID}/agent/sessions/`,
    { method: 'POST', headers: { 'X-API-Key': process.env.KAPA_API_KEY! } },
  );
  if (!res.ok) return NextResponse.json({ error: 'Session failed' }, { status: res.status });
  return NextResponse.json(await res.json());
}
```

**Express**:

```js
app.post('/api/session', async (req, res) => {
  const r = await fetch(
    `https://api.kapa.ai/agent/v1/projects/${process.env.KAPA_PROJECT_ID}/agent/sessions/`,
    { method: 'POST', headers: { 'X-API-Key': process.env.KAPA_API_KEY } },
  );
  if (!r.ok) return res.status(r.status).json({ error: 'Session failed' });
  res.json(await r.json());
});
```

**Other backends (Django, FastAPI, Rails, Go, etc.)**: same three moves. Read `KAPA_API_KEY` and `KAPA_PROJECT_ID` from server config, `POST` to the Kapa session URL with the `X-API-Key` header, forward the JSON response to the client. Reuse the app's existing auth so only signed-in users can mint a session.

### When the frontend talks to a separate backend

Many frontends (especially SPAs) have no server of their own but call a separate backend through an authenticated fetch or API client. In that case:

- **Reuse the app's existing authenticated request layer** (the `authFetch`, `apiClient`, or cookie/session mechanism you found during exploration) to call the session endpoint, so only signed-in users can mint a token and you do not build a second auth path.
- **The session-minting endpoint lives on that backend, not in the frontend. Find the real route; do not guess it.** If the backend is a repo in the same workspace, read its URL routing and the session view to confirm the exact path, its path parameters, and how it derives `external_owner_id`. Do not blind-probe URLs with curl; read the source. Inventing a path (wrong prefix or wrong id) builds fine and then returns 404 at runtime.
- If that backend does not yet expose a session-mint endpoint, it must be added there (server-side, holding the API key and stamping `external_owner_id`). The frontend cannot mint tokens itself.
- Watch the project-id semantics: the id in the endpoint URL may be a permission gate (a project the signed-in user can access) that is distinct from the Kapa **agent** project id passed to the provider. Confirm which is which from the backend rather than assuming they are the same.

If there is genuinely no backend at all, tell the developer they need one small server endpoint (they cannot mint tokens from the browser) and give them the shape above for their stack.

## Conversation history

History lets users see and resume past conversations. It is **off by default** and has two requirements:

1. Set `enableHistory: true` on the provider (React) or in the `Agent` options (Core).
2. Create the session with a stable **owner id** so Kapa knows which user owns the threads.

Decide with the developer:

- **Enable it** when users are signed in, will return, and benefit from resuming past chats.
- **Skip it** for anonymous or one-off usage. Chat still works fully without history.

### Wiring the owner id (required for history)

The owner id is passed as `external_owner_id` in the **body** of the session request, set by your trusted backend. It must be stable for the same user across sessions (for example an internal user id or a hashed email). The browser never sets it, so a user cannot forge another user's history.

```ts
// server side, inside your session endpoint
body: JSON.stringify({ external_owner_id: currentUser.id }),
// remember to send 'Content-Type': 'application/json'
```

Then the built-in `AgentChat` shows a history toggle automatically. In headless or Core usage, call the history methods from `useAgentChat()` or the `Agent`:

- `listThreads(options?)` returns `{ threads, nextCursor }`.
- `resumeThread(threadId)` loads a past conversation into the current chat.
- `deleteThread(threadId)` soft-deletes a thread.

Sessions created without `external_owner_id` can still chat, but the history methods throw `SessionWithoutOwnerError`. Calling history methods when `enableHistory` is off throws `HistoryDisabledError`. A missing or foreign thread id throws `ThreadNotFoundError`. Import these from `@kapaai/agent-core`.

### Verifying history

Create a session with the owner id, have two conversations, reload, and confirm they appear in the list and resume correctly. Confirm a session created without the owner id does not expose another user's threads.
