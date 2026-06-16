# Formal Spec English

Status: constructed for FVK audit; not machine-checked.

This file paraphrases the K claims in `add-filter-spec.k`.

- `ADD-INT`: For any `V` and `A`, after resolving text promises, if both
  operands can be coerced to integers, `add(V, A)` returns the integer sum of
  the resolved operands.
- `ADD-PLUS`: For any `V` and `A`, after resolving text promises, if integer
  coercion does not succeed for both operands and native Python addition
  succeeds, `add(V, A)` returns the native addition result.
- `ADD-EMPTY`: For any `V` and `A`, after resolving text promises, if integer
  coercion does not succeed for both operands and native Python addition also
  fails, `add(V, A)` returns the empty string.
- `ADD-LAZY-RIGHT-PLUS`: For a normal string `S` and lazy text `lazyText(T)`,
  if the resolved strings are not both integer-coercible and string addition
  succeeds, `add(S, lazyText(T))` returns `S + T`.
- `ADD-LAZY-LEFT-PLUS`: For lazy text `lazyText(S)` and a normal string `T`,
  if the resolved strings are not both integer-coercible and string addition
  succeeds, `add(lazyText(S), T)` returns `S + T`.
- `ADD-LAZY-RIGHT-INT`: For a normal string `S` and lazy text `lazyText(T)`, if
  both resolved strings are integer-coercible, `add(S, lazyText(T))` returns the
  integer sum, not the string concatenation.

There are no loop circularities. The proof obligations are straight-line
case splits over the three documented branches.

