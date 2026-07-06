# Migrating from the Chat SDK to the Agent SDK

This covers moving an app from the Kapa Chat SDK (`@kapaai/react-sdk`, provider `KapaProvider`, hook `useChat`) to the Agent SDK (`@kapaai/agent-react`, provider `AgentProvider`, hook `useAgentChat`). The knowledge base answering carries over unchanged; the upgrade adds tools, actions, and approval.

Full mapping and the latest details: `https://docs.kapa.ai/dev/agent/guides/migrating-from-chat-sdk`. Follow it as the source of truth.

## First: keep the existing UI, augment it

The aim is continuity. Do not throw away the current experience. Preserve the app's existing look and behavior, then layer the agent's new abilities (tools, approval) on top. Ask the developer which path they want:

- **Adopt the built-in Agent SDK UI** (`AgentChat` / `AgentPanel`). Less code to maintain, gains theming and tool cards for free. Good when their current UI is close to a standard chat.
- **Keep their custom UI** and migrate the logic. In React this means using `agent-react`'s headless `useAgentChat()` hook in place of the Chat SDK's `useChat()`. They keep their own components and swap the hook underneath. (Direct `@kapaai/agent-core` is only for non-React apps; a React app keeping a custom UI still installs `agent-react` and uses its hook.)

Recommend based on how custom their current UI is, then let them choose.

## Install

```bash
npm uninstall @kapaai/react-sdk
npm install @kapaai/agent-react@latest
# if you will use Zod tool schemas:
npm install zod zod-to-json-schema
```

## Provider: KapaProvider to AgentProvider

The biggest change is authentication. The Chat SDK handled auth internally (integration id plus captcha). The Agent SDK requires a server-side session endpoint and a `getSessionToken` function. Set that up first (see `auth-and-history.md`).

Prop mapping:

- `integrationId` stays; add required `projectId`, `model`, and `getSessionToken`.
- `customizationId` (server-side prompt) becomes `customInstructions` (injected into the system prompt).
- `sourceGroupIDsInclude` becomes `sourceGroupIdsInclude` (note the casing change).
- User identity moves to the `user` prop (`{ email?, unique_client_id? }`).
- Bot protection (reCAPTCHA / hCaptcha) and `uncertainAnswerCallout` are gone; session-token auth replaces captcha, and the Agent SDK does not expose an uncertainty flag.

## Hook: useChat to useAgentChat

- `submitQuery(query)` becomes `sendMessage(text)` (returns a `Promise<void>`).
- `isPreparingAnswer` / `isGeneratingAnswer` collapse into a single `isStreaming` boolean (true from the moment `sendMessage` is called until the loop finishes; use it to disable the input and show a stop button).
- `resetConversation` and `stopGeneration` map directly.
- `threadId` maps directly.
- `addFeedback` (thumbs up/down) has no equivalent and is not planned. Build it against your own endpoint if needed.
- `error` is not a top-level field. Errors surface as assistant messages with `isError: true`, and via the `onEvent` callback with `type: 'response_error'`.

## Conversation model: `conversation` (QA pairs) to `messages` (flat array)

This is the largest structural change.

- `conversation` (a class of question/answer pairs) becomes `messages`, a flat array of `{ role: 'user' | 'assistant', content, ... }`.
- Assistant messages add a `blocks` array (interleaved `text` and `tool_calls`). Render blocks in order (recommended) so tool calls appear inline. For the simplest migration you can still render `message.content` as one markdown string, closest to the old `qa.answer`.
- No per-message `id`: use the array index as the React key (messages are append-only). No per-message `status` (use `isStreaming` plus position). No `is_uncertain`, no `reaction`.

## Sources: per-QA to per-tool-call

Sources previously lived on each QA. Now they live on the `search_knowledge_base` tool call results inside an assistant message's `blocks`. Collect them by walking the `tool_calls` blocks and flattening each tool call's `sources`. Field names change: `source_url` becomes `sourceUrl`, `source_type` becomes `sourceType`.

## Callbacks: `callbacks` prop to `onEvent`

The Chat SDK's `callbacks.askAI.*` become a single `onEvent` handler on `AgentProvider` that switches on `event.type`: `message_sent`, `response_completed`, `response_error`, `generation_stopped`, `tool_executed`, `tool_approved`, `tool_denied`, `conversation_reset`. There is no feedback event (feedback is unsupported).

## New capabilities to introduce after the swap

Once the app compiles and chats again with parity, add what the Agent SDK unlocks. Do this incrementally, with the developer:

- **Tools**: follow `tool-discovery.md` and `agent-configuration.md`.
- **Approval** for write and navigation tools.
- **Custom instructions** grounded in the product.
- **Custom rendering** where a result is clearer as a component (mind the duplication pitfall).
- **Theming** to match the app, and **history** if users are signed in.

## Migration checklist

- [ ] `@kapaai/react-sdk` removed, `@kapaai/agent-react` installed (plus `zod` + `zod-to-json-schema` if using Zod).
- [ ] Server-side session endpoint added; `getSessionToken` wired; API key server-only.
- [ ] Provider swapped with `projectId`, `integrationId`, `model`; props remapped.
- [ ] Hook usage swapped; streaming, stop, reset, and errors handled.
- [ ] Rendering updated to the `messages` / `blocks` model; sources read from tool calls.
- [ ] Callbacks moved to `onEvent`.
- [ ] Parity confirmed against the old experience before adding tools.
- [ ] New capabilities (tools, approval, instructions, theming, history) added incrementally.
