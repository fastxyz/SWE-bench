# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, Python, or Django tests were executed.

## Claims Proved by Construction

The proof targets `fvk/django-delete-spec.k` over the mini semantics in `fvk/mini-django-delete.k`.

1. `deleteShape(0, 0) => direct`
2. `deleteShape(1, 0) => direct`
3. `deleteShape(A, 0) => fallback` when `A >= 2`
4. `deleteShape(A, E) => fallback` when `A >= 0` and `E > 0`

`direct` means `SQLDeleteCompiler.as_sql()` takes `_as_sql(self.query)`. `fallback` means it does not take that direct branch.

## Symbolic Proof Sketch

For claim 1, start with `deleteShape(0, 0)`. The `singleAlias` predicate evaluates `normalizeActive(0)`, which rewrites to `1`. The predicate becomes `1 == 1 and 0 == 0`, so `deleteShape` rewrites to `direct`.

For claim 2, start with `deleteShape(1, 0)`. `normalizeActive(1)` rewrites to `1`; the same predicate evaluates true, so the result is `direct`.

For claim 3, assume `A >= 2`. `normalizeActive(A)` rewrites to `A`; `A == 1` is false under the side condition. Therefore `singleAlias(A, 0)` is false and `deleteShape(A, 0)` rewrites to `fallback`.

For claim 4, assume `A >= 0` and `E > 0`. If `A == 0`, `normalizeActive(A)` rewrites to `1`; if `A > 0`, it rewrites to `A`. In either case, the conjunct `E == 0` is false. Therefore `singleAlias(A, E)` is false and `deleteShape(A, E)` rewrites to `fallback`.

No loop circularity is needed; the audited code is a straight-line predicate plus a branch.

## Adequacy Gate

- `fvk/INTENT_SPEC.md` records the public behavior before candidate behavior is accepted.
- `fvk/PUBLIC_EVIDENCE_LEDGER.md` traces each nontrivial claim to public issue text or source-level compatibility evidence.
- `fvk/FORMAL_SPEC_ENGLISH.md` paraphrases the K claims.
- `fvk/SPEC_AUDIT.md` marks all claims as passing against public intent.
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` finds no public API, signature, or caller incompatibility.

## Machine-Check Commands

These commands are emitted for later checking and were not run:

```sh
cd fvk
kompile mini-django-delete.k --backend haskell
kast --backend haskell django-delete-spec.k
kprove django-delete-spec.k
```

Expected result after a successful machine check: `#Top` for all claims.

## Test Redundancy

No tests are recommended for removal. This proof is not machine-checked, and the task forbids modifying tests. Existing and hidden tests should be kept.

Recommended tests to add or keep:

- A SQL-shape regression test for `Model.objects.all().delete()` that rejects `WHERE pk IN (SELECT pk FROM same table)`.
- A compatibility test for deletes with additional table contributors, such as `extra(tables=...)`, to ensure direct delete is not selected when `_as_sql()` cannot represent the query.
