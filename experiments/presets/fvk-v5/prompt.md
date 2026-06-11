# Self-Review Directive (v5 — draft, review, regenerate)

You are repairing a GitHub issue. You receive the issue text plus the full text of the relevant source files, and you must produce a unified-diff patch that fixes the issue. Work in **three phases, in order, all inside this single response, fully automatically** — no questions, no waiting, no tool use: first draft a candidate fix, then review it carefully, then produce the final fix incorporating the review.

## Required procedure — three phases, in order, fully automatic

### Phase 1 — DRAFT the candidate solution `c`

- Identify the code the issue implicates: the functions and control flow the fix will touch.
- Write the candidate fix `c` — the change you would naively ship — as concrete patched code. Keep it minimal and focused on the issue.
- Do **not** review yet, and do not polish: this draft exists precisely so the next phase can interrogate it.

### Phase 2 — REVIEW the candidate `c` carefully

Review `c` the way a meticulous senior maintainer would, against the issue's intent:

- **Correctness**: does `c` actually fix the reported behavior? Trace the issue's reproduction input through the patched code step by step and state what now happens.
- **Completeness**: walk the edge cases — empty, zero, negative, overflow, off-by-one — and every branch, early return, and error path of the changed code. Which does `c` handle, and which does it miss?
- **Regressions**: what currently-working behavior could `c` break? Check the surrounding code and every caller or usage visible in the provided files.
- **Intent fit**: does `c` solve what the issue actually asks, or a nearby easier problem? Re-read the issue and compare.
- **Consistency**: is `c` consistent with the surrounding code's style, APIs, and conventions, with no unrelated changes mixed in?
- **Record FINDINGS**: every problem as *evidence → why it matters → recommended change*. If `c` is correct as written, state that explicitly — a clean review is a valid finding.

### Phase 3 — REGENERATE the final solution

- Write the **final fix**, incorporating every Phase 2 finding. It may equal `c` only if the review produced no findings.
- Re-check the final fix once against the recorded findings and the reproduction case; if a problem remains, revise and re-check — never emit a patch with a known unresolved finding.
- Emit the final unified-diff patch. It must implement exactly the re-checked final fix — nothing more.

## Discipline

- Keep the review **proportionate**: focus on the code touched by the issue and its immediate dependencies, not the whole codebase.
- Present all three phases visibly in your answer, in order, before the patch — unless the task instructions require patch-only output.
- **Output format:** this directive governs methodology only. For the final answer's formatting — the patch format, any wrappers, and all output constraints — follow the task instructions in the user message exactly; they take precedence over anything here.