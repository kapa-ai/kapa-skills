---
name: analyze-top-questions
description: Analyze a Kapa top questions CSV export against your documentation to assess how well your most important topics are documented. Walk through each topic interactively.
arguments: [csv_path]
allowed-tools: Bash(bash *)
---

# Analyze Top Questions

You are helping the user review their most frequently asked topics and assess whether the documentation serves them well.

## Introduction

Before doing anything else, briefly explain to the user what this process is and how it works:

- Top questions are clusters of the most common themes users ask about, exported from Kapa.
- These represent your highest-traffic topics — the things your users care most about.
- You will walk through each topic one by one, analyze the existing documentation, and assess whether it is serving users well given how they are actually asking about it.
- The user makes the final call on each topic and can choose to improve the documentation on the spot.
- Progress is tracked by moving cluster files between directories (e.g. `to_do/` → `done/`), so the work can be resumed across multiple sessions.

Keep the explanation to a few sentences — just enough so the user understands the flow.

## Setup

### 1. Optionally connect a Kapa hosted MCP server

You can optionally connect your Kapa instance's hosted MCP server. This is not required but can be helpful in two ways:

- **See what Kapa actually surfaces**: For large documentation sites, it lets you check what chunks Kapa retrieves for a given question, rather than just reading the source files yourself. This helps assess discoverability from the user's perspective.
- **Cover all knowledge sources**: Kapa may have access to knowledge sources beyond the documentation repository you are working in — for example, code repositories, Slack threads, or Confluence pages. Querying the MCP server lets you discover if a topic is already covered elsewhere.

You do not need to use the MCP server for every cluster. It is most useful when you are unsure whether the right content is being surfaced, or when you suspect the answer might live outside the documentation repository.

Check if an MCP tool matching `mcp__*__search_*_knowledge_sources` is already available. If it is, confirm with the user which one to use and skip ahead to step 2.

If the user wants to set one up, guide them through:

1. **Create a hosted MCP server** (if they don't have one yet): In the Kapa platform, go to **Integrations → Add new integration → Hosted MCP Server**. Choose a subdomain and set authentication to **API key**.
2. **Install it in Claude Code**: The user should run the following command (replacing the URL with their own):
   ```
   claude mcp add --transport http <server-name> https://<subdomain>.mcp.kapa.ai
   ```
3. **Authenticate**: The user may need to run `/mcp` to authenticate the server.

Once connected, identify the MCP retrieval tool name (it will look like `mcp__<server-name>__search_<project>_knowledge_sources`) and use it when needed throughout the workflow.

If the user chooses not to connect an MCP server, proceed with the documentation analysis using only the source files in the repository.

### 2. Parse the CSV

Run the setup script to parse the CSV and create cluster markdown files:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/setup.sh "$csv_path"
```

Verify the files were created by listing `top_questions/to_do/`.

## Workflow

Walk through each cluster one at a time, starting with the highest thread count. For each cluster:

1. **Read the cluster** — show the user the title, summary, thread count, unique users, and a selection of representative questions. If the unique user count is low relative to the thread count, flag this to the user — it means a small number of people asked repeatedly rather than many users hitting the same topic, so the user may want to skip it.
2. **Analyze the documentation** — search the docs in this repository to find all pages relevant to this topic and read them directly. If a hosted MCP server is connected, you can also query it with representative questions from the cluster to see what the retrieval system actually returns. This is especially useful for large documentation sites, when you are unsure about discoverability, or when the answer might live in a knowledge source outside this repository.

   Consider:
   - **Discoverability**: Would someone phrasing their question like the users in this cluster find the right page?
   - **Completeness**: Do the docs cover what users are actually asking about, or are there subtopics missing?
   - **Clarity**: Given the way users phrase their questions, does the documentation answer them clearly? Are users confused about something the docs could explain better?
   - **Fragmentation**: Is relevant information scattered across too many pages, or is it well-organized?
3. **Present your assessment** to the user. Lead with one of:
   - **Well documented** — the documentation serves this topic well, no changes needed.
   - **Could be improved** — the documentation exists but could better serve users. Explain specifically what could be better and suggest concrete changes.
4. **Wait for the user's decision** before moving the file. The user may agree, disagree, or want to discuss further. They may also want to make improvements immediately.
5. **Update the cluster file** with the analysis and decision, then move it to the appropriate directory based on the user's instruction.
6. **Move to the next cluster** when the user is ready.

## Guidelines

- Be concise in your assessments. Lead with the recommendation.
- When analyzing docs, actually read the relevant files — do not guess.
- Focus on actionable suggestions. "The docs could be better" is not useful. "The setup guide buries the most common configuration option under advanced settings" is useful.
- Pay attention to the phrasing of user questions — it reveals how users think about the topic, which may differ from how the docs are structured.
- Some clusters are noise (analytics questions directed at Kapa itself, off-topic queries). Identify these quickly and move on.
- If the user wants to improve documentation immediately, help them make the edit, then move the cluster to `done/`.
- Keep the user in control — never batch-process clusters without their input.
