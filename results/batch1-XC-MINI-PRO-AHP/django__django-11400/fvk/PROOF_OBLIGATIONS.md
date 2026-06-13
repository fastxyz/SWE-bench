# PROOF_OBLIGATIONS.md — django__django-11400

The obligations the V1 fix must satisfy for the spec in `SPEC.md` to hold. Status is
**constructed, not machine-checked** (FVK MVP). Each obligation names what discharges
it; the symbolic-execution detail is in `PROOF.md`.

Legend: **CORR** = correctness of the fix; **TB** = trusted-base faithfulness
obligation (discharged by reading/citing Django source, not by `kprove`);
**NH** = no-harm / regression; **OOS** = out of scope (recorded, not discharged).

| ID | Kind | Obligation | Discharged by | Status |
|----|------|-----------|---------------|--------|
| PO1 | CORR | `Field.get_choices(ORD)` with `isTruthy(ORD)` enumerates by `ORD` (claim **GC-ORD**) | unfold `getChoicesFwd`(truthy) → `orderByQ(...,ORD)` → `qs(ORD,true,META)`; `effOrdering` br3 | ✅ constructed |
| PO2 | CORR | `Field.get_choices(())` enumerates by `Meta.ordering` (claim **GC-META**) — *the fix* | unfold `getChoicesFwd(_,.Ord)` → `qs(.Ord,true,META)`; `effOrdering` br4 → `META` | ✅ constructed |
| PO3 | CORR | reverse `ForeignObjectRel.get_choices` has the same contract (claims **GC-REV-ORD/META**) | identical, `allQ` replaces `complexFilter`; both preserve `qs` state | ✅ constructed |
| PO4 | CORR | `field_choices` orders by admin ordering when present & non-empty (claim **FC-ADMIN**) | `fieldAdminOrdering(true,AO)=AO`; then PO1 with `ORD:=AO` | ✅ constructed |
| PO5 | CORR | `field_choices` falls back to `Meta.ordering` with no admin / empty admin ordering (**FC-META-NOADMIN/EMPTYADMIN**) | `fieldAdminOrdering` → `.Ord`; then PO2 | ✅ constructed |
| PO6 | CORR | `RelatedOnlyFieldListFilter.field_choices` now threads `ordering` (same contract, forward domain D2) | M4 passes `ordering=self.field_admin_ordering(...)`; then PO4/PO5 | ✅ constructed |
| PO7 | CORR | the fix is **load-bearing**: pre-fix code violates PO2 (claim **BUG-OLD**) | unfold `getChoicesFwdOLD(_,.Ord)` → `orderByQ(qs,.Ord)` → `qs(.Ord,false,META)`; `effOrdering` br2 → `.Ord ≠ META` | ✅ constructed (counterexample) |
| PO8 | TB | `orderByQ` faithfully models `order_by` = `clear_ordering(False)`+`add_ordering` (empty ⇒ `default_ordering:=False`) | `query.py:1073-1080,1858-1891` cited in `mini_orm.k` | ✅ source-verified |
| PO9 | TB | `effOrdering` faithfully models the compiler `get_order_by` ladder | `compiler.py:262-273` cited in `mini_orm.k` | ✅ source-verified |
| PO10 | TB | `complexFilter` & `allQ` preserve `(order_by, default_ordering)`; `defaultManager` yields `default_ordering=True` | `query.py:916-931,881`, `query.py:168`, `manager.py:146` cited | ✅ source-verified |
| PO11 | TB | the model whose admin/`Meta.ordering` is consulted == the model enumerated (`field.remote_field.model`) | `reverse_related.py:62-64,78-82`; `fields/__init__.py:821` — see `FINDINGS.md` F3 | ✅ source-verified |
| PO12 | NH | non-filter callers of `get_choices` are unaffected (choices-declared fields early-return before `order_by`) | `fields/__init__.py:814-820,875`; `options.py:188-200` — see `FINDINGS.md` F4 | ✅ source-verified |
| PO13 | NH | for non-empty `ordering`, behavior is identical to pre-fix (only the empty case changes) | `if ordering:` ⇒ same `order_by(*ordering)` call; `FINDINGS.md` F6 | ✅ constructed |
| PO14 | NH | models without `Meta.ordering` remain unordered (no invented ordering) | `effOrdering(qs(.Ord,true,.Ord)) = .Ord`; ladder branch 5; `FINDINGS.md` F7 | ✅ constructed |
| PO15 | — | (partial correctness) the result comprehension terminates for a finite queryset | always finite for a DB manager; not separately proved (D3) | ⚠️ partial (noted) |
| PO16 | OOS | `RelatedOnlyFieldListFilter` + reverse relation raises `TypeError` (`limit_choices_to` unsupported) | pre-existing; fix does not touch it — `FINDINGS.md` F5 | 🔸 recorded, not fixed |

## Discharge dependency sketch

```
PO8, PO9, PO10  (trusted base: order_by / compiler ladder / qs-preserving ops)
      └── PO2 (empty ⇒ Meta.ordering)  ── PO5 ─┐
      └── PO1 (nonempty ⇒ that ordering)─ PO4 ─┼── PO6  (RelatedOnly threads ordering)
      └── PO7 (BUG-OLD counterexample: old code ≠ PO2)   → proves fix necessary
PO3   mirrors PO1/PO2 for reverse relations (PO10 again)
PO11  ensures PO1–PO6 order the RIGHT model
PO12, PO13, PO14  guard against regressions outside the targeted change
```

**Conclusion.** All CORR obligations (PO1–PO7) are discharged by construction; all TB
obligations (PO8–PO12) are discharged by direct source citation; the NH obligations
(PO13–PO14) hold by inspection. PO15 is the standard partial-correctness caveat; PO16 is
recorded as out of scope. **No obligation is violated by V1**, which is why V1 stands
(see `ITERATION_GUIDANCE.md` and `reports/fvk_notes.md`).
