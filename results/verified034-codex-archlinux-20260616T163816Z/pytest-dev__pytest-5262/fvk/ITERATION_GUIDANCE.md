# ITERATION_GUIDANCE.md

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged. The audit found no gap between public intent and the V1
source change.

## Why No Further Code Change Is Needed

- F-001 is resolved by PO-1, PO-2, and PO-3: `.mode` removes `b` from the
  underlying mode.
- F-002 rejects changing `write()` to accept `bytes`: PO-4 preserves the
  text-oriented API and fixes the advertised mode instead.
- F-003 rejects adding a fallback for buffers without `.mode`: PO-6 preserves
  the prior delegation/error behavior outside the reported stdio-backed domain.
- F-005 confirms the audited behavior space is covered: wrapper mode, buffer
  mode, text-write contract, and non-mode delegation.

## Next Code Iteration

No production edit is recommended.

If a later maintainer wants an additional defensive change, it should first be
backed by new public intent evidence, such as a documented requirement for
`EncodedFile.mode` on buffers that do not expose `mode`.

## Next Verification Iteration

Run the recorded commands in `fvk/PROOF.md` in an environment with K installed.
Until that returns `#Top`, keep all relevant tests.

## Tests To Add Later

Do not edit tests in this benchmark. For a normal project PR, add tests covering:

- `sys.stdout.mode` under fd capture has no `b`;
- `sys.stdout.buffer.mode` under fd capture still has `b`;
- `EncodedFile(fake_buffer_with_mode_rb_plus).mode == "r+"`;
- absent underlying `mode` still raises `AttributeError`.
