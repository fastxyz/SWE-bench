# FVK Notes

Status: FVK audit completed without running tests, Python, or K tooling.

## Source Decision

V1 stands unchanged. I made no V2 source edits.

The no-change decision traces to:

- `fvk/FINDINGS.md::F-001`, which localizes the pre-V1 bug to the old
  `np.can_cast(np.float32, value.dtype)` predicate and records that V1 replaced
  it at both constructor sites.
- `fvk/FINDINGS.md::F-002`, which rejects a narrower `float16` special case and
  confirms that V1 matches the public hint's "every inexact type" obligation.
- `fvk/FINDINGS.md::F-003`, which checks the main compatibility frame:
  explicit dtype, integer/bool/object default coercion, and structured dtype
  behavior remain unchanged.
- `fvk/FINDINGS.md::F-004`, which confirms there is no public API or dispatch
  compatibility break.

The proof obligations supporting that decision are:

- `PO-1` and `PO-3`: the reported unit multiplication path reaches
  `Quantity(m, unit)` and the concrete `float16` dtype is preserved there.
- `PO-2` and `PO-4`: all inexact dtypes are preserved in both constructor
  branches that used the old predicate.
- `PO-5`, `PO-6`, `PO-7`, and `PO-8`: explicit dtype, `copy=False`,
  non-inexact default coercion, and structured dtype behavior are preserved.
- `PO-9`: no public signature, dispatch shape, or test file changes are needed.

## Artifact Decisions

I wrote the five requested FVK artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

I also wrote the formal and adequacy files required by the FVK docs:

- `fvk/mini-quantity.k`
- `fvk/quantity-dtype-spec.k`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

These files model only the dtype decision fragment because the audited property
is exactly the result dtype. The model keeps the property axis visible:
`float16` and `float64` are distinct outcomes, so the abstraction can distinguish
the reported failure from the intended behavior.

## Rejected Alternatives

I did not refactor the duplicate predicate into a helper. `F-004` and `PO-9`
favor keeping the repair minimal, and `PO-2`/`PO-4` are already discharged by
the direct two-site replacement.

I did not add or modify tests. The task forbids test edits, and `F-005` notes
that the constructed proof is not a basis for removing tests without later
machine checking.

I did not broaden the source change to unit multiplication. `PO-1` shows the
unit path already delegates to `Quantity(m, self)` with no explicit dtype, so
the defect is fully discharged at the constructor predicate.
