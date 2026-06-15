# FVK Notes

## Source Decision

No additional source change was made after V1. The decision to keep V1 is based
on `fvk/FINDINGS.md` F1 and `fvk/PROOF_OBLIGATIONS.md` PO1-PO4: the public
failure is caused by `LooseVersion` comparing numeric patch components against
suffix strings, and V1's regex normalization removes those suffix tokens before
the inclusive/exclusive comparison for numeric package versions.

## Compatibility Decision

No public API or callsite change was made. This follows `fvk/FINDINGS.md` F2
and `fvk/PROOF_OBLIGATIONS.md` PO5: `minversion` keeps the same signature,
missing module imports still return `False`, invalid module arguments still
raise `ValueError`, and `version_path` lookup still occurs before comparison.

## Scope Decision

I did not replace the V1 helper with a full package-version parser. This follows
`fvk/FINDINGS.md` F3 and `fvk/PROOF_OBLIGATIONS.md` PO6: the public issue asks
to restore regex normalization around `LooseVersion` and explicitly avoids
returning to `pkg_resources.parse_version`. Full PEP 440 behavior is recorded as
outside the proved scope, not as a required source change.

## Artifact Decisions

The requested five artifacts were written under `fvk/`:

- `SPEC.md`
- `FINDINGS.md`
- `PROOF_OBLIGATIONS.md`
- `PROOF.md`
- `ITERATION_GUIDANCE.md`

I also wrote the formal and adequacy core required by the FVK documentation:
`mini-python.k`, `minversion-spec.k`, `INTENT_SPEC.md`,
`PUBLIC_EVIDENCE_LEDGER.md`, `FORMAL_SPEC_ENGLISH.md`, `SPEC_AUDIT.md`, and
`PUBLIC_COMPATIBILITY_AUDIT.md`.

## Verification Status

No tests, Python code, or K tooling were run, per the benchmark instructions.
The FVK proof is constructed but not machine-checked; the exact future commands
are recorded in `fvk/PROOF.md`.
