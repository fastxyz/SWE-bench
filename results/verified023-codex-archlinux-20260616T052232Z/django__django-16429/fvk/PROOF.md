# FVK Constructed Proof

Status: constructed, not machine-checked. The following commands were not run:

```sh
kompile fvk/mini-timesince.k --backend haskell
kast --backend haskell fvk/timesince-spec.k
kprove fvk/timesince-spec.k
```

## What Is Proved

For the `timesince()` month/year branch, if the initial subtraction `now - d` is
defined for normal Django-supported datetime inputs, then V1 constructs a pivot
whose timezone-awareness class matches `d`, making `now - pivot` defined as
well. This proves the reported `TypeError` cannot be produced by the pivot
constructor after V1 on that in-domain path.

The proof is partial correctness. It does not prove termination, full Python
datetime semantics, translation, or all string formatting behavior.

## Adequacy Gate

The formal claims match the public intent:

- The issue reports a `TypeError` only after a long interval enters the
  month/year pivot path.
- The issue and hint identify the pivot's missing `tzinfo` as the defect.
- The claims model timezone-awareness preservation explicitly; they do not
  abstract away the property that distinguishes the failing pre-fix state from
  the fixed V1 state.
- Public compatibility obligations are frame obligations because V1 does not
  change public signatures or formatting code.

No claim relies on hidden tests, benchmark verdicts, or upstream fixes.

## Symbolic Counterexample on Pre-fix Code

Let `d = dt(DY, DM, DD, DH, DMin, DS, Aware)` and
`now = dt(NY, NM, ND, NH, NMin, NS, Aware)`, with an interval long enough that
`years or months` is true.

1. The initial subtraction check is modeled by `subDefined(now, d)`.
2. `subDefined(Aware, Aware)` rewrites to `true`, so execution reaches the
   month/year pivot branch.
3. Pre-fix pivot construction is modeled by `makePivotV0(d, PY, PM)`, which
   rewrites to `dt(PY, PM, clampDay(PM, DD), DH, DMin, DS, Naive)`.
4. The remaining-time subtraction is now `subDefined(now, pivot)`.
5. `subDefined(Aware, Naive)` rewrites to `false`, so `subOk(now, pivot)`
   rewrites to `typeError`.

This localizes the reported symptom to the omitted timezone information on the
constructed pivot.

## V1 Proof

Use the same in-domain symbolic state:

`d = dt(DY, DM, DD, DH, DMin, DS, TZ)` and
`now = dt(NY, NM, ND, NH, NMin, NS, TZ)`, where `TZ` is either `Aware` or
`Naive`. This is exactly the PO-002 domain where `now - d` is defined.

1. V1 pivot construction is modeled by `makePivotV1(d, PY, PM)`.
2. The `pivotV1` claim rewrites it to
   `dt(PY, PM, clampDay(PM, DD), DH, DMin, DS, TZ)`.
3. The pivot keeps the same `TZ` as both `d` and `now` in this proof domain.
4. The `remainingV1` claim then rewrites
   `subOk(now, makePivotV1(d, PY, PM))` to `ok`, because
   `subDefined(TZ, TZ)` rewrites to `true`.
5. Therefore the month/year branch can compute `remaining_time = (now -
   pivot).total_seconds()` without the reported mixed-awareness `TypeError`.

By source frame inspection, the year/month counts, clamped day, hour, minute,
second, ignored microsecond behavior, depth loop, translation, and
`avoid_wrapping()` calls are unchanged. The issue example therefore reaches the
same month-formatting path as the corresponding naive calculation instead of
crashing.

## Wrapper and Compatibility Proof

`timeuntil()` still calls `timesince(d, now, reversed=True, ...)`. The proof
above applies after `timesince()` performs its existing `d, now = now, d` swap,
because the pivot is constructed from the same post-swap start datetime whose
awareness class participates in the measured interval.

Template filters and humanize helpers call the same public functions with the
same signatures as before. Since the only source diff is an internal constructor
keyword argument, no public callsite or override compatibility proof obligation
remains open.

## Test Guidance

No tests were run and no tests were modified. Existing tests should be kept
until the emitted `kompile`/`kprove` commands are actually machine-checked and
the normal Django test suite can run. A useful public regression test would
exercise `timesince(timezone.now() - timedelta(days=31 or 40))` under
`USE_TZ=True`, and a companion wrapper test could exercise `timeuntil()` with a
future aware datetime at least one month away.
