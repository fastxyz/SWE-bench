# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Safe Relabel Map

For every `change_map` passed to `Query.change_aliases()` or to an expression
that can recursively call `Query.change_aliases()`, `set(change_map)` must be
disjoint from `change_map.values()`.

Trace: E-1, C-1, C-2.

## PO-2: Preserve Initial RHS Alias

When `combine()` prepares RHS aliases, the first alias in `rhs.alias_map` must
not be relabeled. `combine()` depends on both sides sharing the same base alias
and skips `list(rhs.alias_map)[0]` during join merging.

Trace: E-4, C-1, C-2.

## PO-3: Pre-Merge RHS Prefix Bump

If `self.alias_prefix == rhs.alias_prefix` and RHS has aliases beyond the base
alias, `combine()` must normalize RHS before the join loop creates the merge
`change_map`. After this step, RHS aliases that can become `change_map` keys
must be in a different generated-prefix namespace from the aliases LHS will
allocate.

Trace: E-1, E-2, E-3, C-2.

## PO-4: Excluded-Alias Collision Avoidance

`bump_prefix(..., exclude=...)` must not generate a replacement alias that
collides with an alias left unchanged by `exclude`. Otherwise relabeling the
clone could overwrite the preserved base alias.

Trace: E-4, C-1.

## PO-5: RHS Non-Mutation Frame Condition

`combine()` must not mutate `rhs`. Any prefix bump used only to prepare merging
must happen on a clone whose mutable alias-list structures are isolated from
the original RHS query.

Trace: E-5.

## PO-6: Deterministic Prefix Discipline

The fix must reuse deterministic prefix generation and existing subquery-prefix
avoidance rather than randomizing aliases or globally changing `table_alias()`.

Trace: E-3, E-6.

## PO-7: Existing Call Compatibility

Existing `bump_prefix(outer_query)` callers must continue to get the same
full-relabeling behavior when no `exclude` argument is supplied.

Trace: public compatibility audit in `SPEC.md`.

## PO-8: Proof Boundary

The FVK proof must be labeled constructed, not machine-checked, and must not be
used to remove tests. Test recommendations remain conditional on future
`kprove` success.

Trace: FVK honesty gate.
