# FVK Findings

Status: constructed, not machine-checked. No tests or code were executed.

## F1 - Pre-V1 bare tuple replacement was invalid

- Classification: code bug, fixed by V1.
- Evidence: `SPEC.md` E1-E3; `PROOF_OBLIGATIONS.md` PO1.
- Input class: UP028-applicable loop with iterable source `x,`, represented as `iter(bareTuple, "x,")`.
- Observed before V1: the old source-prefixing path produced `yield from x,`, which is invalid in this statement context and triggered Ruff's "Fix introduced a syntax error" rollback.
- Expected: `yield from (x,)`.
- V1 status: discharged by the source change at `yield_in_for_loop.rs` lines 126-137, modeled by the K claim `fix(iter(bareTuple, "x,")) => "yield from (x,)"`.

## F2 - Bare tuple family is covered, not just the literal reproducer

- Classification: confirmation of generalized fix.
- Evidence: `SPEC.md` E1, E4; `PROOF_OBLIGATIONS.md` PO2.
- Input class: any UP028-applicable loop whose iterable AST is `Expr::Tuple` with `parenthesized: false`.
- Observed in V1 by source inspection: the V1 `matches!` branch wraps the sliced iterable text for every unparenthesized tuple AST node, so `x, y` is treated like the singleton `x,`.
- Expected: `yield from (` + original tuple source + `)`.
- V1 status: discharged in the focused model by the general `bareTuple` claim.

## F3 - Non-bare iterable replacement remains source-preserving

- Classification: compatibility/frame condition.
- Evidence: `SPEC.md` E5; `PROOF_OBLIGATIONS.md` PO3.
- Input class: UP028-applicable loops whose iterable is not an unparenthesized tuple, including already parenthesized tuples and non-tuple iterables.
- Observed in V1 by source inspection: these paths still call `contents.to_string()` and then prefix `yield from `.
- Expected: no new parentheses or other source-text rewrite outside the bare tuple case.
- V1 status: discharged in the focused model by the `preserved` claim.

## F4 - Residual proof risk is toolchain and abstraction adequacy, not a source bug

- Classification: proof capability / honesty boundary.
- Evidence: `PROOF.md`; `PROOF_OBLIGATIONS.md` PO4, PO5.
- Input class: full Ruff execution, parser, locator, comments, and fix application.
- Observed: this environment forbids running tests or K tooling, and the mini-K model abstracts the Rust implementation down to the replacement-text branch.
- Expected before deleting tests or claiming machine verification: run the emitted `kompile`, `kast`, and `kprove` commands and keep integration/syntax-validation tests.
- V1 status: no additional code edit justified; keep tests.
