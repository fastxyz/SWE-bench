# Proof Obligations

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Obligations

### PO-1: Domain

For every yielded iterator position, prove under `N >= 0`, `W > 0`, and
`0 <= I < N`.

Source: E-9 and the semantics of iterating over `self.window_labels`.

Status: DISCHARGED by code inspection and K preconditions.

### PO-2: Preserve non-centered right-aligned bounds

When `center` is false-like, V1 must yield:

`start = max(I - (W - 1), 0)`, `stop = min(I + 1, N)`.

Source: E-5, E-7.

Status: DISCHARGED by `rolling-iter-spec.k` claim 1.

### PO-3: Centered bounds match `Variable.rolling_window`

When `center=True`, V1 must yield:

`start = max(I - (W // 2), 0)`,
`stop = min(I + ((W - 1) // 2) + 1, N)`.

Source: E-1, E-2, E-4, E-6.

Status: DISCHARGED by `rolling-iter-spec.k` claim 2.

### PO-4: V1 offset arithmetic is equivalent to centered padding

V1 computes:

`offset = (W - 1) // 2`

`stop0 = I + 1 + offset`

`start0 = stop0 - W`

Prove:

`start0 == I - (W // 2)` and
`stop0 == I + ((W - 1) // 2) + 1`.

Source: E-6, E-8.

Status: DISCHARGED by the simplification lemma in `rolling-iter-spec.k` and the
case split `W=2q` / `W=2q+1` in `PROOF.md`.

### PO-5: Bounds are clipped to the valid data extent

For both centered and non-centered paths, prove:

`0 <= start <= N` and `0 <= stop <= N`.

Source: iterator slices must remain valid views of the original object.

Status: DISCHARGED by use of `np.maximum(starts, 0)` and
`np.minimum(stops, len(self.window_labels))`.

### PO-6: Labels are preserved

For each yielded position `I`, the label must remain
`self.window_labels[I]`.

Source: E-4, E-5, existing public iterator behavior.

Status: DISCHARGED by code inspection; V1 does not change the label source or
iteration order.

### PO-7: `min_periods` masking stays tied to the selected window

After selecting the corrected bounds, masking must still use
`window.count(dim=dim0) >= self.min_periods`.

Source: E-9 and existing rolling iterator semantics.

Status: DISCHARGED by code inspection; V1 only changes bounds, then applies the
same count/mask code to the selected window.

### PO-8: Public compatibility is preserved except for the intended fix

The method signature, yield shape, and multidimensional error behavior must not
change.

Source: IS-5 and `PUBLIC_COMPATIBILITY_AUDIT.md`.

Status: DISCHARGED by source diff inspection.

### PO-9: Honesty gate

The proof must be labeled constructed, not machine-checked, and no tests may be
removed or modified.

Source: FVK docs and task constraints.

Status: DISCHARGED by artifact labels and no test-file edits.

## Machine-Check Commands

These commands are artifacts only and were not executed:

```sh
cd fvk
kompile mini-python-rolling.k --backend haskell
kast --backend haskell rolling-iter-spec.k
kprove rolling-iter-spec.k
```

Expected machine-check result if the K environment is later available:
`kprove` returns `#Top`.
