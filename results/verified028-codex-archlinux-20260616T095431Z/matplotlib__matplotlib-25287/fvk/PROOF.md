# PROOF.md

Status: constructed, not machine-checked.  No tests, Python, `kompile`, or
`kprove` were run.

## What Is Proved

For each `T` in `{xtick, ytick}`, the V1 implementation satisfies:

```text
offsetText.color =
    rcParams[T.color]       if rcParams[T.labelcolor] == "inherit"
    rcParams[T.labelcolor]  otherwise
```

The same resolver is used for default tick label color, so the rcParam path for
offset text and tick labels is consistent.

## Symbolic Proof Sketch

### Resolver

The helper introduced by V1 is:

```text
color = rcParams[T.labelcolor]
if color == "inherit":
    color = rcParams[T.color]
return color
```

Case split:

- If `rcParams[T.labelcolor] != "inherit"`, the conditional is skipped and the
  returned value is `rcParams[T.labelcolor]`.  This discharges PO-001.
- If `rcParams[T.labelcolor] == "inherit"`, the conditional assigns
  `rcParams[T.color]` and returns it.  This discharges PO-002.

### X-axis Offset Text

`XAxis._init()` calls:

```text
offsetText.set(..., color=_get_tick_label_color("xtick"))
```

By PO-001/PO-002, the argument passed to `Text.set(color=...)` is exactly
`Resolve(RC, "xtick")`.  `Text.set` stores the supplied color on the text
artist, so the x-axis offset text postcondition follows.  This discharges
PO-003.

### Y-axis Offset Text

`YAxis._init()` calls:

```text
offsetText.set(..., color=_get_tick_label_color("ytick"))
```

By PO-001/PO-002, the argument passed to `Text.set(color=...)` is exactly
`Resolve(RC, "ytick")`.  `Text.set` stores the supplied color on the text
artist, so the y-axis offset text postcondition follows.  This discharges
PO-004.

### Tick Label Consistency

When no explicit `labelcolor` argument is supplied, `Tick.__init__` now starts
with:

```text
labelcolor = _get_tick_label_color(name)
```

It then creates both tick label `Text` instances with `color=labelcolor`.  Since
`name` is `xtick` for `XTick` and `ytick` for `YTick`, tick labels and offset
text share the same resolver.  This discharges PO-005.

### Frame and Compatibility Conditions

The diff leaves all non-color `offsetText.set(...)` arguments unchanged and
does not change public signatures or virtual dispatch.  The new helper is
private and called only inside `axis.py`.  This discharges PO-006 and PO-007.

## Adequacy Gate

The formal English matches the intent ledger:

- Prompt intent requires `*.labelcolor` to control the exponent/offset label
  when explicitly set.  PO-001, PO-003, and PO-004 prove that behavior.
- Public rcParam docs require `"inherit"` to fall back to `*.color`.  PO-002,
  PO-003, and PO-004 prove that behavior.
- The issue names both x and y rcParams.  PO-003 and PO-004 cover both axes.
- Compatibility and frame obligations are explicit in PO-006 and PO-007.

No formal claim is candidate-derived without public intent support, and no
required behavior is omitted from the proof scope.

## Machine-Check Commands

These commands are intentionally recorded, not executed:

```sh
kompile fvk/mini-axis-color.k --backend haskell
kast --backend haskell fvk/axis-offset-color-spec.k
kprove fvk/axis-offset-color-spec.k
```

Expected machine-check outcome: `kprove` returns `#Top` for the stated claims.

## Test Redundancy Recommendation

No test files should be removed in this task.  The proof is constructed but not
machine-checked, and the user explicitly fixed the test suite as hidden.  After
machine checking, tests that only assert the covered rcParam resolver behavior
could be considered redundant; rendering, integration, and backend-specific
visual tests should remain.

## Residual Risk

- The proof is partial correctness over a small K fragment, not a full Python or
  Matplotlib semantics proof.
- Backend rendering pixels are not modeled; the proof covers the artist color
  state passed to `offsetText`.
- The proof was not machine-checked in this session.
