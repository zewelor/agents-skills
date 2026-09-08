---
name: deep-research
description: Generate or refine a structured prompt for a Deep Research tool and copy it to clipboard. Use only when the user explicitly asks to prepare, write, or revise a Deep Research prompt to paste into another tool. Do not use for requests to conduct research, investigate a topic, or provide research findings, even when the user calls the task deep research.
---

# Deep Research Prompt Builder

Turn the user's question into a focused prompt for another Deep Research tool.
Frame it around the user's decision, expert conversation, or comparison of options.

## Core workflow

1. Identify the user's decision or preparation goal.

2. Gather context from the conversation and local files when relevant.
   - For life/admin/legal/property cases, prefer `AGENTS.md`, dossier files, notes, contracts, scans, summaries, timelines, and TODO files.
   - For technical cases, inspect package/config files only when they matter.
   - If the current conversation already has enough context, use it and avoid re-exploring.
   - Keep source facts separate from assumptions, hypotheses, and missing information.

3. Decide privacy level before drafting.
   - Default to anonymized prompts for external tools.
   - Remove or replace personal names, exact addresses, IDs, tax numbers, registry numbers, account numbers, access codes, dates of birth, and other identifiers unless the user explicitly asks to include them.
   - Preserve decision-relevant facts in generalized form, e.g. "a plot in Porto Santo", "approximately 200 m2", "owners abroad", "2023 draft deed".

4. Craft the prompt using this structure:

```
## Objective
[One paragraph: what to research and what decision/conversation it should support]

## Context
[Concrete facts, anonymized where needed. Separate confirmed facts from reported facts if useful.]

## Investigate
[Numbered list of the most important research angles, ordered by decision importance]

## Output Format
[Exactly how the answer should be structured: summary, decision tree, comparison matrix, question list, action plan, source notes, etc.]

## Constraints
[Source priorities, privacy limits, assumptions to avoid, jurisdiction, language, level of caution]
```

5. Copy the prompt to the clipboard.
   - If the prompt already exists in a file, copy only the prompt block with the most direct command available.
   - Prefer `wl-copy` on Wayland Linux, `pbcopy` on macOS, `xclip -selection clipboard` on X11, or `clip.exe` on Windows.
   - If clipboard access is blocked by sandboxing, rerun the copy command with escalation and a short approval question.
   - If all clipboard methods fail, print the prompt in a clearly marked block and tell the user to copy it manually.

6. After copying, confirm:
   - That the prompt is in the clipboard.
   - What it asks the research tool to produce.
   - Where the user should paste the eventual answer if there is a local research/dossier file.

## Domain guidance

For legal, property, tax, medical, financial, or other high-stakes topics:
- State that the research is preparation for an expert conversation, not a substitute for professional advice.
- Ask for current, primary, jurisdiction-specific sources.
- Ask for confidence levels and source notes.
- Ask for red flags and "what would stop this plan".
- Ask for a short expert-question list, not only a long report.
- Ask the research tool to separate facts, hypotheses, and unknowns.

For consumer/travel/product decisions:
- Ask for current options, prices/availability when relevant, tradeoffs, and a recommendation framework.
- Include user constraints such as budget, location, dates, preferences, and non-negotiables.

For technical decisions:
- Include stack, versions, constraints, existing architecture, and acceptance criteria only when relevant.
- Ask for official docs and implementation implications.

## Refinement

If the user asks to adjust the prompt (e.g., "make it more focused on pricing", "too broad", "add security angle"):
- Modify the previous prompt — do NOT regenerate from scratch
- Copy the updated version to clipboard
- Show what changed

## Prompt Crafting Guidelines

- Write in second person imperative ("Research...", "Investigate...", "Analyze...").
- Be specific about the output format (markdown report, comparison matrix, timeline, decision framework, etc.)
- Put the most important decisions first; avoid long laundry lists unless the user explicitly wants exhaustive research.
- For messy real-life cases, prefer: decision tree, risk matrix, expert question list, document checklist, and next actions.
- Ground the prompt in concrete context, but anonymize external prompts by default.
- Use broad identifiers only when exact identifiers are unnecessary for the research.
- Keep the mission focused: one primary research objective plus a few key subquestions.

## Important Notes

- Do NOT attempt to run any research tool or conduct research yourself — only generate the prompt
- Do NOT invent facts to make the prompt feel complete; mark missing facts as unknowns.
- The user will handle the research session manually in their browser or app
