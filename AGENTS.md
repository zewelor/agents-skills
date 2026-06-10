# Instructions

You are an agent assisting with managing, creating, and optimizing skills in the `agents-skills` repository.

## Repository Purpose

This repository houses custom skills that extend AI agents' capabilities. Every skill is a self-contained directory under the `skills/` folder following the spec defined in `.agents/skills/skill-creator`.

## Critical Workflow: Pre-Commit Skill Audit

Whenever you add a new skill or update an existing one, you **MUST** perform a full audit of the skill before committing or completing the task. 

Follow these audit steps:

### 1. Run Technical Validation
Always run the validation script from the `skill-creator` workspace utility to catch syntax or formatting errors:
```bash
python3 .agents/skills/skill-creator/scripts/quick_validate.py skills/<skill-name>
```

### 2. Generate/Validate UI Metadata (`agents/openai.yaml`)
Ensure each skill contains the required UI metadata file:
- Run `generate_openai_yaml.py` to create or update `agents/openai.yaml`:
  ```bash
  python3 .agents/skills/skill-creator/scripts/generate_openai_yaml.py skills/<skill-name> --interface default_prompt="Use \$<skill-name> to ..."
  ```
- Verify the following constraints:
  - `display_name` is correctly formatted.
  - `short_description` is between **25 and 64 characters**.
  - `default_prompt` is defined and explicitly contains the skill name prefixed with `$` (e.g., `\$skill-name`).

### 3. Verify Description and Triggering
- Ensure all "When to Use" or "When to Apply" information is placed **ONLY** in the frontmatter `description` field of `SKILL.md`.
- **NEVER** include a `## When to Apply` or similar section in the body of `SKILL.md`. The body is not parsed for triggering and only consumes unnecessary context.

### 4. Check for Broken Links and Extraneous Files
- Check that all reference files, templates, or assets linked in `SKILL.md` exist and that the paths are correct.
- Ensure no extraneous files (such as `README.md`, `AGENTS.md` inside individual skill folders, or installation/changelog files) are present. They clutter the workspace and violate the spec.

### 5. Writing Style and Structure
- Ensure all instructions are written in the **imperative/infinitive** form (e.g., *Freeze*, *Use*, *Avoid*, *Extract*).
- Keep reference files under 100 lines where possible. If a reference file exceeds 100 lines, include a table of contents at the top.
