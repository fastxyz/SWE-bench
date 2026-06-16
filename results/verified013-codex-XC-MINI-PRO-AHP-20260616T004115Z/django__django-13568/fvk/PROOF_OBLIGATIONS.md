# FVK Proof Obligations

Status: constructed for audit, not machine-checked.

## PO1: Define Accepted Username Uniqueness

Obligation:

```text
has_username_uniqueness(U) =
  cls._meta.get_field(U).unique
  or exists c in cls._meta.total_unique_constraints:
       c.fields == (U,)
```

Why it is required: intent ledger I1-I3 require accepting a model-level total
unique constraint as an alternative to `unique=True`.

V1 discharge: `repo/django/contrib/auth/checks.py` implements this predicate
directly in the uniqueness branch.

## PO2: Preserve Existing Error Behavior When No Accepted Guarantee Exists

Obligation:

```text
not has_username_uniqueness(U) and default_backend
  => append auth.E003 with the existing message, object, and ID
```

Why it is required: public test evidence I4 and existing auth semantics.

V1 discharge: the original `auth.E003` append block is unchanged and remains
inside the negation of the broadened predicate.

## PO3: Suppress E003/W004 for Single-Field Total UniqueConstraint

Obligation:

```text
field_unique == false
and ("username",) in [c.fields for c in total_constraints]
and U == "username"
  => no auth.E003 and no auth.W004 for U
```

Why it is required: the issue's concrete model in I1-I3.

V1 discharge: tuple equality against `(cls.USERNAME_FIELD,)` makes the `any()`
true for the concrete case, so the enclosing `if not (...)` is false.

## PO4: Preserve Existing Warning Behavior for Custom Backends

Obligation:

```text
not has_username_uniqueness(U) and not default_backend
  => append auth.W004 with the existing message, hint, object, and ID
```

Why it is required: public test evidence I4.

V1 discharge: the original `auth.W004` append block is unchanged and remains
inside the negation of the broadened predicate.

## PO5: Exclude Partial/Conditional UniqueConstraints

Obligation:

```text
conditional UniqueConstraint(fields=[U], condition=...)
  => not accepted by this auth uniqueness predicate
```

Why it is required: the issue says "total UniqueConstraints"; Django metadata
I5 defines total constraints as `UniqueConstraint` instances with
`condition is None`.

V1 discharge: the code consults `cls._meta.total_unique_constraints`, not raw
`cls._meta.constraints`, so conditional constraints do not appear in the
candidate set.

## PO6: Exclude Composite Constraints That Merely Contain USERNAME_FIELD

Obligation:

```text
UniqueConstraint(fields=[U, V]) does not imply U is globally unique
```

Why it is required: I6 and standard uniqueness semantics. A unique pair can
allow repeated `U` values with different `V` values.

V1 discharge: the code requires `constraint.fields == (cls.USERNAME_FIELD,)`,
not membership of `USERNAME_FIELD` in `constraint.fields`.

## PO7: Frame Unrelated Behavior and Public Compatibility

Obligation:

```text
check_user_model signature unchanged
and non-uniqueness checks unchanged
and error/warning payloads unchanged
```

Why it is required: the task asks for a minimal source fix and no test edits.

V1 discharge: source inspection shows only the predicate guarding the existing
uniqueness branch changed. No imports, signatures, message strings, error IDs,
or other check branches changed.

## PO8: Honesty Gate

Obligation:

```text
Do not claim machine-checked verification or test results.
Record expected K/tool commands without running them.
```

Why it is required: benchmark constraints forbid running tests, Python, or K
tooling; FVK MVP requires "constructed, not machine-checked" labeling.

V1 discharge: all FVK artifacts are labeled constructed/not machine-checked, and
no execution commands were run.
