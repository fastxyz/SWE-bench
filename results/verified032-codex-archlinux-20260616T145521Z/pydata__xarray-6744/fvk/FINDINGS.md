# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Findings

### FI-1: V0 ignored `center` in iterator bounds

Classification: code bug in the baseline behavior fixed by V1.

Evidence: E-1, E-2, E-3.

Concrete input: `N=9`, `W=3`, `center=True`.

Observed before V1: iterator bounds were right-aligned, producing manual means
`[nan, nan, 2, 3, 4, 5, 6, 7, 8]`.

Expected: centered bounds should produce manual means
`[nan, 2, 3, 4, 5, 6, 7, 8, nan]`.

Resolution: V1 changes the bounds by adding the centered right-padding offset
before clipping.

### FI-2: V1 discharges the centered odd-window issue witness

Classification: confirmation.

Evidence: PO-3, PO-4, concrete K claims.

For `N=9`, `W=3`, V1 gives bounds `[0:2]`, `[0:3]`, ..., `[7:9]`. With default
`min_periods=3`, the first and last windows mask to `nan`, and interior windows
reduce to `2` through `8`, matching the public expected sequence.

### FI-3: V1 also handles even centered windows under xarray's convention

Classification: confirmation and corner-case audit.

Evidence: E-6, E-8, PO-4.

For `W=2q`, `Variable.rolling_window` uses left padding `q` and right padding
`q-1`. V1's offset `(W - 1) // 2` is `q-1`, so
`start = I + 1 + (q - 1) - 2q = I - q`, matching the construction path.

Rejected alternative: using `W // 2` as the iterator offset. That would shift
even windows one position too far right and fail PO-3.

### FI-4: Edge clipping and `min_periods` masking remain coherent

Classification: confirmation.

Evidence: IS-4, PO-5, PO-7.

The iterator still yields slices of the original object rather than padded
temporary arrays. Centered edge slices are shorter at the leading and trailing
edges, and the existing `counts >= self.min_periods` mask gives the same
aggregate validity as padded `nan` windows.

### FI-5: Public API compatibility has no blocker

Classification: compatibility finding.

Evidence: PO-8 and `PUBLIC_COMPATIBILITY_AUDIT.md`.

The patch does not change the iterator signature, yielded tuple shape, labels,
or multidimensional error behavior. The only semantic change is the intended
`center=True` window alignment.

### FI-6: Proof is constructed only, not machine-checked

Classification: proof honesty / residual risk.

Evidence: PO-9.

The K files and proof commands are emitted but not run. Test removal is not
recommended unless the commands later return `#Top`; in this task, test files
must remain unchanged regardless.

## Proof-Derived Findings From `/verify`

No additional code bug was found beyond FI-1. The only proof side condition
needed for the arithmetic claims is the public/code precondition `W > 0`, which
is already enforced by `Rolling.__init__`.
