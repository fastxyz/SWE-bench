# FVK Notes

## Decision

V1 stands unchanged.

The FVK audit found the root cause from `reports/baseline_notes.md` still
correct: `signature_from_str()` must align `arguments.defaults` across
`posonlyargs + args`, not only across `args`. The V1 source does that directly,
and no additional source edit was justified.

## Trace To Findings

`fvk/FINDINGS.md` F-001 records the original bug:
`foo(a, b=0, /, c=1)` lost `b=0` before rendering. V1 resolves it by padding the
AST defaults across the full positional sequence and using that padded sequence
for positional-only parameters.

`fvk/FINDINGS.md` F-002 records the main confirmation finding: for every
in-domain parsed signature, V1's padding and indexing match the formal intent
family. This justifies keeping the V1 algorithm unchanged.

`fvk/FINDINGS.md` F-003 records the compatibility finding: public function
signatures and consumers are unchanged, and `_parse_arglist()` already renders a
default when `Parameter.default` is not empty.

`fvk/FINDINGS.md` F-004 records the remaining proof limitation: the proof is
constructed but not machine-checked because this task forbids running K tooling,
tests, Python, or project code.

## Trace To Proof Obligations

The no-change decision rests on the following discharged obligations:

- PO-001: V1 pads defaults to `len(posonlyargs) + len(args.args)`.
- PO-002: V1 assigns padded defaults to positional-only parameters.
- PO-003: V1 assigns padded defaults to ordinary positional parameters.
- PO-004: the issue example gives `b.default == '0'` and `c.default == '1'`.
- PO-005: `_parse_arglist()` renders non-empty defaults.
- PO-006: no-positional-only behavior reduces to the prior ordinary default
  alignment.
- PO-007: unrelated parameter forms are framed unchanged.
- PO-008: public API compatibility is preserved.

## Alternatives Considered

I considered editing `_parse_arglist()` instead, but F-001 and PO-005 show that
the renderer already does the right thing when the `inspect.Parameter` carries a
default. The defect is upstream in the conversion from AST arguments to
parameters, so a renderer special case would be less direct.

I considered a small refactor to make V1 visually closer to
`sphinx/pycode/ast.py`, but F-002 through F-003 do not justify a behavior-neutral
source edit. The benchmark asks for a minimal targeted fix, so V1 is left as-is.

## Commands Not Run

Per task constraints, I did not run tests, Python, `kompile`, `kast`, or
`kprove`. The commands that would machine-check the constructed FVK proof are
recorded in `fvk/PROOF.md` and `fvk/SPEC.md`.
