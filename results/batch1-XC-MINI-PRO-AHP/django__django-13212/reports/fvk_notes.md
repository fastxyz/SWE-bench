# reports/fvk_notes.md — FVK audit outcome for django__django-13212

This documents what the Formal Verification Kit pass changed relative to V1, and why,
tracing every decision to specific entries in [`fvk/FINDINGS.md`](../fvk/FINDINGS.md)
and [`fvk/PROOF_OBLIGATIONS.md`](../fvk/PROOF_OBLIGATIONS.md).

**Bottom line:** the audit **revised** V1. V1 was correct for the validators it
touched but **incomplete** against the clean, uniform specification (SPEC.md §1).
Three small, provably-safe edits bring all built-in validators under one contract.

---

## 1. The specification choice (the pivotal decision)

The issue says “make **validators** include the provided value.” Two specifications
fit the words:

- **Spec A (uniform):** *every* rejecting built-in validator exposes
  `params['value']`. Clean, no carve-outs.
- **Spec B (gap-filling):** only validators that *previously had no params* expose it;
  validators that already carry context (`DecimalValidator`, `FileExtensionValidator`)
  stay as-is. This is exactly V1.

The FVK clean-spec lens (formalize.md §7, “spec-difficulty = bug signal”) favors
**Spec A**: Spec B’s exemption is an *implementation-historical* distinction
(“did this raise already have a params dict?”), invisible and surprising to a user,
who would reasonably expect `%(value)s` to work in *any* built-in validator’s custom
message. I adopted **Spec A**, making V1 incomplete (PO1, PO5 partially open) and
driving the edits below.

**Why adopting Spec A is safe (not just cleaner)** — the dominance argument:
extending `value` to `DecimalValidator`/`FileExtensionValidator` is *purely additive*
on params and **rendering-invariant** for their default messages (those reference
`%(max)s` / `%(extension)s` only; Python’s mapping `%` ignores the unused `value`
key — PO3). I also checked `tests/validators/tests.py`: the existing
`DecimalValidator`/`FileExtensionValidator` rows assert only *that* a
`ValidationError` is raised (lines 259–284), and the equality tests (443–494) compare
constructor attributes — **no test anywhere asserts these validators’ exact `params`
dict**. So the extension cannot break an existing assertion, and it *covers* the case
where the contract is meant to be uniform. Worst case it is a harmless superset; best
case it is required. (Detail in FINDINGS F1/F2 and PROOF_OBLIGATIONS PO1.)

---

## 2. Code changes made in V2 (each traced)

All edits are in `django/core/validators.py`.

### Change 1 — `DecimalValidator`: add `'value': value` to all 4 raises
- **Traces to:** Finding **F1** → **PO1** (value-present).
- **What:** `params={'value': value}` on the NaN/`invalid` branch; `'value': value`
  added to the existing `params` of the `max_digits`, `max_decimal_places`,
  `max_whole_digits` branches.
- **Why safe:** PO2 (guards unchanged), PO3 (default messages use `%(max)s` only;
  `value` is an unused, tolerated mapping key), PO4 (per-call literal). Deliberately
  did **not** add a `code` to the NaN branch — that is the separate Finding **F6**
  (out of scope; would change `e.code` and risk an unrelated test).

### Change 2 — `FileExtensionValidator`: add `'value': value` to its raise
- **Traces to:** Finding **F2** → **PO1**.
- **What:** `'value': value` added alongside the existing `extension` /
  `allowed_extensions` keys.
- **Why safe:** identical reasoning to Change 1; the default message references only
  `%(extension)s` / `%(allowed_extensions)s` (PO3). `value` is the `File`; `%(value)s`
  would render `str(File)` (its name).

### Change 3 — `URLValidator` IDN retry: report the provided value
- **Traces to:** Finding **F3** → **PO5** (provided-value identity).
- **What:** wrapped the IDN-retry `super().__call__(url)` in
  `try/except ValidationError: raise e`. `e` is the original `RegexValidator` failure
  on the *provided* `value` (it already carries `params={'value': value}`), so the
  reported value is what the user submitted, not the ACE/punycode-normalized `url`.
- **Why safe:** symmetric with the adjacent `except UnicodeError: raise e`. PO2 is
  preserved because the new `except` only fires when `super().__call__(url)` *already*
  raised (a reject path); the **IDN-success path is untouched** (no exception → falls
  through to the L146 length check exactly as before). Common (non-IDN) reject inputs
  were already correct since `urlunsplit(urlsplit(value)) == value`; the fix closes
  the narrow IDN gap. (PROOF.md §3.)

---

## 3. V1 decisions retained (and re-justified by the proof)

- **All V1 additions kept** (RegexValidator L51; URLValidator direct sites
  L103/107/118/140/147; EmailValidator L216/221/233; `validate_ipv4/6/46_address`;
  `ProhibitNullCharactersValidator` L559). These already satisfy **PO1**; the proof
  of (CONTRACT-REJECT) covers them. No change needed.
- **`BaseValidator` family left untouched.** It already binds `params['value']`
  (`params = {'limit_value', 'show_value', 'value'}`), so **PO1/PO5 already hold**;
  `test_max_length_validator_message` is the existing evidence. (PROOF_OBLIGATIONS PO1.)
- **`EmailValidator` not modified for PO5** because, unlike `URLValidator`, it mutates
  only `domain_part` and always raises on the original `value` — PO5 already holds at
  all three sites (PROOF_OBLIGATIONS PO5 cross-checks).
- **Documentation note from V1 kept** (`docs/ref/validators.txt`): it says “each of
  these validators passes the value … as `params['value']`,” which now reads as
  literally true after the uniform extension.

---

## 4. Findings surfaced but deliberately NOT fixed

- **F4 (bare-`%` custom message now raises).** Because params is now always truthy,
  `ValidationError.__iter__` runs `message %= params` even for the patched validators,
  so a *custom* message with an unescaped `%` raises `ValueError`. **Accepted, not
  fixed:** it matches long-standing `BaseValidator` behaviour and Django’s
  `%%`-escaping convention, and **PO3 guarantees no default message is affected** (none
  contains a `%` — PROOF.md §4). A fix would have to live in
  `ValidationError.__iter__` (out of scope; would affect `BaseValidator` identically).
- **F6 (`DecimalValidator` NaN branch lacks `code`).** Pre-existing, orthogonal; left
  for a separate ticket (ITERATION_GUIDANCE §3).
- **`invalid(·)` predicates and the `TEST_DATA` suite.** Outside the verified domain
  (the proof abstracts the regex/parse/range tests); untouched. The test-redundancy
  analysis (PROOF.md §7) recommends **keeping every existing test** — the suite pins
  the orthogonal `invalid(·)` predicate, which the proof subsumes none of. Honest zero
  CI saving.

---

## 5. Verification status & residual risk

The three reachability claims (CONTRACT-REJECT, CONTRACT-ACCEPT, RENDER-DEFAULT) are
**constructed, not machine-checked** — this environment has no `kompile`/`kprove`
(run-commands in PROOF.md §5). The Findings (benefit 2) do not depend on the machine
check and stand today. The one named gap is the `str.__mod__` **[ESCALATION
BOUNDARY]** (only the `noPercent ⇒ identity` slice is modelled); it does not weaken
PO1/PO2/PO4/PO5, which are control-flow/map facts, nor the default-message guarantee
of PO3. Net: **V2 discharges PO1–PO5; V1 left PO1 and PO5 partially open** — the
precise, audit-backed reason the fix was revised rather than confirmed.
