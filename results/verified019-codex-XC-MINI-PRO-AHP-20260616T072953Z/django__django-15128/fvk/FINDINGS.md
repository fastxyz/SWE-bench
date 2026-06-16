# Findings

Status: constructed, not machine-checked. These findings are based on public
intent, source inspection, and the FVK proof obligations; no tests or code were
run.

## F-1: Original alias-overlap bug is addressed by V1

Input/state: `combine()` merges an RHS query whose aliases include sequential
generated aliases such as `T4` and `T5`, while LHS alias allocation creates
`T5` and then `T6`.

Observed before fix: the merge `change_map` can become
`{'T4': 'T5', 'T5': 'T6'}`, so keys and values overlap and
`Query.change_aliases()` can raise `AssertionError`.

Expected: RHS aliases are normalized before the merge map is built, so aliases
used as RHS change-map keys are not also generated as LHS replacement values.

V1 status: discharged by PO-1, PO-2, PO-3, and PO-6. `combine()` clones RHS and
calls `rhs.bump_prefix(self, exclude={initial_alias})` before join merging.

## F-2: Initial alias preservation is necessary and V1 preserves it

Input/state: `combine()` starts from two queries over the same base model.

Potential defect: calling the old `bump_prefix()` directly on RHS would relabel
the base alias too, conflicting with `combine()`'s algorithm that skips the
first RHS alias and expects both sides to start from the same base table.

Expected: all RHS aliases except the initial alias may be bumped.

V1 status: discharged by PO-2 and PO-4. `bump_prefix()` accepts `exclude`, and
the combine path excludes `next(iter(rhs.alias_map), None)`.

## F-3: RHS non-mutation frame condition is explicitly protected

Input/state: `combine()` is called with a reusable RHS query object.

Potential defect: `Query.clone()` shallow-copies `table_map`, whose values are
alias lists. Relabeling the clone could otherwise mutate alias-list objects
shared with the original RHS query.

Expected: `rhs` remains unmodified, matching the `combine()` docstring.

V1 status: discharged by PO-5. The combine path copies each `table_map` alias
list on the clone before calling `bump_prefix()`.

## F-4: Existing `bump_prefix()` callers remain compatible

Input/state: subquery code calls `clone.bump_prefix(query)` and
`query.bump_prefix(self)` without `exclude`.

Observed in V1: `exclude` defaults to an empty set, preserving the prior
full-relabel behavior.

Expected: no public or internal caller must be updated unless it needs the new
exclude behavior.

V1 status: discharged by PO-7.

## F-5: Machine checking and full Django semantics remain open

Input/state: this benchmark forbids running K tooling, Python, or tests.

Observed: the proof is an alias-calculus abstraction, not a machine-checked
proof of the full Django ORM.

Expected: the artifact must be honest about the proof boundary, and no tests
should be removed on this basis.

V1 status: open proof boundary, not a code defect. Tracked by PO-8.
