# Defining tools, approval, custom rendering, and custom instructions

This covers how to turn the chosen endpoints into tools, when to gate them behind approval, when to render custom UI (and how to avoid the common duplication pitfall), and how to draft the custom instructions.

Always confirm prop and type details against the installed package types and `https://docs.kapa.ai/dev/agent`.

## Built-in knowledge base search comes first

Before adding any tool, remember the agent already has a built-in, server-side `search_knowledge_base` tool. It answers product questions from the customer's knowledge sources with cited sources, with no setup. Custom tools are additive on top of that.

**Always give the built-in tool a friendly display name via `builtinToolMeta`.** Without it the chat shows the raw `search_knowledge_base` name, which looks unpolished. Add an `icon` and `iconColor` too when the app has an icon library (see "Display names and icons" below):

```ts
builtinToolMeta: {
  search_knowledge_base: {
    displayName: 'Search docs',
    icon: SearchIcon,   // optional, if the app has an icon library
    iconColor: '#38bdf8', // optional
  },
}
```

## Defining a tool

Use `createToolHelper` for type-safe definitions. In React import it from `@kapaai/agent-react`; in non-React from `@kapaai/agent-core`. Zod schemas need `zod` and `zod-to-json-schema` installed.

```tsx
import { createToolHelper } from '@kapaai/agent-react';
import { z } from 'zod';

type ToolContext = { apiClient: ApiClient }; // whatever your tools need
const tool = createToolHelper<ToolContext>();

const tools = [
  tool({
    name: 'list_orders',                         // sent to the LLM; snake_case, action-oriented
    description: 'List the current user\'s orders, most recent first. Returns id and summary per order.',
    parameters: z.object({
      status: z.enum(['open', 'shipped', 'all']).optional().describe('Filter by status'),
      limit: z.number().optional().describe('Max results, default 20'),
    }),
    displayName: 'List orders',                  // shown in the UI
    execute: async ({ status, limit }, ctx) => {
      return ctx.apiClient.listOrders({ status, limit });   // reuse the app's own API + auth
    },
  }),
];
```

The `execute` function receives the parsed, typed args and the shared `context` object (whatever you passed to the provider or `Agent`). Put the app's API client, auth token, or fetch wrapper in `context` so tools reuse existing authentication and permission checks.

Guidance:

- **Name and description are prompt surface.** The name is the model's first signal for when to call the tool. The description should say what it does and what it returns. Be concrete.
- **Keep parameter schemas simple.** Simple schemas produce far more reliable tool calls than complex nested ones. If the model fills a tool inconsistently, simplify the schema before adding more instructions.
- **Return small results.** See `tool-discovery.md`. Trim and flatten before returning.

## Display names and icons

Give every tool a human-readable `displayName`; it is what the chat shows instead of the raw snake_case name. Set it on the built-in tool too, via `builtinToolMeta` (above).

If the codebase already uses an icon library, set an `icon` (and optional `iconColor`) on each tool and on the built-in tool so the chat matches the app's visual language. Detect the library during exploration; common ones are `@tabler/icons-react`, `lucide-react`, `@heroicons/react`, and `react-icons`. The `icon` prop expects a component that accepts `{ size?, color?, stroke? }` props, so Tabler, Lucide, and Heroicons-style components fit directly. If the app's icons do not match that shape, wrap them in a small adapter or skip the icon rather than passing an incompatible component. Do not add an icon dependency just for this; use only what the app already has. (`icon` and `iconColor` are React-only; in Core you render icons yourself.)

## Approval: read vs write

Set `needsApproval: true` on any tool that changes data, has side effects, or navigates the user. Read-only tools should execute immediately (no approval), or the agent feels sluggish.

- **No approval**: list, get, search, count, analytics. Anything read-only.
- **Approval required**: create, update, delete, tag, trigger jobs, send messages, and navigation / deep-linking (redirecting the user unexpectedly is jarring).

```tsx
tool({
  name: 'cancel_order',
  description: 'Cancel an order by id.',
  parameters: z.object({ orderId: z.string() }),
  needsApproval: true,               // shows Allow / Deny before executing
  execute: async ({ orderId }, ctx) => ctx.apiClient.cancelOrder(orderId),
});
```

With the built-in UI, approval shows Allow / Deny buttons automatically. In headless mode you render them and call `approveToolCall(id)` / `rejectToolCall(id)` from `useAgentChat()` (or the `Agent` methods). Tool status is `approval_requested` until the user decides.

## Custom rendering

By default a tool result renders as an expandable card with JSON. Use the `render` prop (React) when a result is much clearer as a chart, card, table, or other component. This is a React-only feature; in Core you decide how to render tool results in your own UI code.

```tsx
tool({
  name: 'get_revenue_series',
  description: 'Return revenue per period for charting.',
  parameters: z.object({ period: z.enum(['weekly', 'monthly']) }),
  execute: async ({ period }, ctx) => ctx.apiClient.revenueSeries(period),
  render: ({ status, result }) => {
    if (status !== 'completed') return null;    // fall back to the default card while running
    return <RevenueChart data={result as Series} />;
  },
});
```

`render` receives `{ status, args, result, error, onApprove, onReject }`. Returning `null` for a status falls back to the default card, so you can customize only the states you care about (for example, keep the default approval UI and only customize the completed state).

Keep the chart or card **schema simple**. A tool with a small, flat data shape (for example a `title`, a `type`, and an array of `{ label, value }`) renders reliably. A tool with a large nested config that mixes data and styling tends to be filled inconsistently by the model.

## The custom-render duplication pitfall (important)

When a tool renders its own UI (a chart, a card), the model will often **also restate the same data as text**, so the user sees the chart and then a paragraph listing every number. This is the single most common polish problem. Defend against it in two complementary ways:

1. **Instruct the model.** Add a rule to `customInstructions`, for example: "After a tool renders its own visual output (a chart or card), do not repeat the underlying numbers in prose. Give only a one-line takeaway or a next step."
2. **Shape the tool response.** Return a result that signals the UI is already shown rather than dumping the full dataset back into the conversation. For example, return a small object like `{ displayed: true, note: 'Chart shown to the user.' }` (plus any minimal summary the model genuinely needs to reason further), instead of returning the whole series again as text.

Verify this live: ask something that triggers the rendered tool and confirm the model does not echo the data as text underneath.

## Drafting the custom instructions

`customInstructions` is injected into the system prompt and is the single biggest quality lever. Draft it from what you learned about the product and the tools, then review it with the developer. Keep every line earning its place; add a line because you observed a specific failure, not speculatively.

Structure it in sections:

1. **Role and domain context.** One or two sentences on what the product is and what the agent helps with. Then define the domain terms the agent will encounter (drawn from the app's models, types, and UI labels) so it does not misuse them.
2. **Tool strategy, especially chaining.** Describe how tools combine for common tasks. This is where interdependencies from `tool-discovery.md` go. Typical patterns:
   - "To filter by a named entity, first call the relevant list tool to resolve the name to an id, then pass the id to the filtering tool."
   - "For how-many questions, use the count tool rather than listing and counting."
   - "Prefer short keyword search terms over full sentences" (if the search endpoint expects that).
3. **Anti-patterns to prevent.** The duplication rule above. Any "never state X as exact when the result is capped" rules. Anything you saw the agent get wrong.
4. **Optional reinforcement of grounding.** The built-in search already makes the agent cite sources and express uncertainty when the knowledge base lacks an answer. You usually do not need to restate this, but you may reinforce tone if the developer wants.

Draft, then walk through it with the developer line by line. Iterate against real questions.
