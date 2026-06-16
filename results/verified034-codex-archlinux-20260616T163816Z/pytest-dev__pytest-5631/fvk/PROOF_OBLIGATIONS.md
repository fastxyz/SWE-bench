# FVK Proof Obligations

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## PO-001: Explicit `new=` objects are never equality-compared

Statement: for every patching object `p` and every loaded sentinel `s`, the
sentinel predicate may inspect whether `p.new is s`, but it must not evaluate
`p.new == s`, `s == p.new`, or the truth value of an equality result.

Evidence: intent entries I-001 and I-002 in `fvk/SPEC.md`; finding F-001.

Discharge: V1 uses `any(p.new is s for s in sentinels)`. Python `is` performs
identity comparison and returns a scalar boolean without dispatching to
`__eq__`.

Status: discharged by code inspection.

## PO-002: Default sentinel patchings count

Statement: if `not p.attribute_name` and `p.new` is identical to one of the
loaded mock module `DEFAULT` sentinels, that patching object contributes exactly
one to the returned count.

Evidence: intent entries I-003 and I-004; finding F-002.

Discharge: for the matching sentinel `s`, `p.new is s` is true, `any(...)` is
true, and the list comprehension includes `p` exactly once.

Status: discharged by code inspection and represented by the second K claim in
`fvk/num-mock-patch-args-spec.k`.

## PO-003: Explicit non-sentinel replacements do not count

Statement: if `p.new` is not identical to any loaded `DEFAULT` sentinel, the
patching object does not contribute to the returned count, regardless of its
equality behavior.

Evidence: intent entries I-001, I-002, and I-004; findings F-001 and F-003.

Discharge: every generated identity comparison returns false; `any(...)` is
false; the list comprehension excludes `p`.

Status: discharged by code inspection and represented by the first K claim in
`fvk/num-mock-patch-args-spec.k`.

## PO-004: Returned value is the cardinality of matching patchings

Statement: when at least one mock module is loaded, the helper returns the
number of patching objects satisfying both `not p.attribute_name` and identity
with a loaded `DEFAULT` sentinel.

Evidence: intent entries I-003 and I-004; findings F-001 through F-003.

Discharge: the return expression is `len([...])` over exactly that predicate.
Each patching object appears at most once in the comprehension, so the length is
the predicate cardinality.

Status: discharged by code inspection and represented by the mixed-sequence K
claim in `fvk/num-mock-patch-args-spec.k`.

## PO-005: Empty or missing patchings return zero

Statement: if `getattr(function, "patchings", None)` is absent or falsey, return
`0`.

Evidence: helper purpose in source and compatibility frame condition I-005.

Discharge: V1 did not change the existing `if not patchings: return 0` branch.

Status: discharged by code inspection.

## PO-006: No-loaded-mock fallback is preserved

Statement: if no `mock` or `unittest.mock` module is loaded but `patchings` is
truthy, return `len(patchings)`, preserving the pre-existing fallback.

Evidence: compatibility frame condition I-005 and finding F-004.

Discharge: V1 did not change the `return len(patchings)` fallback.

Status: discharged by code inspection.

## PO-007: API and mutation frame conditions are preserved

Statement: the fix must not change the helper signature, return type, imports,
callers, or mutate patching/mock state.

Evidence: compatibility frame condition I-005 and finding F-004.

Discharge: V1 changes only an expression inside a list-comprehension predicate.
It does not assign to any object and does not alter any public call surface.

Status: discharged by code inspection.

## PO-008: Formal artifact adequacy

Statement: the formal model must preserve the property axis that distinguishes
the bug: identity-based sentinel membership must be distinguishable from
equality-based sentinel membership for explicit array-like `new=` values.

Evidence: findings F-005 and F-006.

Discharge: `fvk/mini-patchcount.k` represents object identities as `Obj` atoms
and defines `identityIn` over those identities. The model can distinguish a
passing case (`arrayNew` not counted) from the failing legacy case described in
F-001 (an equality-based predicate would attempt array equality instead).

Status: adequate for this audit, but constructed and not machine-checked.
