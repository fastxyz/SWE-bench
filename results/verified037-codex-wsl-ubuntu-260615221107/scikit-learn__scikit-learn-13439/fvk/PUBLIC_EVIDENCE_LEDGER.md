# Public Evidence Ledger

| ID | Source | Quoted evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "Pipeline should implement __len__" | `Pipeline` exposes `__len__`; `len(pipe)` no longer raises because the method is missing. | Encoded in `LEN` claim. |
| E2 | prompt | "With the new indexing support `pipe[:len(pipe)]` raises an error." | Full-prefix slicing through `len(pipe)` should be evaluable. | Encoded in `FULL-SLICE-AFTER-LEN` claim. |
| E3 | prompt example | `Pipeline([('anova', anova_filter), ('svc', clf)])` followed by `len(pipe)` | A two-step pipeline is an in-domain concrete case; expected length follows from Python length convention. | Covered by `LEN` with `N = 2`. |
| E4 | source docstring | "`steps : list`" and "List of (name, transform) tuples" | Length is the cardinality of `self.steps`. | Encoded in `LEN` claim. |
| E5 | source code | `__getitem__` returns `self.__class__(self.steps[ind])` for slices. | Existing slice behavior is defined over `self.steps`; the full-prefix slice preserves all steps. | Encoded in `FULL-SLICE-AFTER-LEN` claim. |
| E6 | public hints | "I don't think we should implement other things from sequences such as iter" and "add as little as possible" | Do not add broader sequence protocol beyond `__len__`. | Frame obligation PO-3. |
| E7 | source validation | `_validate_steps` unpacks `zip(*self.steps)` and uses `estimators[-1]`. | Valid constructed pipelines are non-empty, so adding `__len__` does not make valid instances falsey. | Compatibility obligation PO-4. |
