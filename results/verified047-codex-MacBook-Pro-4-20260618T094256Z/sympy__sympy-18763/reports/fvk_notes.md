# FVK Notes

## Decision

V1 stands unchanged. I made no additional edits under `repo/` during the FVK
audit because the artifacts under `fvk/` found no concrete counterexample, unmet
proof obligation, or compatibility blocker that V1 demonstrably fails.

## Artifact package

The FVK artifacts are written under `fvk/` so they do not enter the repository
diff:

- `fvk/mini-latex-printer.k`
- `fvk/subs-latex-spec.k`
- `fvk/PROOF.md`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/SPEC.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/FINDINGS.md`

The proof is labeled `constructed, not machine-checked`. Per the task
constraints, I did not run tests, Python, `kompile`, `kast`, or `kprove`.

## Trace from findings to decision

`fvk/FINDINGS.md` finding `FVK-1` models the legacy direct-rendering behavior as
`mulTex(numTex(3), subsTex(rawAdd, assignOne))`, which corresponds to the
reported bad output `3 \left. - x + y \right|_{...}`. The candidate claim
`ISSUE-EXAMPLE` in `fvk/subs-latex-spec.k` shows V1 changes that shape to
`mulTex(numTex(3), subsTex(paren(rawAdd), assignOne))`, matching the requested
parenthesized output.

`fvk/FINDINGS.md` finding `FVK-2` checks the main regression risk: non-additive
`Subs` expressions such as `Subs(x*y, ...)` remain unparenthesized in the modeled
fragment. That is backed by `PAREN-NONLOW-STRICT` and
`SUBS-NONLOW-PRECEDENCE` in `fvk/subs-latex-spec.k` and by public evidence entry
`E5` in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

`fvk/SPEC_AUDIT.md` marks every formal obligation as `PASS`, with no `FAIL` or
`AMBIGUOUS` entries. `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` reports no signature,
dispatch, override, or public callsite compatibility blocker.

## Alternatives considered

The revision discipline required a source edit only for a documented FVK
finding. The audit considered the two obvious alternatives from the baseline:
changing `Subs` precedence or changing generic multiplication bracket logic.
Neither is forced by the FVK findings, and both would touch broader behavior than
the documented bug mechanism. Because V1 already discharges the issue example
and the modeled frame condition, no further code change is justified.
