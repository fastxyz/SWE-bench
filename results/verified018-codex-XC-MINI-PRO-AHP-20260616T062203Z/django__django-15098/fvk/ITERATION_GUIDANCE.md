# Iteration Guidance

Status: V1 stands after FVK.

## Decision

No additional source change is recommended. The V1 patch satisfies the public
intent captured in `fvk/INTENT_SPEC.md` and discharges the proof obligations in
`fvk/PROOF_OBLIGATIONS.md`.

## Why No Code Change

- F1 and PO1 show that lower-case script-region prefixes are handled by exact
  configured-language matching.
- F2 and PO5 show that BCP 47 case paths are handled through configured-language
  matching plus case-insensitive resolver prefix comparison.
- F3 and PO3 show that V1 avoids the public hint's regex-overmatch hazard.
- F4 and PO4 show that existing legacy fallback behavior is preserved by
  delegating to the unchanged original regex path.
- PO7 shows no public callsite or signature compatibility issue.

## Future Work Outside This Task

- In a normal development environment, add public regression tests for
  `/en-latn-us/`, `/en-Latn-US/`, and a non-configured multi-hyphen slug.
- In a K-enabled environment, run the commands in `fvk/PROOF.md` before treating
  the proof as machine-checked.
- A full Django/Python semantics could replace the mini semantics, but the
  focused model is sufficient to audit the V1 repair surface.
