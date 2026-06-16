# Baseline Notes

## Root Cause

`E252` uses the pycodestyle logical-line `DefinitionState` to decide whether an `=` token is inside PEP 695 type parameters. For a type alias without explicit type parameters, such as:

```python
type MyType = Annotated[
    str, pydantic.Field(min_length=4)]
```

the state entered `InTypeAlias(BeforeTypeParams)` at the `type` keyword but never transitioned out of `BeforeTypeParams` when it reached the alias assignment `=`. As a result, the first `[` in the right-hand side (`Annotated[...]`) was incorrectly treated as the start of a type-parameter list. Keyword argument defaults inside that subscript were then interpreted as type-parameter defaults, causing false-positive `E252` diagnostics. Because the arguments had no whitespace on either side of `=`, the rule emitted one fix for the missing space before and one fix for the missing space after, making each false positive appear twice.

## Changed Files

- `repo/crates/ruff_linter/src/rules/pycodestyle/rules/logical_lines/mod.rs`
  - Updated the `DefinitionState` documentation to include type aliases, since the enum already tracks them.
  - Added a transition for `InTypeAlias(BeforeTypeParams)` on `TokenKind::Equal`, marking type parameters as ended. This preserves handling of actual type alias parameters like `type Alias[T = int] = int` while preventing brackets in the alias value from being misclassified as type parameters when no type-parameter list exists.

## Assumptions

- The `=` token after a type alias name is the boundary that proves there is no type-parameter list for that alias. If a type-parameter list exists, the state will already have entered `InTypeParams` after the `[` before the alias assignment.
- The existing behavior of producing separate `E252` diagnostics for missing whitespace before and after the same `=` is intentional for real annotated parameters and type-parameter defaults, as reflected by existing fixtures and snapshots.

## Alternatives Considered

- Deduplicating `E252` diagnostics by token range was rejected because it would change established behavior for legitimate cases where both sides of an annotated parameter default are missing whitespace.
- Special-casing `Annotated[...]` or call expressions in the `E252` rule was rejected because the actual failure is earlier: `DefinitionState` incorrectly marks the entire alias value subscript as type parameters.
- Restricting the fix to `whitespace_around_named_parameter_equals` was rejected because `DefinitionState` is shared by other logical-line whitespace rules; correcting the state transition prevents related misclassification in those rules too.
