# SPEC

Status: constructed, not machine-checked. No tests, Python, Rust, or K tooling were executed.

## Scope

This FVK run audits the V1 change to `DefinitionState::visit_token_kind` and the specific consumer condition in `whitespace_around_named_parameter_equals` that decides whether an equals token enters the `E252` missing-whitespace branch.

The reduced formal model is in:

- `fvk/mini-ruff-logical-lines.k`
- `fvk/definition-state-spec.k`

The model does not attempt to formalize all of Ruff or Rust. It preserves the exact observable needed for this issue: whether `DefinitionState::in_type_params()` is true when the `E252` rule sees a keyword-argument equals token inside a type alias value.

## Intent Summary

From `benchmark/PROBLEM.md`, the reproducer is:

```python
type MyType = Annotated[
    str, pydantic.Field(min_length=4, max_length=7, pattern='^[0-9]{4,7}$')]
```

The issue reports the `E252` diagnostics on `min_length=4`, `max_length=7`, and `pattern=...` as false positives. Therefore, for a type alias with no explicit type-parameter list, brackets in the alias value must not keep or enter the type-parameter state that triggers `E252`.

## Public Intent Ledger

The standalone ledger is `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical entries mirrored here:

- E-01: The prompt says the reported `E252` output is a false positive.
- E-02: The prompt's alias is `type MyType = ...`, with no explicit type-parameter list before the alias assignment.
- E-03: The erroneous diagnostics point to keyword-argument equals signs inside `pydantic.Field(...)`.
- E-05: Existing public fixtures expect E25-family diagnostics for actual PEP 696 type-parameter defaults such as `def pep_696_bad[A=int, ...]`.
- E-06: The implementation chooses the `E252` missing-whitespace path when `definition_state.in_type_params()` is true.

## Contract

For every logical-line token stream in the audited domain:

1. If a `type` alias reaches the alias assignment `=` while still in `BeforeTypeParams`, the type-parameter window must transition to `TypeParamsEnded`.
2. After that transition, any later `[` in the alias value must not transition the state into `InTypeParams`.
3. For actual type-parameter lists, a `[` before the alias assignment must still transition into `InTypeParams`.
4. Nested brackets inside actual type parameters must still be counted so only the matching outer `]` ends type-parameter state.
5. Annotated function parameter behavior must be unchanged.

## Adequacy

The adequacy files are:

- `fvk/INTENT_SPEC.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

All formal-English obligations pass the intent audit. No claim preserves the prompt-described false-positive behavior.
