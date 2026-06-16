# Formal Spec In English

Status: constructed for FVK audit; not machine-checked.

## Claim C-001: `DRAGGABLE-GETSTATE-NO-CANVAS`

For any draggable helper state, calling the modeled `__getstate__` returns a
state map with no legacy `canvas` key, with `_canvas` set to `None`, with
`got_artist` set to `False`, and with `background` removed. Therefore the helper
pickle state contains no direct live backend canvas.

## Claim C-002: `DRAGGABLE-SETSTATE-CANVAS-DEFAULT`

For any restored helper state, calling the modeled `__setstate__` removes any
legacy `canvas` key and guarantees that `_canvas` exists. If the serialized
state did not carry `_canvas`, the restored value is `None`.

## Claim C-003: `DRAGGABLE-CANVAS-LAZY-RESTORE`

For a restored helper with `_canvas = None` and a still-parented reference
artist, the modeled `canvas` property resolves to the current canvas attached to
the artist's figure. This means the helper can reconnect behavior to the new
post-unpickle canvas instead of preserving the old backend canvas.

## Claim C-004: `DRAGGABLE-BLIT-SAFE-WHEN-NO-CANVAS`

For a helper with no resolvable canvas, the modeled `_use_blitting` predicate is
false. This prevents blit-only methods from being selected when no current
canvas exists.

## Claim C-005: `FIGURE-PICKLE-WITH-DRAGGABLE`

For a modeled figure state that already removes its own `canvas`, and whose
draggable legend or annotation helpers are serialized through C-001, the
reachable serialized object graph contains no live backend canvas through the
draggable helper path.
