# FVK Iteration Guidance

Status: constructed, not machine-checked. This guidance is based on
`fvk/FINDINGS.md` and `fvk/PROOF_OBLIGATIONS.md`.

## V2 Decision

V1 stands unchanged.

Reason:

- F-1 confirms the primary issue intent is satisfied by PO-1, PO-2, and PO-3.
- F-3 confirms SIGINT restoration is preserved by PO-4.
- F-4 confirms public call compatibility is preserved by PO-5.
- F-2 identifies the only direct conflict as stale `.pgpass`/`PGPASSFILE`
  public-test evidence, which PO-6 classifies as suspect because it contradicts
  the issue's explicit `PGPASSWORD` replacement request.

## Recommended Source Changes

No additional production-code changes are recommended for this issue.

Rejected changes:

- Do not reintroduce `.pgpass` or `PGPASSFILE`; F-2 and PO-6 show that would
  preserve the legacy behavior the issue asks to replace.
- Do not broaden the patch to other database backends; the issue and PO-5 scope
  are PostgreSQL-specific.
- Do not change public method signatures or management command dispatch; F-4
  and PO-5 show compatibility is already preserved.
- Do not add a password type coercion in this pass; F-5 and PO-8 identify
  string-like password values as the public domain for this method.

## Test Guidance

No tests were run or modified.

Future public tests for this issue should:

- mock `subprocess.run`, not `subprocess.call` or `subprocess.check_call`;
- assert `check=True`;
- assert the subprocess `env` contains `PGPASSWORD` when a password is supplied;
- assert `os.environ` is not mutated with `PGPASSFILE`;
- preserve existing argv and SIGINT restoration coverage.

Do not delete tests based on this FVK pass alone. Test redundancy is conditional
on machine-checking the emitted K artifacts in a proper environment.

## Future Machine Check

The benchmark forbids running these commands here. In a K-enabled environment,
the next verification step is:

```sh
kompile fvk/mini-python-dbshell.k --backend haskell
kast --backend haskell fvk/postgresql-client-spec.k
kprove fvk/postgresql-client-spec.k
```

Expected target result: `#Top` for the Django-side source-level obligations,
with the external `psql` behavior boundary from F-6 and PO-7 remaining outside
the proof.

## Residual Risks

- F-6/PO-7: The proof does not model the external PostgreSQL client binary.
- F-5/PO-8: Direct third-party calls to `runshell_db()` with non-string
  password objects are outside the audited domain.
- The K artifacts are constructed and not machine-checked in this session.
