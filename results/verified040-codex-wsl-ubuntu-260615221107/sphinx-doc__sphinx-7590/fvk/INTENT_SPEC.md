# Intent Spec

Status: constructed from public evidence only.

## Required Behavior

1. The C++ domain must accept C++ user-defined literal expressions in object
   initializers and other parsed expressions.
2. A numeric literal immediately followed by a user-defined suffix must be
   consumed as one literal expression, so parsing can continue at the following
   operator or delimiter. The reported example requires
   `6.62607015e-34q_J * 1q_s` to parse as multiplication of two suffixed numeric
   literals.
3. The same suffix mechanism applies to the C++ user-defined literal family:
   integer, floating, string, and character literals.
4. The rendered signature must preserve the literal spelling, including the
   suffix, and the suffix must not be parsed as a separate identifier expression.
5. Existing C++ literal behavior without a user-defined suffix must be preserved.
6. Literal operator declarations such as `operator""_udl` are a separate surface
   and must remain unchanged.
7. The C domain must not gain C++ user-defined literal support through shared
   utility regexes.

## Domain Assumptions

- User-defined suffixes are represented by the parser's existing ASCII
  identifier character set: `[A-Za-z_][A-Za-z0-9_]*`.
- This audit targets the C++ domain parser's literal-expression path, not a full
  replacement of Sphinx's C++ grammar.
- Partial correctness only: the FVK proof concerns the parser state transition
  when the relevant literal recognizer is reached.
