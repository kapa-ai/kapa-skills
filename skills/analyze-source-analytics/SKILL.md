---
name: analyze-source-analytics
description: Audit a Kapa source analytics CSV export against your documentation. For each highly-cited URL, spawn a subagent that audits the page against the questions that cited it, then walk through the findings interactively.
arguments: [csv_path]
allowed-tools: Bash(bash *)
---

# Analyze Source Analytics

You are helping the user audit their documentation against a Kapa source analytics CSV export. The goal is to find specific changes to documentation pages (additions, clarifications, restructures, cross-links, deletions) that would have improved Kapa's answers, backed by exact counts and verbatim quotes.

## Background

Kapa is a Retrieval-Augmented Generation (RAG) system that customers deploy on their own documentation. Kapa indexes the documentation, then answers end-user questions about the product by retrieving the most relevant pages and citing them in its answer.

Every time Kapa answers a question, it logs which pages it cited. The source analytics export is the flat log of those citation events: one row per Q/A-to-page citation. The cited page is identified by the `Referenced URL` column, so grouping rows by that column gives you every Q/A in which a given page was used as a source.

A few terms to know:

- **URL** is one documentation page (the `Referenced URL`).
- **Thread** is one user conversation. A thread can contain multiple Q/As across follow-up turns.
- **Question/Answer (Q/A)** is one user question paired with Kapa's generated answer. Each Q/A in the export is one where Kapa cited a specific page while generating that answer.
- **Uncertain** is Kapa's own flag for an answer where it concluded the indexed knowledge sources did not sufficiently cover the user's question. A high uncertain count on a page does not necessarily mean the page is failing its citers. When Kapa cannot find a good source, it still cites the closest semantic match, so a broad page often ends up as a catch-all for adjacent topics it was never meant to cover. The fix for an uncertain question may belong on a different page (or on no existing page at all), not on the page that happened to be cited.
- **Integration** is the surface the question came in through (Website Widget, Slack Bot, Marketing, Interactive Demo, and so on), usually synonymous with where this instance of Kapa was deployed.

The subagents that audit each page receive more detailed background and a strict methodology in `subagent-instructions.md` inside this skill directory.

## Introduction

Before doing anything else, briefly explain to the user what this is:

- Source analytics shows which docs pages Kapa cited when answering user questions.
- For each highly-cited page, this skill audits how well the page actually serves those questions.
- A subagent runs the audit for each page in parallel (10 at a time), following the methodology in `subagent-instructions.md` inside this skill directory.
- Each subagent writes its findings to a per-page markdown file. You then walk through the findings interactively with the user.
- Findings are backed by exact counts and verbatim user questions — no hand-waving.
- Progress is tracked by moving files between three directories: `to_do/` (bundles waiting to be audited), `to_review/` (audited reports waiting for user review), `done/` (user has reviewed). Work resumes across sessions.

Keep the explanation to a few sentences.

## Prerequisites

Before running setup, confirm both of the following with the user. If either is missing, stop and walk them through it.

### 1. You are in your documentation repository

This skill audits the source files of a documentation site against the questions users asked about it. It must be run from the root of the docs repo the export came from. Check that the current working directory looks like a docs repo (for example, it has a `docs/` directory, an `mkdocs.yml`, `docusaurus.config.*`, `mint.json`, `hugo.toml`, or similar). If it does not, ask the user to switch to their docs repo before continuing.

### 2. You have exported the source analytics CSV from the Kapa platform

The CSV is exported from the Kapa platform's Source Analytics view. If the user does not yet have the file, point them to the documented export steps: <https://docs.kapa.ai/analytics/source-analytics#export-source-analytics>.

Once both are confirmed, proceed to Setup.

## Setup

Run the setup script to parse the CSV and create per-URL bundle files:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/setup.sh "$csv_path"
```

This produces:
- `source_analytics/to_do/<cites>-<slug>.json` — one bundle per Referenced URL with every unique Q/A that cited it (deduped by Q/A ID). Files are prefixed with the actual citation count, zero-padded to the largest count (for example, `1234-getting-started.json`, `0042-billing.json`), so the prefix tells you at a glance how often the page was cited.
- `source_analytics/to_review/` and `source_analytics/done/` — empty directories that will receive per-page audit reports.

The script prints the top URLs by citation count. Show that table to the user.

## Workflow

### 1. Decide which URLs to audit

The goal is to work through every page the user wants to audit, not just the top of the list. Default strategy is to process the bundles in `source_analytics/to_do/` in batches of 10, ordered by citation count descending (highest-numbered filename prefix first), pausing between batches for the user to review findings before the next batch is spawned.

Before starting, ask the user how they want to proceed. Options to surface:
- Default: batches of 10 in rank order, continuing until all bundles are audited or the user stops.
- A specific number of pages (for example, just the top 5, or top 25 in one pass).
- A specific list of pages (by rank number or URL).
- A filter (for example, only pages with uncertain Q/As above some threshold).

Once the user picks a strategy, confirm the first batch with them before spawning subagents. After each batch finishes and the user has walked through the findings, check in again before starting the next batch.

### 2. Spawn one subagent per bundle, 10 in parallel at a time

For each selected bundle file in `to_do/`, spawn a general-purpose subagent. **Run 10 subagents at a time in parallel** (use `run_in_background=true` on the Agent tool). When 10 are in flight, wait for some to complete before spawning more.

Each subagent's prompt must:
- Instruct the subagent to read and **strictly follow** `.claude/skills/analyze-source-analytics/subagent-instructions.md`.
- Provide:
  - `bundle_path` — the absolute path to `source_analytics/to_do/<cites>-<slug>.json`
  - `output_path` — `source_analytics/to_review/<cites>-<slug>.md`

The subagent's deliverables, per the instructions, are: (a) write the markdown report to `output_path`, (b) delete the input bundle from `to_do/` once the report is written. It returns one line confirming the file was written and the number of clusters with a recommended change other than "No change".

### 3. Walk through reports as they land, do not wait for the full batch

You do not need to wait for every subagent in the batch to return before starting to review. As soon as a report appears in `source_analytics/to_review/`, start processing it with the user. The slower subagents continue running in the background while you work through the ones that have already finished.

The loop:

1. Look at `source_analytics/to_review/` for completed reports. Pick the one with the highest citation-count prefix (most important page first). If none are ready yet, wait for the next subagent to finish before continuing.
2. Read the report. Skim for trust-but-verify red flags:
   - Counts that look invented (no verbatim quotes backing them)
   - Clusters with a recommended change but no evidence that other documentation pages were searched
   - Vague specifics ("improve this section", "make it clearer") instead of concrete proposals
   If a report looks thin, spawn a follow-up subagent or do the work yourself before surfacing it to the user.
3. Surface the recommended changes to the user (verbatim quotes, exact counts, specific proposal per cluster).
4. Wait for the user's decision: agree / disagree / fix now / skip.
5. If the user wants to fix immediately, help make the edit.
6. Move the file from `to_review/` to `done/`.
7. Return to step 1.

The orchestrator (this agent) is the one moving files between `to_review/` and `done/`. Subagents do not touch these directories.

## Guidelines

- Run subagents in parallel, 10 at a time. Do not serialize.
- Some pages will have zero recommended changes. That is a fine outcome.
- Every recommended change must be backed by verbatim quotes, exact counts, evidence that other documentation pages were checked, and a concrete proposal for what to add, clarify, restructure, cross-link, or delete.
- Keep the user in control. Never batch-process audits without their input.
- If a subagent's report claims many changes but the evidence is thin, push back rather than relaying it.
