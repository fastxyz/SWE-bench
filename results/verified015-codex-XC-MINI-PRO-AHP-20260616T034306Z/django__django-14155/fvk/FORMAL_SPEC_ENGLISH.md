# Formal Spec in English

Status: English paraphrase of `fvk/resolvermatch-spec.k`; constructed, not machine-checked.

## Claim PARTIAL-REPR

Given a `ResolverMatch` built from a single `partial(F, PA, PK)` callback plus URL args `A` and URL kwargs `K`, initialization reaches a state whose public callback is still the original partial, whose public args/kwargs are still `A` and `K`, whose display path is `path(F)`, whose display args are `PA + A`, and whose display kwargs are `PK` overridden by `K`.

## Claim NESTED-PARTIAL-REPR

Given a nested partial `partial(partial(F, PA1, PK1), PA2, PK2)` plus URL args `A` and URL kwargs `K`, initialization reaches a state whose display path is `path(F)`, display args are `PA1 + PA2 + A`, and display kwargs are `PK1` overridden by `PK2` overridden by `K`.

## Claim NONPARTIAL-REPR

Given a non-partial callback `F`, initialization reaches a state whose display path is `path(F)`, display args are exactly the URL args, and display kwargs are exactly the URL kwargs.

## Claim FRAME-PUBLIC-TRIPLE

For any callback `V`, including partials, initialization leaves the public callback, URL args, and URL kwargs fields equal to the values supplied to `ResolverMatch.__init__()`.

## Claim VIEW-NAME-FRAME

The view-name contributor uses `url_name` when it is present; otherwise it uses the computed display path. This is unchanged except that the computed display path for partials is now the wrapped callable path.

