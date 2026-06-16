# FVK Iteration Guidance

## Verdict

V1 stands unchanged. The audit found that the reported failure is produced by
the month/year pivot dropping timezone awareness, and the V1 source change
directly discharges that obligation by passing `tzinfo=d.tzinfo` to the pivot
constructor.

## Decisions

- Keep the V1 code change. It resolves F-001 and F-002 and discharges PO-003 and
  PO-007.
- Do not add a broader timezone normalization step. PO-006 requires preserving
  the existing calendar algorithm; normalizing to UTC would be broader than the
  public issue requires.
- Do not change public APIs or template filters. F-005 and PO-006 show there is
  no compatibility problem to repair.
- Do not edit tests. The task forbids test edits, and PO-008 keeps all test
  removal recommendations conditional on future machine checking.
- Do not add a `fold=d.fold` source edit in this iteration. F-007 and PO-009
  classify it as a possible future precision question, not as a public
  obligation for django__django-16429.

## Suggested Future Checks

When an execution environment is available, run the Django regression test for
an aware datetime at least one month in the past with `USE_TZ=True`, plus the
existing `utils_tests.test_timesince` and template filter timesince/timeuntil
tests. If K tooling is available, first run:

```sh
kompile fvk/mini-timesince.k --backend haskell
kast --backend haskell fvk/timesince-spec.k
kprove fvk/timesince-spec.k
```

Expected machine-check result for the FVK core: `kprove` returns `#Top`.
