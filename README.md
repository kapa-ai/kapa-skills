# kapa-skills

A collection of AI agent skills for working with [Kapa](https://www.kapa.ai). These skills let you instruct your AI agents to work with Kapa's data and capabilities using workflows recommended by the Kapa team.

## Skills

| Skill | Description |
|-------|-------------|
| [Analyze Coverage Gaps](#analyze-coverage-gaps) | Work through topics where your documentation has no coverage and create the missing content. |
| [Analyze Top Questions](#analyze-top-questions) | Work through your most common topics and ensure your documentation covers them well. |
| [Answer RFP](#answer-rfp) | Answer incoming RFPs end-to-end using a kapa-powered MCP as the sole knowledge source. |

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

### Answer RFP

Answer incoming RFPs (and vendor questionnaires / security assessments) end-to-end using a kapa-powered MCP as the sole knowledge source. The skill guides the agent through a structured six-step workflow — upload, requirements extraction, capability mapping, drafting, compliance check, and file output — with three mandatory user checkpoints where your judgment shapes the response before the next step begins. All product capability claims are retrieved live from your kapa MCP; nothing is invented or assumed.

1. Install the skill into your repository by copying it into your agent's skills directory
2. Connect your kapa MCP server to your Claude session (kapa platform → Integrations → Hosted MCP Server)
3. Invoke the skill with your AI agent: `/answer-rfp`
4. Upload the RFP document when prompted and follow the guided workflow

## Compatibility

These skills are designed to work with any AI agent that supports a skills directory. To install a skill, copy its folder into your agent's skills directory within your documentation repository.

| Agent | Skills directory | Example |
|-------|-----------------|---------|
| Claude Code | `.claude/skills/` | `cp -r skills/analyze-coverage-gaps /path/to/your/docs-repo/.claude/skills/` |
| Cursor | `.cursor/skills/` | `cp -r skills/analyze-coverage-gaps /path/to/your/docs-repo/.cursor/skills/` |
| Codex | `.agents/skills/` | `cp -r skills/analyze-coverage-gaps /path/to/your/docs-repo/.agents/skills/` |

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
