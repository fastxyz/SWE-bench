# FVK Specification: autodoc docstring overload signatures

Status: constructed from public intent and source inspection, not
machine-checked.

## Target

Repository state: V1 fix applied in `repo/sphinx/ext/autodoc/__init__.py`.

Primary units under audit:

- `DocstringSignatureMixin._find_signatures()`
- `DocstringSignatureMixin._find_signature()`
- `DocstringSignatureMixin.format_signature()`
- Existing consumer `Documenter.add_directive_header()`
- Compatibility consumer `DocstringStripSignatureMixin.format_signature()`

## Intent-only contract

`autodoc_docstring_signature` is intended to extract signatures written at the
start of an object's docstring.  For SWIG-wrapped overloaded functions and
methods, the convention described in the issue is to place one signature line
for each overload at the start of the docstring.  The fixed behavior must collect
all consecutive leading signature lines for the documented object, preserve
their order, remove them from the emitted docstring body, and render them as
multiple autodoc directive signatures.

The contract does not require scanning arbitrary later paragraphs for
signature-looking text.  The public issue names signatures "at the start of the
docstring", and the existing Sphinx setting documents this as a leading-docstring
feature.  Later examples or prose that happen to look like signatures are outside
the extraction region.

## Public evidence ledger

| ID | Source | Evidence | Obligation | Status |
|---|---|---|---|---|
| E1 | prompt/issue | "if they have overloaded methods ... place the signatures for each of the overloaded C++ methods at the start of the docstring" | Leading docstring signatures form an ordered family of overload signatures. | Encoded by PO-1 and K claims FIND-TWO and FIND-THREE-PREFIX. |
| E2 | prompt/issue | "`autodoc_docstring_signature` can only pick up the first one. It would be nice to be able to pick up all of them." | Extract every leading overload signature, not only the first. | Encoded by PO-1; V1 satisfies through `_find_signatures()`. |
| E3 | prompt/issue | "`getFeatures` has 4 overloaded signatures. The generation documentation appends the 4 signatures with the 4 docstrings." | Cardinality matters: for N leading signatures, output N directive signatures. | Encoded by PO-1 and PO-7. |
| E4 | project docs | `autodoc_docstring_signature` looks at the first line and removes it from docstring content. | Existing single-signature behavior and body stripping must remain compatible for N=1. | Encoded by PO-2, PO-4, and FIND-SINGLE-COMPAT. |
| E5 | source code | `py_ext_sig_re` parses a signature and existing code checks `base in valid_names`. | The fix must reuse the existing syntactic and object-name validity test instead of broadening accepted signatures. | Encoded by PO-3 and PO-8. |
| E6 | source code | `add_directive_header()` already splits `sig` on newline and emits one directive line per split line. | Multisignature formatting may use newline-separated signature strings without changing the directive API. | Encoded by PO-7 and FORMAT-TWO. |
| E7 | source code | `DocstringStripSignatureMixin` calls `_find_signature()` and then `super().format_signature()`. | The legacy `_find_signature()` wrapper must keep first-signature return compatibility and not cache plural signatures in a way that reintroduces a stripped signature. | Encoded by PO-6. |
| E8 | source code | `format_signature()` only reads docstrings when `self.args is None`. | Explicit directive signatures continue to bypass docstring extraction. | Encoded by PO-9. |

## Formal contract

Definitions:

- A line is a valid signature line for an object when it matches
  `py_ext_sig_re` and its `base` is in the object's `valid_names`.
- `valid_names` is the pre-existing Sphinx set: the current object name, plus
  class constructor aliases used by `ClassDocumenter`.
- A leading signature block is the maximal prefix of a docstring whose lines are
  valid signature lines for the documented object.
- The normalized docstring body is the result of applying the existing
  `prepare_docstring()` step to the docstring after the leading signature block
  has been removed.

Obligations:

1. For any docstring whose leading signature block has length `N > 0`,
   `_find_signatures()` returns exactly those `N` `(args, retann)` pairs in
   source order.
2. For that same docstring, `_new_docstrings` replaces only the matching
   docstring entry with the normalized body after dropping exactly those `N`
   leading lines.
3. If a docstring has no leading valid signature, `_find_signatures()` leaves
   that docstring unchanged and checks later docstrings.
4. The search stops at the first docstring that has a nonempty leading
   signature block, preserving the prior "first matching docstring" behavior.
5. `_find_signature()` remains a compatibility wrapper returning the first pair
   or `None`, while still using the plural stripping semantics.
6. `DocstringSignatureMixin.format_signature()` returns one formatted signature
   for one extracted pair and a newline-separated sequence of formatted
   signatures for multiple extracted pairs.
7. `Documenter.add_directive_header()` consumes the newline-separated string as
   one directive signature line per overload.
8. If `self.args` is already explicit, docstring extraction is not performed.
9. `DocstringStripSignatureMixin` continues to strip docstring signature lines
   without emitting a signature for attributes/properties.

## Scope and frame conditions

In scope:

- Leading overload signatures in a single docstring.
- Existing regular expression and object-name validation.
- Existing newline-based directive rendering.
- Existing single-signature and no-signature behavior.

Out of scope:

- Inventing support for signatures not accepted by `py_ext_sig_re`.
- Scanning non-leading paragraphs for signatures.
- Proving total termination over arbitrary Python object graphs.  The
  constructed proof assumes finite docstring lists and finite docstring line
  lists, which is the normal domain of `get_doc()`.
- Editing fixed test files.

## Adequacy summary

The formal model in `mini-autodoc.k` does not model all of Python or all of
Sphinx autodoc.  It models only the property-bearing behavior: ordered leading
signature extraction, stripping of the remainder, first-match search over
docstrings, compatibility first-signature projection, and newline formatting.
This abstraction distinguishes the pre-fix failing case from the fixed case:

- Failing instance: two leading valid lines abstract to one returned pair and a
  remainder that still contains one signature line.
- Passing instance: the same two leading valid lines abstract to two returned
  pairs and a remainder beginning after both signature lines.

That discriminator is the property the issue reports.
