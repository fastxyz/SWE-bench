# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-01: Intent Adequacy

The formal contract must be derived from the issue's expected signature and
public hints, not from V1 behavior. The suspect legacy output
`<MyEnum.ValueA: 10>` must not be preserved as an oracle.

Status: discharged by `SPEC.md` evidence entries E1-E4 and spec audit K1-K5.

## PO-02: Named Enum Member Formatting

For any enum object with class qualname `C` and member name `N` where `N` is not
`None`, `object_description()` must return `C + "." + N`, except that flag
combination names are handled by PO-05.

Status: discharged by the enum branch in `repo/sphinx/util/inspect.py` and the
K claim `NAMED-ENUM-DESCRIPTION`.

## PO-03: Signature Propagation

When `stringify_signature()` formats a parameter default that is a named enum
member, the default-value substring must be the result from PO-02, with the
existing spacing rules preserved.

Status: discharged by the unchanged call
`arg.write(object_description(param.default))` and the K claim
`SIGNATURE-NAMED-ENUM-DEFAULT`.

## PO-04: Non-Enum Frame Condition

For non-enum inputs, `object_description()` must preserve the existing behavior:
sorted dicts where sortable, sorted sets and frozensets where sortable, generic
`repr()` fallback, memory-address stripping, and newline replacement.

Status: discharged statically because the edit adds only a preceding enum
branch and leaves the existing non-enum branches unchanged; modeled by
`OTHER-OBJECT-FALLBACK`.

## PO-05: Flag and Nameless Enum Edge Condition

For `enum.Flag` values whose name is pipe-separated, each component must be
qualified as `C.Component`. For enum values whose name is `None`, the formatter
must not return `C.None`; it must fall through to the existing repr fallback.

Status: discharged by the V2 refinement and the K claims
`FLAG-COMPOSITE-DESCRIPTION` and `UNNAMED-ENUM-FALLBACK`.

## PO-06: Public Compatibility

The fix must not change public callable signatures, return types, dispatch
protocols, or test files.

Status: discharged by the public compatibility audit in `SPEC.md`; no tests
were modified.

## PO-07: Proof Honesty

Because this session forbids running tests, Python, or K tooling, the proof
must be labeled constructed, not machine-checked, and test removal must not be
recommended unconditionally.

Status: discharged by `PROOF.md` and `ITERATION_GUIDANCE.md`.
