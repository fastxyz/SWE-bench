# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were executed.

## Claim Being Proved

The V1 patch satisfies the intent-level contract in `fvk/SPEC.md`: a
`USERNAME_FIELD` is accepted as unique if either the field itself has
`unique=True` or `_meta.total_unique_constraints` contains exactly one field,
the configured `USERNAME_FIELD`.

The proof is partial correctness for the checked branch: if
`check_user_model()` reaches the username-uniqueness section with a resolved
user model and existing `USERNAME_FIELD`, the branch appends the intended
uniqueness messages and no others.

## Symbolic Execution Sketch

Let:

```text
U = cls.USERNAME_FIELD
field_unique = cls._meta.get_field(U).unique
single_total_uc = any(c.fields == (U,) for c in cls._meta.total_unique_constraints)
has_username_uniqueness = field_unique or single_total_uc
default_backend = settings.AUTHENTICATION_BACKENDS == [
    'django.contrib.auth.backends.ModelBackend'
]
```

The V1 code evaluates:

```text
if not has_username_uniqueness:
    if default_backend:
        append auth.E003
    else:
        append auth.W004
```

Case 1: `field_unique` is true.

`has_username_uniqueness` is true by Boolean disjunction. The outer `if not`
guard is false, so neither uniqueness message is appended. This discharges PO1.

Case 2: `field_unique` is false and there is a total constraint with
`fields == (U,)`.

The `any()` expression is true. Therefore `has_username_uniqueness` is true and
the outer branch is skipped. This is the concrete reported issue case and
discharges PO3.

Case 3: `has_username_uniqueness` is false and `default_backend` is true.

The outer branch is entered and the inner default-backend branch appends the
unchanged `auth.E003` object. This discharges PO2.

Case 4: `has_username_uniqueness` is false and `default_backend` is false.

The outer branch is entered and the inner custom-backend branch appends the
unchanged `auth.W004` object. This discharges PO4.

Case 5: the only model-level constraint is conditional.

By Django's `Options.total_unique_constraints`, conditional constraints are not
members of the sequence V1 iterates. The `any()` expression is false unless
another accepted guarantee exists. This discharges PO5.

Case 6: the only model-level constraint is composite, such as
`fields == (U, "tenant")`.

Tuple equality against `(U,)` is false. The `any()` expression is false unless
another accepted guarantee exists. This discharges PO6.

Frame case: all other checks in `check_user_model()` run before or after the
uniqueness branch and have unchanged code. The public function signature,
return shape, message strings, and IDs are unchanged. This discharges PO7.

## K-Style Commands Not Run

The benchmark forbids executing K tooling. These are the commands that would be
used for a standalone K realization of the abstract branch model described in
`fvk/SPEC.md` and `fvk/PROOF_OBLIGATIONS.md`:

```sh
kompile fvk/mini-auth-check.k --backend haskell
kast --backend haskell fvk/auth-username-unique-spec.k
kprove fvk/auth-username-unique-spec.k
```

Expected outcome after translating the abstract claims into concrete K files:
`kprove` returns `#Top` for PO1-PO7. This expectation is constructed reasoning,
not a machine result.

## Residual Risk

The proof is not machine-checked. It also abstracts away Django app loading,
model construction, and system-check registration because V1 did not change
those mechanisms. The property under audit is still represented: the model
distinguishes accepted and rejected uniqueness guarantees, including the
reported single-field total constraint, conditional constraints, and composite
constraints.

No test-redundancy recommendation is made because tests were neither run nor
machine-subsumed by a completed `kprove` result.
