# PROOF

Status: constructed, not machine-checked.  Commands are recorded but were not
run.

## Claims

The formal claims are in `fvk/python-xrefs-spec.k`:

- `PIPE-UNION` shape: `bytes | str` becomes `xref("bytes")`, literal ` | `,
  and `xref("str")`.
- `OR-FRAME` shape: `str or int or None` remains three xrefs separated by
  literal `or` delimiters.
- `PUNCT-FRAME` shape: `Tuple[str, ...]` remains type xrefs plus literal
  punctuation and ellipsis.

## Constructed Proof

1. Delimiter recognition:
   In V1, `PyXrefMixin.make_xrefs()` compiles the delimiter regex
   `(\s*[\[\]\(\),](?:\s*or\s)?\s*|\s+or\s+|\s*\|\s*|\.\.\.)`.
   Compared with the pre-fix expression, the only new accepted delimiter family
   is `\s*\|\s*`.  Therefore `bytes | str` is split into the nonempty sequence
   `bytes`, ` | `, `str`, rather than remaining one target.

2. Node construction loop:
   For each nonempty split segment, the loop checks `delims_re.match(sub_target)`.
   Delimiter segments append literal output through `contnode` or `innernode`.
   Non-delimiter segments call `self.make_xref(...)`.  Applying this to the
   sequence from step 1 gives `xref("bytes")`, literal ` | `, and `xref("str")`.

3. Existing delimiter frame:
   The alternatives for brackets, parentheses, commas, word `or`, and ellipsis
   are byte-for-byte preserved around the inserted pipe alternative.  Existing
   examples such as `str or int or None` and `Tuple[str, ...]` still take the
   same delimiter branches and the same atom branches.

4. Field plumbing:
   `TypedField.make_field()` calls `make_xrefs()` for single text type bodies.
   `DocFieldTransformer` stores separate `:type:` bodies as type content and
   also converts inline `:param type name:` syntax into a text type body.  Python
   parameter and variable fields are `PyTypedField`; Python return type fields
   are `PyField`; both inherit `PyXrefMixin`.  Thus the proof applies to PO-5,
   PO-6, and PO-7.

5. Compatibility:
   Non-text type content is appended unchanged by `TypedField.make_field()`.
   Non-Python domains do not inherit `PyXrefMixin`, and the generic
   `TypedField` implementation was not edited.  Attribute directive option
   annotations already route through `_parse_annotation()` and its `ast.BitOr`
   handling.

## Completeness Check

The proof spans the public intent slice: pipe-separated union type fields in the
Python domain, existing `or` and typing-style punctuation behavior, and the
parameter/variable/return field family.  It does not claim to verify unrelated
docutils parsing, non-Python domains, or a full Python annotation grammar for
field-list text.

## Commands To Machine Check Later

```sh
kompile fvk/mini-python-xrefs.k --backend haskell
kast --backend haskell fvk/python-xrefs-spec.k
kprove fvk/python-xrefs-spec.k
```

Expected outcome if the constructed mini-semantics is accepted by K:
`kprove` discharges the claims to `#Top`.  This expectation was not checked.

## Test Recommendation

Do not delete tests.  If the K artifacts are machine-checked later, focused
unit tests that assert only the modeled in-domain token mapping may be redundant
with the proof, but integration tests for docutils parsing, rendering, and
cross-reference resolution should remain.
