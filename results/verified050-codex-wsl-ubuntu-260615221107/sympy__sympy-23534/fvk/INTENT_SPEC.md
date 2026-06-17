# Intent Specification

Status: constructed from public evidence only. Current implementation behavior
is treated as candidate behavior to audit, not as the expected result.

## Required Behavior

I1. `symbols()` can create symbol-like objects using the caller-provided
`cls` keyword, including `Function`.

I2. The `cls` behavior applies to all supported input shapes for `names`,
including an iterable container of strings used to produce separate output
groups.

I3. For `symbols(('q:2', 'u:2'), cls=Function)`, the first object in the first
returned group has type `sympy.core.function.UndefinedFunction`, not
`sympy.core.symbol.Symbol`.

I4. The extra iterable layer is intentional and must preserve the output shape:
the outer tuple gives separate `q` and `u` groups, and each range string expands
inside its own tuple.

I5. Existing string parsing, range expansion, keyword assumptions, and return
container behavior remain otherwise unchanged.

## Domain

The audited domain is the public `symbols(names, *, cls=Symbol, **args)` API for
string names and non-string iterable containers of accepted name entries. The
formal core focuses on nested iterable inputs containing string range specs,
because that is the issue's failing class of inputs and the branch modified by
the candidate patch.

## Default-Domain Assumptions

Python keyword-only argument binding means `cls` is not present in `**args`
inside `symbols()`. Therefore recursive calls must pass `cls` explicitly when
they need to preserve it.

The proof is partial correctness only: it proves that the constructed result is
correct if the function returns. Termination is not separately proved.
