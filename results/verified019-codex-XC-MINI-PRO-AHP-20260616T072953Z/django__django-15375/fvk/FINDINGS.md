# FVK Findings

Status: constructed from public issue evidence and source inspection. No tests, Python code, or K tooling were run.

## F1: Pre-fix default wrapper loses terminal summary state

- Classification: code bug fixed by V1
- Evidence: `Aggregate.resolve_expression()` created `Coalesce(c, default, ...)` after `c` had already received `is_summary` from `summarize`; the new wrapper previously kept `BaseExpression.is_summary = False`.
- Input: queryset with existing annotations plus terminal `aggregate(Sum("id", default=0))`.
- Observed before V1: the wrapper is not summary, so `Query.get_aggregation()` does not move it to the outer aggregate query; the outer SQL select can be empty.
- Expected: the wrapper is summary when it wraps a terminal aggregate, so the outer aggregate query selects it.
- Proof obligation: PO1 and PO2.
- Resolution: V1 sets `coalesce.is_summary = c.is_summary`; no further code edit needed.

## F2: Public hint's unconditional `True` is broader than the resolved-expression contract

- Classification: no code bug in V1; compatibility/frame-condition finding
- Evidence: the public hint shows `coalesce.is_summary = True`, but `BaseExpression.resolve_expression()` defines `summarize` as the terminal aggregate marker and ordinary annotations resolve with `summarize=False`.
- Input: ordinary aggregate annotation using `Sum(..., default=0)` outside a terminal `aggregate()` call.
- Observed in V1: the wrapper inherits `False`, matching the non-terminal resolution path.
- Expected: normal annotations should not be reclassified as terminal aggregate reductions.
- Proof obligation: PO3.
- Resolution: keep V1's `c.is_summary` inheritance instead of changing to unconditional `True`.

## F3: No public API compatibility issue found

- Classification: compatibility pass
- Evidence: no signature, import, class, return-shape, or virtual dispatch change was introduced; the returned expression family remains `Coalesce` for defaulted aggregates.
- Input: public callers of `Aggregate.resolve_expression()` through `Query.add_annotation()`.
- Observed in V1: terminal callers pass `is_summary=True`; non-terminal callers use the default `False`.
- Expected: existing callsites continue to work with only the wrapper metadata corrected.
- Proof obligation: PO4.
- Resolution: no source edit needed.

## F4: Verification remains constructed, not machine-checked

- Classification: proof/tooling caveat
- Evidence: benchmark instructions prohibit running K tooling or tests.
- Input: the emitted K files and claims.
- Observed: artifacts are written but not executed.
- Expected: a later environment can run the emitted `kompile` and `kprove` commands and should expect `#Top` if the mini semantics and claims are accepted.
- Proof obligation: PO5.
- Resolution: keep tests and hidden test suite unchanged; do not claim machine-checked proof.
