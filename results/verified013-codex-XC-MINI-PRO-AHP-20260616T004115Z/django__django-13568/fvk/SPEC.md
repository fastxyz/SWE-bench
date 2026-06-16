# FVK Specification for django__django-13568

Status: constructed for audit, not machine-checked. No tests, Python, or K
tooling were executed.

## Unit Under Audit

The audited production behavior is the uniqueness branch in
`django.contrib.auth.checks.check_user_model()`. The surrounding checks for
`REQUIRED_FIELDS`, `is_anonymous`, and `is_authenticated` are frame conditions:
this task does not require changing their behavior.

## Public Intent Ledger

I1. Source: `benchmark/PROBLEM.md`.

Quoted evidence: "Skip auth.E003 system check for USERNAME_FIELD with total
UniqueConstraints."

Semantic obligation: A `USERNAME_FIELD` whose model has a total
`UniqueConstraint` on that same single field must not produce `auth.E003`.

Status: encoded by PO1 and PO3 in `fvk/PROOF_OBLIGATIONS.md`.

I2. Source: `benchmark/PROBLEM.md`.

Quoted evidence: `constraints = [UniqueConstraint(fields=["username"],
name="user_username_unq")]`.

Semantic obligation: The concrete reported model, with
`USERNAME_FIELD == "username"`, `field.unique == False`, and a non-partial
single-field `UniqueConstraint(fields=["username"])`, is in scope.

Status: encoded by PO3.

I3. Source: `benchmark/PROBLEM.md`.

Quoted evidence: "Sometimes it's not preferable to set the field as unique with
unique=True as it will create an extra implicit *_like index for CharField and
TextField on PostgresSQL."

Semantic obligation: The check must accept a model-level uniqueness guarantee
without requiring `unique=True` on the field.

Status: encoded by PO1 and PO3.

I4. Source: `repo/tests/auth_tests/test_checks.py`.

Quoted evidence: "A non-unique USERNAME_FIELD raises an error only if the
default authentication backend is used. Otherwise, a warning is raised."

Semantic obligation: If no accepted uniqueness guarantee exists, the existing
split remains: default `ModelBackend` emits `auth.E003`; non-default backends
emit `auth.W004`.

Status: encoded by PO2 and PO4.

I5. Source: `repo/django/db/models/options.py`.

Quoted evidence: `total_unique_constraints` returns constraints where
`isinstance(constraint, UniqueConstraint) and constraint.condition is None`.

Semantic obligation: The auth check may rely on `_meta.total_unique_constraints`
as the source of total, non-partial unique constraints.

Status: encoded by PO1 and PO5.

I6. Source: uniqueness semantics and
`repo/django/db/models/fields/related.py`.

Quoted evidence: related-field checks use `frozenset(uc.fields)` from
`_meta.total_unique_constraints` to decide whether referenced fields are
guaranteed unique.

Semantic obligation: A single `USERNAME_FIELD` is globally unique only when the
accepted constraint key is exactly that one field. A composite constraint that
contains `USERNAME_FIELD` does not imply username uniqueness by itself.

Status: encoded by PO6.

## Intent-Level Contract

Let:

- `U` be the value of `cls.USERNAME_FIELD`.
- `field_unique` be `cls._meta.get_field(U).unique`.
- `total_constraints` be `cls._meta.total_unique_constraints`.
- `default_backend` be whether `settings.AUTHENTICATION_BACKENDS` is exactly
  `['django.contrib.auth.backends.ModelBackend']`.
- `has_username_uniqueness` mean:

```text
field_unique
or exists c in total_constraints such that c.fields == (U,)
```

The intended uniqueness behavior is:

1. If `has_username_uniqueness` is true, append no `auth.E003` and no
   `auth.W004` for `U`.
2. If `has_username_uniqueness` is false and `default_backend` is true, append
   exactly the existing `auth.E003` uniqueness error for `U`.
3. If `has_username_uniqueness` is false and `default_backend` is false, append
   exactly the existing `auth.W004` uniqueness warning for `U`.
4. Conditional unique constraints are not accepted by this check unless they are
   exposed through `_meta.total_unique_constraints`.
5. Composite unique constraints are not accepted as proof that a single
   `USERNAME_FIELD` is globally unique.

## K-Style Claim Summary

The formal core is modeled as an abstract, side-effect-free decision for the
auth uniqueness branch. This is sufficient for the property under audit because
the changed code only decides whether to append one of the existing uniqueness
messages.

```text
claim AUTH-USERNAME-UNIQUE-SATISFIED
  requires hasUsernameUniqueness(U, field_unique, total_constraints) == true
  ensures uniquenessMessages(errors_after, U) == []

claim AUTH-USERNAME-UNIQUE-DEFAULT-BACKEND
  requires hasUsernameUniqueness(U, field_unique, total_constraints) == false
       and default_backend == true
  ensures uniquenessMessages(errors_after, U) == [auth.E003]

claim AUTH-USERNAME-UNIQUE-CUSTOM-BACKEND
  requires hasUsernameUniqueness(U, field_unique, total_constraints) == false
       and default_backend == false
  ensures uniquenessMessages(errors_after, U) == [auth.W004]

function hasUsernameUniqueness(U, field_unique, total_constraints):
  field_unique or any(c.fields == (U,) for c in total_constraints)
```

Adequacy check: these claims match I1-I6 and do not derive expected behavior
from the candidate implementation alone.
