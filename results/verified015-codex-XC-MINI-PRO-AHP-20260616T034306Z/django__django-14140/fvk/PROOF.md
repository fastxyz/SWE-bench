# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Unit Under Proof

`repo/django/db/models/query_utils.py:83`:

```python
def deconstruct(self):
    path = '%s.%s' % (self.__class__.__module__, self.__class__.__name__)
    if path.startswith('django.db.models.query_utils'):
        path = path.replace('django.db.models.query_utils', 'django.db.models')
    args, kwargs = (), {}
    if len(self.children) == 1 and getattr(self.children[0], 'conditional', False) is False:
        child = self.children[0]
        kwargs = {child[0]: child[1]}
    else:
        args = tuple(self.children)
        if self.connector != self.default:
            kwargs = {'_connector': self.connector}
    if self.negated:
        kwargs['_negated'] = True
    return path, args, kwargs
```

The path canonicalization is unchanged and deterministic for `Q`, producing
`django.db.models.Q`.

## Branch Proof

### PO-1: Single non-conditional lookup child

Given `children == [child]` and `conditional(child) is False`, the branch guard
is true. The implementation binds `child = self.children[0]` and constructs
`kwargs = {child[0]: child[1]}`. Under PO-1's precondition, `child[0]` and
`child[1]` are defined as the lookup key and value.

With default connector and no negation, no later metadata writes occur. The
returned triple is therefore:

```text
("django.db.models.Q", (), {lookup_key(child): lookup_value(child)})
```

This proves the ordinary `Q(x=1)` shape and preserves the public test.

### PO-2: Single conditional child

Given `children == [child]` and `conditional(child) is True`, the branch guard:

```text
len(children) == 1 and conditional(child) is False
```

is false. Execution therefore takes the `else` branch, assigns
`args = tuple(children)`, and never evaluates `child[0]` or `child[1]`.

With default connector and no negation, the returned triple is:

```text
("django.db.models.Q", (child,), {})
```

This discharges the reported `Exists(...)` case because `Exists` inherits the
normal expression `conditional` protocol and has a boolean output field.

### PO-3: Single nested `Q` child

`Q` has class attribute `conditional = True`. A nested `Q` child therefore makes
the single-child kwargs guard false for the same reason as PO-2. The child is
preserved in positional `args`, proving the existing nested-`Q` behavior.

### PO-4: Multiple children

Given `len(children) != 1`, the first conjunct of the kwargs guard is false.
Execution takes the positional branch and returns `tuple(children)` as `args`.
With default connector and no negation, `kwargs` remains `{}`.

### PO-5: Connector and negation metadata on positional branch

On every positional-branch path, the implementation checks connector metadata
before negation:

1. If `self.connector != self.default`, it assigns
   `kwargs = {'_connector': self.connector}`.
2. If `self.negated`, it writes `kwargs['_negated'] = True`.

These writes are to distinct keys. Therefore a non-default connector is
preserved, negation is preserved, and both are preserved together when both
conditions hold.

This matters for the fix because a single conditional child now reaches the
positional branch.

## Empty-`Q` Combination Consequence

`Q._combine()` clones a non-empty `Q` through `self.deconstruct()` when the other
operand is empty. For `self == Q(conditional_child)`, PO-2 shows
`deconstruct()` returns `(child,)` without indexing the child. Reconstructing via
`type(self)(*args, **kwargs)` produces a `Q` with the same conditional child,
rather than raising `TypeError`.

This proves the clone path that made conditional-expression combination fragile.

## Residual Scope

PO-6 records that arbitrary non-conditional, non-lookup children are not proven.
The proof does not claim to fix `Q(False).deconstruct()`. That is intentional:
the public hint narrows the accepted repair to conditional expressions and
preserving the current `deconstruct()` format.

## Test Guidance

No tests were run or modified. Because the proof is constructed but not
machine-checked, no test should be removed based on this artifact. Useful tests
to add in the fixed test suite would cover:

- `Q(Exists(...)).deconstruct()` returns the expression in `args`.
- `~Q(Exists(...)).deconstruct()` preserves `_negated`.
- An existing single-lookup `Q` still deconstructs to kwargs.
- A nested `Q` child remains positional.

