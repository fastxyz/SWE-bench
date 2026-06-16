# Iteration Guidance

Status: V1 stands unchanged.

## Decision

Do not revise `repo/sklearn/pipeline.py` beyond the existing V1 patch.

## Rationale

* F-001 is closed by PO-1 and PO-2: `__len__` returns `len(self.steps)`, and the
  issue path `pipe[:len(pipe)]` becomes evaluable through existing slice logic.
* F-002 and PO-3 confirm the patch should remain minimal and should not add
  `__iter__` or other sequence methods.
* F-003 and PO-4 confirm no public compatibility issue blocks the change for
  valid `Pipeline` instances.
* PO-5 and the adequacy files confirm the proof obligations match public
  intent.

## Recommended follow-up tests

Do not edit tests in this benchmark. In a normal development pass, the focused
tests would be:

```python
assert len(pipe) == len(pipe.steps)
assert pipe[:len(pipe)].steps == pipe.steps
```

These tests should be kept until the emitted K commands are actually
machine-checked.

## Machine-check follow-up

Run the commands recorded in `fvk/PROOF.md` when a K environment is available.
Until `kprove` returns `#Top`, the proof remains constructed, not
machine-checked.
