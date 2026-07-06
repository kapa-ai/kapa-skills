# kapa-skills

A collection of AI agent skills for working with [Kapa](https://www.kapa.ai). These skills let you instruct your AI agents to work with Kapa's data and capabilities using workflows recommended by the Kapa team.

## Skills

| Skill | Description |
|-------|-------------|
| [Analyze Coverage Gaps](#analyze-coverage-gaps) | Work through topics where your documentation has no coverage and create the missing content. |
| [Analyze Top Questions](#analyze-top-questions) | Work through your most common topics and ensure your documentation covers them well. |
| [Analyze Source Analytics](#analyze-source-analytics) | Audit your most-cited documentation pages against the questions they were used to answer. |
| [Answer RFP](#answer-rfp) | Answer incoming RFPs end-to-end using a kapa-powered MCP as the sole knowledge source. |
| [Agent SDK Integration](#agent-sdk-integration) | Set up, improve, or migrate to the Kapa Agent SDK in your own application. |

### Analyze Coverage Gaps

Work through topics where your documentation has no coverage and create the missing content directly in your repository. For each coverage gap, the agent analyzes the conversations, takes into account the recommendation from Kapa, and reviews your documentation repository to suggest whether you should address the gap and if so, how. Not every gap requires action — some topics are intentionally undocumented, some are noise, and some are outside the scope of your documentation.

1. Install the skill into your documentation repository by copying it into your agent's skills directory
2. Export your [Coverage Gaps](https://docs.kapa.ai/analytics/coverage-gaps) for the time period you want to analyze
3. Invoke the skill with your AI agent from within your documentation repository: `/analyze-coverage-gaps <csv_path>`

### Analyze Top Questions

Go through your most common topics and ensure your documentation addresses all the ways users ask about them. Your most common topics are obviously already documented. The question is whether your documentation covers them in the best possible way. Users may be approaching a topic from a different angle than how you have written about it, or explanations may not be clear enough to address what people really want to know.

1. Install the skill into your documentation repository by copying it into your agent's skills directory
2. Export your [Top Questions](https://docs.kapa.ai/analytics/top-questions) for the time period you want to analyze
3. Invoke the skill with your AI agent from within your documentation repository: `/analyze-top-questions <csv_path>`

### Analyze Source Analytics

Audit your most-cited documentation pages against the actual questions they were used to answer. For each highly-cited page, a subagent reviews how well the page serves those questions and recommends specific changes (add, clarify, restructure, cross-link, delete) backed by exact counts and verbatim user quotes. You walk through the findings interactively and decide what to act on.

1. Install the skill into your documentation repository by copying it into your agent's skills directory
2. Export your [Source Analytics](https://docs.kapa.ai/analytics/source-analytics#export-source-analytics) for the time period you want to analyze
3. Invoke the skill with your AI agent from within your documentation repository: `/analyze-source-analytics <csv_path>`

### Answer RFP

Answer incoming RFPs (and vendor questionnaires / security assessments) end-to-end using a kapa-powered MCP as the sole knowledge source. The skill guides the agent through a structured six-step workflow — upload, requirements extraction, capability mapping, drafting, compliance check, and file output — with three mandatory user checkpoints where your judgment shapes the response before the next step begins. All product capability claims are retrieved live from your kapa MCP; nothing is invented or assumed.

1. Install the skill into your repository by copying it into your agent's skills directory
2. Connect your kapa MCP server to your Claude session (kapa platform → Integrations → Hosted MCP Server)
3. Invoke the skill with your AI agent: `/answer-rfp`
4. Upload the RFP document when prompted and follow the guided workflow

### Agent SDK Integration

Add a Kapa AI agent to your own application with the [Kapa Agent SDK](https://docs.kapa.ai/dev/agent), improve an existing integration, or migrate from the Kapa Chat SDK. The agent works interactively: it explores your codebase, decides whether to use the React or Core SDK, finds the API endpoints that make good agent tools and reasons through which to include with you, drafts custom instructions from your product, sets up server-side session authentication and (optionally) conversation history, and themes the chat to match your app. Nothing is invented: it grounds every detail in the installed package types and the official docs, and confirms each decision with you.

1. Install the skill into your application repository by copying it into your agent's skills directory
2. Set up an Agent integration in the [Kapa dashboard](https://app.kapa.ai) (Integrations → Agent) so you have a Project ID, Integration ID, and API key ready
3. Invoke the skill with your AI agent from within your app repository: `/agent-sdk-integration`

## Compatibility

These skills are designed to work with any AI agent that supports a skills directory. To install a skill, copy its folder into your agent's skills directory within your documentation repository.

| Agent | Skills directory | Example |
|-------|-----------------|---------|
| Claude Code | `.claude/skills/` | `cp -r skills/analyze-coverage-gaps /path/to/your/docs-repo/.claude/skills/` |
| Cursor | `.cursor/skills/` | `cp -r skills/analyze-coverage-gaps /path/to/your/docs-repo/.cursor/skills/` |
| Codex | `.agents/skills/` | `cp -r skills/analyze-coverage-gaps /path/to/your/docs-repo/.agents/skills/` |

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
