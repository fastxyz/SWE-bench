# PROOF OBLIGATIONS

Status: obligations constructed and discharged by source/formal reasoning; not machine-checked.

| ID | Obligation | Evidence | Formal claim / discharge | Status |
| --- | --- | --- | --- | --- |
| PO1 | Generated checkbox state is controlled by `check_test(value)`. | E4 | `checkedOut(V, attrs(C)) = C or shouldCheck(V)` in `mini-django-widgets.k`. | Discharged. |
| PO2 | `CheckboxInput.get_context()` must not mutate caller-owned attrs when adding generated `checked`. | E3, E5 | `CHECKBOX-CONTEXT-NO-MUTATE`; source has `attrs = attrs.copy()` before `attrs['checked'] = True`. | Discharged. |
| PO3 | Split-array checkbox rendering must be per-index independent: a true value at index `i` must not force later false values checked. | E1, E2, E6 | `SPLIT-ARRAY-CHECKED-INDEPENDENT`; induction/circularity over value list with attrs invariant unchanged. | Discharged. |
| PO4 | Explicit caller-supplied `checked` remains respected. | E5, compatibility intent | Formal parameter `C = true` makes every `checkedOut(V, attrs(C))` true; source copy preserves original keys. | Discharged. |
| PO5 | Non-`checked` attrs and public API frame conditions are preserved. | E5, E7 | Source diff adds only `attrs.copy()` in the true branch before generated assignment; no signatures or call sites change. | Discharged by source inspection. |
| PO6 | Missing/false boolean values remain unchecked absent explicit `checked`. | E2, default checkbox behavior | For `V = false` and `C = false`, `checkedOut(false, attrs(false)) = false`. For source `None`, default `boolean_check(None)` is false and the no-mutation proof still applies. | Discharged. |
| PO7 | Concrete reproduction `[False, True, False]` renders `[False, True, False]`. | E1, E2 | `REPRODUCTION-FALSE-TRUE-FALSE`. | Discharged. |
| PO8 | Honesty gate: no claim of machine-checked proof or test-removal safety without running K tooling. | FVK docs, task no-exec rule | `PROOF.md` includes exact commands and labels the result constructed, not machine-checked. | Discharged. |
| PO9 | List accumulator algebra used by the split-array circularity must preserve output order. | Proof construction | Simplification lemma `append(snoc(OS, B), CS) => append(OS, ccons(B, CS))`. | Discharged as a constructed simplification lemma. |

No proof obligation failed or forced a source change beyond V1.
