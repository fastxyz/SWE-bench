# Iteration Guidance

Status: V1 stands unchanged.

## Decision

No source change is recommended in this FVK pass. V1 satisfies the
intent-derived obligations for `pk = None` on a finite MTI primary-key
parent-link chain and avoids the over-broad all-parent reset that public
discussion already flagged as problematic.

## Why V1 stands

- F2 and PO1 show V1 clears every attname in the active PK chain.
- PO4 shows this is exactly what the save path needs to avoid updating old
  parent rows through stale PK values.
- F3 and PO5 show that broadening the patch to every `_meta.parents` entry would
  be compatibility-risky and not justified by `pk` alias semantics.

## Follow-up questions for a future iteration

1. Should direct inherited parent PK assignment, such as `derived.uid = None`,
   also trigger child parent-link reset? This is not covered by the current
   `pk` setter contract.

2. Should Django provide a separate documented copy API for multi-table models
   with multiple independent concrete parents? `pk` denotes a single primary-key
   alias and does not fully specify non-primary parent links.

## Commands for later verification

Do not run these in this benchmark session. They are listed for a future
environment with K installed:

```sh
kompile fvk/mini-django-pk.k --backend haskell
kast --backend haskell fvk/model-pk-spec.k
kprove fvk/model-pk-spec.k
```
