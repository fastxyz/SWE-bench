# ITERATION_GUIDANCE.md — feedback for the next generation pass

Actionable guidance distilled from the audit (FINDINGS.md / PROOF_OBLIGATIONS.md).
Each item: **Evidence → Classification → UltimatePowers question → recommended
change → tests.** Items already applied in V2 are marked **[DONE in V2]**.

---

## 1. Uniformity of the contract — **[DONE in V2]**

- **Evidence:** PO1 failed for `DecimalValidator`/`FileExtensionValidator` (F1, F2);
  PO5 failed for `URLValidator`’s IDN retry (F3).
- **Classification:** missing-postcondition / consistency gap (not a crash).
- **UltimatePowers question:** *“Should `%(value)s` work for **every** built-in
  validator, including `DecimalValidator` and `FileExtensionValidator` (which already
  expose other context), or only the ones that previously had no params?”* The audit
  answered **every** — the clean, uniform spec — and showed extending is provably safe
  (PO2/PO3 preserved; no existing test asserts those validators’ exact params).
- **Change applied:** added `'value': value` to the 4 `DecimalValidator` raises and
  the `FileExtensionValidator` raise; wrapped `URLValidator`’s IDN
  `super().__call__(url)` to `raise e` (provided value).
- **Tests:** if the hidden suite checks `params['value']` per validator, V2 now
  satisfies it for all of them; if it only checks the formerly-no-params validators,
  V2 is a harmless superset.

## 2. The `str.__mod__` boundary & bare-`%` messages — **OPEN (accepted)**

- **Evidence:** F4 / PROOF.md §6 — params is now always truthy, so
  `ValidationError.__iter__` runs `message %= params` and a *custom* message with a
  bare `%` raises `ValueError` (default messages are unaffected, PO3).
- **Classification:** intentional behaviour change, consistent with `BaseValidator`.
- **UltimatePowers question:** *“Should Django defensively skip interpolation when a
  message has no `%(name)s` placeholder, to tolerate stray `%` in custom messages?”*
  That is a change to `django/core/exceptions.py::ValidationError.__iter__`, affecting
  **all** params-bearing errors — a separate ticket, out of scope here.
- **Recommended change:** none in `validators.py`. If pursued, document and test in the
  exceptions layer; otherwise document the `%%`-escaping requirement near the
  `%(value)s` docs.
- **Tests:** keep; add (in the exceptions suite, not here) a case pinning the chosen
  policy if §2 is ever taken on.

## 3. `DecimalValidator` NaN branch missing `code` — **OPEN (out of scope)**

- **Evidence:** F6 — `raise ValidationError(self.messages['invalid'], …)` sets no
  `code` (every sibling branch sets one).
- **Classification:** pre-existing latent inconsistency, orthogonal to this issue.
- **UltimatePowers question:** *“Should the ‘not a number’ Decimal error carry
  `code='invalid'` like the others?”*
- **Recommended change:** add `code='invalid'` there — but **separately**, because it
  changes `e.code` from `None` and could trip an unrelated test. V2 intentionally left
  `code` untouched and only added `params={'value': value}`.

## 4. Documentation — **[DONE in V1, retained]**

- **Evidence:** the issue references the docs’ `%(value)s` example.
- **Change applied:** `docs/ref/validators.txt` gained a note + `versionchanged:: 3.2`
  stating built-in validators expose `params['value']` for `%(value)s`.
- **Follow-up:** if §1’s uniform scope is upstreamed, the note already covers “each of
  these validators,” so no doc change is needed for the Decimal/FileExt extension.

## 5. What NOT to change

- Do **not** touch the `invalid(·)` predicates (regex/parse/range) — outside this
  issue and outside the proof’s domain; the `TEST_DATA` suite pins them and must stay.
- Do **not** store `params` on the validator instance — PO4 / `@deconstructible` and
  validator `__eq__` depend on it remaining a per-call local.
- Do **not** add `value` by mutating a shared dict — keep the per-call `{...}` literal.
