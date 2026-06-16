# FVK Notes

Status: FVK audit complete; V1 stands unchanged.

## Decisions

1. Kept the V1 source change unchanged.

   Trace: Finding F-001 identified the real bug as raw comparison of path-like
   objects and strings. PO-001 requires `os.fspath()` normalization before
   validation, PO-002 requires mixed string/path-like duplicates to raise, and
   PO-003 requires path-like app default fixture directory conflicts to raise.
   The V1 line in `loaddata.py` discharges those obligations while preserving
   the existing validation branches.

2. Did not add `os.path.realpath()` canonicalization before duplicate checks.

   Trace: Finding F-002 records this as a plausible broader hardening, but
   PO-006 marks it outside the proven contract because the public issue only
   requires fixing `Path` instance comparison. Applying that change now would
   expand validation semantics beyond the issue evidence.

3. Made no API, command-line, exception-message, or test-file changes.

   Trace: Finding F-003 and PO-005 confirm the fix is local to the internal
   normalization step. `PUBLIC_COMPATIBILITY_AUDIT.md` found no public callsite
   or override compatibility issue.

4. Did not run tests, Python, or K tooling.

   Trace: `PROOF.md` labels the proof as constructed, not machine-checked, and
   lists the commands that should be run later in an environment where K
   tooling is allowed.

## Files added for FVK

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-python-paths.k`
- `fvk/loaddata-fixture-dirs-spec.k`
