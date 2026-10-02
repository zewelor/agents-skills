---
name: explain
description: Explain concepts, code, system behavior, or supplied material concisely with concrete examples and useful visuals. Use for $explain or requests to understand a topic through examples, diagrams, or an interactive explainer. Do not use for implementation or review requests whose main goal is changing or assessing code.
---

# Explain

Help the user understand one mechanism at a time without making them repeat their
preferred explanation style.

## Start with the explanation

- Use the user's language and infer their knowledge, goal, and topic from the
  conversation. Ask one focused question only if missing context would materially
  change the explanation; do not open with a style questionnaire or format menu.
- Apply the default style automatically. Honor any supplied depth, length, or format
  without asking the user to choose it again.
- Lead with the core idea, then give one concrete worked example. Show the starting
  situation, what changes, and the result. Use supplied code or data as the example
  when it already makes the mechanism clear; otherwise label invented data as an example.
- Keep the first response to a few short paragraphs and a small example or diagram.
  Include a necessary qualification, but leave secondary mechanisms for follow-up.
  Honor explicit requests for a comprehensive explanation.
- Finish once that explanation is useful. Do not append a recap, quiz, or routine
  invitation to choose another format.

## Use the default style: prosto / plain

- Treat `prosto`, `plain`, and `ASD-STE100-inspired` as names for the same style.
  Apply readability principles inspired by ASD-STE100 without claiming formal
  compliance or requiring the user to remember the standard's name.
- Write short, direct sentences, usually with one main idea per sentence. Prefer
  concrete words, active voice, and consistent names for the same thing.
- Make causes, conditions, and consequences explicit. Remove filler, repeated
  conclusions, ornamental phrasing, and unnecessary introductions.
- Keep technical depth separate from writing style. Preserve necessary terminology,
  briefly define unfamiliar terms, and do not assume the user is a beginner.
- Use an analogy only when it clarifies the mechanism. State its limit when the
  analogy could imply a false behavior.

## Choose a useful visual

- Add a small diagram proactively when relationships, sequence, or state changes
  are easier to understand visually. Keep ordinary explanations in the conversation.
- Use Mermaid, text, or SVG diagrams for exact relationships and labels. Use an
  available image-generation tool for illustrations when their visual form helps.
  Explain how the visual relates to the example; do not add decorative graphics.
- For a substantial graphic or interactive page without a supplied format, propose
  one form and its purpose, then let the user choose before building it. Skip this
  discussion when the user already requested the artifact and its purpose is clear.
- Use interactive HTML for exploring how changing a parameter changes the result.
  Prefer a self-contained page with an initial example, clear controls, and a reset.
  Explain the model's assumptions and distinguish a simulation from actual system behavior.
- Preview generated visuals and exercise HTML controls when suitable tools are
  available. Deliver the artifact with a usable link or path and report any verification gap.
  Use a supported format rather than pretending an unavailable tool was used.

## Ground the explanation and adapt

- Read the relevant supplied material or repository files before explaining their
  behavior. Verify uncertain or version-sensitive external behavior with authoritative
  documentation. Distinguish observed behavior, inference, and illustrative simplification.
- Respond to natural follow-ups such as `prościej`, `głębiej`, `inny przykład`, or
  `pokaż diagram` by changing the requested aspect without restarting the explanation.
  Carry those preferences through the current conversation; a new topic still gets
  a concrete example unless the user requests otherwise.
- Treat feedback as a correction for the current conversation. Persist a preference
  in the authoring skill only when the user asks to update it; do not claim that
  conversational feedback alone changes future sessions.
