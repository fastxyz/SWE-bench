# Spec Audit

| Formal item | Intent coverage | Result |
| --- | --- | --- |
| `HGB-GET-Y-BASE` | Matches I4: regression/base targets are not label encoded and should pass through unchanged. | Pass |
| `HGB-GET-Y-CLASSIFIER` | Matches I1, I2, D2: classifier scorer targets are internal class codes and must be mapped back through `classes_`. | Pass |
| `HGB-SCORER-CLASSIFIER-VAL` | Matches I2 and I5: both training-subset and validation scorer calls use public labels when validation data exists. | Pass |
| `HGB-SCORER-CLASSIFIER-NOVAL` | Matches I2 and I5: training scorer call uses public labels when early stopping scores on training data only. | Pass |
| `HGB-SCORER-BASE-VAL` | Matches I4 and I5: base/regression scorer calls preserve original targets. | Pass |
| `HGB-SCORER-BASE-NOVAL` | Matches I4 and I5: base/regression training-only scorer call preserves original targets. | Pass |
| Frame condition: loss scoring unchanged | Matches I3: `scoring='loss'` remains encoded and internal. | Pass |
| Frame condition: no public API/signature change | Matches I6 and compatibility audit C1-C3. | Pass |

No formal item is candidate-derived without public intent support. No item
preserves the reported pre-fix mixed-representation behavior.
