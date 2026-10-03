---
name: software-project-starter
description: Design and bootstrap minimal software projects across languages. Use for new-project kickoff or early MVP planning, not routine changes in established codebases.
---

# Software Project Starter

Turn an idea into the smallest useful project and complete the authorized scope.
Give the user's instructions and existing project conventions precedence over
these defaults; reuse decisions and authorization already established.

## Frame the project

- Read relevant instructions and files present in the target directory. An empty
  directory is valid: work from the user's brief. Check Git status if applicable,
  preserve unrelated changes, and initialize Git only if requested.
- Inspect a user-named starter or previous product; reuse its conventions where
  they fit this project's needs.
- Define the first observable outcome, project shape, and realistic user scenario.
  Ask only about unresolved choices that materially affect scope or design;
  recommend the simplest adequate option.

## Plan the MVP

- Tie scope and dependencies to the first useful scenario and required guarantees.
  Keep speculative abstractions and deferred features out of the implementation.
- Reuse canonical documents. For a tiny project, combine the contract and short
  prioritized plan; include observable acceptance criteria and verification.
- Present the compact plan, then implement when authorized and material decisions
  are settled. For a specification-only request, deliver the documents.

## Select supporting guidance

Read the references relevant to this project:

- [Automation](references/automation.md): read for every new-project bootstrap.
  Include GitHub Actions CI by default unless explicitly excluded; ask about
  Renovate and Docker only when those choices are undecided.
- [Testing](references/testing.md): briefly assess PBT, stateful testing, and
  formal methods against concrete risks before finalizing the contract.
- [Project documents](references/project-docs.md): for contracts, plans, and
  durable project guidance.
- [Docker](references/docker.md): after Docker is selected; apply image-build
  guidance when building project-owned images.
- [Go](references/go.md) or [Ruby](references/ruby.md): for the selected stack.

For other stacks, reuse project conventions. Consult official documentation for
version-sensitive choices; add new references only when real use warrants them.

## Complete the work

- Establish important failure scenarios before coding. Work one slice at a time
  and continue through the authorized scope; pause only at an agreed gate, a
  material unresolved decision, or a blocker.
- Run checks appropriate to the project and complete required validation. Broaden
  testing when failures or unresolved risks justify it; review and correct issues.
- Update the canonical contract and plan when scope changes. When durable agent
  guidance will help future work, include the testing reconsideration reminder.
- Report the working result, verification evidence, and remaining gaps. Honor
  agreed user acceptance gates without declaring acceptance on the user's behalf.
- Treat commits, pushes, PRs, releases, and deployments as separate actions;
  perform them only within the user's authorized delivery scope.
