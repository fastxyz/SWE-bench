# FVK Findings

Status: findings are from public intent and static source reasoning. No tests,
Python, or K tooling were run.

## F1: Original F523 fix left an empty `.format()` call

Input: `"Hello".format("world")`

Observed before the V1 fix: the argument-removal path produced
`"Hello".format()`.

Expected from the issue: `"Hello"`.

Classification: code bug in fix construction.

Resolution: retained in V2. `remove_unused_positional_arguments_from_format_call`
can now replace the full call with the receiver when the format operation is
empty and identity-preserving.

Related proof obligations: PO1, PO5, PO6.

## F2: V1 would incorrectly erase escaped-brace formatting

Input: `"{{}}".format(1)`

Observed under V1 by static reasoning: all explicit positional arguments are
unused and there are no keyword arguments, so V1 would replace the call with
`"{{}}"`.

Expected: F523 may remove the unused positional argument, but it must not erase
the formatting operation here. With zero arguments, `str.format` still
normalizes doubled braces, so `"{{}}".format()` and `"{{}}"` are not equivalent.

Classification: V1 code bug found by the FVK audit.

Resolution: V2 adds `FormatSummary::is_literal_identity` and requires it before
dropping `.format(...)`.

Related proof obligations: PO3, PO5.

## F3: V1 would incorrectly erase missing-placeholder behavior

Input: `"{name}".format("unused")`

Observed under V1 by static reasoning: the sole positional argument is unused,
and no keyword arguments remain, so V1 would replace the call with `"{name}"`.

Expected: F523 should remove unused positional arguments only. It must not erase
the `.format(...)` operation when the format string still has a named field,
because missing-placeholder behavior belongs to the remaining format operation
and to F524's domain.

Classification: V1 code bug found by the FVK audit.

Resolution: V2 passes `FormatSummary` into the fix helper and requires
`autos`, `indices`, and `keywords` to all be empty before dropping the full call.

Related proof obligations: PO2, PO6.

## F4: Remaining keyword arguments are correctly preserved

Input: `"{name}".format("unused", name="world")`

Observed under V1 and V2 by static reasoning: the special drop branch is blocked
because keyword arguments are present, so the fallback removes only the unused
positional argument.

Expected: `"{name}".format(name="world")`.

Classification: confirmed behavior.

Related proof obligations: PO4.

## F5: The proof is constructed, not machine-checked

Input: the abstract K claims in `fvk/f523-format-fix-spec.k`.

Observed: commands are emitted in `fvk/SPEC.md` and `fvk/PROOF.md`, but this
session is forbidden from running K tooling.

Expected: keep all tests; add focused tests for F1-F3 in a normal development
environment, and only treat proof-based test redundancy as actionable after
`kprove` returns `#Top`.

Classification: proof capability and execution-environment limitation.

Related proof obligations: PO8.
