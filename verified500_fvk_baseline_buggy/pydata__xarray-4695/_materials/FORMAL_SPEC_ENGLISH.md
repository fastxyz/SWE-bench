# Formal Spec in English

Status: constructed, not machine-checked.

## Claim LOC-GENERIC

For every mapping `M`, `locGet(M)` rewrites to a downstream `.sel` dispatch with
the same mapping `M` and exact-match method state. No key in `M` is interpreted
as a reserved `.sel` parameter during `.loc` dispatch.

## Claim LOC-METHOD-CONCRETE

For the concrete mapping `{"dim1": "x", "method": "a"}`, `locGet` reaches
downstream `.sel` dispatch with exactly that mapping and exact-match method
state. The `"method"` key remains an indexer key.

## Claim HELPER-METHOD-CONCRETE

For a dynamically constructed one-item indexer with dimension name `"method"`
and label `"a"`, the helper dispatch reaches downstream `.sel` with the mapping
`{"method": "a"}` and exact-match method state.

## Claim HELPER-GENERIC

For every dynamic dimension name `D` and label `V`, helper dispatch reaches
downstream `.sel` with the one-item mapping `{D: V}` and exact-match method
state.

## Diagnostic Claim LEGACY-METHOD-COUNTEREXAMPLE

The pre-fix keyword-unpacking path for `{"dim1": "x", "method": "a"}` rewrites
to an invalid fill-method outcome. This is not an intended behavior claim; it
localizes the public traceback mechanism.

## Frame Claim

The proof does not change or re-specify downstream label lookup. After dispatch
has delivered an indexer mapping and exact method state to `.sel`, existing
xarray and pandas selection semantics decide the final selected object or any
valid downstream error.
