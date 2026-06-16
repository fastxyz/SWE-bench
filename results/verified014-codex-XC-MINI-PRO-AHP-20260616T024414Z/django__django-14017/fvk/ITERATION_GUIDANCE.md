# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged. The FVK audit found the original bug and the empty-`Q`
clone edge case, and V1 already addresses both. No additional source edit is
justified by the public intent or by the proof obligations.

## Recommended follow-up tests

Do not edit tests in this benchmark. If adding public tests in normal
development, cover:

1. `Employee.objects.filter(Q(salary__gte=30) & Exists(is_ceo))`
2. `Employee.objects.filter(Q(salary__lt=15) | Exists(is_poc))`
3. `Q() & Exists(queryset)` at object-construction level, if a lightweight
   construction test is acceptable.
4. Existing `Q(x=1) & object()` / `Q(x=1) | object()` rejection behavior.

## Machine-checking commands to run later

These commands are recorded only; they were not run in this environment.

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/q-combine-spec.k
kprove fvk/q-combine-spec.k
```

Expected machine-check result after a real K run: `#Top` for all listed claims.
Until then, the proof remains constructed, not machine-checked, and no test
removal is recommended.

