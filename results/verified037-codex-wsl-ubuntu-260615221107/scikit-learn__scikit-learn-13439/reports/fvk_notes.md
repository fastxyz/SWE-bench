# FVK Notes

## Decision: keep V1 source unchanged

I kept `repo/sklearn/pipeline.py` unchanged after the FVK audit. The V1 method

```python
def __len__(self):
    """Returns the length of the Pipeline."""
    return len(self.steps)
```

is justified by F-001 in `fvk/FINDINGS.md` and PO-1/PO-2 in
`fvk/PROOF_OBLIGATIONS.md`: the missing behavior was `len(pipe)` and the
dependent full slice `pipe[:len(pipe)]`, and returning `len(self.steps)`
discharges both because `__getitem__` already slices over `self.steps`.

## Decision: do not add `__iter__` or other sequence methods

I made no broader sequence-protocol edits. This is justified by F-002 and PO-3:
the public hints explicitly prefer adding as little as possible and not adding
other sequence methods such as `__iter__`.

## Decision: no extra guard for empty `steps`

I did not add a guard or special case for empty `steps`. This is justified by
F-003 and PO-4: valid constructed `Pipeline` instances are non-empty, so adding
`__len__` does not make valid objects falsey. If a user mutates `steps` to an
empty sized sequence, the method still returns the actual cardinality.

## Decision: produce supporting FVK artifacts

In addition to the five benchmark-required files, I wrote the supporting K and
adequacy artifacts under `fvk/`. This is justified by PO-5 and by the FVK
artifact contract: the proof obligations must be tied to public intent rather
than merely restating the candidate patch.

## Verification status

No tests, Python code, or K tooling were run. The proof is constructed, not
machine-checked, as recorded in `fvk/PROOF.md`. No proof-derived source defect
was found, so V1 stands.
