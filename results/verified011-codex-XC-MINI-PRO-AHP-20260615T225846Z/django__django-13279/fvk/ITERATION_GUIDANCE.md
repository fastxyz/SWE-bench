# Iteration Guidance

## Decision

Keep V1 source code unchanged.

## Rationale

- `F1` identifies the original defect and is resolved by `PO1` and `PO2`.
- `PO3`, `PO4`, and `PO5` show V1 preserves both current decode paths and default SHA256 encoding behavior.
- `PO6` and `PUBLIC_COMPATIBILITY_AUDIT.md` show no public signature, override, or storage consumer requires another edit.
- `F2` corrects the explanatory scope around the pure cache backend but does not indicate a source defect.
- `F3` is an honesty caveat for the proof model, not a reason to withhold the derived source fix.

## Suggested Follow-Up Tests

Do not modify tests in this task. If tests are added elsewhere, useful coverage would include:

- With `DEFAULT_HASHING_ALGORITHM='sha1'`, `SessionBase.encode()` produces a payload decodable by `_legacy_decode()`.
- With the default SHA256 setting, `SessionBase.encode()` still produces a `signing.dumps()` payload decodable by `SessionBase.decode()`.
- DB/file session save paths write SHA1-mode legacy payloads.
- Signed-cookie sessions still use `signing.dumps()` and remain governed by `django.core.signing`.

## Machine Verification

The next verification pass may run:

```sh
cd fvk
kompile mini-session-format.k --backend haskell
kast --backend haskell session-encode-spec.k
kprove session-encode-spec.k
```

These commands were intentionally not executed in this no-execution environment.

