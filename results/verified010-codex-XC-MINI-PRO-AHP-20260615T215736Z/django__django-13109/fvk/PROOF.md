# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or Django tests were run.

## Claims proved in the abstract model

The proof uses `mini-django-validation.k` and
`foreignkey-validate-spec.k`.

1. `FK_BASE_MANAGER_ACCEPTS`: with `manager=BaseManager`,
   `baseExists=true`, and `limitAllows=true`, validation reaches `Valid`
   regardless of `defaultExists`.
2. `FK_BASE_MANAGER_REJECTS_MISSING`: with `manager=BaseManager` and
   `baseExists=false`, validation reaches `Invalid`.
3. `FK_LIMIT_CHOICES_STILL_APPLIES`: with `manager=BaseManager`,
   `baseExists=true`, and `limitAllows=false`, validation reaches `Invalid`.
4. `FK_LEGACY_DEFAULT_MANAGER_FAILS_ARCHIVED`: with
   `manager=DefaultManager`, `baseExists=true`, `defaultExists=false`, and
   `limitAllows=true`, validation reaches `Invalid`, matching the reported
   legacy symptom.

## Proof sketch

For `FK_BASE_MANAGER_ACCEPTS`, symbolic execution starts from:

`ValidateFK(BaseManager, VALUE, true, DEFAULT_EXISTS, true)`

The first base-manager rule in `mini-django-validation.k` applies directly and
rewrites the computation to `Valid`. The `DEFAULT_EXISTS` value is framed and
unconstrained, proving that default-manager visibility no longer controls this
success case.

For `FK_BASE_MANAGER_REJECTS_MISSING`, the second base-manager rule applies
when `baseExists=false` and rewrites to `Invalid`.

For `FK_LIMIT_CHOICES_STILL_APPLIES`, the third base-manager rule applies when
`baseExists=true` but `limitAllows=false`, preserving explicit relation limits.

For `FK_LEGACY_DEFAULT_MANAGER_FAILS_ARCHIVED`, the default-manager missing rule
applies when `defaultExists=false`, even though `baseExists=true`. This
constructs the pre-fix symptom and demonstrates why switching the production
query manager removes it.

## Source correspondence

The abstract `manager=BaseManager` program corresponds to the V1 source line:

`qs = self.remote_field.model._base_manager.using(using).filter(...)`

The `limitAllows` check corresponds to:

`qs = qs.complex_filter(self.get_limit_choices_to())`

The `Invalid` outcome corresponds to the existing `if not qs.exists(): raise
exceptions.ValidationError(...)` branch.

## Machine-check commands, not executed

```sh
kompile fvk/mini-django-validation.k --backend haskell
kast --backend haskell fvk/foreignkey-validate-spec.k
kprove fvk/foreignkey-validate-spec.k
```

Expected result if the abstract K artifacts are accepted and the claims
discharge: `#Top`.

## Test recommendation

No test files were read or modified. Any future public test asserting that an
archived related row selected through a base-manager form queryset validates
would be covered by `FK_BASE_MANAGER_ACCEPTS` after machine checking. Integration
tests for forms, routers, and custom managers should still be kept because the
abstract proof does not model full Django execution.
