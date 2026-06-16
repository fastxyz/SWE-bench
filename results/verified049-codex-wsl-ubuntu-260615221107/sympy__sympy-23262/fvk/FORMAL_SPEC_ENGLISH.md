# Formal Spec in English

Status: constructed, not machine-checked.

This file paraphrases each nontrivial claim from `fvk/lambdify-recursive-to-string-spec.k`.

## Claim `TUPLE-SINGLETON`

For any printable expression node `E`, rendering a native Python tuple whose only element is `E` produces a parenthesized singleton tuple literal: an opening parenthesis, the recursively rendered element, a comma, and a closing parenthesis.

## Claim `RETURN-SINGLETON-TUPLE`

For any printable expression node `E`, the generated function return line for a native one-element tuple is `return (` followed by the recursively rendered element and then `,)`. This is the observable `lambdify` source-code requirement from the issue.

## Claim `TUPLE-EMPTY`

Rendering an empty native Python tuple produces `()`.

## Claim `TUPLE-MULTI`

Rendering a native Python tuple with at least two elements produces parentheses around the recursively rendered elements, separated by comma-space, in the original order, with no singleton-only trailing comma rule applied.

## Claim `LIST-FRAME`

Rendering a native Python list produces square brackets around the recursively rendered elements, separated by comma-space, in the original order.

## Claim `LEAF-DELEGATION`

Rendering a leaf delegates to the leaf's already supplied printed string. This models the helper's `doprint(arg)` and raw string branches without re-specifying SymPy's printer behavior.

