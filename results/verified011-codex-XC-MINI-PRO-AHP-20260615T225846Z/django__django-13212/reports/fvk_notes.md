# FVK Notes

## Decision

V1 stands as V2 without additional source edits.

## Trace to FVK Findings and Proof Obligations

`fvk/FINDINGS.md` F1 and `fvk/PROOF_OBLIGATIONS.md` PO1-PO8 confirm that the
core validators now attach `params['value']` on invalid paths while preserving
validity decisions, messages, codes, and existing params. That is the primary
issue requirement from the public prompt.

F2 and PO3-PO5 justify keeping V1's handling of derived internal values. The
URL punycode retry, email domain/literal helpers, IPv6 literal checks, decimal
digit calculations, file extension extraction, and key-set calculations must
all report the original submitted value. V1 already does that, including the
extra URL re-raise around the punycoded retry.

F3 and PO9 justify the V1 choice to include
`django.contrib.postgres.validators.KeysValidator`. It is documented as a
public reusable validator and had direct `ValidationError` raises with existing
`keys` params, so V1 correctly adds `value` without removing `keys`.

F4 and PO10 justify not widening the source patch to password validators,
form-field cleaning errors, or model-field cleaning errors. The issue and docs
target reusable validator callables and a `%(value)s` customization pattern;
password values have a separate security exposure concern, and form/model
field cleaning errors are a broader API surface.

F5 and PO11 explain the verification constraint. The proof artifacts are
constructed, not machine-checked, and this task forbids running tests, Python,
or K tooling. Therefore I did not remove or edit tests and do not recommend
test removal.

## Changes Made In This FVK Pass

No source files under `repo/` were changed in this pass.

Added FVK artifacts under `fvk/`, including the five requested reports plus
the constructed K core and adequacy/compatibility audit files.

Added this report at `reports/fvk_notes.md`.
