# FVK Findings

Status: constructed, not machine-checked.  No tests or project code were run.

## F-01: V1 fixes the reported cardinality bug

Input:

```text
docstring lines:
  getFeatures(request)
  getFeatures(rect) -> Iterator
  Body text
```

Observed before V1:

```text
signature output:
  getFeatures(request)
docstring body still starts with:
  getFeatures(rect) -> Iterator
```

Expected from public intent:

```text
signature output:
  getFeatures(request)
  getFeatures(rect) -> Iterator
docstring body starts with:
  Body text
```

V1 status: satisfied.  `_find_signatures()` accumulates all consecutive leading
valid signature lines and strips all of them from `_new_docstrings`.

Related proof obligations: PO-1, PO-2, PO-7.

## F-02: The extraction region must remain leading-only

Input:

```text
docstring lines:
  getFeatures(request)
  Body text
  getFeatures(example)
```

Expected:

Only `getFeatures(request)` is extracted.  The later example-like line remains
in the body because public intent and existing docs describe leading docstring
signatures, not arbitrary body scanning.

V1 status: satisfied.  The inner scan breaks at the first non-matching line.

Related proof obligations: PO-3, PO-8.

## F-03: Legacy single-signature behavior is preserved

Input:

```text
docstring lines:
  func(a, b) -> int
  Body text
```

Expected:

`_find_signature()` returns the same `(args, retann)` pair as before, and the
formatted signature remains a single signature string.

V1 status: satisfied.  The compatibility wrapper returns `signatures[0]`, and
`format_signature()` falls back to the prior single-signature path when the
plural list has length one.

Related proof obligations: PO-4, PO-5.

## F-04: Strip-only documenters must not re-emit stripped signatures

Risk:

`DocstringStripSignatureMixin.format_signature()` calls `_find_signature()` and
then delegates to `DocstringSignatureMixin.format_signature()`.  If the
compatibility wrapper cached plural signatures, the delegated call could see the
cached values and emit a signature for a documenter that is supposed to strip
only.

V1 status: satisfied.  `_find_signature()` does not populate
`_docstring_signatures`; it only updates `_new_docstrings` through
`_find_signatures()`.  The delegated plural lookup reparses the already-stripped
docstring and finds no signatures.

Related proof obligations: PO-6.

## F-05: Public docs under-describe the new behavior

Observation:

The existing user docs say `autodoc_docstring_signature` looks at "the first
line" and uses "the line" as the signature.  The issue requests broader
behavior for multiple leading lines.

Classification:

Documentation follow-up, not a blocker for the production-code fix in this
benchmark.  The behavior change is justified by prompt/issue intent, and no test
or code path relies on the wording as a runtime invariant.

Related proof obligations: PO-1, PO-4.

## F-06: No FVK-phase source edit is required

The FVK audit did not surface an unresolved code defect in the V1 source.  The
current V1 patch satisfies the proof obligations over the specified domain:
finite docstring lists, finite line lists, and existing `py_ext_sig_re` validity.

Residual caveat:

The proof is constructed, not machine-checked.  The emitted `kompile` and
`kprove` commands in `PROOF.md` should be run in an environment with K installed
before treating any test as redundant.

Related proof obligations: all, especially PO-1 through PO-9.
