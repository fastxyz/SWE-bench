# FVK Findings

Status: constructed, not machine-checked.

## F1 - V1 shifted old positional constructor arguments

Classification: code bug in V1, fixed in V2.

Input:

```python
IsolationForest(100, "auto", "legacy", 1., False, 3, "new", 0, 1)
```

Expected from the pre-existing public signature:

```text
n_jobs=3
behaviour="new"
random_state=0
verbose=1
warm_start=False
```

Observed under V1:

```text
warm_start=3
n_jobs="new"
behaviour=0
random_state=1
verbose=0
```

Cause: V1 inserted `warm_start` before `n_jobs`. Because this version's
constructor is not keyword-only, that is a public API regression.

Resolution: V2 appends `warm_start=False` after `verbose=0`, preserving the old
positional mapping while still enabling `IsolationForest(warm_start=True)`.

Trace: PO4, `IFOREST-POSITIONAL-COMPAT`.

## F2 - Original issue gap: constructor did not expose inherited warm-start behavior

Classification: code bug in the baseline, fixed by V1 and retained in V2.

Input:

```python
IsolationForest(warm_start=True)
```

Observed before the fix:

```text
unexpected keyword argument `warm_start`
```

Expected from public intent:

```text
constructor accepts warm_start=True and configures inherited BaseBagging state
```

Resolution: V2 includes `warm_start=False` in the signature and forwards
`warm_start=warm_start` to `BaseBagging.__init__`.

Trace: PO1, PO2, `IFOREST-EXPLICIT-WARM-START`.

## F3 - No IsolationForest-specific warm-start algorithm was required

Classification: confirmed non-bug.

Input:

```text
IsolationForest(..., warm_start=W)
```

Expected from public intent:

```text
reuse the inherited BaseBagging warm-start behavior
```

Observed in source:

```text
BaseBagging.__init__ stores self.warm_start and BaseBagging._fit branches on it
```

Resolution: V2 keeps the implementation minimal by forwarding the constructor
value and not adding new fitting logic.

Trace: PO2, PO3.

## Residual proof limitation

The proof artifacts are constructed but not machine-checked. This is an
environment limitation, not a code finding. The exact `kompile` and `kprove`
commands are recorded in `PROOF.md`.
