# ITERATION GUIDANCE — django__django-14007 (V1 fix audit)

Feedback package for the next generate→formalize→verify pass. **Verdict: V1 is
correct against the spec; it stands, with one behaviour-preserving clarifying
comment added.** No functional change. Below: the decision trail, the open
questions an intent layer should ask, and the test guidance.

---

## 1. Decision: keep V1 (functionally) — justification

| Audit result | Source | Consequence for V1 |
|---|---|---|
| Bug = converters never applied on insert-returning path | `FINDINGS.md` F1 | V1's `get_converters`/`apply_converters` reuse is exactly the right repair |
| Clean structural spec exists; one side condition only | `SPEC.md §4`, `PROOF.md §2` | strong evidence the fix is correct & complete |
| Inert for plain `AutoField` on all 4 backends | F2, `OB-NOOP` | no regression in the common path |
| Backend converters also applied, matching SELECT | F3 | required for intent, not scope creep |
| `Col` wrapper necessary & well-typed (incl. Oracle `.field`) | F4, F5, `OB-NOATTR` | the `field.get_col(...)` choice is correct, not incidental |
| `list` vs `tuple` row shape benign | F7, `OB-CONSUMER` | the `if converters:` guard is the right backward-compat choice |
| One escalation item, moot for `AutoField` | F11, `OB-ORACLE-RAW` | nothing to change in V1 |

The only edit applied this pass is a 3-line comment above the converter step,
documenting **why** it exists, so a future refactor cannot silently delete the
load-bearing conversion and reintroduce the F1 bug. The proof obligations are
unaffected (behaviour identical).

## 2. UltimatePowers questions (intent elicitation for the next pass)

- **UP-1 (precondition ownership).** Should a third-party field that sets
  `db_returning = True` be *required* to also be returned as a real column by the
  backend (so `PRE-INDEX` holds), or should `execute_sql` defensively guard
  against a converter position that exceeds the row width? *Today this can only
  arise via an unsupported custom field, and the RETURNING SQL would already be
  malformed — so a guard would mask a deeper misconfiguration.* Recommendation:
  document the precondition; do **not** add a defensive guard. (Ref `FINDINGS.md`
  F9, `OB-INDEX`.)
- **UP-2 (scope of conversion).** Confirm the intended contract is "the inserted
  value equals the value a SELECT would yield" (⇒ apply **both** backend and field
  converters), rather than the narrower literal report "call `from_db_value`."
  V1 implements the former. (Ref F3.)
- **UP-3 (Oracle rawness).** For a hypothetical custom Oracle `db_returning` field
  carrying a backend converter, is the `RETURNING … INTO` value at the same
  conversion stage as a SELECT value? Needs Oracle-in-K to settle. Moot for
  `AutoField`. (Ref F11, `OB-ORACLE-RAW`.)

## 3. Recommended code/spec changes for future iterations

- **None required for correctness.** Optional, low priority:
  - a one-line docstring on `execute_sql` summarizing the `convertRows` contract
    (the comment added this pass already covers the intent inline);
  - if `db_returning` is ever opened to third-party fields, add a system check
    that such a field is emitted as a returnable column (enforces `PRE-INDEX`
    structurally instead of by convention).

## 4. Tests — add / keep / (conditionally) remove

> The project suite is fixed and hidden; this is advisory only and never edits
> tests. Removal is conditioned on `kprove` returning `#Top` (Honesty gate).

**Add (behaviour the fix introduces):**
- `create()` and `save()` on a model with a custom `from_db_value` returning field
  ⇒ the pk attribute is the *wrapper*, and equals the raw int, on every supported
  backend (this is the F1 scenario; covers the single-row branch).
- `bulk_create()` on backends with `can_return_rows_from_bulk_insert` ⇒ each
  object's pk is the wrapper (covers the bulk branch / `OB-ROWS`).
- the `last_insert_id` branch (a backend without `can_return_columns_from_insert`)
  ⇒ pk is still converted.

**Keep (out-of-domain or below the trust boundary — never remove):**
- plain-`AutoField` insert still yields a plain `int` (pins `OB-NOOP`; guards
  against future spurious-converter regressions);
- per-backend integration tests hitting a real DBMS (exercise `OB-RAWSHAPE`);
- `ignore_conflicts` / row-count / ordering tests (`OB-TERM`, shape — not covered
  by partial correctness);
- any Oracle-returning test (`OB-ORACLE-RAW` escalation).

**Conditionally redundant (only after machine-checking):** single-input
"converted value after insert" assertions, subsumed by the `(APPLY)` contract for
all in-domain inputs (`PROOF.md §6`). CI saving: negligible but real.

## 5. Escalation register

- `OB-ORACLE-RAW` 🅔 — Oracle `RETURNING … INTO` value rawness vs SELECT. Route to
  a real Oracle-in-K semantics (`knowledge/sources.md`); do not fake as
  `[trusted]`. Impact today: none (no converter on `AutoField`).
- `OB-RAWSHAPE` 🅑 — DBMS/driver returns one column per returning field, in order.
  Trusted interface boundary, identical to pre-V1 assumptions.

## 6. One-line status

V1 fix **confirmed correct**; kept functionally unchanged (plus a clarifying
comment); proof constructed (not machine-checked); run `PROOF.md §5` to upgrade to
machine-verified and unlock the conditional test removals.
