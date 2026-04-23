---
name: analyze-coverage-gaps
description: Analyze a Kapa coverage gaps CSV export against your documentation to identify documentation gaps and noise. Walk through each cluster interactively.
arguments: [csv_path]
allowed-tools: Bash(bash *)
---

# Analyze Coverage Gaps

You are helping the user analyze a Kapa coverage gaps export to identify where their documentation needs improvement.

## Introduction

Before doing anything else, briefly explain to the user what this process is and how it works:

- Coverage gaps are clusters of user questions where Kapa could not find sufficient information in the knowledge sources to provide a good answer.
- First, the CSV export will be parsed into a directory of individual cluster files — one per topic.
- You will then walk through each cluster one by one, analyze the existing documentation, and recommend whether it needs a documentation fix or requires no action.
- The user makes the final call on each cluster and can choose to fix documentation issues on the spot.
- Progress is tracked by moving cluster files between directories (e.g. `to_do/` → `done/`), so the work can be resumed across multiple sessions.

Keep the explanation to a few sentences — just enough so the user understands the flow.

## Setup

1. Run the setup script to parse the CSV and create cluster markdown files:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/setup.sh "$csv_path"
```

2. Verify the files were created by listing `coverage_gaps/to_do/`.

## Workflow

Walk through each cluster one at a time. For each cluster:

1. **Read the cluster** — show the user the title, summary, thread count, unique users, and questions. If the unique user count is low relative to the thread count, flag this to the user — it means a small number of people asked repeatedly rather than many users hitting the same gap.
2. **Analyze the documentation** — search the docs in this repository to understand what is already documented about the topic. Check relevant pages, FAQs, and configuration references.
3. **Present your assessment** to the user. Categorize it as one of:
   - **No action needed** — already documented, noise, or not a documentation issue
   - **Documentation fix** — there is a real gap in the documentation that should be addressed
4. **Wait for the user's decision** before moving the file. The user may agree, disagree, or want to discuss further. They may also want to make the fix immediately.
5. **Update the cluster file** with the analysis and decision, then move it to the appropriate directory based on the user's instruction.
6. **Move to the next cluster** when the user is ready.

## Guidelines

- Be concise in your assessments. Lead with the recommendation.
- When analyzing docs, actually read the relevant files — do not guess.
- Some clusters are noise (random numbers, misdirected questions, questions about other products). Identify these quickly and move on.
- Some clusters contain ticket-based queries routed through Kapa integrations that are not about the product itself. These are noise.
- If the user wants to fix a documentation issue immediately, help them make the edit, then move the cluster to `done/`.
- Keep the user in control — never batch-process clusters without their input.
