# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`,
`kast`, or `kprove` were run.

## Claims Proved Against the Mini Model

The formal claims are in `fvk/django-aggregate-spec.k` and use the fragment in
`fvk/mini-django-aggregate.k`.

1. `Avg(..., distinct=True)` reaches `Obj(true)`, not `TypeError`.
2. `Sum(..., distinct=True)` reaches `Obj(true)`, not `TypeError`.
3. A distinct `AVG` aggregate renders with `DISTINCT ` in the aggregate call.
4. A distinct `SUM` aggregate renders with `DISTINCT ` in the aggregate call.
5. `Min` and `Max` are outside the required change and keep inherited rejection
   of `distinct=True`.

There are no loops or recursive functions in the audited change, so no
circularity or loop invariant is required.

## Symbolic Execution Sketch

For PO-1, start in `init(Avg, true)`.

The model defines `allowDistinct(Avg) => true`. The error rule requires
`allowDistinct(C) ==Bool false`, so it is not enabled. The success rule is
enabled because `allowDistinct(Avg) ==Bool true`, yielding `Obj(true)`.

For PO-2, the same derivation applies with `Sum`: `allowDistinct(Sum) =>
true`, the error rule is disabled, and the success rule yields `Obj(true)`.

For PO-3 on `AVG`, start in `asSql("AVG", true, E)`. The distinct SQL rule
matches the `true` flag and yields `Sql("AVG(DISTINCT " + E + ")")`. The
`SUM` proof is identical with the function string changed to `SUM`.

For PO-4, start in `init(Max, true)` or `init(Min, true)`. The model defines
`allowDistinct(Max) => false` and `allowDistinct(Min) => false`, enabling the
error rule. This is a frame condition showing V1 did not broaden the optional
`Min`/`Max` behavior.

## Source-Level Proof

`Aggregate.__init__()` has exactly one distinct-specific rejection condition:
`if distinct and not self.allow_distinct`. V1 sets `allow_distinct = True` on
the two required concrete classes, `Avg` and `Sum`, so that branch cannot be
taken for either class solely because `distinct=True`.

After construction, `Aggregate.__init__()` stores `self.distinct = distinct`.
`Aggregate.as_sql()` reads that flag and writes `DISTINCT ` into
`extra_context` before delegating to SQL rendering. The aggregate template
already includes the `%(distinct)s` placeholder, so the existing SQL path
implements the intended distinct aggregate call.

Because V1 does not change signatures, constructors, templates, or shared SQL
logic, existing `distinct=False` behavior and existing `Count` behavior are
preserved.

## Commands To Machine-Check Later

These commands are recorded for a future environment with K installed. They
were not executed in this benchmark session.

```sh
kompile fvk/mini-django-aggregate.k --backend haskell
kast --backend haskell fvk/django-aggregate-spec.k
kprove fvk/django-aggregate-spec.k
```

Expected outcome after a successful machine check: `kprove` returns `#Top` for
all claims.

## Test Guidance

Do not remove tests based on this run. The proof is constructed, not
machine-checked.

Recommended tests to add or keep in the fixed suite:

- `Avg("field", distinct=True)` constructs successfully and has `distinct` set.
- `Sum("field", distinct=True)` constructs successfully and has `distinct` set.
- SQL compilation for `Avg(..., distinct=True)` and `Sum(..., distinct=True)`
  contains the distinct aggregate fragment.
- An aggregate subclass without `allow_distinct = True` still rejects
  `distinct=True`.

If the K commands are machine-checked later and return `#Top`, point tests that
only re-check the in-domain constructor gating may be considered redundant, but
integration SQL tests should remain.
