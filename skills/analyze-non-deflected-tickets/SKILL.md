# Analyze non-deflected conversations

This guide explains how to use the deflection analysis skill to classify your non-deflected support conversations, estimate your potential deflection rate, and generate a prioritized list of documentation improvements.

The skill is available in the [kapa skills repository](https://github.com/kapa-ai/kapa-skills/tree/main/skills).

## When to use this skill

Run this analysis when you want to understand why users are still reaching human support after receiving a kapa AI response, and what specifically to do about it. It is most useful when your deflection rate has plateaued, when you need to prioritize documentation work, or when you want to separate cases that require human action from cases that could be resolved with better documentation.

For reliable trend detection, aim for at least 200 deflected and 200 non-deflected conversations in your export. Smaller datasets may not produce clusters large enough to generate actionable priorities.

## Prerequisites

- A CSV export of your support form deflector conversations ([how to export](https://docs.kapa.ai/analytics/conversations#export-conversations)) — filter for the support form deflector integration specifically
- The skill installed from the [kapa skills repository](https://github.com/kapa-ai/kapa-skills/tree/main/skills)
- A kapa MCP server connected to your Claude session (recommended — see [What the MCP adds](#what-the-mcp-adds))

## Install the skill

**If you prefer a UI-based setup:**

1. Download the `analyze-non-deflected-tickets` folder from the [kapa skills repository](https://github.com/kapa-ai/kapa-skills/tree/main/skills)
2. Open Claude and go to **Customize**
3. Click **+** and select **Create skill**
4. Upload the skill file — the skill will be available immediately

**If you prefer a developer setup:**

1. Clone the [kapa skills repository](https://github.com/kapa-ai/kapa-skills/tree/main/skills)
2. Copy the `analyze-non-deflected-tickets` folder to your local skills directory
3. Restart Claude — the skill will be available automatically

## How it works

The skill runs through five phases after you provide the CSV:

1. **Baseline counts** — establishes total conversations, current deflection rate, and number of non-deflected cases before classification begins.
2. **Domain orientation** — reads a sample of non-deflected conversations to understand your product, common question types, and which support requests structurally require human action. If a kapa MCP is connected, the skill queries your documentation directly at this stage to calibrate its understanding.
3. **Classification** — labels every non-deflected row as either `Could Deflect` or `Couldn't Deflect` and writes the result to `classified_conversations.csv`. Ambiguous cases default to `Couldn't Deflect` to keep the opportunity estimate conservative.
4. **Summary** — produces headline numbers: current deflection rate, potential deflection rate, and estimated uplift. The potential rate applies a 0.5x multiplier to Could Deflect cases to account for users who will open a ticket regardless of documentation quality. You can adjust this multiplier.
5. **Documentation action list** — groups Could Deflect cases into themes and assigns a specific action to each: create a new article, update an existing page, or investigate why content is not being surfaced. Each action includes an estimated ticket volume, a type label, and a priority rank.

## Output files

The skill produces two files:

| File | Contents |
|---|---|
| `classified_conversations.csv` | Your original export with a `Classification` column added (`Could Deflect`, `Couldn't Deflect`, or `Deflected`) |
| `deflection_report.md` | Headline numbers, theme breakdowns, and the full documentation action list |

## Classification categories

**Could Deflect** cases are questions that were, in principle, answerable from your documentation. The most common reasons a ticket was still opened:

- The user was not satisfied with or did not engage with the AI response
- The answer was incomplete because the documentation did not fully cover the case
- The answer was phrased in a way the user did not understand

**Couldn't Deflect** cases required a human to take a specific action: account unlocks, billing changes, GDPR deletion requests, transaction traces, security incidents. No documentation improvement addresses these. They represent your structural deflection ceiling.

## What the MCP adds {#what-the-mcp-adds}

Connecting a kapa MCP server before running the analysis improves classification accuracy in two ways: it anchors the skill's understanding of your product and what it supports, and it allows the classifier to verify borderline cases by querying your actual documentation.

When the MCP is connected, each Could Deflect case is further typed:

| Type | Meaning | Next step |
|---|---|---|
| `Missing doc` | No answer found in the knowledge base | Write the missing content |
| `Outdated doc` | Answer found but incomplete or no longer accurate | Update the existing article |
| `Surfacing issue` | A good answer exists but the AI did not present it confidently | Review coverage configuration or chunking |

Without an MCP connected, the skill still runs but marks borderline recommendations as unverified.

To set up a kapa MCP server, go to **Integrations → Add new integration → Hosted MCP Server** in the kapa platform.

## Understanding the potential uplift

The summary expresses the opportunity as a percentage point gap between your current deflection rate and the estimated potential rate. The 0.5x multiplier on Could Deflect cases is applied before calculating the potential rate — the default is conservative by design, since even with complete, well-surfaced documentation, some users will open a ticket regardless.

What the gap means in practice depends on your support volume. A 2 percentage point improvement is 1,000 fewer tickets per month for a team handling 50,000 conversations; for a team handling 100, a 20 percentage point improvement is 20 tickets. Use the percentage point figure as a comparable metric; convert to ticket count to make it meaningful in your context.

## Next steps

1. [Export your deflector conversations](https://docs.kapa.ai/analytics/conversations#export-conversations) from the kapa platform, filtered for the support form deflector integration
2. [Connect your knowledge sources](https://docs.kapa.ai/data-sources/overview) if you haven't already — documentation, FAQs, and troubleshooting guides are the most valuable sources for this use case
3. [Set up a Hosted MCP server](https://docs.kapa.ai/integrations/mcp/overview) for your project to enable per-case documentation verification
4. Download and install the `analyze-non-deflected-tickets` skill from the [kapa skills repository](https://github.com/kapa-ai/kapa-skills/tree/main/skills)
5. Drop the CSV into a Claude session and run the analysis

Questions about setup? Email [support@kapa.ai](mailto:support@kapa.ai).
