# Tool discovery: find every endpoint, then pick the right tools

Tools are functions the agent can call. In the Agent SDK they run client-side, so they can reuse the app's existing API calls, auth, and permission checks. The goal of this phase is twofold: find **all** the endpoints the app already talks to, then decide **with the developer** which ones become tools and why.

## Part 1: Find every endpoint

Do not guess the data layer. Detect it, then enumerate exhaustively. Apps usually use one or two of these patterns. Search for all of them.

### Detect the data-access layer

Search the codebase for these signals and note which are present:

- **TanStack Query / React Query**: `@tanstack/react-query`, `react-query`, `useQuery(`, `useMutation(`, `useInfiniteQuery(`, `queryFn`, `queryKey`, `QueryClient`. The `queryFn` bodies and `mutationFn` bodies are where the real HTTP calls live.
- **SWR**: `swr`, `useSWR(`, `useSWRMutation(`, and the fetcher functions passed to them.
- **axios**: `axios`, `axios.create(`, `.get(` / `.post(` / `.put(` / `.patch(` / `.delete(`, and any `apiClient` / `http` instance built on it.
- **fetch wrappers**: a project-local helper such as `apiFetch`, `authFetch`, `request`, `httpClient`, `api.ts`, `client.ts`. Grep for `fetch(` and for the wrapper name.
- **tRPC**: `@trpc/`, `createTRPCReact`, `trpc.<router>.<procedure>.useQuery`, and the server router definitions (the routers are the endpoint list).
- **GraphQL**: `graphql`, `useQuery`/`useMutation` from Apollo or urql, `.graphql` files, or generated hooks. The operations and the schema list the fields.
- **Generated API clients**: `openapi-typescript`, `openapi-fetch`, `orval`, `swagger-typescript-api`, `@hey-api/openapi-ts`, GraphQL codegen. These generate a typed client whose methods are the full endpoint list. Find the generated file and read its exported methods.
- **Server routes (if the backend is in this repo)**: Next.js route handlers under `app/api/**/route.ts` or `pages/api/**`, Express/Fastify routers, Django `urls.py` + viewsets, FastAPI routers, Rails routes. These are the authoritative endpoint list for the backend.

### Enumerate exhaustively

Once you know the layer, list every endpoint. Useful tactics:

- Read the central API client or generated client and list its methods.
- Collect all `queryKey`s / query hooks: each usually maps to one read endpoint.
- Collect all mutations: each maps to one write endpoint.
- Grep for the API base URL or path prefix (for example `/api/`, `/v1/`, an env var like `API_URL`) to catch calls that bypass the central client.
- If there is an OpenAPI or GraphQL schema, read it. It is the complete list.

### Build an endpoint inventory

Produce a table you can discuss with the developer. Do not skip this. Example shape:

| Endpoint / method | What it does | Read or write | Typical latency | Auth / scope | Maps to a user question or action? |
|---|---|---|---|---|---|
| `GET /projects` | List projects | read | fast | user token | "what projects do I have" |
| `POST /projects` | Create a project | write | fast | user token | "create a project" |
| `GET /reports/export` | Heavy CSV export | read | slow (>5s) | user token | rarely asked directly |

Fill it from what you actually found. Flag anything slow, destructive, admin-only, or paginated.

## Part 2: Choose which endpoints become tools

Design tools around what users ask and want to do, not around the raw API surface. Walk the inventory with the developer and decide each one. Recommend, give a reason, and let them decide.

### Strong candidates (lean toward including)

- **Reads that answer real questions**: status, details, lists, counts, recent activity, analytics.
- **Discovery / list tools that return IDs.** These resolve human names ("the marketing project") to the IDs other tools need as filters. They are the glue that lets the agent chain calls. Prefer list tools that return both the human-readable name and the ID.
- **Counts.** A dedicated "how many" tool that returns just a number is cheaper than fetching a list and counting.
- **Actions users would delegate**: create, update, tag, trigger. Include these only behind approval (see `agent-configuration.md`).

### Weak candidates (lean toward excluding, at least at first)

- **Slow endpoints** (more than a few seconds). A tool that hangs mid-conversation makes the whole agent feel broken. Exclude until the endpoint is faster, and say so.
- **Endpoints that return huge or deeply nested payloads.** Either exclude, or add a lightweight/summary mode (see below) before including.
- **Rarely-needed, admin-only, or highly sensitive** operations.
- **Anything destructive without a clear user need.**
- **Near-duplicates.** Pick the one that best matches how users ask.

### Reason about the set as a whole

- Prefer a small set of fast, reliable tools that compose well over a comprehensive set. Starting with roughly ten to fifteen and expanding based on usage is usually better than shipping everything.
- Make sure the discovery tools that other tools depend on are included. A filter tool that needs an ID is useless without the list tool that produces it.
- Note interdependencies now; they feed directly into the custom instructions (which tool to call first).

### Prepare endpoints for agent consumption

Existing endpoints are often not agent-ready. Common fixes to propose:

- **Lightweight modes**: add a flag (for example `include_details=false`) that returns summaries instead of full nested objects.
- **Direct lookups**: if an endpoint only returns "the latest" with pagination, a by-key or by-date variant lets the agent fetch a specific item directly.
- **Counting**: a count-only mode (page size 1, return the total) for "how many" questions.
- **Small page sizes** by default so the agent does not request thousands of rows.
- **Selective fields**: strip fields the agent does not need before returning from the tool.

Keep tool responses small. Large responses fill the context window, degrade reasoning, and raise cost. Return the minimum the agent needs, with a way to drill deeper.

## Output of this phase

- An endpoint inventory table.
- An agreed list of tools to build, each with a one-line reason for inclusion or exclusion.
- A note of which tools depend on which (for the custom instructions).
- A list of endpoint adaptations to make (lightweight modes, counts, by-key lookups).
