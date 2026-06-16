# Baseline Notes

## Root cause

`Q.deconstruct()` has a special case for a `Q` object with exactly one child:
it serializes the child as keyword arguments instead of positional arguments.
That path assumed the child was a lookup pair and indexed it as `child[0]` and
`child[1]`.

Boolean expressions such as `Exists(...)` are valid conditional expressions and
can be combined with `Q` objects. When such an expression is wrapped in a
single-child `Q`, or when combining it with an empty `Q` causes Django to clone
through `deconstruct()`, the expression is not subscriptable. The single-child
special case therefore raises `TypeError` before the expression can be preserved
as a positional child.

## Changed files

`repo/django/db/models/query_utils.py`

Updated `Q.deconstruct()` so the single-child keyword-argument special case is
used only when the child is not a conditional expression. Conditional children,
including `Exists(...)`, now use the existing positional-argument path. This
preserves existing deconstruction output for ordinary single lookup conditions
such as `Q(x=1)` while avoiding indexing into expression objects.

## Assumptions and alternatives

I assumed the compatibility of the existing `Q(x=1).deconstruct()` format should
be preserved because the current public tests assert that shape and the issue
discussion mentions a backward-compatible approach.

I considered removing the single-child special case entirely. That would make
all `Q` deconstruction output more consistent, but it would also change the
documented-by-tests output for ordinary one-condition `Q` objects, so I rejected
it as broader than necessary.

I also considered validating that the child is specifically a length-two tuple
before using the keyword path. That would protect additional unsupported inputs,
but it would change behavior for other currently accepted subscriptable lookup
pairs. The reported crash involves conditional expressions, and Django already
uses the `conditional` marker for this distinction, so the narrower guard is the
targeted fix.
