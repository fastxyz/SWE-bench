# FVK Spec

Status: constructed, not machine-checked. No tests, Python, or K tools were run.

## Scope

The audited observable is the path from a Napoleon-generated docutils field list to Sphinx's typed-field transformation for Python parameters. The full Sphinx/Docutils node model is intentionally abstracted to the property that matters for this issue:

- the field argument text used as the parameter key;
- whether the inline shorthand `:param type name:` rewrites that key;
- whether a separate `:type <fieldarg>:` field can match the parameter key exactly;
- whether documented inline shorthand remains supported.

Formal core:

- `fvk/mini-docfields.k`
- `fvk/docfield-transformer-spec.k`

Machine-check commands to run later:

```sh
kompile fvk/mini-docfields.k --backend haskell
kast --backend haskell fvk/docfield-transformer-spec.k
kprove fvk/docfield-transformer-spec.k
```

## Intent Spec

1. NumPy docstrings may document several parameters in one field line, as in `x1, x2 : array_like`.
2. Adding `optional` to the type must be visible in the rendered parameter output.
3. The expected output form keeps the combined names visible together, e.g. `x1, x2 (array_like, optional) -- Input arrays...`.
4. Sphinx's documented inline typed field syntax, e.g. `:param int priority:`, must remain valid for a single-word type.
5. Behavior outside the comma-separated field-argument ambiguity is a frame condition: Napoleon's parsing and formatting should not be changed to fix this issue.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
|---|---|---|---|---|
| E1 | prompt | "contains 3 inputs that are similar, so we want to put them in the same line in the docstring" | A comma-separated NumPy parameter field is in-domain. | Encoded by `commaList`. |
| E2 | prompt | `x1, x2 : array_like, optional` | The exact field argument is the combined name `x1, x2`, and type text includes `optional`. | Encoded by claims C1/C2. |
| E3 | prompt | "there is no way to tell whether it is optional" | Rendered output must attach the explicit type field to the parameter entry. | Encoded by claim C2. |
| E4 | prompt | "Something like - x1, x2 (_array_like, optional_) - Input arrays..." | The visible parameter entry should preserve the combined name, not replace it with only `x2` or duplicate the description as unrelated fields. | V1 finding; V2 encoded by claim C1. |
| E5 | public docs | `repo/doc/usage/restructuredtext/domains.rst` documents `:param int priority:` for single-word inline types. | Existing inline shorthand remains supported. | Encoded by claim C3. |
| E6 | implementation | `DocFieldTransformer.transform()` split `fieldarg` on whitespace for all typed fields. | This is implementation evidence for the failure mechanism, not expected behavior. | Guarded in V2. |

## Formal Spec English

- C1: For a typed field whose argument is a comma-separated name list such as `x1, x2`, transformation keeps the field argument as `x1, x2` and does not synthesize an inline type.
- C2: If an explicit type field is keyed by the same comma-separated argument `x1, x2`, rendering can attach `array_like, optional` to that combined parameter entry.
- C3: For a documented inline typed field such as `:param str sender:`, transformation still rewrites the field argument to `sender` and records type `str`.
- C4: For a non-typed comma-separated field argument, transformation preserves `x1, x2`.

## Adequacy Audit

| Claim | Audit |
|---|---|
| C1 | Pass. It directly addresses the issue field `x1, x2 : ...` and prevents the observed loss of the combined name/type key. |
| C2 | Pass. It is the positive rendering obligation: `optional` remains attached because the exact type key matches. |
| C3 | Pass. It is required by public Sphinx docs and prevents an overbroad parser change. |
| C4 | Pass. It is a frame condition over non-typed fields. |

## Compatibility Audit

- Changed symbol: `DocFieldTransformer.transform()` internals only; no public signature change.
- Public documented behavior preserved: `:param int priority:` and other single-word inline typed forms continue through the same branch because `argtype` does not end with a comma.
- Producer/consumer shape preserved: Napoleon still emits `:param x1, x2:` and `:type x1, x2:` for grouped NumPy names. The transformer now preserves the exact key instead of rewriting it to `x2`.
- Public overrides/subclasses: no virtual dispatch signature or method contract changed.

## Final Code Decision

V1 split the Napoleon field into separate `:param x1:` and `:param x2:` entries. That fixed type visibility but did not satisfy the grouped output form in E4. V2 removes the V1 Napoleon change and instead guards the generic inline typed-field branch in `repo/sphinx/util/docfields.py` so a comma-terminated first token is not interpreted as an inline type.
