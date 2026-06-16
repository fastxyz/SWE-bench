# FVK Notes

The FVK audit confirms V1 should stand unchanged.

Source decision:

- No source file was changed in the FVK pass. `FVK-F1` traces the reported
  Python 3 byte-method bug to PO-1 and PO-3, and V1 discharges both by using
  `to_native_string(method)` instead of `builtin_str(method)` in
  `Session.request`.
- No compatibility edit was needed. `FVK-F2` traces native string behavior to
  PO-2 and PO-4; `to_native_string` is identity for native strings, and V1 keeps
  the existing `method.upper()` behavior.
- I rejected the broader `PreparedRequest.prepare_method` change. `FVK-F3` and
  PO-5 classify direct preparation with byte methods as underspecified for this
  issue: it does not traverse the reported `builtin_str(method)` line, and the
  public hint specifically calls for replacing that conversion with the
  native-string helper.
- I made no non-ASCII method change. `FVK-F4` and PO-5 set the proof domain to
  ASCII HTTP method tokens, matching the default HTTP method domain and
  `to_native_string`'s default decoding.

Artifact decisions:

- `fvk/SPEC.md` records the intent-only spec, public evidence ledger, formal
  English paraphrase, adequacy audit, and public compatibility audit.
- `fvk/mini-requests-method.k` and `fvk/session-request-method-spec.k` provide
  the constructed formal core required by the FVK docs.
- `fvk/PROOF_OBLIGATIONS.md` names the obligations that justify V1.
- `fvk/PROOF.md` gives the constructed proof and exact commands that would be
  run later in an environment with K tooling.
- `fvk/FINDINGS.md` records the resolved bug, preserved behavior, and explicit
  out-of-scope boundaries.
- `fvk/ITERATION_GUIDANCE.md` explains why no V2 code edit is recommended and
  what future public intent would be needed to broaden the fix.

No tests, Python, or K tooling were run.
