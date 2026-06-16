# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | prompt | "hist() no longer respects range=... when density=True" | `density=True` must not drop or override the user-specified range. | Encoded by PO-001 and claim `hist-range-density`. |
| E-002 | prompt | `plt.hist(np.random.rand(10), "auto", range=(0, 1), density=True)` | The audited path is a non-empty single dataset with automatic bins, explicit range, density true, and not stacked. | Encoded by PO-001 and I-001. |
| E-003 | prompt | "Expected outcome: Some array where the first value is 0 and the last one is 1." | Automatic bin edges must span the provided range endpoints. | Encoded as the postcondition that `range` reaches `np.histogram`; NumPy endpoint generation is treated as an external library contract. |
| E-004 | prompt | "Note that this bug doesn't happen if density=False." | Preserve the existing range-respecting non-density path. | Encoded by PO-002 and claim `hist-range-no-density`. |
| E-005 | docstring | "The lower and upper range of the bins. Lower and upper outliers are ignored." | `range` is a bin-domain control, not a normalization control. | Supports I-001 and I-002. |
| E-006 | docstring | "If bins is a sequence or range is specified, autoscaling is based on the specified bin range instead of the range of x." | When range is specified, the bin range is the specified value. | Supports I-001. |
| E-007 | docstring | "If True, the first element of the return tuple will be the counts normalized..." | `density` affects count scaling. It does not state a change to range semantics. | Supports I-002. |
| E-008 | docstring | "If either is set, then that value will be used." | `normed` remains an effective-density synonym in this code path. | Encoded by PO-005 and claim `hist-range-normed`. |
| E-009 | source/test | `if stacked and density:` manual normalization plus public stacked-density tests | Stacked density must not be changed to per-dataset `np.histogram(..., density=True)` normalization. | Encoded by PO-003 and claim `hist-stacked-frame`. |
| E-010 | implementation | `hist_kwargs['range'] = bin_range` on the single/empty path and per-dataset `np.histogram(..., **hist_kwargs)` | Implementation mechanism that must carry range through the kwargs dict. | Used in the K transition model, not as intent by itself. |
| E-011 | implementation | V1 changed `hist_kwargs = dict(density=density)` to `hist_kwargs['density'] = density` | Candidate mechanism for preserving existing kwargs while adding density. | Audited by PO-001 through PO-005. |

## Suspect legacy evidence

S-001: The issue's actual output starts near the data minimum and ends near the
data maximum instead of at `(0, 1)`. This output is explicitly described as
buggy, so it is not used as an expected behavior.
