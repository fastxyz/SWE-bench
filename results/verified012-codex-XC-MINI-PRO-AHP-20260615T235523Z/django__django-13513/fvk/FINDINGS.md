# FVK Findings

Status: constructed, not machine-checked.

## F1 - Suppressed Context Must Not Be Traversed

Classification: code bug fixed by V1 and preserved by V2.

Evidence:

- Public intent E1-E4 in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.
- Proof obligation PO1 in `fvk/PROOF_OBLIGATIONS.md`.
- K claim `resolve(none, true, OLD) => none`.

Input:

```text
ValueError("my new error")
  __cause__ = None
  __suppress_context__ = True
  __context__ = RuntimeError("my error")
```

Observed before the fix:

```text
The debug traceback traversed to RuntimeError("my error").
```

Expected:

```text
The visible chain stops at ValueError("my new error").
```

Resolution:

`explicit_or_implicit_cause()` now returns `None` when there is no explicit cause and `__suppress_context__` is true.

## F2 - V1 Left Truthiness In The Chain And Metadata Boundary

Classification: code robustness and spec-consistency issue found by the FVK audit; fixed in V2.

Evidence:

- PO2 requires traversal to stop on the `None` sentinel, not on arbitrary truthiness.
- PO3 requires `exc_cause_explicit` to be the predicate `__cause__ is not None`.
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` shows templates use `exc_cause_explicit` as a boolean flag.

V1 behavior:

```text
while exc_value:
    ...

'exc_cause_explicit': getattr(exc_value, '__cause__', True)
```

Issue:

After V1 made cause resolution identity-based, these adjacent boundaries still used truthiness. Standard exceptions are truthy, but Python's cause semantics are sentinel-based: the question is whether the cause is `None`, not whether the object is truthy. The frame field name and template usage also make it a boolean explicitness flag rather than a place to store the cause object.

Resolution:

V2 changes the chain loop to `while exc_value is not None` and changes `exc_cause_explicit` to `getattr(exc_value, '__cause__', None) is not None`.

## F3 - No Remaining In-Scope Code Finding After V2

Classification: confirmation within the stated FVK scope.

Evidence:

- PO1 through PO4 are discharged by the V2 source shape and the constructed proof in `fvk/PROOF.md`.
- `fvk/SPEC_AUDIT.md` marks each formal-English obligation as matching public intent.

Residual risk:

The proof is constructed, not machine-checked. The full Django rendering path and cycle-warning behavior are outside the issue-specific formal model and should remain covered by ordinary tests.
