# Formal Spec English

Status: paraphrase of `fvk/definition-state-spec.k`; constructed, not machine-checked.

1. For the issue-shaped token prefix `type Name = Name [ newline Name , Name ( Name`, the E252 missing-whitespace branch is false at the following keyword-argument equals when paren depth is 2 and the token is not an annotated function parameter.
2. For a type alias with no explicit type parameters, scanning through `type Name = Name [` ends in `InTypeAlias(TypeParamsEnded)`, so the right-hand-side bracket is not treated as a type-parameter opener.
3. For an actual type-parameter list prefix `type Name [ Name`, the E252 missing-whitespace branch remains true, preserving diagnostics for type-parameter defaults.
4. Nested brackets inside type parameters keep the state in `InTypeParams` until the matching outer `]`, after which the state is `TypeParamsEnded`.
5. For annotated function parameters, the E252 branch remains true when the caller-provided function-annotation state is true and paren depth is 1.
