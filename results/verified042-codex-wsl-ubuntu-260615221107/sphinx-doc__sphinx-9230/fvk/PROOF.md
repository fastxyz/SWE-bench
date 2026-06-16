# Proof

Status: constructed, not machine-checked.

## Claims Proved by Construction

The formal claims are in `fvk/docfield-spec.k` and are paraphrased in
`fvk/FORMAL_SPEC_ENGLISH.md`.

The modeled functions are pure token-split abstractions:

- `parseInline(Words)` for the `DocFieldTransformer.transform()` inline typed
  branch.
- `scanParam(Words)` for autodoc's type-hint field scanner.

There are no loops, recursion, arithmetic verification conditions, heap effects,
or ordering VCs in this audited slice.

## Symbolic Proof Sketch

### PO1 / Claims C1-C2

Initial state:

```k
<k> parseInline(words(TYPE, NAME)) </k>
```

By the `parseInline(words(TYPE, NAME))` rule in `MINI-DOCFIELD`, this rewrites
in one step to:

```k
<k> inline(joinWords(TYPE), NAME) </k>
```

The concrete issue input is represented as:

```k
words(words(word("dict(str,"), "str)"), "opc_meta")
```

`joinWords(words(word("dict(str,"), "str)"))` rewrites by the two `joinWords`
rules to:

```k
"dict(str," +String " " +String "str)"
```

which is the modeled type string `dict(str, str)`.  Therefore the concrete
result is:

```k
inline("dict(str, str)", "opc_meta")
```

This is exactly the issue's required type/name boundary and contradicts the
legacy first-split output.

### PO2 / Claim C3

Initial state:

```k
<k> parseInline(words(word("str"), "name")) </k>
```

The same right-split rule rewrites to:

```k
<k> inline(joinWords(word("str")), "name") </k>
```

`joinWords(word("str")) => "str"`, so the result is
`inline("str", "name")`, preserving the public test behavior.

### PO3

The changed source branch runs only after `is_typefield` has been handled.
The separate `:type name:` collection branch remains before the inline typed
split and was not edited.  By source inspection, the frame condition holds:
separate type-field behavior is unchanged.

### PO4 / Claims C5-C6

For any `words(TYPE, NAME)` input, the `scanParam` rule rewrites in one step to:

```k
scanResult(true, true, NAME)
```

For the concrete issue token list, `NAME` is `opc_meta`, so autodoc records the
documented typed parameter under `opc_meta`.

## Adequacy Gate

- `INTENT_SPEC.md`: present and non-empty.
- `PUBLIC_EVIDENCE_LEDGER.md`: present and non-empty.
- `FORMAL_SPEC_ENGLISH.md`: present and non-empty.
- `SPEC_AUDIT.md`: all formal claims pass against intent.
- `PUBLIC_COMPATIBILITY_AUDIT.md`: no unhandled public callsite or signature
  issue.

The formal abstraction is adequate for the bug because it models the only
reported divergent observable: the boundary between type expression and
parameter name.

## Machine-Check Commands Not Run

Per the benchmark no-execution rule, these commands were not executed.  They
are provided for a later environment with K installed:

```sh
kompile fvk/mini-docfield.k --backend haskell --main-module MINI-DOCFIELD
kast --backend haskell fvk/docfield-spec.k
kprove fvk/docfield-spec.k --definition mini-docfield-kompiled
```

Expected result after successful machine checking: `#Top`.

## Test Guidance

No tests were run or modified.

Conditioned on machine checking, a unit test that only asserts
`:param str name:` still splits as type `str`, name `name` is subsumed by PO2.
Integration tests for full docutils/Sphinx rendering should be kept because this
mini semantics proves the split logic, not the entire builder pipeline.

## Residual Risk

- The proof is constructed, not machine-checked.
- The mini semantics abstracts away docutils nodes and Sphinx builders; it is
  property-complete for the split bug but not a full Sphinx semantics.
- Termination is irrelevant for the audited slices because there are no loops or
  recursion.
