# PROOF OBLIGATIONS

Status: constructed, not machine-checked.

| ID | Obligation | Evidence | Formal claim | Audit result |
| --- | --- | --- | --- | --- |
| PO1 | `value is None` returns `None` unchanged. | Existing source and base field behavior. | `toPython(none, PREC) => returnNone` | Discharged. |
| PO2 | Float values use context conversion and preserve precision behavior. | Public DecimalField float tests. | `toPython(floatInput(F), PREC) => returnDecimal(decimalFromFloat(F, PREC))` | Discharged. |
| PO3 | Valid non-float decimal constructor inputs return converted decimal values. | Public DecimalField integer/string tests; base conversion contract. | `toPython(validInput(D), PREC) => returnDecimal(decimal(D))` | Discharged. |
| PO4 | Invalid decimal syntax remains a `ValidationError`. | Public invalid string test; existing `InvalidOperation` guard. | `toPython(invalidSyntaxInput, PREC) => validationError(invalidSyntaxInput)` | Discharged. |
| PO5 | Dictionary/type-error input raises `ValidationError`, not raw `TypeError`. | Public issue E1/E2; base conversion contract E4. | `toPython(dictInput, PREC) => validationError(dictInput)` | Discharged by V1. |
| PO6 | Malformed/value-error input raises `ValidationError`, not raw `ValueError`. | Base conversion contract E4; adjacent numeric fields E8. | `toPython(malformedTupleInput, PREC) => validationError(malformedTupleInput)` | Discharged by V1. |
| PO7 | The exception normalization is targeted to known decimal conversion failures and does not become an unbounded catch-all. | Minimality and frame condition E9. | `toPython(otherExceptionInput, PREC) => rawException(otherError)` | Discharged. |
| PO8 | Public compatibility is preserved. | Compatibility audit: no signature, callsite, override, or return-shape change. | Public compatibility audit, not a K value claim. | Discharged by inspection. |

## Notes

- There are no loop invariants or recursive circularities.
- The proof is partial correctness by default. Since this method has no loop or recursion, no termination measure is needed for the audited branch structure.
- PO5 is the central issue obligation. PO6 is the V1 broadening beyond the exact dict example and is justified by the base field contract rather than hidden tests.
