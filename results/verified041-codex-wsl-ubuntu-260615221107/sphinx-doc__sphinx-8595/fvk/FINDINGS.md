# FVK Findings

Status: constructed for audit, not machine-checked.

## F-001: Empty explicit `__all__` was conflated with missing `__all__`

Classification: code bug, resolved by V1.

Input:

- Module members: `foo`, `bar`, `baz`, each with docstrings.
- Module export state: explicit `__all__ = []`.
- Directive state: `.. automodule:: example` with `:members:`.
- No `autodoc-skip-member` event override.

Observed before V1:

- `ModuleDocumenter.get_object_members(want_all=True)` evaluated
  `if not self.__all__:` as true for `[]`.
- The function returned the implicit-member path, so `foo`, `bar`, and `baz`
  could be documented.

Expected:

- An explicit empty export list means no names are exported.
- Every module member should be forced skipped, and default filtering should
  emit no module-member entries.

Resolution:

- V1 changes the branch to `if self.__all__ is None:`.
- This makes only absent/ignored `__all__` use the implicit path. Empty explicit
  sequences use the existing explicit-`__all__` path and therefore force-skip all
  members.

Trace:

- Intent entries: I1, I2, I3.
- Proof obligations: PO-1, PO-2, PO-3, PO-4.
- K claims: `EMPTY-ALL-BRANCH`, `EMPTY-ALL-FILTER`.

## F-002: User skip-event override remains outside the default issue behavior

Classification: compatibility/frame condition, no code change required.

Input:

- Same as F-001, but with an `autodoc-skip-member` event handler returning
  `False` for a forced-skipped member.

Observed/expected:

- Public tests show event handlers can override autodoc's skip decision for
  members not in `__all__`.
- V1 reuses the existing explicit-`__all__` skipped-member path, so this
  extension behavior is preserved.

Resolution:

- Do not special-case empty `__all__` by returning an immediate empty list from
  `get_object_members()`. That would be a larger semantic change and could
  bypass the established skip-event path.

Trace:

- Intent entry: I6.
- Proof obligation: PO-6.

## F-003: No additional source defect surfaced by FVK

Classification: confirmation, no code change required.

Checked cases:

- Absent/ignored `__all__` remains `None` and uses the implicit path.
- Non-empty explicit `__all__` continues to mark only non-exported members
  skipped.
- Empty explicit `__all__` now uses the same explicit path and marks every
  member skipped.
- Explicit `:members: foo,bar` selection is not changed by the V1 edit.

Conclusion:

- The V1 source change is sufficient for the public issue and preserves the
  public compatibility obligations identified in the audit.

Trace:

- Proof obligations: PO-1 through PO-7.
- K claims: all claims in `autodoc-module-all-spec.k`.

## Proof-derived notes

The proof is constructed but not machine-checked. No `kompile`, `kast`, or
`kprove` command was run. The proof obligations are simple case splits over
`AllState`; the only residual risk is the ordinary FVK MVP trust base:
adequacy of the mini semantics and a future machine check of the `.k` files.
