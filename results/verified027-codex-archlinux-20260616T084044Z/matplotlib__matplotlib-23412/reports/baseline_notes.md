# Baseline Notes

## Root cause

`Patch.set_linestyle()` already accepts dash tuples of the form
`(offset, onoffseq)` and stores the parsed, linewidth-scaled result in
`self._dash_pattern`. However, `Patch.draw()` wrapped drawing in a temporary
attribute override that replaced the stored dash offset with `0`:

```python
self._dash_pattern = (0, self._dash_pattern[1])
```

As a result, rectangle, ellipse, and other patches using the base `Patch.draw()`
always rendered dashed edges from offset zero, even when a non-zero offset was
provided by the user.

## Files changed

`repo/lib/matplotlib/patches.py`

Removed the temporary `_dash_pattern` override from `Patch.draw()`. The draw
method now uses `_bind_draw_path_function()` directly, allowing the dash pattern
stored by `set_linestyle()` and `set_linewidth()` to reach the graphics context
unchanged. This keeps the existing dash parsing and linewidth scaling behavior
while making patch rendering honor non-zero dash offsets.

## Assumptions

The intended behavior is that patch dash tuples should match the documented
`(offset, onoffseq)` contract and the behavior of `Line2D`, because the setter
already preserves the offset and the renderer graphics context already supports
dash offsets.

I assumed no compatibility guard or warning is needed for users who previously
passed a non-zero offset but relied on patches ignoring it. That behavior was
the reported bug, and preserving it would keep the documented tuple offset from
working.

## Alternatives considered

Updating only the docstring to say patch dash offsets are ignored was rejected
because the implementation already stores offsets correctly, the lower-level
renderer API accepts them, and the issue discussion indicates there is little
reason to keep ignoring them.

Changing `set_linestyle()` or dash scaling was rejected because the offset is
not lost there. The offset is discarded only during `Patch.draw()`.

Adding special handling for individual patch subclasses was rejected because the
bug affects the shared base drawing path. Fixing `Patch.draw()` addresses the
affected subclasses with the smallest change.
