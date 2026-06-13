# Key FVK artifact excerpts — django__django-13212
Source dir: results/batch1-XC-MINI-PRO-AHP/django__django-13212/

## 1. FINDINGS.md F3 (VERBATIM, lines 42-60) — the primer's cited finding
> ## F3 — `URLValidator` IDN retry reports the normalized URL, not the provided value **[FIXED in V2]**
>
> - **input:** an invalid internationalized-domain URL `u` whose `netloc` is changed
>   by `punycode()` (IDN -> ACE), e.g. one that still fails after normalization, with a
>   custom message `'%(value)s is not a valid URL'`.
> - **observed (V1):** the value reaches the IDN branch; `super().__call__(url)` is
>   called with the **ACE-normalized** `url`, and `RegexValidator` raises with
>   `params['value'] == url` (e.g. `http://...xn--...`). The user sees the punycode form,
>   not what they submitted.
> - **expected (PO5, value-identity):** `params['value']` is the value **as provided**.
> - **classification:** value-identity violation (PO5) on one sub-path. *Severity is
>   low* ... But the clean contract is "the provided value," so this is a real (if narrow) finding.
> - **fix:** wrap the IDN-retry `super().__call__(url)` in `try/except ValidationError`
>   and `raise e` ...

ADJUDICATION: F3 *is* a genuine instance of primer tell #3 (postcondition/intent
divergence: intent = "report the provided value", V1 contract = reports the
*normalized* punycode/ACE value). It is NOT a decoy in the django-10554 sense.
BUT it is about **URLValidator**, which is **orthogonal to this instance's actual
failure** (the DecimalField NaN case). No URL case is in the graded test set.
So F3 is a real tell *of its pattern* but does NOT point at this instance's root cause.

## 2. SPEC.md — REJECT/value-identity contract (lines 28-31)
> **REJECT contract.** If `V` rejects `x`, the raised `ValidationError e` satisfies
> `e.params is not None`, `'value' in e.params`, and `e.params['value'] is x` -- where
> `x` is the value **as provided to `V`**, not an internally derived or normalized form.

## 3. PROOF_OBLIGATIONS.md PO5 (lines 71-89) — formalized value-identity
> ## PO5 -- params['value'] is the *provided* value, not a derived form
> ... e.params['value'] is x, where x is the value passed to V -- not a normalized,
> reconstructed, or sub-component value.
> - **V1 status:** [FAILS] on one `URLValidator` sub-path (IDN retry reports the ACE-
>   normalized `url`) -- Finding F3.
(Again: scoped to URLValidator; the Decimal/File/forms-layer paths are out of view.)

## 4. FINDINGS.md F1 (lines 17-29) — the validator fvk DID fix (at the wrong layer)
> ## F1 -- V1 is incomplete: `DecimalValidator` omits `value` **[FIXED in V2]**
> - input: DecimalValidator(max_digits=2, decimal_places=1)(Decimal('0.99')) ...
> - fix: add 'value': value to all four DecimalValidator raises (incl. the invalid/NaN branch).
NOTE: F1 names the *DecimalValidator* (core/validators.py). The NaN failure is NOT in
DecimalValidator at all -- it is short-circuited by `DecimalField.validate()` in
django/forms/fields.py, which no artifact, PO, .k claim, or grep ever reaches.

## 5. FINDINGS.md F6 (lines 103-110) — the OUT-OF-SCOPE decision that touches NaN
> ## F6 -- `DecimalValidator`'s NaN/`invalid` branch has no `code` **[OUT OF SCOPE]**
> - input: DecimalValidator(1, 0)(Decimal('NaN')).
> - observed: raises with code is None (every other Decimal branch sets a code).
> - note: ... The V2 change adds params={'value': value} here for uniformity but
>   **deliberately does not** add a `code` ... Flagged for a future ticket, not fixed here.
NOTE: Even this NaN-adjacent finding stays inside DecimalValidator. The actual NaN raise
the test hits is `DecimalField.validate()` (forms layer) -- never mentioned. F6's decision
not to add `code` would *also* have blocked the message swap had NaN reached the validator,
but it never does, so F6 is a second-order miss, not the operative cause.

## 6. SCOPE STATEMENTS that fenced the search to core/validators.py
- reports/fvk_notes.md: "All edits are in `django/core/validators.py`."
- transcript fvk.jsonl.gz (baseline phase, ~line 526): the Decimal/FileExt params were
  initially judged "out of scope for this issue, which targets validators that previously
  provided no params."
- Final coherence check (transcript ~line 240-246): a Grep over `django/core/validators.py`
  ONLY -- never grepped django/forms/fields.py, so the forms-layer raise sites that the
  hidden tests exercise were never surfaced.

## 7. The actual root-cause spot, ABSENT from every artifact
django/forms/fields.py DecimalField.validate() (base_commit, lines 353-358):
    def validate(self, value):
        super().validate(value)
        if value in self.empty_values: return
        if not value.is_finite():
            raise ValidationError(self.error_messages['invalid'], code='invalid')  # no params
Gold DELETES this method. No FVK artifact (SPEC.md, FINDINGS.md, PROOF_OBLIGATIONS.md,
PROOF.md, ITERATION_GUIDANCE.md, validators-mini.k, validators-spec.k), no fvk_notes.md,
and no transcript line names django/forms/fields.py or DecimalField.validate().
