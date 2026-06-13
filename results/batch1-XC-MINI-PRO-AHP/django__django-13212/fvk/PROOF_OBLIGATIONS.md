# PROOF_OBLIGATIONS.md — django__django-13212

The obligations the fix must discharge to satisfy the SPEC.md contract. Each lists
the claim it maps to, the code sites it ranges over, status on **V1** vs **V2**, and
the discharging argument (full detail in PROOF.md).

Notation: `V` a built-in validator, `x` an input, `e` the raised `ValidationError`.

---

## PO1 — value is present in params on every rejection

> For every built-in validator `V` and every `x` that `V` rejects:
> `e.params is not None ∧ 'value' ∈ e.params`.

- **Claim:** (CONTRACT-REJECT).
- **Sites:** all 21 `raise ValidationError(...)` sites across
  `RegexValidator`, `URLValidator` (incl. inherited `super().__call__`), `EmailValidator`,
  `validate_ipv4/6/46_address`, `BaseValidator`, `DecimalValidator` (×4),
  `FileExtensionValidator`, `ProhibitNullCharactersValidator`.
- **V1 status:** ✖ FAILS for `DecimalValidator` (4 sites) and `FileExtensionValidator`
  (1 site) — Findings F1, F2.
- **V2 status:** ✔ HOLDS universally — `'value'` added to those 5 sites; all others
  already had it (`BaseValidator` via its `params` dict).
- **Discharge:** symbolic execution of each `reject(...)` site; the rule writes
  `verr(M,C,P)` into `<exc>` with the literal `P` the source constructs, and every
  `P` now contains `"value" |-> value`.

## PO2 — accept path unchanged (no spurious rejections)

> For every `V` and every `x` that `V` accepts: `V(x)` returns `None` and raises nothing.

- **Claim:** (CONTRACT-ACCEPT).
- **V1 status:** ✔.  **V2 status:** ✔.
- **Discharge:** the fix edits only the *arguments of existing `raise` statements*
  (and, for `URLValidator`, wraps one already-present `super().__call__` in
  `try/except` that re-raises). No guard predicate `invalid(·)` is altered and no new
  `raise` is introduced on a fall-through path. The `notBool invalid(V)` rule leaves
  `<exc> = noExc`. Critical for “purely additive”: confirmed for the
  `URLValidator` IDN edit — the new `except ValidationError` only fires when
  `super().__call__(url)` *already* raised, i.e. on a reject path; the
  IDN-success path is untouched.

## PO3 — default-message rendering is invariant under the added params

> For every built-in default message `m`: `m % {'value': x, …} == m`
> (so `ValidationError.__iter__` produces identical text before/after the fix).

- **Claim:** (RENDER-DEFAULT), side condition `noPercent(m)`.
- **V1 status:** ✔.  **V2 status:** ✔.
- **Discharge:** enumerate all built-in default messages (PROOF.md §4) and observe
  none contains a `%`. Hence `noPercent(m)` holds and the render rule gives `m`
  unchanged. The previously-`None` params now being truthy *does* make
  `__iter__` run `message %= params`, but on a `%`-free message that is the identity.
- **Boundary:** the general `str.__mod__` law is an [ESCALATION BOUNDARY]; only the
  `noPercent ⇒ identity` slice is used and modelled. The complementary case
  (a *custom* message with a bare `%`) is Finding **F4**, explicitly *not* covered by
  PO3 and accepted as a documented behaviour change.

## PO4 — freshness / no aliasing / instance not mutated

> Each rejection builds a fresh `params` dict; no params state is shared across calls
> or stored on the validator instance.

- **V1 status:** ✔.  **V2 status:** ✔.
- **Discharge:** every site uses a `{...}` dict literal (or `BaseValidator`’s
  per-call local `params = {…}`), evaluated anew per `__call__`. `params` is never
  assigned to `self`, so `@deconstructible` and each validator’s `__eq__` (which
  compare constructor-level attributes only) are unaffected (Finding F5).

## PO5 — params['value'] is the *provided* value, not a derived form

> `e.params['value'] is x`, where `x` is the value passed to `V` — not a normalized,
> reconstructed, or sub-component value.

- **Claim:** (CONTRACT-REJECT) — the postcondition reuses the *same symbolic* `V`
  bound by the precondition.
- **V1 status:** ✖ FAILS on one `URLValidator` sub-path (IDN retry reports the
  ACE-normalized `url`) — Finding F3.
- **V2 status:** ✔ HOLDS — the IDN retry now `raise e`, and `e` is the original
  `RegexValidator` failure on the *provided* `value` (`params={'value': value}`).
- **Cross-checks:**
  - `EmailValidator` mutates only `domain_part`, never `value` → original value
    reported at all 3 sites. ✔
  - `validate_ipv46_address` catches the inner `validate_ipv4/6_address` failures
    (raised on the same `value`) and re-raises on its own `value` arg → provided
    value. ✔
  - `URLValidator` line-140 IPv6 check raises on the *original* `value`, not on the
    extracted `potential_ip`. ✔

---

## Summary table

| PO | V1 | V2 | Driver |
|----|----|----|--------|
| PO1 value-present     | ✖ (Decimal, FileExt) | ✔ | F1, F2 |
| PO2 accept-unchanged  | ✔ | ✔ | F5 |
| PO3 render-invariant  | ✔ | ✔ | F5 (F4 = accepted exception) |
| PO4 freshness/no-alias| ✔ | ✔ | F5 |
| PO5 provided-value-id | ✖ (URL IDN)          | ✔ | F3 |

V2 discharges PO1–PO5 in full (PO3 modulo the named [ESCALATION BOUNDARY] for
`str.__mod__`, which does not affect the default-message guarantee). V1 left PO1 and
PO5 partially open — the precise reason the audit revised rather than confirmed V1.
