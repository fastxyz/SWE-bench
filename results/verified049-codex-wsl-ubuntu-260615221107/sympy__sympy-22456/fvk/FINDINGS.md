# FVK Findings

Status: constructed, not machine-checked. Findings are based on public issue
intent and static source inspection only.

## F1: Resolved code bug - empty `String.args` broke Basic reconstruction

- Evidence: E1, E2, E8; PO1, PO2.
- Input: `expr = String("foobar")` on the pre-fix design.
- Observed before V1: `text` was listed in `not_in_args`, so `expr.args` was
  empty and `expr.func(*expr.args)` attempted to reconstruct without `text`.
- Expected: `expr.func(*expr.args) == expr` for this `Basic` subclass.
- V1 disposition: resolved by storing `Str(expr.text)` in `_args` and accepting
  `Str` in `_construct_text`.

## F2: Resolved compatibility risk - raw Python `str` in `.args` would violate Basic

- Evidence: E3, E4, E6; PO1.
- Input: proposed alternative `String("foobar").args == ("foobar",)`.
- Observed under that alternative: reconstruction would work, but the `.args`
  tuple would contain a non-`Basic` object.
- Expected: every `.args` element is a `Basic` instance.
- V1 disposition: resolved by using `sympy.core.symbol.Str("foobar")` as the
  positional argument carrier.

## F3: Resolved compatibility risk - nonempty `String.args` could expose `Str` in codegen atoms

- Evidence: E5, E7; PO5.
- Input: `sizeof("unsigned int").atoms()` after making `String.args` nonempty.
- Observed without the V1 `Token.atoms()` frame: generic traversal would see
  the internal `Str("unsigned int")` and could stop treating codegen `String`
  as the default atom leaf.
- Expected: public codegen atom collection remains `{String("unsigned int"),
  String("sizeof")}` for that shape.
- V1 disposition: resolved by making default `Token.atoms()` skip into
  `String` objects while preserving typed `atoms(T)` behavior through `Basic`.

## F4: Residual proof status - constructed but not machine-checked

- Evidence: PO7.
- Input: the FVK proof artifacts in `fvk/`.
- Observed: no `kompile`, `kast`, `kprove`, Python import, or test run was
  executed because the task forbids execution.
- Expected: exact commands are emitted for later machine checking.
- Disposition: acceptable residual risk for this task; no source change follows
  from it.

## Overall code decision

The audit found no new source defect after F1-F3 were checked against the proof
obligations. V1 stands unchanged.
