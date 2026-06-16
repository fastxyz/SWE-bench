# Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## F1 - Confirmed Root Cause: Override Returned the First Attrs Mapping

Input: two datasets with attrs `{"a": "b"}` and `{"a": "c"}`, merged with `combine_attrs="override"`.

Observed in the public issue before V1: mutating `xds3.attrs["a"] = "d"` also changes `xds1.attrs["a"]` to `"d"`.

Expected by public intent: `xds3.attrs` starts with `{"a": "b"}`, but mutating `xds3.attrs` leaves `xds1.attrs` unchanged.

Trace: PO1, PO2, PO3. The old `return variable_attrs[0]` violated PO2; V1's `return dict(variable_attrs[0])` satisfies it.

Classification: code bug fixed by V1.

Recommended action: keep V1 source change.

## F2 - No Additional Source Change: Shallow Copy Is the Intended Boundary

Input: attrs contain a mutable value object, for example `{"nested": some_list}`.

Observed under V1 by source reasoning: the result attrs dictionary is fresh, but `result.attrs["nested"]` and `source.attrs["nested"]` refer to the same value object.

Expected by public intent: only the attrs mapping object must be independent. The issue mutates a top-level attrs key, and the suggested fix plus sibling branches use `dict(...)`.

Trace: PO5.

Classification: residual behavior outside the reported contract, not a code bug.

Recommended action: no source change. Do not replace the shallow copy with `copy.deepcopy`.

## F3 - Empty Attrs Return `None` Remains Acceptable

Input: `merge_attrs([], "override")`.

Observed by source reasoning: returns `None`.

Expected for this audit: no source/result attrs alias exists because there is no source attrs mapping. Existing internal convention is preserved.

Trace: PO6.

Classification: boundary behavior, not a code bug for this issue.

Recommended action: no source change.

## F4 - Compatibility Audit Found No Public API Break

Input: public callers `merge`, `concat`, and combine paths passing existing `combine_attrs` strings.

Observed by source reasoning: signatures and mode strings are unchanged; the returned attrs value remains a mapping for non-empty preserving modes.

Expected by public intent: repair aliasing without changing public API.

Trace: PO4 and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

Classification: confirmed compatibility.

Recommended action: no source change.

## Proof-Derived Findings From `/verify`

The constructed proof for `MERGE-ATTRS-OVERRIDE-COPY` closes under the mini semantics if the allocator id for the result is distinct from the first source id. In Python, `dict(existing_dict)` supplies that allocation. No proof-derived code bug was found.

Residual proof risk: the proof is constructed but not machine-checked. The exact `kompile`, `kast`, and `kprove` commands are recorded in `fvk/PROOF.md` and must be run in an environment with K before treating test removal as justified.
