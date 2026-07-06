# Building the UI

How to mount the agent and render the chat, for both React (`@kapaai/agent-react`) and non-React (`@kapaai/agent-core`) apps. Match prop and export names against the installed types and `https://docs.kapa.ai/dev/agent`.

**Do not import any CSS from the SDK.** The React SDK injects its own styles at runtime, so no stylesheet import is needed. The package does ship a `dist/style.css`, but it is not exposed through the package `exports` map (only the root entry is), so importing it (for example `import '@kapaai/agent-react/dist/style.css'`) does not resolve and breaks the build. Just mount `AgentProvider` and the styles apply automatically.

## Shared rule: mount the provider high and keep it mounted

The provider (React `AgentProvider`, or the Core `Agent` instance) holds all conversation state: messages, streaming status, session token, approval state. Mount it high in the tree and keep it mounted for the app's lifetime. Unmounting it resets everything. Show and hide the chat by toggling the panel's `open` prop or conditionally rendering the chat component, not by unmounting the provider.

In React, also keep `tools` and `context` **stable** with `useMemo` so they are not recreated on every render. Recreating them churns the agent's configuration and can cause tools to see stale values.

**Reset the agent when the app's active scope changes.** If the agent is scoped to a tenant, project, workspace, or user (for example its tools and its session token are minted for the currently selected project), then a stale conversation and a session from the old scope will leak when the user switches. Watch that scope and call `resetConversation()` when it changes. In React this is a small effect keyed on the scope id that calls `resetConversation` from `useAgentChat()`. Reset on logout too.

## React: built-in UI (recommended default)

Fastest path, fully themed, handles streaming, markdown, tool cards, approval, sources, and history.

```tsx
import { AgentProvider, AgentChat } from '@kapaai/agent-react';

const tools = useMemo(() => buildTools(), []);
const context = useMemo(() => ({ apiClient }), [apiClient]);

<AgentProvider
  getSessionToken={getSessionToken}
  projectId="your-project-id"
  integrationId="your-integration-id"
  model="kapa-agent-1.0"
  tools={tools}
  context={context}
  customInstructions={instructions}
  theme={{ accentColor: '#2563eb', colorScheme: 'auto' }}
  enableHistory={false}
>
  <div style={{ height: '100vh' }}>
    <AgentChat branding={{ title: 'AI Assistant', examplePrompts: ['How do I get started?'] }} />
  </div>
</AgentProvider>
```

- `AgentChat` fills its parent container, so give the parent a defined height.
- For a slide-in drawer instead, use `AgentPanel`, which you control with an `open` / `onClose` pair (add a `top` offset if the app has a fixed navbar). Toggling `open` preserves state.
  - **The SDK does not provide the button that opens the panel; you build it.** First check whether the app already has an assistant, "Ask AI", or help entry point; if so, wire that to open the panel instead of adding a duplicate trigger. Otherwise this is a visible, product-shaping choice, so ask the developer how they want to trigger it and place it accordingly. Common options: a floating action button (fixed corner, always visible), a fixed button in the existing header or nav bar, an entry in a sidebar or command menu, or a keyboard shortcut. Match the app's existing patterns, and wire the trigger to set the state that drives `AgentPanel`'s `open` prop.
- For advanced layouts, lower-level components are exported (`AgentInput`, `AgentMessageBubble`, `ToolCallCard`, `SourceTiles`, `ExamplePrompts`, `AgentThreadHistory`). Use only if needed.
- If the app has an analytics tool (PostHog, Segment, and similar), pass an `onEvent` handler to `AgentProvider` to forward agent events (message sent, tool executed, errors, and so on) for observability, using whatever analytics client the app already uses.

## React: headless (full UI control)

Use `AgentProvider` for state plus the `useAgentChat()` hook, and build every element yourself. This is still the `agent-react` package, not `agent-core`.

```tsx
import { AgentProvider, useAgentChat } from '@kapaai/agent-react';

function Chat() {
  const {
    messages, isStreaming, inputValue, setInputValue,
    sendMessage, stopGeneration, approveToolCall, rejectToolCall,
  } = useAgentChat();
  // render messages (see message model below), an input, and tool cards with Allow/Deny
}
```

You render: user bubbles, assistant text, tool call cards (name, status, result, sources), approval buttons, and a streaming indicator. Use a markdown renderer for assistant text and sanitize the output (for example `marked` plus `DOMPurify`).

## Non-React: the Core SDK, build a UI that matches the app

For Vue, Svelte, Angular, vanilla JS, or any non-React app, use `@kapaai/agent-core` directly and render into the app's own components so the chat looks native.

```js
import { Agent } from '@kapaai/agent-core';

const agent = new Agent({
  projectId: 'your-project-id',
  integrationId: 'your-integration-id',
  model: 'kapa-agent-1.0',
  tools: [],
  context: {},
  getSessionToken,
  onMessagesChange: (messages) => renderMessages(messages), // wire to reactive state
  onStreamingChange: (isStreaming) => toggleIndicator(isStreaming),
});

await agent.sendMessage('How do I get started?');
```

Methods: `sendMessage`, `stopGeneration`, `resetConversation`, `approveToolCall(id)`, `rejectToolCall(id)`, plus history methods when enabled. Wire `onMessagesChange` and `onStreamingChange` to the framework's reactive state (a Vue `ref`, a Svelte store, an Angular signal or subject).

Build the UI to match the host app: reuse its typography, colors, spacing, buttons, and dark/light handling rather than inventing a new look. Render assistant text as sanitized markdown.

### Message model (both Core and headless React)

Assistant messages carry `blocks`, an ordered array of `text` and `tool_calls` segments. Render blocks in order so text and tool cards interleave the way the agent produced them.

```ts
type ContentBlock =
  | { type: 'text'; content: string }
  | { type: 'tool_calls'; toolCalls: ToolCallDisplay[] };
```

Each `ToolCallDisplay` has `name`, `displayName`, `status`, `arguments`, `result`, `error`, `durationMs`, and `sources`. Statuses: `pending`, `approval_requested`, `executing`, `completed`, `error`, `denied`, `stopped`. Show Allow / Deny when `status === 'approval_requested'`. Show `sources` (each has `title`, `sourceUrl`, `sourceType`, `sourceVisibility`) as citation links or tiles.

## Theming to match the app

React exposes a `theme` prop on `AgentProvider`:

- `accentColor` (hex; a full palette is generated). **Always set this from the app's primary/brand color token; do not ship only `colorScheme`.** The SDK auto-contrasts foreground text against it.
- `colorScheme`: `'dark' | 'light' | 'auto'`. Use `'auto'` to follow system, or drive it from the app's own theme toggle via `useAgentColorScheme()`.
- `fontFamily`, `fontSize`, `radius` (`'sharp' | 'soft' | 'round' | 'pill'`). Match the app's font and corner style.

Pull these values from the app's existing design tokens or theme config rather than hardcoding, so the agent stays visually consistent as the app's theme changes. In Core apps there is no `theme` prop; you achieve consistency by building the UI with the app's own components and tokens.
