# PROOF OBLIGATIONS

Status: constructed, not machine-checked.

## PO-DOMAIN

For `Q(...) ^ Q(...)` expressions compiled by the ORM, the audited XOR fallback
receives a non-empty child list. Empty `Q()` operands are simplified before an
XOR node reaches SQL rendering.

Evidence: `Q._combine()` returns the non-empty side when either side is empty;
otherwise it creates an XOR node.

Status: discharged for the public issue domain. Related finding: FVK-F3.

## PO-XOR-PARITY

For every ORM-produced non-empty child truth list `B`, the fallback predicate
must be true iff `truth_count(B)` is odd.

Status: discharged by V1 formula `truth_count(B) % 2 == 1`. Related findings:
FVK-F1, FVK-F2.

## PO-REPEATED-TRUE-FAMILY

For repeated identical true predicates of length `n >= 1`, the fallback result
must be true exactly when `n` is odd. This is the family behind the issue's
expected `1, 0, 1, 0, 1` sequence.

Status: discharged because `truth_count(B) = n` for this family and V1 checks
`n % 2 == 1`. Related finding: FVK-F2.

## PO-CASE-COUNT

Each existing `Case(When(child, then=1), default=0)` term contributes `1` exactly
when the child predicate is true and `0` otherwise.

Status: discharged by Django's existing fallback construction; V1 does not
change this part.

## PO-SUM

The `reduce(operator.add, case_terms)` expression denotes the sum of all child
truth indicators.

Status: discharged for non-empty child lists. This is the same summation V1
inherited from the pre-fix fallback.

## PO-MOD-PARITY

For a non-negative integer `k`, `k % 2 == 1` iff `k` is odd.

Status: arithmetic obligation discharged. The truth count is non-negative
because it is a sum of zero/one indicators.

## PO-OR-REDUNDANCY

For every child truth list `B`, if `truth_count(B) % 2 == 1`, then at least one
child is true. Therefore:

```text
any_true(B) AND (truth_count(B) % 2 == 1)
```

is equivalent to:

```text
truth_count(B) % 2 == 1
```

Status: discharged. Related finding: FVK-F4.

## PO-NEGATION

When `self.negated` is true, `WhereNode.as_sql()` wraps the synthesized fallback
node in `NOT (...)`. Therefore negated XOR renders as `NOT odd_parity(B)`.

Status: discharged by preserving `self.negated` when constructing the fallback
`AND` node.

## PO-BACKEND-FALLBACK

The modulo expression must be representable by Django's expression layer on
backends that lack native logical XOR.

Status: discharged by existing `Combinable.MOD` support and backend
`combine_expression()` implementations. Base backends render the modulo operator;
Oracle renders `MOD(lhs,rhs)`; MySQL normally bypasses the fallback via
`supports_logical_xor = True`.

## PO-COMPATIBILITY

The patch must not change public APIs, signatures, test files, or the ORM call
chain that produces and compiles `Q` XOR expressions.

Status: discharged. V1 changes only the expression compared against `1` inside
`WhereNode.as_sql()`.
