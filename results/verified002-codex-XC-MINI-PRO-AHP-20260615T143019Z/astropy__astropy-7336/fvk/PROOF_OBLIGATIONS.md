# Proof Obligations

Status: constructed, not machine-checked.

## Return-Handling Obligations

PO-RNONE: For all in-domain executions where
`wrapped_signature.return_annotation is None`, the wrapper returns `return_`
unchanged and does not call `return_.to(...)`.

Linked claims: QI-NONE, QI-NONE-ANY.
Linked findings: F-001.

PO-REMPTY: For all in-domain executions where
`wrapped_signature.return_annotation is inspect.Signature.empty`, the wrapper
returns `return_` unchanged.

Linked claims: QI-EMPTY.
Linked findings: none open.

PO-RUNIT: For all in-domain executions where the return annotation is present
and not `None`, the wrapper calls `return_.to(return_annotation)` exactly as the
pre-existing return-unit feature specified.

Linked claims: QI-UNIT.
Linked findings: F-002.

PO-OLD-WITNESS: The reported pre-fix failure is reproduced by the abstract old
branch condition: a non-empty `None` annotation with a `None` return goes to
`.to` and reaches `AttributeError`.

Linked claims: QI-OLD-BUG.
Linked findings: F-001.

## Frame Obligations

PO-FRAME-ARGS: The V1 edit does not change argument binding, argument unit
validation, default handling, or equivalency setup before the wrapped function
is called.

Evidence: the diff is after the wrapped function returns.

PO-FRAME-API: The V1 edit does not change public signatures or call shape for
`quantity_input`, `QuantityInput.as_decorator`, `QuantityInput.__call__`, or the
generated wrapper.

Evidence: only local return-branch statements changed.

PO-TERMINATION: No new loop or recursion is introduced by V1. The return branch
terminates in one conditional branch if the framed earlier steps terminate.

## Adequacy Obligations

PO-ADEQUACY-DOMAIN: The proof domain must include the issue reproducer:
`return_annotation is None` and `return_ is None`.

PO-ADEQUACY-FRAME: The proof must not certify an overbroad fix that skips unit
conversion for all actual `None` returns, because public docs/tests still define
non-`None` return annotations as conversion requests.

PO-ADEQUACY-COMPAT: Any no-change conclusion must pass the compatibility audit.

Result: all obligations are discharged by construction in `PROOF.md`; no source
change beyond V1 is justified.
