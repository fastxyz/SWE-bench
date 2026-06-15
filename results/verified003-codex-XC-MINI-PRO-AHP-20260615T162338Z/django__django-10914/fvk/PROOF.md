# FVK Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
tests, Python, or project code were executed.

## Reproduction Commands

These commands are emitted for later machine checking only:

```sh
kompile fvk/mini-upload-permissions.k --backend haskell
kast --backend haskell fvk/upload-permissions-spec.k
kprove fvk/upload-permissions-spec.k
```

Expected machine-check result after a suitable K installation: `#Top` for all
claims.

## Semantics Summary

The mini semantics models only the observable property under audit: final file
permission mode.

- `defaultUploadPermissions` rewrites to `mode(420)`.
- `initialMode(temporary, TMP, MEM)` rewrites to `TMP`.
- `initialMode(memory, TMP, MEM)` rewrites to `MEM`.
- `savedMode(SRC, mode(MODE), TMP, MEM)` rewrites to `MODE`.
- `savedMode(SRC, none, TMP, MEM)` rewrites to
  `initialMode(SRC, TMP, MEM)`.

Decimal `420` is octal `0o644`.

## Constructed Proof Sketch

### DEFAULT

Starting configuration:

```text
<k> defaultUploadPermissions </k>
```

Apply the default-setting rule:

```text
defaultUploadPermissions => mode(420)
```

The postcondition is reached directly.

### TEMP-DEFAULT

Starting configuration:

```text
<k> savedMode(temporary, defaultUploadPermissions, TMP, MEM) </k>
```

The second argument is strict, so symbolic execution first rewrites:

```text
defaultUploadPermissions => mode(420)
```

The configuration becomes:

```text
<k> savedMode(temporary, mode(420), TMP, MEM) </k>
```

Apply the configured-mode finalization rule:

```text
savedMode(temporary, mode(420), TMP, MEM) => 420
```

The temporary upload path reaches final mode `420`.

### MEMORY-DEFAULT

The memory path is identical except for the source constructor:

```text
savedMode(memory, defaultUploadPermissions, TMP, MEM)
=> savedMode(memory, mode(420), TMP, MEM)
=> 420
```

The memory upload path reaches final mode `420`.

### TEMP-NONE and MEMORY-NONE

For explicit `None`, the configured-mode rule does not apply:

```text
savedMode(temporary, none, TMP, MEM)
=> initialMode(temporary, TMP, MEM)
=> TMP
```

```text
savedMode(memory, none, TMP, MEM)
=> initialMode(memory, TMP, MEM)
=> MEM
```

This proves the documented restoration of previous path-dependent behavior when
the setting is explicitly `None`.

## Adequacy Gate

The English meaning of the K claims is compared to public intent in
`SPEC_AUDIT.md`.

- The default-setting claim matches the issue title and accepted public hint.
- The two default save-path claims cover the complete source-path family named
  by the issue: temporary-file uploads and memory uploads.
- The `None` claims are not used to preserve the old default; they only support
  the public hint that users may set `None` to restore previous behavior.
- Directory permissions are a frame condition, not part of the file-mode proof.

No adequacy failure blocks accepting the code behavior.

## Test Recommendation

No test removal is recommended. The proof is constructed, not machine-checked,
and the task forbids modifying tests. If machine checking later returns `#Top`,
unit tests that only assert the default file permission mode for successful
temporary and memory upload saves would be candidates for conditional
redundancy review; integration, OS-permission, staticfiles, explicit-override,
and `None` behavior tests should be kept.

## Residual Risk

- The proof is partial correctness over successful save finalization. It does
  not prove termination, retry behavior, locking, byte persistence, or
  filesystem syscall success.
- The trusted base is the adequacy of the mini semantics relative to the Django
  source slice, plus the future K toolchain result.
- No machine-check result is available in this environment.
