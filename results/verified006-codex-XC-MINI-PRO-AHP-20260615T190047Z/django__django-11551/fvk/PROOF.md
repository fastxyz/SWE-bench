# FVK Proof

Status: constructed, not machine-checked.

## Claims Proved by Construction

The proof covers `ModelAdminChecks._check_list_display_item()` as an abstract
decision procedure over lookup outcomes. The K claims in
`list-display-check-spec.k` correspond one-to-one to the branch obligations in
`PROOF_OBLIGATIONS.md`.

There are no loops and no recursive calls, so no circularity claim is needed.
Partial and total correctness coincide for the modeled branch structure because
every rule rewrites directly to a terminal result.

## Proof Sketch

1. Case split on `callable(item)`.
   - If true, the helper returns `OK` immediately. This discharges PO1.
   - If false, continue to metadata lookup.
2. Case split on `obj.model._meta.get_field(item)`.
   - If it resolves a regular field or a `None`-like descriptor result in the
     abstraction, the helper reaches the common ManyToMany check and returns
     `OK`. This discharges PO2.
   - If it resolves a `ManyToManyField`, the helper reaches the common
     ManyToMany check and returns `E109`, regardless of `ModelAdmin` attribute
     existence. This discharges PO3 and the V2 improvement over V1.
   - If it raises `FieldDoesNotExist`, continue to admin attribute lookup.
3. Case split on `hasattr(obj, item)`.
   - If true, the helper returns `OK`. This discharges PO4.
   - If false, continue to model attribute fallback.
4. Case split on `getattr(obj.model, item)`.
   - If it resolves a regular or `None`-like object, the helper reaches the
     common ManyToMany check and returns `OK`. This discharges PO5 and preserves
     the 28490 regression behavior discussed in the issue.
   - If it resolves a `ManyToManyField`, the helper returns `E109`. This
     discharges PO6.
   - If it raises `AttributeError`, the helper returns `E108`. This discharges
     PO7.
5. The source patch does not change `_check_list_display_item()`'s signature,
   `_check_list_display()`'s direct call shape, or the error IDs/messages. This
   discharges PO8 and PO9.

## Adequacy Gate

The formal English paraphrases in `FORMAL_SPEC_ENGLISH.md` match the intent-only
obligations in `INTENT_SPEC.md`; `SPEC_AUDIT.md` marks each required behavior as
pass. The only V1 adequacy failure was the same-name field/admin precedence
case, recorded as Finding F2 and repaired in V2.

## Machine Check Commands

These commands were not executed.

```sh
cd fvk
kompile mini-admin-check.k --backend haskell
kast --backend haskell list-display-check-spec.k
kprove list-display-check-spec.k
```

Expected machine-check result after installing K: `kprove` discharges all claims
to `#Top`.

## Test Guidance

Conditioned on machine-checking only:

- Existing missing-field, valid-field/method/callable, and direct
  `ManyToManyField` tests are subsumed by PO1, PO2, PO3, PO4, and PO7.
- A regression test for the issue's descriptor case is recommended and
  corresponds to F1/PO2.
- A regression test for same-named `ModelAdmin` attribute plus model
  `ManyToManyField` is recommended and corresponds to F2/PO3.

No tests were edited, and no test deletion is recommended until the emitted K
commands are actually run and return `#Top`.

## Residual Risk

The trusted base is the adequacy of the mini semantics abstraction, the K
reachability proof system, and the future machine check. The abstraction is
deliberately small but keeps the exact observable result axis (`OK`, `E108`,
`E109`) and the exact lookup-order axis manipulated by the bug.

