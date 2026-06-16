# FVK Iteration Guidance

Status: V1 stands unchanged.

## Decision

No additional source edits are recommended. The FVK audit confirms that V1
matches the public intent and does not broaden the uniqueness check beyond a
single-field total uniqueness guarantee.

## Evidence Trace

- Keep the V1 predicate: supported by F1 and discharged by PO1 and PO3.
- Keep tuple equality rather than field membership: supported by F4 and
  discharged by PO6.
- Keep `_meta.total_unique_constraints` rather than raw `_meta.constraints`:
  supported by F3 and discharged by PO5.
- Keep the existing `auth.E003`/`auth.W004` blocks unchanged: supported by F2
  and discharged by PO2 and PO4.
- Keep the function signature and unrelated checks unchanged: supported by F5
  and discharged by PO7.

## Suggested Tests for a Conventional Test Pass

Do not edit tests in this benchmark. For a normal Django contribution, targeted
tests would cover:

1. A custom user with `USERNAME_FIELD = "username"` and
   `UniqueConstraint(fields=["username"], ...)` produces no `auth.E003`.
2. The same model under a custom authentication backend produces no
   `auth.W004`.
3. A conditional `UniqueConstraint(fields=["username"], condition=...)` does
   not satisfy the auth uniqueness requirement by itself.
4. A composite `UniqueConstraint(fields=["username", "tenant"], ...)` does not
   satisfy the single-field auth uniqueness requirement by itself.

## Commands Not Run

The following would be reasonable after leaving this no-execution benchmark:

```sh
python runtests.py auth_tests.test_checks
kompile fvk/mini-auth-check.k --backend haskell
kprove fvk/auth-username-unique-spec.k
```

They were not run here, per task constraints.
