# FVK Iteration Guidance

Status: V1 stands unchanged.

## Decision

No additional source edit is justified by the FVK audit.

V1 directly discharges the intent-derived obligations:

- PO-1: byte-string methods on `Session.request` decode to native method text.
- PO-2: native string methods preserve existing uppercasing behavior.
- PO-3: the `builtin_str(bytes)` bytes-repr path is removed from the audited
  session request path.
- PO-4: public API compatibility is preserved.
- PO-5: the ASCII HTTP method domain is explicit.

## Rejected V2 Change

Do not move the fix into `PreparedRequest.prepare_method` for this task.

Reason: `FVK-F3` identifies that direct preparation with byte methods is a
possible broader hardening, but the public issue and hint localize the defect to
`Session.request` and the `builtin_str(method)` conversion. Changing the lower
preparation layer would alter behavior outside the proven intent.

## Future Work If Intent Expands

If a future public requirement says all preparation paths must coerce byte-string
methods to native strings, then revisit `PreparedRequest.prepare_method` or
`Session.prepare_request` and add proof obligations for:

- direct `Request(...).prepare()`;
- direct `Session.prepare_request(Request(...))`;
- adapter dispatch receiving only native text methods.

That broader change should include compatibility evidence for any public code
that may currently pass non-string or custom method-like objects.

## Commands Not Run

The following commands are recorded in `PROOF.md` but were not executed:

```sh
kompile fvk/mini-requests-method.k --backend haskell
kast --backend haskell fvk/session-request-method-spec.k
kprove fvk/session-request-method-spec.k
```

No tests, Python, or K tooling were run.
