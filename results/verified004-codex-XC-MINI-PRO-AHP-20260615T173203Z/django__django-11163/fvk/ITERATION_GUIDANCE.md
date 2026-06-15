# Iteration Guidance

Status: V2 keeps V1 source unchanged.

## Decision

No additional production code edit is justified by the FVK audit.

The current source satisfies the proof obligations for the reported issue:

- `fields=[]` returns an empty dictionary.
- `fields=[]` skips all field value reads.
- `fields=None` continues to mean no inclusion filter.
- `exclude` continues to remove names even when they are listed in `fields`.

## If Continuing

1. In an environment with K installed, run:

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/model-to-dict-spec.k
kprove fvk/model-to-dict-spec.k
```

2. Keep all tests until the claims are machine-checked and test coverage is
   separately mapped.
3. Do not broaden this patch to other `fields` truthiness checks unless a
   separate public intent source identifies those behavior surfaces as wrong.
4. If a future task targets `_save_m2m()` or `fields_for_model()`, run a separate
   intent ledger and compatibility audit for that API surface.
