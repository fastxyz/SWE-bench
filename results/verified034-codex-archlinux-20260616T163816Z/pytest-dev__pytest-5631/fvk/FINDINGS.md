# FVK Findings

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## F-001: Equality-based sentinel detection was the root bug

Classification: code bug, resolved by V1.

Input shape: `function.patchings` contains a patching object with
`not p.attribute_name` and `p.new` equal to an explicit array-like object; a mock
module is loaded and contributes a `DEFAULT` sentinel.

Observed before V1: `p.new in sentinels` invokes equality between the explicit
array-like `new=` object and a sentinel. The issue reports that this produces an
array of booleans, which Python then attempts to interpret as a truth value,
raising `ValueError` during collection.

Expected from public intent: the explicit `new=` object does not create a mock
argument and must not be equality-compared with sentinels. The helper should
count `0` for that patching object and collection should continue.

V1 status: resolved. The code now uses `any(p.new is s for s in sentinels)`,
which checks object identity and does not invoke equality on `p.new`.

Related proof obligations: PO-001, PO-004.

## F-002: Default `mock.DEFAULT` patching still counts

Classification: compatibility requirement, confirmed.

Input shape: `function.patchings` contains a patching object with
`not p.attribute_name` and `p.new` identical to one loaded mock module's
`DEFAULT` sentinel.

Expected from public intent and existing mock integration behavior: this patch
creates a generated mock argument, so the helper should count `1` for this
patching object.

V1 status: confirmed. Identity comparison accepts the actual sentinel object.

Related proof obligations: PO-002, PO-004.

## F-003: Explicit non-sentinel `new=` values do not consume arguments

Classification: compatibility requirement, confirmed.

Input shape: `function.patchings` contains a patching object with
`not p.attribute_name` and `p.new` equal to any explicit non-sentinel object,
including arrays, classes, callables, or objects with unusual `__eq__`.

Expected from public intent: explicit replacement values do not add a generated
mock parameter for pytest to trim.

V1 status: confirmed for the audited predicate. The identity predicate is false
for every object that is not the exact loaded `DEFAULT` sentinel.

Related proof obligations: PO-001, PO-004.

## F-004: No public compatibility problem found

Classification: compatibility audit, no code action.

Observed V1 change: only the internal sentinel predicate changed. The helper
name, signature, return type, callers, imports, and fallback branch are
unchanged.

Expected from public intent: a collection bug fix should not alter public API or
fixture-discovery wiring.

V1 status: confirmed.

Related proof obligations: PO-006, PO-007.

## F-005: Constructed proof is not machine-checked

Classification: proof status, residual verification work.

The FVK proof artifacts include K-style semantics, claims, and commands, but the
benchmark forbids running K tooling. Therefore the result is constructed, not
machine-checked. This does not require a source change; it only conditions any
claim about formal verification strength.

Related proof obligations: PO-008.

## F-006: Abstract model boundary

Classification: proof capability boundary, no code bug.

The K artifact models patch metadata and object identity, not full Python,
`unittest.mock`, or NumPy behavior. This abstraction is adequate for the bug
because the property under audit is exactly whether the predicate uses identity
instead of equality for sentinel detection. It would be inadequate for broader
questions about Python decorator execution or mock internals.

Related proof obligations: PO-008.
