# FVK Iteration Guidance

## Code decision

V1 should not stand unchanged. Findings F2 and F3 show that V1 dropped
`.format(...)` for cases where zero-argument formatting is still semantically
relevant. V2 keeps V1's intended fix for the issue case while narrowing the full
call removal to the proof-obligation conditions in PO1-PO5.

## Recommended next tests

Add focused F523 autofix coverage in the normal test workflow, without editing
tests in this benchmark session:

- empty identity format string: `"Hello".format("world")`;
- empty string: `"".format(1)`;
- escaped braces: `"{{}}".format(1)`;
- missing named placeholder: `"{name}".format("unused")`;
- remaining keyword argument: `"{name}".format("unused", name="world")`.

## Residual risks

- The K model abstracts the Rust AST and CST rewrite machinery down to the
  branch predicate that decides whether to drop the full call. A fuller proof
  would model `TextRange`, `Locator::slice`, and LibCST round-tripping.
- The proof is constructed, not machine-checked. Keep test coverage until the
  K commands in `SPEC.md` and `PROOF.md` are run successfully.
- F522 named-argument empty-call behavior is adjacent but outside this issue's
  F523 scope. Do not change it without a separate intent ledger.

## Next implementation rule

Any future broadening of the "drop empty `.format(...)`" edit should first prove
that no-argument `str.format` is identity-preserving for the literal and that no
remaining field, keyword, or spread argument can affect behavior.
