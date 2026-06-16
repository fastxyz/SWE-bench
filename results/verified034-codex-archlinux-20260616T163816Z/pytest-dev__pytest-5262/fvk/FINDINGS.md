# FINDINGS.md

Status: constructed, not machine-checked. Findings are derived from public
intent, source inspection, and constructed proof obligations only.

## F-001 - Resolved Code Bug: Binary Mode Was Advertised By A Text Wrapper

Input/state: an `EncodedFile` whose wrapped buffer has mode `rb+` or `wb+`.

Pre-fix observed behavior: `EncodedFile.mode` was delegated through
`__getattr__`, so callers saw `rb+` or `wb+`.

Expected behavior: `EncodedFile.mode` should not contain `b`; for the examples
above it should be `r+` or `w+`.

Evidence: E-001 through E-005 in `fvk/SPEC.md`.

Status: V1 resolves this with `return self.buffer.mode.replace("b", "")`.
Discharged by PO-1, PO-2, and PO-3.

## F-002 - Rejected Alternative: Accepting Bytes Would Broaden The API

Input/state: a third-party caller writes `bytes` after seeing `b` in
`out.mode`.

Observed failure in the issue: on Python 3, `EncodedFile.write(bytes)` raises
`TypeError`.

Expected behavior: third-party callers should not be led into the bytes-writing
path by `.mode`. The wrapper can remain text-oriented.

Evidence: E-002 and E-004 in `fvk/SPEC.md`.

Status: no source change beyond V1 is justified. Discharged by PO-1 and PO-4.

## F-003 - Confirmed Scope: Buffers Without A Mode Attribute Are Not The Bug

Input/state: an `EncodedFile` wrapping an object that has no `mode` attribute.

Observed behavior: direct `.mode` access raises `AttributeError`, as it did
before V1 through `__getattr__`.

Expected behavior: unchanged. The public issue concerns captured stdio backed by
a file object with an underlying binary mode.

Evidence: E-003 and E-005 name the wrapped stream mode transformation.

Status: no additional guard or fallback is justified. Discharged by PO-6.

## F-004 - Residual Verification Risk: Proof Not Machine-Checked

Input/state: the emitted K artifacts and claims.

Observed state: by task constraint, `kompile`, `kast`, and `kprove` were not run.

Expected state before claiming machine verification: a later environment runs
the commands in `fvk/PROOF.md` and obtains `#Top`.

Status: not a code bug. Test removal is not recommended before machine checking.
Tracked by PO-7.

## F-005 - No V1 Adequacy Gap Found

Input/state: the whole audited behavior space for this issue: mode access,
buffer mode preservation, text-write contract, and unchanged non-mode
delegation.

Observed V1 behavior by source inspection: `.mode` is intercepted and strips
`b`; `.buffer.mode` is untouched; `write` remains unchanged; `__getattr__`
continues to delegate other attributes.

Expected behavior: same as the intent spec in `fvk/SPEC.md`.

Status: V1 stands unchanged. Discharged by PO-1 through PO-6.
