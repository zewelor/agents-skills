# Review patterns

Use these illustrative fragments to check an edit, not as rules for every project.
Treat the paths and commands below as fixture data; verify real targets before
putting an equivalent instruction into a repository.

## Preserve requirements while removing filler

Original:

```text
Write clean, maintainable code and follow best practices.
Run bin/ci before submitting. Production deployment requires the owner's approval.
Never include access tokens in logs.
```

Revised:

```text
Before submitting, run bin/ci and report its result.
Deploy to production only after the owner approves that deployment.
Never include access tokens in logs; redact them from diagnostic output.
```

Check that the test command, approval gate, and token boundary survive. Remove
only the generic encouragement. Do not invent an approval requirement that was
absent from the source, or interpret rewriting this fragment as deployment approval.

## Replace a vague reference with a conditional read

Original:

```text
Database documentation: docs/database.md
```

Revised:

```text
Before changing a schema, index, constraint, or data backfill, read docs/database.md
for migration constraints and verification requirements.
```

Check that each listed case is actually covered by the target. Resolve the path
from the containing document. If the required target is missing, report the gap
instead of inventing its contents or silently proceeding without its constraints.

## Define completion without claiming unperformed checks

Original:

```text
Check the migration and make sure it is safe.
```

Example revision, after establishing these project requirements:

```text
Record affected tables and indexes. Run the migration against the approved test
fixture and report the command and result. Document the recovery approach.
If a required check cannot run, report it as unverified with the blocker.
```

Separate newly proposed requirements from requirements already agreed with the
user. Do not turn an unavailable production-sized fixture into a successful test,
or assume every migration has a safe automatic rollback.

## Preserve retrieval order when splitting a document

Keep the shared prerequisites and approval boundary in the main file. Move only
branch-specific detail, and put its read instruction before the dependent action.
Verify that a reader starting at the entry point can discover every required branch.

Do not treat opening another file as clearing the earlier context. Use a real
isolated run when a test requires a fresh context; do not promise isolation from
ordinary document splitting.
