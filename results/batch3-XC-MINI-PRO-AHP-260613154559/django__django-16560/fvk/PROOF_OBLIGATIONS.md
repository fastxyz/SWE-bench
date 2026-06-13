# PROOF_OBLIGATIONS.md — django__django-16560 (V1 fix)

Each obligation is tied to a contract in `SPEC.md`, a claim in `constraints-spec.k`
(where applicable), and a discharge method. Status is **constructed, not
machine-checked** (the MVP does not run `kprove`); see `PROOF.md`.

Discharge legend: **SE** = symbolic execution over `constraints.k`; **CS** = guard
case-split (`C is null` / `C ≠ null`); **EQ** = `#Equals`/`==K` reduction; **TR** =
Transitivity composition; **RO** = read-off from the literal source (structural
argument over the unchanged Python text); **Z3** = propositional/linear side fact.

| PO | Statement | Source | Claim | Discharge | Status |
|----|-----------|--------|-------|-----------|--------|
| PO1 | After `__init__(..., violation_error_code=C)`, effective code `= C` for **all** `C`. | C1 | `(INIT-CODE)` | SE + CS | ✅ constructed |
| PO2 | `__init__` still sets `violation_error_message` to the passed value or `default_violation_error_message`; code insertion does not perturb it. | C1 | — | RO | ✅ constructed |
| PO3 | `deconstruct()` yields `kwargs` with `kwargs.get("violation_error_code", None) = C` for **all** `C`. | C2 | `(DECON-CODE)` | SE + CS | ✅ constructed |
| PO4 | When `C = null`, `deconstruct()` `kwargs` is identical to the pre-fix output (no extra key). | C2 | `(DECON-CODE)`, null branch | SE + EQ | ✅ constructed |
| PO5 | `clone(c)` has effective code `= c`'s effective code, for **all** `C`. | C3 | `(ROUNDTRIP-CODE)` | TR(PO3,PO1) | ✅ constructed |
| PO6 | `clone(c) == c` (all fields), for **all** `C`. | C3, C5 | `(ROUNDTRIP-CODE)` + EQ | TR(PO5) + RO(other fields round-trip, pre-existing) | ✅ constructed |
| PO7 | `__eq__` distinguishes the code: `c1.code ≠ c2.code ⇒ c1 ≠ c2`. | C5 | `(EQ-CODE)` | SE + EQ + Z3 | ✅ constructed |
| PO8 | `__eq__` consistency: equal code ∧ equal other fields ⇒ equal (no new false-negative). | C5 | — | RO | ✅ constructed |
| PO9 | `validate()` in-domain raise binds `error.code = C` (Check / Exclusion / Unique-expr / Unique-condition). | C4 | `(VALIDATE-CODE)` | SE | ✅ constructed (within abstraction PV3) |
| PO10 | `validate()` on `Unique(fields, condition=None)` binds `error.code = "unique"/"unique_together"` (≠ `C`). | C4 scope-out | — | RO | ✅ constructed (deliberate, F5) |
| PO11 | `__repr__` with `C = null` is byte-identical to the pre-fix repr. | C6 | — | RO (format-string empty slot) | ✅ constructed |
| PO12 | `__repr__` with `C ≠ null` contains `" violation_error_code=%r" % C` (before the message slot). | C6 | — | RO | ✅ constructed |
| PO13 | Subclass `deconstruct()` overrides inherit code emission (they call `super().deconstruct()` and only add keys). | C2 | — | RO | ✅ constructed |
| PO14 | Coverage: every `BaseConstraint` subclass and every code-bearing raise site is updated. | all | — | RO (enumeration) | ✅ constructed |

## Coverage enumeration for PO14

`BaseConstraint` subclasses (`grep '(BaseConstraint)'`): `CheckConstraint`,
`UniqueConstraint`, `ExclusionConstraint` — **all three** updated (init/eq/repr;
deconstruct via inheritance).

Code-bearing `ValidationError` raises:
- `constraints.py:130` `CheckConstraint.validate` → `code=` added ✅
- `constraints.py:423` `UniqueConstraint.validate` (expressions) → `code=` added ✅
- `constraints.py:432` `UniqueConstraint.validate` (fields, no condition) → **intentionally not** (PO10/F5) ✅
- `constraints.py:441` `UniqueConstraint.validate` (condition) → `code=` added ✅
- `postgres/constraints.py` `ExclusionConstraint.validate` (no condition) → `code=` added ✅
- `postgres/constraints.py` `ExclusionConstraint.validate` (condition) → `code=` added ✅

## Open / bounded obligations

- **PV3 / PO9 boundary:** real Python exception propagation, the `try/except
  FieldError` wrapper, and the DB query are **not** modeled (out of the mini-X
  fragment). PO9 proves the *local* fact "the constructed error object's `code` is
  the effective code." This is an explicit **[ESCALATION BOUNDARY]**, not a
  `[trusted]` admission. It does not affect the audited property (code propagation).
- **Termination:** not in scope (partial correctness). The changed code is
  straight-line and trivially terminating anyway (no new loops/recursion).
