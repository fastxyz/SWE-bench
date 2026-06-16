# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found that the current source edit satisfies
the public intent without requiring a broader change to `rc_context()` or
`pyplot.switch_backend()`.

## Trace To Findings And Obligations

- Kept the V1 loaded-backend branch in `RcParams.__getitem__` because F-1 shows
  it discharges PO-1: in the stale-sentinel state created by `rc_context()`,
  `get_backend()` returns the already selected backend and does not call the
  destructive `switch_backend(auto)` path.
- Made no change to initial lazy backend resolution because F-2 shows PO-2 is
  still satisfied: when `_backend_mod` is absent, V1 falls back to the original
  pyplot import and sentinel-resolution behavior.
- Made no change to `pyplot.switch_backend()` because F-3 shows PO-5 is
  satisfied: real backend switches keep their documented close-all behavior.
- Made no change for standalone `RcParams` because F-4 shows PO-4 is satisfied:
  the repair remains inside the existing global-`rcParams` identity guard.
- Made no API or signature changes because PO-6 and compatibility audit C1-C5
  found the public surface unchanged.

## Artifacts

The FVK package is under `fvk/`. The main requested files are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Supporting FVK files include the mini semantics, K claims, and adequacy audits:

- `fvk/mini-backend.k`
- `fvk/backend-rcparams-spec.k`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

## Verification Caveat

No tests, Python, or K tooling were run. The proof is constructed and the exact
commands are written in `fvk/PROOF.md`, but they remain not machine-checked per
the task constraint.
