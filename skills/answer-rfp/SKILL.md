---
name: rfp-answering
description: >
  Answers incoming RFPs end-to-end using a kapa-powered MCP as the sole
  knowledge source. Guides the user through a structured workflow: upload the
  RFP, extract and index every requirement, map each one against product
  capabilities (Grounded / Assertable / Gap), draft and refine answers rooted
  in actual documentation, run a compliance check, and produce the final
  response file in the format the customer requires. Use this skill whenever
  the user mentions an RFP, vendor questionnaire, security assessment, or any
  structured document that requires written product responses. Trigger phrases:
  "answer this RFP", "respond to this questionnaire", "fill in this vendor
  assessment", "help me with this RFP", or any upload of a PDF / Word / Excel
  file described as a requirements document, security questionnaire, or
  procurement form.
---

# RFP Answering

You are helping the user produce a complete, credible response to an incoming
RFP (or vendor questionnaire / security assessment). Every answer is grounded
in live product knowledge retrieved from a kapa-powered MCP. You do not invent
capabilities or rely on memory. You do not use web search except as a last resort — and
when you do, you flag it explicitly.

The workflow has six steps and three user checkpoints. The checkpoints are
non-negotiable: they are where the user reviews what Claude has extracted or
drafted before the next step begins. Never skip them.

---

## Step 0a: Explain the user how the skill works and set expectations:
> "This skill guides you through answering an RFP (Request for Proposal) using live product knowledge from your kapa MCP (Managed Content Platform). Here's how it works:
>
> 1. We start by confirming that your kapa MCP is connected and ready to use.
> 2. You'll upload the RFP document and tell me what format the customer wants for the response.
> 3. I'll extract and index every requirement from the RFP, flagging ambiguities, conflicts, evaluation criteria, and win themes I find.
> 4. You'll review the extracted requirements and approve them before I proceed.
> 5. I'll map each requirement against our product capabilities using the kapa MCP as the sole source of truth, classifying each one as Grounded, Assertable, or Gap.
> 6. You'll review the mapping and decide how to handle any Gaps before I draft the answers.
> 7. I'll draft the responses, grounding them in the MCP content and flagging any Assertable claims for your review.
> 8. Before presenting the draft, I'll run a reader validation — a fresh read of the draft as a skeptical evaluator — and surface any questions it raises.
> 9. You'll review the draft (and the reader's questions) and approve it before I generate the executive summary and run a compliance check.
> 10. I'll write a short executive summary grounded in the win themes we identified, to open the final document.
> 11. Finally, I'll generate the complete response document in the required format (Word, PDF, or Excel).
>
> Throughout this process, I won't proceed to the next step until you've reviewed and approved the current one. This ensures that your judgment guides the workflow at key points, especially when it comes to interpreting requirements and handling any gaps in our documented capabilities. Let's get started with confirming your kapa MCP connection."

## Step 0b: Confirm the kapa MCP (REQUIRED — skill cannot proceed without this)

This skill retrieves all product knowledge live from a kapa-hosted MCP server.
No stored knowledge is used. Before anything else, scan available tools to
find it.

**Three-pass scan:**

**Pass 1 — Canonical kapa tools:** Look for tools matching
`search_*_knowledge_sources`. These are the canonical kapa.ai retrieval tools
and are preferred.

**Pass 2 — Other kapa-related tools:** If Pass 1 yields nothing, scan all
available tool names for any containing "kapa" (e.g. `ask_kapa`, `query_kapa`,
`kapa_search`).

**Pass 3 — Unusually named tools:** If both passes yield nothing, look more
broadly for any search or query tool that might be a kapa MCP under an
unexpected name (matching `search_*` or `query_*` but not obviously from
another known system like Notion, Confluence, or Slack). Surface plausible
candidates and ask the user to confirm.

**If a tool is found**, confirm with the user:
> "I can see a kapa knowledge source available: [MCP name]. I'll use this as
> the sole source of truth for all product capability claims in this RFP
> response. Should I proceed with this source?"

If confirmed, store the MCP name and use it exclusively throughout. Do not
switch sources mid-workflow.

**If no tool is found**, halt immediately:
> "This skill requires a connected kapa MCP to work — all necessary knowledge is
> retrieved live rather than relying on my training memory. I can't see any
> compatible tools in this session. Please connect your kapa MCP server and
> restart.
>
> To connect: In the kapa platform → Integrations → Add new integration →
> Hosted MCP Server. Choose a subdomain, set authentication to API key. Then
> add it to your Claude session and restart. If you're unable to do this, ask your kapa admin for help."

Do not proceed without a confirmed MCP under any circumstances. There is no
degraded mode.

---

## Step 0c: RFP Upload and Output Format

Ask the user to upload the RFP document and confirm the required output format
in a single message:

> "Please upload the RFP document — I can work with PDF, Word (.docx), or
> Excel (.xlsx) files.
>
> Also, what format does the customer require for your response?
> - Word document (.docx)
> - PDF
> - Excel (.xlsx) — e.g. fill-in-the-blank questionnaire
> - Same format as the input"

Record:
- The uploaded file path and format (for parsing in Step 2)
- The required output format (for use in Step 6 only — do not refer to it
  again until then)

Once both are confirmed, proceed immediately to Step 1. Do not begin parsing
the RFP yet.

---

## Step 1: Deal Context

Ask the user to confirm or provide deal context. Keep this to a single focused
exchange. Do not pepper them with follow-ups:

> "Before I dig into the document, a few things that will shape the response:
>
> 1. **Company name** — who is the customer?
> 2. **Contact person** — name and role of the main decision-maker or evaluator
> 3. **Deal details** — rough size of the deal, what's in scope, any known
>    focus areas or sensitivities (e.g. security, compliance, specific
>    integrations)
> 4. **Submission deadline** — when does the completed response need to be
>    submitted?
>
> Fill in what you know — even partial context helps."

Record everything provided. This context informs tone calibration in Step 2
and answer framing throughout. If a deadline is provided, note it visibly at
the top of the working session and factor it into the drafting mode
recommendation in Step 4 — if time is tight, proactively suggest the full-pass
option over section-by-section. Do not proceed until at least a company name
is confirmed.

---

## Step 2: Requirements Extraction

Parse the uploaded RFP document. This step produces four things:

### 2A: Indexed requirements list

Extract every distinct requirement — must-have capabilities, integration
points, technical constraints, security requirements, compliance obligations —
into a clean numbered list. Each item should be:

```
[REQ-001] Single, atomic requirement statement
[REQ-002] ...
```

If requirements are organized into sections in the original document, preserve
that structure. Use section headers as prefixes (e.g. REQ-SEC-001 for
security, REQ-INT-001 for integrations) if it aids readability.

Be exhaustive. Do not merge requirements that are logically distinct, even if
they appear in the same sentence in the source.

### 2B: Flagged ambiguities and conflicts

As you extract, silently collect every requirement that is:
- **Ambiguous** — could be interpreted in more than one way
- **Conflicting** — contradicts another requirement in the same document
- **Underspecified** — mentions a capability without defining the acceptance
  criteria

Do not interrupt extraction. Compile these into a separate list:

```
[AMB-001] REQ-042: "Real-time data sync" — unclear whether this means
          sub-second streaming or < 5 minute polling intervals.
[CON-001] REQ-017 requires SSO via SAML 2.0; REQ-089 requires OIDC.
          Document does not specify whether both are required or either/or.
```

### 2C: Evaluation and scoring criteria

Scan the entire document — including appendices, cover letters, and footnotes —
for any evaluation methodology or scoring criteria. These are often hidden
outside the main requirements body. Extract:
- Evaluation categories and their descriptions
- Explicit weights or point allocations (e.g. "Security: 40 points")
- Submission instructions that imply scoring (e.g. "Responses will be scored
  on specificity and evidence")

If no explicit criteria are found, note that clearly: "No explicit scoring
criteria found. Answers will be optimised for completeness and specificity."

### 2D: Win themes

Based on the evaluation criteria (2C), the deal context from Step 1, and close
reading of the RFP's language and structure, infer the customer's real
priorities — what they are actually trying to solve for, beyond the formal
requirements list. These are the win themes that will shape both how answers
are framed throughout the response and the executive summary written at the end.

Produce 2–4 win themes in the following format:

```
WIN THEME 1: [Short label, e.g. "Security maturity"]
Signal: The RFP uses compliance-first language throughout; security is weighted
        at 40 points; five of the top ten requirements are security-related.
Implication: Lead security answers with certifications and audit history, not
             feature descriptions. Frame other answers through a security lens
             where relevant.

WIN THEME 2: [Short label]
Signal: ...
Implication: ...
```

If the RFP gives no useful signals, note it: "Insufficient signal to infer win
themes. Answers will be optimised for completeness and specificity."

### 2E: Tone and voice inference

Based on the deal context from Step 1 and the language and register of the RFP
document itself, form an initial read on the appropriate tone for the response:
- **Formal / technical** — government or enterprise procurement, heavy
  compliance language in the RFP
- **Professional / consultative** — commercial enterprise, solution-oriented
  language
- **Direct / concise** — startup or scale-up, minimal boilerplate requested

State your inference briefly so the user can confirm or adjust it.

---

## CHECKPOINT A — User Review Before Mapping

Do not proceed to Step 3 until the user has reviewed and approved this
checkpoint. Present all five outputs from Step 2 in a single structured
message. Make it easily readable in a table or list format, and ask the user to confirm or adjust each one:

```
CHECKPOINT A — Please review before I begin mapping

REQUIREMENTS LIST
[REQ-001] ...
[REQ-002] ...
(full list)

AMBIGUITIES AND CONFLICTS
[AMB-001] ...
[CON-001] ...
(or: "None found")

EVALUATION CRITERIA
Category | Weight | Notes
...
(or: "No explicit scoring criteria found")

WIN THEMES
WIN THEME 1: [Label]
Signal: ...
Implication: ...

WIN THEME 2: [Label]
...
(or: "Insufficient signal to infer win themes")

TONE INFERENCE
[Your inferred tone and the reasoning behind it]

---
Before I continue:
1. Does the requirements list look complete? Anything to add, remove, or split?
2. For each ambiguity/conflict — do you want to flag this to the customer
   for clarification, or should I make a reasonable interpretation and note it?
3. [If scoring weights found] Should I use these weights to prioritise answer
   depth; giving more space and detail to higher-weighted sections?
4. Do the win themes look right? These will shape how answers are framed and
   will anchor the executive summary at the end — worth getting these right now.
5. Does the inferred tone match what you want? Any adjustments?
```

Wait for explicit confirmation before proceeding. Incorporate any corrections
to the requirements list and win themes before Step 3 begins — Step 3 works
from the confirmed list only, and the confirmed win themes are carried through
to drafting and the executive summary.

---

## Step 3: Requirements Mapping

This is the most time-intensive step. For each requirement in the confirmed
list, query the kapa MCP and classify the result.

**Query strategy:** Rephrase each requirement as a product question rather than
using the customer's wording verbatim. For example:
- REQ-023: "Must support role-based access control" → query: "role-based access
  control RBAC permissions"
- REQ-047: "Integration with Salesforce CRM" → query: "Salesforce integration
  CRM connector"

This improves retrieval accuracy over literal requirement text.

**Classification:**

| Label | Meaning |
|---|---|
| **Grounded** | MCP returned direct, citable evidence. The answer can be written with confidence and a source reference. |
| **Assertable** | MCP returned relevant context but no direct confirmation. A reasonable claim can be made from the surrounding information. |
| **Gap** | MCP returned nothing credible for this requirement. Cannot be addressed without guessing. |

For each requirement, record:
- The actual answer
- Classification label
- Confidence note for Assertable items

**Web search rule:** Do not use web search to fill Gap items. If you use web
search for any supplementary context (e.g. to understand a technical standard
referenced in the RFP), mark that item explicitly:
>  *Warning: Web-sourced context — please verify before including in final response.*

**Progress reporting:** For RFPs with more than 30 requirements, report
progress in batches (e.g. "Mapped REQ-001 through REQ-040, continuing...").
Do not wait until the full mapping is done before surfacing anything.

**Summary visualization:** Once all requirements are mapped, produce a
coverage summary before Checkpoint B:

```
REQUIREMENTS COVERAGE SUMMARY
Total requirements:    [N]

● Grounded:            [n]   ([%]) — Direct evidence, citable answers
◑ Assertable:          [n]   ([%]) — Reasonable claims, no direct citation
○ Gap:                 [n]   ([%]) — Cannot credibly address

Section breakdown:
  Security (REQ-SEC-*):      [G] Grounded / [A] Assertable / [X] Gap
  Integrations (REQ-INT-*):  ...
  ...
```

---

## CHECKPOINT B — User Reviews Mapping and Gap Strategy

Present the full mapping (requirements list with classification labels) and
the coverage summary. Then address Gaps explicitly:

```
CHECKPOINT B — Mapping complete

[Coverage summary as above]

GROUNDED ITEMS (can answer with confidence)
[REQ-001] ● Grounded — [brief note on evidence found]
...

ASSERTABLE ITEMS (reasonable claims, flag in answer)
[REQ-012] ◑ Assertable — [brief note on what was inferred and from what]
...

GAP ITEMS (cannot credibly address from documentation)
[REQ-031] ○ Gap — [what was queried, why nothing credible came back]
...

---
For each Gap item, I'll default to acknowledging it honestly in the response
(e.g. "This capability is not currently documented in our product — please
contact us to discuss your specific requirements"). 

If you'd like to handle any Gap items differently — for example, if you know
the capability exists but isn't documented, or if you'd prefer to skip an item
entirely — tell me now and I'll adjust before drafting.

Ready to proceed to drafting?
```

Wait for confirmation. Accept per-gap instructions if provided. Incorporate
before Step 4.

---

## Step 4: Draft and Refine Answers

Before drafting, ask the user one question:

> "How would you like me to draft the answers?
> A) **Section by section** — I draft one section at a time, you review and
>    approve before I move to the next
> B) **Full pass first** — I draft all answers end-to-end, then we review and
>    refine together
>
> For large RFPs (50+ requirements), option A usually produces better results."

Wait for their choice, then proceed accordingly.

**Drafting principles:**

*Grounded items:*
- Lead with the specific capability or feature as described in the MCP content
- Include a brief, natural reference to where this comes from ("Our [feature]
  supports...")
- Avoid padding — one clear, evidenced paragraph per requirement unless length
  guidance from the RFP says otherwise

*Assertable items:*
- Draft a confident, reasonable claim based on the surrounding MCP context
- Add a subtle internal marker `[ASSERTABLE — verify]` at the end of the answer so the user can review before submission. If it is in an Excel, include it in a separate "Notes" column if possible.
- Do not present assumptions as documented facts

*Gap items:*
- Use honest acknowledgment language by default:
  "This capability is not currently available in [Product]. We'd welcome the
  opportunity to discuss your specific requirements and our roadmap."
- If the user specified an alternative approach at Checkpoint B, apply it here

**Tone and voice:**
Apply the tone confirmed at Checkpoint A throughout. Specifically:
- Match the register and vocabulary of the RFP itself where it signals preferences (e.g. if the RFP uses "end-users" not "customers", mirror that)
- Keep sentences direct — no filler openings like "We are pleased to confirm that..." or "Our solution is designed to..."
- Every answer should open with the substance, not a preamble

**Scoring criteria (if confirmed at Checkpoint A):**
- Higher-weight sections receive longer, more detailed answers
- Lower-weight sections receive concise, precise answers. No unnecessary padding to match word count

**Slop check (run before presenting each section or the full draft):**
Before surfacing any drafted content, read it once for:
- Redundant sentences that repeat the same point
- Filler phrases ("robust solution", "best-in-class", "seamlessly integrates")
- AI-typical openers ("Certainly!", "Great question", "As an AI...")
- Hedging language that undercuts confidence without adding information
  ("may", "might", "potentially" used unnecessarily)

Remove all of the above before presenting.

---

## Reader Validation (runs before Checkpoint C)

After the slop check and before presenting the draft to the user, run a reader
validation. The goal is to catch gaps in clarity and completeness that are
invisible from inside the workflow — things a skeptical evaluator would notice
on first read.

**If a subagent tool is available:**

Spawn a fresh subagent using only the completed draft as input. No prior
conversation context, no requirements list, no mapping. The subagent's only
instruction is:

> "You are a skeptical procurement evaluator reading this vendor response for
> the first time. You have no prior knowledge of this company or product.
> Read the document and list 5–8 questions you still have after reading it —
> things that are unclear, missing, vague, or that you'd want to verify before
> scoring this response favourably. Be specific: cite the section or answer
> that prompted each question."

Once the subagent returns its questions, assess each one:
- **Answerable from document** — the document does contain the answer; the
  reader missed it or the answer is buried. Flag for clarity improvement.
- **Genuinely missing** — the document does not answer this question at all.
  Flag as a gap to surface to the user.

**If no subagent tool is available:**

Generate the reader questions yourself, but do so in a separate reasoning pass
— set aside everything you know about the workflow and read the draft as if
encountering it cold. Then apply the same answerable/missing classification.
Note in the Checkpoint C output: "Reader validation run without subagent —
recommend a manual read-through before submission."

**Surface findings at Checkpoint C** (see below). Do not modify the draft based
on reader validation without user approval first.

---

## CHECKPOINT C — User Reviews Full Draft

Present the complete draft (or the final section if working section-by-section).
Include the reader validation findings alongside the assertable flags so the
user has a complete picture before approving:

```
CHECKPOINT C — Draft complete

[Full draft with section structure]

---
READER VALIDATION — Questions a fresh evaluator still had after reading:

Answerable but buried (clarity improvements suggested):
• Section 3 / REQ-023 — The answer covers RBAC but the evaluator asked where
  audit logs are stored. This is mentioned in REQ-041 but not cross-referenced
  here. Suggest adding a one-sentence pointer.

Genuinely missing (gaps to address before submission):
• Section 5 / REQ-067 — No mention of SLA commitments for support response
  times. The evaluator flagged this as a likely scoring criterion.

---
ITEMS FLAGGED FOR YOUR REVIEW:
• [REQ-012] — Assertable claim about [X]. Please confirm this is accurate
  before submission.
• [REQ-031] — Gap item with honest acknowledgment language. If you'd like to
  revise this, let me know.

Any changes before I generate the executive summary and run the compliance check?
```

Wait for approval or revision requests. Apply any revisions, then confirm the
user is ready to proceed.

---

## Step 4b: Executive Summary

Once the user approves the draft at Checkpoint C, generate a short executive
summary. This is written last because it must honestly reflect what is actually
in the answers — not what was intended before drafting.

**Length:** 250–400 words. No padding to hit a word count.

**Structure:**

1. **Opening (1–2 sentences):** State the customer's core challenge or
   objective as inferred from the RFP and deal context — in their vocabulary,
   not yours. This signals to the evaluator that you understood what they were
   actually asking.

2. **Capability summary (2–3 sentences per win theme):** For each confirmed win
   theme, summarise your strongest relevant capabilities. Ground these in
   Grounded answers from the draft — do not introduce claims here that don't
   appear in the body. If a win theme maps to Gap items, do not paper over them;
   either omit that win theme or briefly acknowledge it.

3. **Gap acknowledgment (if any):** If there are Gap items in the response,
   include one honest sentence: "There are [N] areas where our current
   documentation does not fully address your requirements; we have noted these
   transparently in the relevant sections and welcome a conversation about them."
   Skip this entirely if there are no Gap items.

4. **Closing (1 sentence):** A confident, forward-looking statement. No
   superlatives, no generic phrases ("we look forward to partnering with you").
   Tie it to the evaluator's objective.

**Rules:**
- Do not use the executive summary to introduce capabilities not covered in the
  body answers. It summarises; it does not supplement.
- Apply the confirmed tone throughout.
- Apply the same slop check rules as for body answers before presenting.
- Do not mark this section with `[ASSERTABLE]` — if a claim in the summary
  isn't fully grounded in the body, remove it rather than marking it.

Present the executive summary to the user for a quick review before proceeding
to the compliance check. It does not require formal approval — a simple "looks
good" or a minor edit request is sufficient to move on.

---

## Step 5: Compliance Check

Validate the approved draft against the RFP's explicit submission requirements,
and run a cross-answer consistency scan across the full document. This step has
two distinct checks.

### 5A: Format and completeness check

**Check against:**
- Page or word limits (per section and overall, if specified)
- Required sections — are all mandatory sections present and titled as
  specified?
- Mandatory certifications, declarations, or signature blocks required
- Appendices required (e.g. "Please include a data processing agreement as
  Appendix A")
- Submission format requirements (e.g. "All answers must be in the provided
  template", "Do not exceed 200 words per response")
- Numbering or reference conventions required by the customer

### 5B: Cross-answer consistency scan

Read the full draft as a single document and check for:

- **Conflicting claims** — two answers that make incompatible statements about
  the same capability, feature, or limitation (e.g. REQ-004 says the system
  supports X; REQ-087 says it does not)
- **Inconsistent terminology** — the same feature or concept named differently
  across answers in a way that could confuse an evaluator (e.g. "workspace" in
  one answer, "project" in another for what appears to be the same concept)
- **Implicit contradictions** — an answer that does not explicitly conflict with
  another but implies a different reality (e.g. claiming enterprise-grade uptime
  in one section and acknowledging no SLA in another without reconciling the two)

Flag anything found as `⚠ CONSISTENCY` in the combined report.

**Output — combined compliance report:**

```
COMPLIANCE CHECK

FORMAT & COMPLETENESS
✓ All required sections present
✓ Word counts within limits (Section 3: 847 words vs. 1000 limit)
✗ FAIL: Appendix B (Security Certifications) referenced but not included
⚠ WARN: Section 4 answers exceed 200-word guideline on REQ-047 (312 words)

CONSISTENCY
✓ No conflicting claims found
⚠ CONSISTENCY: REQ-004 refers to "workspaces"; REQ-061 refers to "projects"
  for what appears to be the same concept. Recommend aligning terminology.
⚠ CONSISTENCY: REQ-019 claims 99.9% uptime; REQ-088 acknowledges no formal
  SLA. These are not reconciled. Suggest adding a clarifying sentence to one.

Action required before submission:
1. Add Appendix B — list your current security certifications
2. REQ-047 answer: trim by ~110 words or confirm word guideline is not binding
3. Align "workspaces" / "projects" terminology across REQ-004 and REQ-061
4. Reconcile uptime claim and SLA acknowledgment in REQ-019 / REQ-088
```

Do not proceed to Step 6 until the user has acknowledged the compliance report
and either resolved all failures or explicitly accepted any warnings.

---

## Step 6: File Output

Generate the final response document in the format confirmed in Step 0b.

**Call the appropriate output skill:**
- Word document → read and follow `skills/docx/SKILL.md`
- PDF → read and follow `skills/pdf/SKILL.md`
- Excel → read and follow `skills/xlsx/SKILL.md`

**Structural guidance by output type:**

*Word / PDF:*
- Open with the executive summary from Step 4b as the first page after the
  cover page — before the requirements responses begin
- Mirror the section structure of the original RFP for the body
- Use the customer's requirement numbering in the response (REQ-001, etc. or
  their original numbering if different)
- Include a cover page with: customer name, vendor name, response date, contact
  person from Step 1
- Remove all internal markers (`[ASSERTABLE — verify]`, etc.) before output

*Excel (fill-in-the-blank):*
- Populate the answer column directly — do not add new columns or change the
  original structure
- Preserve all original formatting, row structure, and formulas
- If a Gap item uses honest acknowledgment language, paste it in the cell as
  written — do not leave cells blank

**Final check before presenting the file:**
- Confirm all `[ASSERTABLE — verify]` markers are removed
- Confirm Gap items are populated with the agreed language
- Confirm cover page (if applicable) reflects correct names and date

Present the completed file with a brief summary:
> "Your RFP response is ready. Executive summary + [N] of [total] requirements
> addressed — [Grounded], [Assertable], [Gap]. The compliance check passed /
> flagged [issues] which have been resolved. [View your response file](link)"

---

## What this skill does NOT do

- Does not proceed without a confirmed kapa MCP. There is no degraded mode.
- Does not invent capabilities or fill Gap items with plausible-sounding claims.
  Gaps are acknowledged honestly.
- Does not use web search as a primary source. Web-sourced content is always
  flagged for user verification.
- Does not skip checkpoints. A, B, and C are all required — they are where the
  user's judgment replaces Claude's assumptions.
- Does not present assertable claims as documented facts. All Assertable items
  carry an internal marker until the user confirms them.
- Does not begin drafting before the requirements list is confirmed at
  Checkpoint A.
- Does not skip the reader validation step. If no subagent is available, the
  validation is run as an internal cold-read pass and the user is advised to
  do a manual read-through before submission.
- Does not write the executive summary before all answers are approved at
  Checkpoint C — the summary reflects the actual answers, not the intended ones.
- Does not generate the output file before the compliance check is acknowledged.
