# Constructed Proof

Status: constructed, not machine-checked.  No K tooling, tests, Python, or
project code were run in this benchmark session.

## Claims proved by construction

The constructed proof covers the obligations in `PROOF_OBLIGATIONS.md` over the
finite-docstring domain:

- `_find_signatures()` returns the complete ordered leading block of valid
  signature pairs.
- `_find_signatures()` strips exactly that leading block from the matching
  docstring entry.
- `_find_signature()` remains a first-pair compatibility wrapper.
- `format_signature()` emits one signature for one pair and newline-separated
  signatures for multiple pairs.
- `DocstringStripSignatureMixin` does not re-emit a stripped signature.
- Existing newline-based directive rendering is a valid consumer for the
  multisignature string.

## Semantics fragment

`mini-autodoc.k` defines a small term-rewriting model for:

- finite lists of docstring lines;
- signature lines `sig(base, args, retann)` and prose lines `text(value)`;
- a valid-name set;
- `collect`, which scans a maximal leading valid signature block;
- `find`, which searches docstrings for the first nonempty leading block;
- `first`, the compatibility projection used by `_find_signature()`;
- `format`, the newline join used by `format_signature()`.

The model intentionally abstracts away Python object identity, the full regular
expression engine, Sphinx event callbacks, and `prepare_docstring()` indentation
normalization.  Those are frame assumptions.  The modeled observable is the
axis changed by the bug: ordered cardinality of leading signatures and the
remaining docstring body.

## Proof sketch

### PO-1 and PO-2

For a docstring beginning with valid lines
`sig(B, A1, R1), sig(B, A2, R2), ...` and `B` in `valid_names`, `collect`
rewrites once per leading signature line:

```text
collect(NS, lines(sig(B, A1, R1), Rest))
  => prepend(pair(A1, R1), collect(NS, Rest))
```

After each step, the remaining line list is shorter.  By induction on the
finite leading block, `collect` returns the ordered pair list for the whole
block and the first non-signature remainder.  `find` then rewrites the current
docstring to `found(pairs..., docs(remainder, tail))`, which is exactly the
stripped body obligation.

### PO-3 and PO-8

When the scan reaches `text(T)` or a `sig(B, A, R)` whose `B` is not in
`valid_names`, no signature-collecting rule applies.  The stop rule returns the
accumulated prefix and leaves the current line and the rest of the lines in the
remainder.  Therefore later signature-looking lines after prose are preserved
in the body.

### PO-4 and PO-5

`first(find(NS, Docs))` rewrites to the first pair only when `find` found a
nonempty pair list, and rewrites to `nonePair()` when `find` reports no match.
For a one-element prefix this equals the legacy behavior.  For no match, no
docstring entry is consumed as a signature block.

### PO-6

The compatibility wrapper `_find_signature()` uses `_find_signatures()` only to
update `_new_docstrings` and project the first pair.  It does not write the
plural cache.  In the strip-only path, the subsequent delegated plural lookup
therefore reads the already-stripped docstrings and receives no pairs.  The
claim `STRIP-WRAPPER-NO-REEMIT` captures this by composing `first(find(...))`
with a second `find` over the stripped remainder.

### PO-7

`format` recursively formats the head pair and joins it with `"\n"` plus the
formatted tail.  Induction on the pair list gives one output line per pair in
the same order.  `Documenter.add_directive_header()` already splits the
signature string on newline, so the formatted string is consumed as separate
directive signature lines without changing that public method's API.

### PO-9

The source branch `if self.args is None and autodoc_docstring_signature` guards
all docstring extraction in `DocstringSignatureMixin.format_signature()`.
Therefore explicit signatures follow the existing `Documenter.format_signature`
path and do not depend on `_find_signatures()`.

## Residual risk

This proof is partial correctness over finite lists and a faithful abstraction
of `py_ext_sig_re` as the `sig(...)` constructor.  It does not prove termination
for arbitrary host-language objects, does not machine-check the K claims, and
does not verify all Sphinx event callback behaviors.  Those are outside the
benchmark's no-execution environment.

## Machine-check commands

Do not run these here.  In an environment with K installed:

```sh
kompile fvk/mini-autodoc.k --backend haskell
kast --backend haskell fvk/autodoc-docstring-signatures-spec.k
kprove fvk/autodoc-docstring-signatures-spec.k
```

Expected machine-check result: `#Top`.

## Test guidance

No tests were edited.  If machine-checking later returns `#Top`, focused unit
tests that assert representative in-domain extraction cases become redundant
with respect to this proof.  Integration tests for Sphinx directive rendering,
event callback interactions, and full `prepare_docstring()` indentation behavior
should be kept because the mini semantics abstracts those pieces.
