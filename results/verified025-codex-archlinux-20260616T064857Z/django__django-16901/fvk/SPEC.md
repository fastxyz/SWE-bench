# SPEC: django__django-16901 XOR fallback

Status: constructed, not machine-checked.

## Target

Source under audit: `repo/django/db/models/sql/where.py`, specifically
`WhereNode.as_sql()` when:

- `self.connector == XOR`
- `connection.features.supports_logical_xor` is false
- the node was produced by normal ORM `Q(...) ^ Q(...)` construction

The V1 source translates a non-native XOR node to:

```text
(c1 OR c2 OR ... OR cn) AND ((case(c1) + ... + case(cn)) % 2 = 1)
```

where `case(ci)` is `1` when child predicate `ci` is true and `0` otherwise.

## Intent-Only Spec

I1. Source: `benchmark/PROBLEM.md`.
Quote: "The correct interpretation ... is that a ^ b ^ c is true when an odd number of the arguments are true."
Obligation: for every ORM-produced XOR predicate list, the non-native fallback must accept exactly odd truth counts.
Status: encoded as `PO-XOR-PARITY`.

I2. Source: `benchmark/PROBLEM.md`.
Quote: "Expected: 1, 0, 1, 0, 1."
Obligation: repeated identical true predicates must alternate true/false by operand count.
Status: encoded as `PO-REPEATED-TRUE-FAMILY`.

I3. Source: `benchmark/PROBLEM.md`.
Quote: "On databases that don't natively support XOR, such as PostgreSQL..."
Obligation: the fallback path, not the native backend path, must match the same parity semantics.
Status: encoded as `PO-BACKEND-FALLBACK`.

I4. Source: public source code.
Evidence: `Q._combine()` returns the non-empty side when either `Q()` operand is empty, and otherwise builds an XOR tree.
Obligation: the formal domain is ORM-produced, non-empty XOR child lists; direct construction of an empty internal `WhereNode(connector=XOR)` is outside the public issue path.
Status: encoded as `PO-DOMAIN`.

I5. Source: public source code.
Evidence: `WhereNode.as_sql()` applies `self.negated` to the synthesized replacement node.
Obligation: negated XOR must render as logical negation of parity.
Status: encoded as `PO-NEGATION`.

## Formal Model

Let `B = [b1, ..., bn]`, with each `bi` the boolean truth value represented by
the child predicate in `CASE WHEN child THEN 1 ELSE 0`.

Definitions:

- `truth_count(B) = sum(1 if bi else 0 for bi in B)`
- `odd_parity(B) = (truth_count(B) mod 2) = 1`
- `any_true(B) = b1 OR ... OR bn`
- `fallback_v1(B) = any_true(B) AND odd_parity(B)`
- `negated_fallback_v1(B) = NOT fallback_v1(B)`

Contract:

For every ORM-produced non-empty child list `B`:

```text
fallback_v1(B) = odd_parity(B)
negated_fallback_v1(B) = NOT odd_parity(B)
```

The K formal core is emitted in:

- `fvk/mini-xor-fallback.k`
- `fvk/xor-fallback-spec.k`

Commands to machine-check later, not run in this session:

```sh
kompile fvk/mini-xor-fallback.k --backend haskell
kast --backend haskell fvk/xor-fallback-spec.k
kprove fvk/xor-fallback-spec.k
```

## Adequacy Audit

The formal English claim says "non-native fallback XOR matches odd truth-count
parity for every ORM-produced non-empty XOR child list." This is exactly I1 and
I3, and it covers the whole repeated-true family in I2 rather than only the
three-operand example.

No public API, method signature, return type, or virtual dispatch shape changed.
The compatibility audit is therefore pass: public callers continue to call
`Q.__xor__()`, `Query._add_q()`, and `WhereNode.as_sql()` through the same APIs.

## Scope Boundaries

The proof abstracts SQL child predicates to booleans at the point where Django's
fallback already uses `CASE WHEN child THEN 1 ELSE 0`. It does not model the
entire SQL compiler, joins, or backend parser. Those are frame conditions:
V1 changes only the numeric comparison applied to the already-existing truth
count.

The proof is partial correctness and constructed only. No tests, Python code, or
K tooling were run.
