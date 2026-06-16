# Baseline Notes

## Root cause

`Pipeline` already implemented `__getitem__` for integer, name, and slice access,
but it did not implement `__len__`. As a result, calling `len(pipe)` raised a
`TypeError`, and expressions that depend on it, such as `pipe[:len(pipe)]`,
failed before the existing slice handling could run.

## Files changed

`repo/sklearn/pipeline.py`

Added `Pipeline.__len__`, returning `len(self.steps)`. This matches the existing
indexing and slicing behavior, which operate directly on `self.steps`, and keeps
the change limited to the missing sequence protocol method requested by the
issue.

## Assumptions and alternatives considered

I assumed the length of a `Pipeline` should be the number of configured steps,
including passthrough or `None` steps, because indexing and slicing are defined
over `self.steps` rather than over the filtered `_iter()` view.

I considered adding broader sequence behavior, such as `__iter__`, but rejected
that because the public hints explicitly favored adding as little as possible and
not implementing other sequence methods. I also considered changing slice
handling in `__getitem__`, but the failing expression depends on `len(pipe)`, and
the existing slice logic already works once a length is available.
