# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: All leading overload signatures are collected

For any finite docstring line list whose maximal leading prefix consists of
`N > 0` valid signature lines for the documented object, `_find_signatures()`
returns exactly `N` `(args, retann)` pairs in source order.

K claims: `FIND-TWO`, `FIND-THREE-PREFIX`.

Findings: F-01.

## PO-2: Collected signatures are stripped from docstring content

If `_find_signatures()` returns a nonempty prefix of length `N`, the matching
entry in `_new_docstrings` is the prepared remainder beginning at line `N`.

K claims: `FIND-TWO`, `FIND-THREE-PREFIX`.

Findings: F-01.

## PO-3: Extraction stops at the first non-signature line

Only the maximal leading block is extracted.  A later signature-looking line
after prose remains in the docstring body.

K claims: `FIND-STOPS-AT-PROSE`.

Findings: F-02.

## PO-4: Single-signature compatibility is preserved

For one leading signature line, `_find_signature()` returns the same first
`(args, retann)` pair as the legacy helper, and `format_signature()` returns the
same single formatted signature shape.

K claims: `FIND-SINGLE-COMPAT`, `FORMAT-SINGLE`.

Findings: F-03.

## PO-5: No-match behavior is preserved

For docstrings with no leading valid signature for the documented object,
`_find_signatures()` returns an empty list, `_find_signature()` returns `None`,
and the docstrings remain unchanged except for ordinary existing preparation.

K claims: `FIND-NO-MATCH`.

Findings: F-03.

## PO-6: Strip-only compatibility is preserved

`DocstringStripSignatureMixin` may call `_find_signature()` and then delegate to
the plural mixin without causing stripped signatures to be formatted.  This
requires `_find_signature()` not to populate the plural cache.

K claims: `STRIP-WRAPPER-NO-REEMIT`.

Findings: F-04.

## PO-7: Multisignature formatting is newline-separated

For multiple collected signature pairs, `format_signature()` returns exactly one
formatted signature per pair, joined by newline, preserving order.  The existing
`add_directive_header()` consumer maps those newline-separated signatures to
one directive signature line per overload.

K claims: `FORMAT-TWO`.

Findings: F-01.

## PO-8: Existing validity checks are preserved

The extractor must use the existing `py_ext_sig_re` parse shape and the existing
object-name membership test.  Invalid names stop the leading block rather than
being extracted.

K claims: `FIND-NO-MATCH`, `FIND-STOPS-AT-PROSE`.

Findings: F-02.

## PO-9: Explicit directive signatures bypass docstring extraction

When `self.args is not None`, `DocstringSignatureMixin.format_signature()` must
not call the docstring extractor; the explicit directive signature remains the
source of truth.

K claim: represented as a frame condition in `FORMAT-EXPLICIT-BYPASS`.

Findings: F-06.

## Machine-check commands to run later

Do not run these in this benchmark session.  They are emitted for a future
environment with K installed:

```sh
kompile fvk/mini-autodoc.k --backend haskell
kast --backend haskell fvk/autodoc-docstring-signatures-spec.k
kprove fvk/autodoc-docstring-signatures-spec.k
```

Expected result after machine checking: `#Top` for all claims.
