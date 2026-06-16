# FVK Findings

Status: constructed, not machine-checked.

## F1: Resolved Root Cause - Variable Field Label Becomes Wrong Link

Input shape:

```rst
.. py:module:: pkg

.. py:data:: limit

.. py:class:: Foo

   :ivar limit: per-instance limit
```

Pre-V1 observed behavior by source reasoning:

`PyTypedField('variable', rolename='obj', ...)` creates a `pending_xref` for the
field argument `limit`. Python-domain contextual lookup can then resolve that
`pending_xref` to `pkg.limit` when no `pkg.Foo.limit` object is registered.

Expected behavior:

The `:ivar limit:` field label is documentation for the instance variable. It
should render as a plain label and should not link to `pkg.limit`.

V1 status:

Resolved. The variable field no longer has `rolename='obj'`; `Field.make_xref()`
therefore returns plain content and no `pending_xref` exists for the label.

Traced obligations:

- `fvk/PUBLIC_EVIDENCE_LEDGER.md`: E1-E4, E6, E8-E10
- `fvk/PROOF_OBLIGATIONS.md`: PO1, PO2

## F2: Rejected Alternative - Resolver-Only Fuzzy Narrowing Is Incomplete

Input shape:

Same as F1, with a same-module object `pkg.limit`.

Observed by source reasoning:

The resolver tries `modname + "." + name` before suffix/fuzzy searching. A
change that only removes suffix matches for attributes/data would still allow
`:ivar limit:` to resolve to `pkg.limit`.

Expected behavior:

The field label should not auto-link to same-module `pkg.limit` either.

V1 status:

Resolved by avoiding creation of the field-label xref at the source.

Traced obligations:

- `fvk/PUBLIC_EVIDENCE_LEDGER.md`: E3, E8-E10
- `fvk/PROOF_OBLIGATIONS.md`: PO2, PO5

## F3: Compatibility Finding - Type Links Must Remain

Input shape:

```rst
.. py:class:: Foo

   :ivar limit: per-instance limit
   :vartype limit: int
```

Expected behavior:

The `limit` label is plain text, while the type name `int` remains eligible for
Python class cross-reference resolution.

V1 status:

Satisfied. `typerolename='class'` remains on the variable typed field.

Traced obligations:

- `fvk/PUBLIC_EVIDENCE_LEDGER.md`: E7, E10
- `fvk/PROOF_OBLIGATIONS.md`: PO3

## F4: Honesty Gate - Proof and Tests Not Executed

Input shape:

All claims in `fvk/sphinx-fields-spec.k`.

Observed:

Per task constraints, no tests, Python code, or K tooling were executed.

Expected:

Artifacts must label the proof as constructed, not machine-checked, and test
removal must not be recommended unconditionally.

Status:

Open operational caveat, not a source-code bug. The proof artifacts include the
commands that would be run later, and no tests are removed.

Traced obligations:

- `fvk/PROOF_OBLIGATIONS.md`: PO6

## Proof-Derived Findings from `/verify`

The constructed proof introduces no new code-change findings. It confirms that
the V1 code shape discharges the no-xref and type-preservation obligations. The
only residual item is F4: the proof is not machine-checked because execution is
forbidden in this benchmark session.
