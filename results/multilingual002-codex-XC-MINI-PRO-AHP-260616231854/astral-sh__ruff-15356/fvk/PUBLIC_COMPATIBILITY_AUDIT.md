# Public Compatibility Audit

Status: source audit, no execution.

## Changed Symbol Surface

- `DefinitionState` remains a private enum in `repo/crates/ruff_linter/src/rules/pycodestyle/rules/logical_lines/mod.rs`.
- `DefinitionState::visit_token_kind` keeps the same private method signature.
- `TypeParamsState` and `before_type_params` keep the same private shape.
- No public Rust API, CLI option, diagnostic code mapping, file format, or test fixture was changed.

## Compatibility Verdict

No public callsite, subclass, override, or producer/consumer protocol requires an update. The behavioral change is intentionally limited to the private logical-line state transition for type aliases without explicit type parameters.
