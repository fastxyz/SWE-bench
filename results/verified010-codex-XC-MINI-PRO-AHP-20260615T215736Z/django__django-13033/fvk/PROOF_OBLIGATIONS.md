# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Final-segment attname recognition

For any valid ordering path whose resolved final field is a relation field `F`,
if `F.attname == pieces[-1]`, then `find_ordering_name()` must classify the
ordering as a direct column ordering rather than expanding `opts.ordering`.

Evidence:
SPEC E-002, E-005, E-006.

V1 discharge:
The predicate compares `getattr(field, 'attname', None) != pieces[-1]`; when the
final piece is the attname, the related-ordering branch is skipped.

## PO-002: Multi-hop `record__root_id` uses the attname rule

For the issue's model shape, `_setup_joins(["record", "root_id"], ...)`
resolves the final lookup segment `root_id` to the `root` `ForeignKey`, whose
`attname` is `root_id`. Therefore PO-001 applies to `record__root_id`.

Evidence:
SPEC E-002, E-007.

V1 discharge:
`pieces[-1]` is `root_id`, so V1 skips default-order expansion even though the
whole lookup name is `record__root_id`.

## PO-003: Direct classification permits join trimming to the FK column

When related-default expansion is skipped for `record__root_id`,
`query.trim_joins()` receives the target field from the final direct FK join.
Because direct FK joins can be trimmed when the target column is already present
on the previous table, the self-join to `root` is removed and the target becomes
the local `root_id` column on the `record` alias.

Evidence:
SPEC E-001, E-002; `trim_joins()` source comment: direct joins are trimmed when
the target column is already in the previous table.

V1 discharge:
The patch reaches the existing direct/trim branch; no join-trimming edit is
needed.

## PO-004: Explicit ordering direction applies to the direct FK column

For direct FK-column ordering, the `descending` flag computed from the original
user string must be attached to `OrderBy(transform_function(target, alias),
descending=descending)`.

Evidence:
SPEC INT-004 and the issue's `-record__root_id` inversion example.

V1 discharge:
By skipping related-default expansion, V1 avoids recursive `get_order_dir()` on
`OneModel.Meta.ordering = ("-id",)` and uses the original `descending` flag on
the FK column.

## PO-005: Relation-name ordering remains expanded

For `record__root`, the final lookup segment is `root`, not `root_id`; if the
related model has `Meta.ordering`, `find_ordering_name()` must still expand to
that ordering.

Evidence:
SPEC E-003, E-004.

V1 discharge:
`getattr(field, 'attname', None) != pieces[-1]` remains true for `root_id !=
root`, so the expansion branch is preserved.

## PO-006: Direct one-hop FK attname behavior is unchanged

For `author_id`, `pieces[-1] == name == "author_id"`. V1 must preserve the
existing behavior covered by the public `test_order_by_fk_attname`.

Evidence:
SPEC E-006.

V1 discharge:
For one-segment paths, replacing `name` with `pieces[-1]` is behaviorally
identical.

## PO-007: Non-relation, no-related-ordering, and `pk` paths remain framed

The patch must not change paths where `field.is_relation` is false,
`opts.ordering` is empty, or the `pk` shortcut applies.

Evidence:
SPEC INT-006 and compiler branch comment.

V1 discharge:
The patch changes only the attname comparison operand inside a conjunction. All
other conjuncts and the `pk` check are unchanged.

## PO-008: API compatibility and recursion guard remain framed

The patch must not alter the signature, return shape, recursion behavior, or
infinite-loop protection of `find_ordering_name()`.

Evidence:
SPEC compatibility audit and FINDINGS F-005.

V1 discharge:
No callsite-facing symbol changed, and `already_seen` logic is untouched.
