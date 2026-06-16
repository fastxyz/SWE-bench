# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found the original defect, proved the intended V1
behavior over the constructed abstract model, and found no compatibility issue that
justifies another source edit.

## Trace to findings and proof obligations

* `fvk/FINDINGS.md` F-1 identifies the pre-V1 root cause: `OutputWrapper` inherited
  `TextIOBase.flush()`, so `__getattr__()` did not delegate `flush` to the wrapped
  stream. `fvk/PROOF_OBLIGATIONS.md` PO-1 requires explicit delegation for streams with
  `flush`, and PO-3 requires partial-write visibility after a flush. The V1 source at
  `repo/django/core/management/base.py` lines 146-148 satisfies those obligations by
  returning `self._out.flush()` when present.
* `fvk/FINDINGS.md` F-2 audits the `hasattr()` guard. `fvk/PROOF_OBLIGATIONS.md` PO-2
  models a stream-like object without `flush` as a no-op compatibility case, and PO-4
  preserves the existing custom stdout/stderr stream contract. This supports keeping
  the guard instead of changing V1 to unconditionally call `_out.flush()`.
* `fvk/FINDINGS.md` F-3 records the honesty boundary: the K proof is constructed but not
  machine-checked because this task forbids K tooling. `fvk/PROOF_OBLIGATIONS.md` PO-5
  passes the adequacy gate, and PO-6 records the commands to run later. This means no
  test-removal recommendation is made, but the source-level decision can still stand.

## Alternatives considered

* Editing `migrate` was rejected again. F-1 and PO-3 localize the failure to the wrapper:
  `migrate` already writes the partial message and calls `self.stdout.flush()` at the
  intended point.
* Replacing the guarded delegation with an unconditional `_out.flush()` call was rejected.
  F-2 and PO-2 show that the public issue only requires delegation when the wrapped stream
  supports `flush`, while compatibility favors leaving write-only stream-like objects
  alone.
* Adding broader changes to `OutputWrapper.__getattr__()` or inheritance was rejected.
  F-1 identifies `flush()` as the shadowed method relevant to the reported observable,
  and PO-4 keeps unrelated wrapper behavior framed.

## Verification status

No tests, Python, or K tools were run. The FVK artifacts provide a constructed proof and
the exact later commands in `fvk/PROOF_OBLIGATIONS.md` PO-6, but the result is not
machine-checked in this session.
