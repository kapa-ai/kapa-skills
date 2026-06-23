# Subagent instructions: audit a single cited page

Your job is to audit a single documentation page against the user questions that were answered using it as a source.

## Background

Kapa is a Retrieval-Augmented Generation (RAG) system that customers deploy on their own documentation. Kapa indexes the documentation, then answers end-user questions about the product by retrieving the most relevant pages and citing them in its answer.

Every time Kapa answers a question, it logs which pages it cited. The source analytics export is the flat log of those citation events: one row per Q/A-to-page citation. The orchestrator (`analyze-source-analytics`) groups that log by page and hands each per-page bundle to a subagent (that is you).

## What you have to work with

You have two inputs:

1. **The bundle** at `bundle_path`. A JSON file containing every unique Q/A in which this specific page was cited as a source. The file is named `source_analytics/to_do/<cites>-<slug>.json`, where the numeric prefix is the citation count for this page.
2. **The documentation repository** itself. The current working directory of your session is the source repository that Kapa indexed for this customer. Kapa may also have indexed other data sources (a separate developer portal, a GitHub repository, a help center, and so on), but this documentation repository should be the primary one. Use it to read the page being audited, and to grep across other pages to check whether topics raised in the bundle are covered elsewhere in the documentation.

Use both. The bundle tells you what users asked and what Kapa answered. The repository tells you what the page actually contains, and whether other pages already cover the topics in question.

## The bundle in detail

Before getting to the JSON schema, the key concepts the bundle represents:

- **URL** is the documentation page being audited (for example, `docs.example.com/some/page`).
- **Thread** is one user conversation. A thread can contain one or more Q/As, and may cite this page across more than one turn.
- **Question/Answer (Q/A)** is one user question paired with Kapa's generated answer. Every Q/A in your bundle is an answer where this page was retrieved and cited as a source.
- **Uncertain** is Kapa's flag for an answer where it concluded that the indexed knowledge sources did not sufficiently cover the user's question. It correlates with hedging language in the answer text. An uncertain answer means Kapa lacked good coverage somewhere in the knowledge base, but the page it cited is just the closest semantic match it could find. That is not the same as this page failing to serve the question: the topic may genuinely belong on a different page (or on no page that exists yet). When you see uncertain Q/As in the bundle, treat them as evidence that the knowledge base is incomplete for that topic, then judge separately whether the fix belongs on this page or somewhere else.
- **Integration** is the surface where this instance of Kapa was deployed and through which the question came in (Website Widget, Slack Bot, Marketing, Interactive Demo, and so on).

The bundle JSON has this shape:

```json
{
  "url": "docs.example.com/some/page",
  "rank": 1,
  "stats": {
    "cites": 193,
    "threads": 165,
    "uncertain": 14,
    "upvotes": 7,
    "downvotes": 0
  },
  "threads": [
    {
      "thread_id": "...",
      "integration": "Website Widget",
      "custom_tags": "",
      "qas": [
        {
          "qa_id": "...",
          "asked_at": "2026-04-12T10:23:00Z",
          "is_uncertain": false,
          "upvotes": 0,
          "downvotes": 0,
          "feedback_comments": "",
          "question": "How do I ...",
          "answer": "...",
          "support_form_deflection_status": ""
        }
      ]
    }
  ]
}
```

Q/As within a thread are sorted by `asked_at` so multi-turn conversations read in order.

### Field reference

- `url`: the page being audited.
- `stats.cites`: total Q/As in the bundle.
- `stats.threads`: total threads in the bundle.
- `stats.uncertain`: Q/As where Kapa flagged its answer as uncertain.
- `stats.upvotes` and `stats.downvotes`: totals of user feedback across all answers.
- `threads[].thread_id`: ID of the conversation.
- `threads[].integration`: the Integration the conversation came through (see above).
- `threads[].custom_tags`: any tags the Kapa customer applied to the conversation.
- `threads[].qas[].question`: the verbatim user question. Primary evidence.
- `threads[].qas[].answer`: Kapa's verbatim answer to the question. Primary evidence.
- `threads[].qas[].is_uncertain`: the Uncertain flag for this Q/A (see above).
- `threads[].qas[].upvotes`, `threads[].qas[].downvotes`, `threads[].qas[].feedback_comments`: explicit user feedback on this answer. A downvote with a comment is high-signal.
- `threads[].qas[].support_form_deflection_status`: whether this Q/A deflected a support form submission, if applicable.

Read the bundle first to recover the URL and stats. Do not infer them from the filename.

## Your deliverable

A strict markdown report at the output path you were given (`source_analytics/to_review/<cites>-<slug>.md`). Nothing else.

## The bar

Your work must be rigorous. Every recommended change must be backed by exact counts, verbatim user quotes, and a concrete proposal for what to add, clarify, restructure, cross-link, or delete. No paraphrases, no estimates, no vague "improve this section".

**Minimum threshold: a recommended change must be supported by at least 3 distinct user questions that the same change would have helped.** A change backed by 1 or 2 questions does not clear the bar. Note such clusters in the report as "No change" with a one-line reason ("only 2 backing questions"), but do not recommend a modification.

The default outcome for a cluster is "No change to this page". Recommend a change only when the evidence makes it clear that a specific modification to this page would have improved Kapa's answers to the questions in that cluster. If the fix belongs on a different page, say so but do not recommend bulking up this page with content that does not belong here.

Your report will be reviewed by a human who decides whether to write or rewrite documentation. Recommendations drive real edits, so the evidence has to be solid.

## Methodology

Your goal is to find changes to this page that would have improved Kapa's answers to the questions in the bundle. "Change" is intentionally broad: add something, clarify something, restructure something, remove something, or add a cross-link to a page that already covers it. "No change needed" is a perfectly valid finding when the page already serves the questions or when the fix belongs on a different page.

Cluster questions by the change that would help them, not by topic alone. A change recommended on the back of 10 similar questions is much higher leverage than one recommended on the back of 1. The clustering is the analysis.

Follow these steps in order.

### 1. Find the source file in the documentation repository

The URL maps to a markdown file in this repository, but the convention varies by documentation framework (Docusaurus, Mintlify, MkDocs, Hugo, plain markdown). Try, in order:

- Search for filenames matching the URL's trailing path slug (`Glob` on `**/<slug>.{md,mdx}`).
- For root URLs and category indexes, search frontmatter for `slug:` matching the URL path, and check for `index.{md,mdx}` in the matching directory.
- If nothing matches, record "source file not found" in the report. Continue using only the URL as context.

### 2. Read the page

If you found the source file, read it fully. Note its current sections, what it covers, and what it explicitly does not cover. You need this to judge what kind of change (if any) would help.

### 3. List every question in the bundle

Read the bundle JSON. Walk through `threads[].qas[]` and note, for each Q/A: the thread index, the question (verbatim), the thread's integration, and the Q/A's `is_uncertain` flag. Keep lines short enough to scan all at once. Treat each Q/A as a separate question for clustering purposes, but remember that several Q/As in the same thread are turns in one conversation and may share context.

### 4. Cluster questions by what change would have helped them

Before clustering, skip Q/As that already look fine: Kapa's answer was confident, well-sourced, and `is_uncertain` is false. No change can improve an answer that was already good, and clustering them wastes effort. Count them as "Already well-served" and move on.

For the remaining Q/As, group questions where the SAME modification to this page would have improved Kapa's answer. The cluster is built around a candidate change, not around a topic in the abstract.

Also count off-topic questions (chitchat, error dumps, gibberish, off-product questions) as their own cluster.

Count each cluster exactly.

### 5. For each actionable cluster with **3 or more** backing questions

Build the evidence before recommending anything.

#### a) Verbatim quotes
Include at least 3 user questions, copy-pasted exactly from the bundle. Do not paraphrase. Do not condense. If a question has a typo or is in another language, keep it as-is.

#### b) Examine actual answers
Read 2-3 of the answers for questions in this cluster. Look for:
- Hedging language. Quote it verbatim. Examples: "the knowledge sources do not contain", "I do not have specific information", "I would recommend reaching out to support".
- Confidence and complete answers. If the answer is confident and well-sourced, the page may already serve the topic adequately.

List every `docs.kapa.ai/...` URL the answers cite. These tell you what Kapa retrieved beyond the page being audited.

#### c) Check the rest of the documentation
For each cited URL, plus any plausibly related page you can think of, use `Grep` on the documentation directory to confirm whether the topic is actually covered. Open candidate pages and read them. Do not trust that a citation means coverage. Verify.

If another page covers the topic adequately, name the file path.

#### d) Recommend a change

Pick exactly ONE of the following for the cluster:

- **Add to this page** — the topic is in scope for what this page is about and is not covered here or anywhere else. Recommend specifically what to add.
- **Clarify on this page** — content exists but is unclear, ambiguous, or being misread. Quote the section being misread and propose the revision.
- **Restructure on this page** — content exists on the page but is buried, mis-titled, or in the wrong section, so Kapa cannot retrieve it. Propose the move.
- **Cross-link from this page** — the topic is covered adequately on another page. Name the file path and the anchor text the cross-link should use.
- **Delete from this page** — content is outdated, contradictory, or pulled Kapa toward a wrong answer. Quote what to remove.
- **No change to this page** — out of scope for this page, already adequately covered here, or the fix belongs on a different page. Say which and why.

If the change belongs on a different page, say so but do not recommend bulking up this page with content that does not belong here.

### 6. Write the report

Write to the `output_path` you were given, using **exactly** this template. Do not improvise sections. Do not omit any section, even if empty.

```
# Audit: <URL>

- Total Q/As: <N>
- Uncertain Q/As: <U>
- Source file: <path or "not found">

## What the page currently covers
- <one-bullet-per-section>

## Clusters (3+ backing questions)

### Cluster: <name> — <X> of <N>
**Verbatim quotes:**
- "..."
- "..."
- "..."

**What Kapa's answers look like:**
- <Hedging language verbatim, or "answers are confident and well-sourced">
- Docs URLs cited by answers: <comma-separated list, or "none">

**Coverage elsewhere in the documentation:**
- <file_path>: <covered / partial / absent, one short sentence>
- <…>

**Recommended change:** <Add | Clarify | Restructure | Cross-link | Delete | No change>
**Specifics:** <1-2 sentences describing exactly what to change on this page, or "n/a" for No change>

### Cluster: <name> — <X> of <N>
...

## Discarded clusters
- Off-topic / non-actionable: <count> of <N>, one-line characterization with one example quote.

## Summary
Group clusters by their recommended change:
- Add: <list of cluster names with counts, or "none">
- Clarify: <list, or "none">
- Restructure: <list, or "none">
- Cross-link: <list, or "none">
- Delete: <list, or "none">
- No change: <list, or "none">
```

### 7. Delete the input bundle from `to_do/`

Once the report is written and saved to `output_path`, delete the input bundle file at `bundle_path`. This empties the work item out of `to_do/`. Do this only after confirming the report file was written, so a crash mid-way does not lose data.

### 8. Return to the orchestrator

Your final message to the orchestrator is one line confirming:
- The output file you wrote
- The number of clusters with a recommended change other than "No change"

That is all. Do not summarize the findings in your final message. The report file is the deliverable.

## Guidelines

- Quote questions verbatim. Do not paraphrase.
- Do not synthesize across clusters. One cluster equals one recommended change.
- The bar for a recommended change is high. Default to "No change" unless the evidence is clear that a specific modification to this page would have helped.
- Off-topic clusters must be counted, not silently dropped.
- If you cannot find the source file, the report still ships. You just have less context for judging whether a topic is in scope.
- If the bundle has fewer than 5 actionable questions total, the report will be mostly "No change". That is fine.
