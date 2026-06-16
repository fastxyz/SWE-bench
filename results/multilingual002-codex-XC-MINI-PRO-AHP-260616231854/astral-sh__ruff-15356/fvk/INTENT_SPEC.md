# Intent Spec

Status: constructed from public issue text and repository source comments/tests; not machine-checked.

## Required Behavior

1. `E252` must not be emitted for keyword-argument equals signs in the value of a PEP 695 type alias that has no explicit type-parameter list.
2. A type alias value such as `Annotated[...]` may contain brackets and calls; those brackets are value syntax after the alias assignment `=`, not type-parameter syntax.
3. Existing `E252` handling for real annotated function parameters and actual PEP 695 type-parameter defaults must be preserved.
4. The fix must be source-only and must not modify the fixed public/hidden test suite.

## Domain

The verified domain is the logical-line state transition used by pycodestyle whitespace rules for definition headers and type aliases. The concrete issue path is a logical line whose first nontrivia token is `type`, followed by an alias name, an alias assignment `=`, and an alias value containing `Annotated[...]` and keyword calls.

## Out of Scope

This FVK run does not model all of Ruff, the Rust type system, the Python parser, or tokenization. The reduced K model preserves the observable property relevant to the issue: whether `DefinitionState::in_type_params()` is true when `whitespace_around_named_parameter_equals` sees a keyword-argument `=`.
