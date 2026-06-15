# Intent Spec

Status: constructed from public evidence only; no tests, Python, or K tooling were run.

## Required Behaviors

I1. When `order_by()` targets a parent or related model and that related model's
`Meta.ordering` contains an expression item, query compilation must not pass
that expression item to the string-only `get_order_dir()` helper.

I2. `OrderBy(F(...))` entries in related model `Meta.ordering` must compile as
ordering expressions rather than crashing because the item is not subscriptable.

I3. Non-`OrderBy` expressions such as `Lower('name')` in related model
`Meta.ordering` must be accepted by the same expression-ordering contract that
top-level `get_order_by()` already applies: wrap in ascending `OrderBy` by
default, and reverse when the enclosing relation ordering is descending.

I4. Field references inside the related model's ordering expression must be
interpreted relative to the related model currently being expanded, not
relative to the root query model.

I5. Existing string ordering behavior must be preserved: string items still use
`get_order_dir()`, relation default ordering still recurses, and infinite-loop
detection remains in force.

I6. The public method shape of `find_ordering_name()` and query compilation must
remain compatible with existing callers.

I7. The verified domain is expression ordering trees made from Django expression
objects whose field-reference leaves are plain `F()` nodes and whose expression
children either support the normal `copy()` plus source-expression protocol or
are non-expression child nodes intentionally delegated to their own resolver.
Conditional `Q` lookup strings inside `Case/When` are recorded as residual risk
because resolving those lookups relative to an arbitrary related alias requires
a deeper query-resolution API than the reported `OrderBy`/`Lower` failure needs.
