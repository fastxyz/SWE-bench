# FVK Iteration Guidance for sphinx-doc__sphinx-7454

Status: V1 stands. No additional source edit is justified by the FVK audit.

## Decision

Keep the V1 source change:

```python
reftype = 'obj' if text == 'None' else 'class'
```

This is justified by:

- F-001 and PO-001: direct signature annotation `None` must become a Python
  object-role reference.
- F-002 and PO-006: the change aligns signature mode with existing
  description-mode behavior.
- F-003, PO-003, and PO-004: all non-`None` annotation tokens keep class-role
  behavior.
- F-005 and PO-007: no public API or return-shape compatibility issue was
  introduced.

## Recommended Follow-up Tests

Do not add or modify tests in this task. For future maintainers, useful tests
would be:

- Unit: `_parse_annotation("None")` returns a `pending_xref` whose
  `reftype` is `obj`, `refdomain` is `py`, and `reftarget` is `None`.
- Unit: `_parse_annotation("int")` still returns a class-role pending
  reference.
- Integration: an autodoc signature for `def f() -> None` with Python
  intersphinx mapping renders a link to `library/constants.html#None`.
- Regression: `def f() -> int` still links to the Python documentation for
  `int`.

## Machine-check Guidance

The constructed FVK commands are:

```sh
kompile fvk/mini-sphinx-annotation.k --backend haskell
kast --backend haskell fvk/sphinx-7454-spec.k
kprove fvk/sphinx-7454-spec.k
```

They were not run in this session. Keep all tests until those commands are run
successfully and any integration-level behavior remains covered.

## Next Iteration Trigger

Reopen the source patch only if a future public finding shows one of these:

- Python's intersphinx inventory does not expose `None` through any object-role
  type reachable from `py:obj`.
- A public consumer depends on `None` signature annotations being class-role
  references, contrary to the current issue intent.
- A broader type-annotation parser bug appears for compound annotations where
  exact `None` is not emitted as its own token.
