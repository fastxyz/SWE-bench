# FVK Notes

## Source decision

No additional source changes were made after V1.

The decision is based on `fvk/FINDINGS.md` and
`fvk/PROOF_OBLIGATIONS.md`:

- `F-001` identifies the reported pre-fix bug: a built-in list input was
  rebuilt as a tuple. `PO-1` and `PO-3` show V1 discharges that obligation by
  returning the accumulated `resolved_values` list for list inputs while keeping
  the existing element-resolution loop unchanged.
- `F-002` confirms the relevant integration path for exact lookups.
  `PO-5` shows `build_filter()` passes the preserved RHS from
  `resolve_lookup_value()` into lookup construction, so type-sensitive exact
  lookup preparation receives the list rather than a coerced tuple.
- `PO-2`, `PO-4`, and `PO-6` show V1 preserves tuple behavior, preserves
  unrelated expression and atom paths, and does not change the method signature
  or dispatch shape.

## Rejected source change

I considered broadening V1 to reconstruct with the exact concrete constructor,
for example `type(value)(resolved_values)`. The FVK audit records this as
`F-003` and `PO-7`.

That change was rejected for this pass because the public issue specifically
describes a value of type `list` being coerced to `tuple`, while exact subclass
preservation is not independently specified by the allowed evidence. The
broader constructor approach could also change behavior or raise for tuple
subclasses whose constructors do not accept a single iterable argument, such as
namedtuple classes. Because `PO-7` remains under-specified rather than
discharged, it cannot justify a source edit.

## FVK artifacts

The following artifacts were written:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`
- `fvk/mini-python-resolve-lookup.k`
- `fvk/resolve-lookup-value-spec.k`

The proof is constructed, not machine-checked. Per the task constraints, I did
not run tests, Python, `kompile`, `kast`, or `kprove`; the commands are recorded
in the artifacts for a future environment that has K tooling.
