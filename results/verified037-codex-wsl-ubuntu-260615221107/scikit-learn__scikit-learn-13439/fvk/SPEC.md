# FVK Spec

Status: constructed, not machine-checked.

## Target

The audited production change is `Pipeline.__len__` in
`repo/sklearn/pipeline.py`.

V1 implementation:

```python
def __len__(self):
    """Returns the length of the Pipeline."""
    return len(self.steps)
```

## Public Intent Ledger

| ID | Evidence | Obligation |
| --- | --- | --- |
| E1 | Issue title: "Pipeline should implement __len__" | `len(pipe)` must be defined. |
| E2 | Issue description: "`pipe[:len(pipe)]` raises an error" | The full-prefix slice path must be evaluable. |
| E3 | Reproducer constructs a two-step pipeline and calls `len(pipe)` | A two-step pipeline should have length `2` by Python length convention. |
| E4 | `Pipeline` docstring says `steps : list` and describes a list of step tuples | Length is the cardinality of `self.steps`. |
| E5 | Existing `__getitem__` slices via `self.steps[ind]` | Full-prefix slicing should preserve the complete step sequence. |
| E6 | Public hints advise adding as little as possible and not adding `__iter__` | Add only `__len__`; do not broaden the sequence protocol. |
| E7 | `_validate_steps` requires a final estimator from `self.steps` | Valid constructed pipelines are non-empty, limiting truthiness compatibility risk. |

The standalone ledger is mirrored in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

## Formal Model

`fvk/mini-python.k` defines a minimal pipeline fragment:

* `pipeline(N)` represents a `Pipeline` whose `steps` sequence has cardinality
  `N`.
* `pipelineLen(pipeline(N))` represents `Pipeline.__len__`.
* `slicePrefix(pipeline(N), K)` represents the existing prefix slice behavior
  over the same `steps` sequence.

This abstraction keeps the property under verification, namely step
cardinality, observable. It distinguishes a passing instance such as
`pipeline(2)` returning `2` from a failing pre-V1 instance where `len(pipe)` has
no method and cannot produce the cardinality at all.

## Claims

### LEN

For all `N >= 0`:

```k
pipelineLen(pipeline(N)) => N
```

This proves `len(pipe)` returns the cardinality of `pipe.steps`.

### FULL-SLICE-AFTER-LEN

For all `N >= 0`:

```k
slicePrefix(pipeline(N), pipelineLen(pipeline(N))) => pipeline(N)
```

This proves the issue path `pipe[:len(pipe)]` reaches the existing full-prefix
slice result once `len(pipe)` is defined.

## Side Conditions

`N >= 0` is a default-domain cardinality condition. The valid public
constructor path is narrower (`N >= 1`), but the method body is correct for any
sized sequence with non-negative length.

## Adequacy

The adequacy round-trip passes:

* `fvk/INTENT_SPEC.md` states the public requirements without relying on V1.
* `fvk/FORMAL_SPEC_ENGLISH.md` paraphrases the K claims.
* `fvk/SPEC_AUDIT.md` marks every paraphrased claim as entailed by public
  intent or named default-domain assumptions.
* `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` finds no unhandled public compatibility
  issue.
