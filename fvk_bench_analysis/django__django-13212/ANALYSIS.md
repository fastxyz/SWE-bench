# Analysis — `django__django-13212`

Batch: `batch1-XC-MINI-PRO-AHP` · arm: fvk (forked from baseline) · result: `resolved: false`
(report: FAIL_TO_PASS 3/5; **but see the §1 incident — the real test run had only 1 failure**).

---

## 1. Root cause (and which F2P actually remained failing)

**Issue.** "Make validators include the provided value in `ValidationError`" so a custom
`message` can interpolate `%(value)s`. (Problem statement says **"the provided value"** —
the value as submitted; no normalization mentioned.) Public test `ValidatorCustomMessageTests`
pins the behavior per field type.

**The gold fix has two parts:**
1. `django/core/validators.py` — thread `params={'value': value}` through every rejecting
   built-in validator (Regex/URL/Email/IP/Decimal/FileExtension/ProhibitNullCharacters),
   and add `code='invalid'` to the `DecimalValidator` NaN branch.
2. `django/forms/fields.py` — **DELETE `DecimalField.validate()`** (the `is_finite()` /
   NaN override, lines 350-356 of the oracle diff).

**Why part 2 matters (this is the operative root cause for the remaining failure).**
The form `clean` chain is `to_python -> validate -> run_validators`, and **only
`run_validators` swaps in the field's custom message** (and only it preserves `e.params`).
`DecimalField.validate()` intercepts `Decimal('NaN')` (`is_finite()` is False) and raises
`ValidationError(self.error_messages['invalid'], code='invalid')` **with no params**, *before*
`run_validators` runs. With no params, `ValidationError.__iter__` skips `message %= params`,
so the custom message renders as the literal `'%(value)s'`. The (fixable) `DecimalValidator`
is never consulted for NaN. **Bug type: wrong-layer / short-circuit validation (an over-eager
pre-`run_validators` raise that must be removed).**

**Which F2P remained failing — corrected by direct evidence.** The eval **report.json**
lists *two* F2P failures (decimal_field, file_field). The stored fvk test_output
(`logs/run_evaluation/batch1-XC-MINI-PRO-AHP.fvk/.../django__django-13212/test_output.txt`)
shows the truth: `FAILED (failures=1)` — **exactly one** failure,
`test_value_placeholder_with_decimal_field` at sub-case `value='NaN'`:
`AssertionError: {'field': ['%(value)s']} != {'field': ['NaN']}`. The line
`test_value_placeholder_with_file_field ... ok` shows **file_field PASSED**. The report
over-counts because Django emitted decimal_field's (status-less, due to a failed subTest)
line and file_field's line on one physical line, and the SWE-bench parser mis-assigned
file_field. (Baseline, by contrast, ends `FAILED (failures=1, errors=4)` and genuinely
fails *both* — KeyErrors from never fixing DecimalValidator/FileExtensionValidator.) See
`evidence/failing-test-and-eval.md`. So **the single remaining failure is the DecimalField
NaN case**, caused entirely by the untouched `DecimalField.validate()`.

**Public-data reachability: YES.** The placeholder is named in the issue; the public test
pins the NaN case; tracing `Field.clean`/`run_validators`/`ValidationError.__iter__` makes
the two-part nature derivable from public source. The non-obvious step (delete
`DecimalField.validate()`) is discoverable by asking *why does NaN render `'%(value)s'`?* —
it raises at the wrong layer with no params.

---

## 2. What the fvk arm did (V1 vs final + key artifacts)

**V1 (`solution_baseline.patch`)** edited `django/core/validators.py` only, and notably
**skipped `DecimalValidator` and `FileExtensionValidator` entirely** (hunks jump line 287 ->
550) plus a docs note. So V1 failed both decimal and file at the validator layer.

**Final (`solution_fvk.patch`)** is a strict **superset** of V1 — fvk **changed** V1, adding
exactly the three changes its findings predicted, all still inside
`django/core/validators.py`:
- **F1:** `params={'value': value}` on all four `DecimalValidator` raises (the NaN branch got
  `params` but, per F6, **deliberately no `code='invalid'`**).
- **F2:** `'value': value` on `FileExtensionValidator`.
- **F3:** wrap the URL IDN retry `super().__call__(url)` in `try/except ValidationError: raise e`
  (report the provided value, not the punycode form).

`docs/ref/validators.txt` is byte-identical V1->fvk. **Neither V1 nor fvk touched
`django/forms/fields.py`.**

**Net effect at the test level (the report hides this): fvk strictly improved on baseline** —
it fixed file_field and the three decimal `max_*` sub-cases; only the decimal **NaN** sub-case
remained. Both arms are nonetheless scored `resolved: false`.

**Artifacts** are unusually complete and high-quality: `SPEC.md` (a clean REJECT/ACCEPT/
RENDER contract + intent ledger), `FINDINGS.md` (F1-F6 + one labelled escalation boundary),
`PROOF_OBLIGATIONS.md` (PO1-PO5 with V1/V2 status), `PROOF.md`, `ITERATION_GUIDANCE.md`, and
**both `.k` files** (`validators-mini.k` semantics, `validators-spec.k` with a value-identity
`[all-path]` claim). All stamped "constructed, NOT machine-checked." The formal apparatus is
correct *for the slice it modeled* — it just modeled the wrong file.

---

## 3. Artifact audit — VERDICT

### VERDICT: **MISSING (but reachable)** — does **not** count toward headroom.

The operative root cause — the over-eager `DecimalField.validate()` NaN short-circuit in
`django/forms/fields.py`, which the gold patch deletes — has **no trace anywhere** in the
FVK artifacts or transcript. Confirmed absence (searched all of `fvk/*`, `reports/fvk_notes.md`,
and the full `transcripts/fvk.jsonl.gz`):

```
$ grep -rniE 'forms/fields|forms\.fields|DecimalField\.validate|is_finite|fields\.py' \
      fvk/ reports/fvk_notes.md
(no matches)
$ zcat transcripts/fvk.jsonl.gz | grep -ciE 'forms/fields|DecimalField|is_finite'
0
$ grep -n 'All edits' reports/fvk_notes.md
47:All edits are in `django/core/validators.py`.
```

This is the **primer tell #7 (scope-induced false-negative)** in its purest form: FVK drew
the spec domain around `django/core/validators.py` ("All edits are in ..."), wrote a contract
it could prove *clean and total on that domain*, and the actual fix site was **defined out of
scope before any obligation was written**. No `requires`, no PO, no escalation boundary, and
no `.k` rule sits on `DecimalField.validate()`. Per the rubric that is **MISSING-but-reachable**,
not BURIED. Even F6 — the one NaN-adjacent finding — stays inside `DecimalValidator` and never
reaches the forms layer.

### Adjudication of the primer's F3 claim (the explicit task)

The primer (§v tell #3) cites **`django-13212 F3`** as a postcondition/intent divergence:
"intent says report the provided value but the contract/finding shows a normalized value."

**Verdict on the pointer: TRUE TELL of its pattern, but NOT pointed at this instance's root
cause — i.e. a *correct illustration, wrong target*.** F3 (FINDINGS.md:42-60, quoted verbatim
in `evidence/artifact-excerpts.md`) genuinely encodes the divergence: intent (PO5) = report
the value *as provided*; V1 behavior = `URLValidator`'s IDN retry reports the **ACE/punycode-
normalized** URL via `super().__call__(url)`. SPEC.md:30-31 ("not an internally derived or
normalized form") and PO5 (PROOF_OBLIGATIONS.md:71-89) formalize it. It is **not** a decoy in
the django-10554 sense — it correctly models the right mechanism on its sub-path, and fvk even
fixed it. So as an *example of the tell*, the citation is sound.

**However**, F3 is about **`URLValidator`**, which is **orthogonal to the actual failing test**
(DecimalField NaN). No URL case is in the graded set; F3 fixed a real-but-ungraded narrow
defect. So if a reader takes the primer's pointer to mean "F3 encodes *this instance's* root
cause," that is **false** — the root cause is the forms-layer NaN short-circuit, which is
MISSING. The pointed-at-the-spot test applied to the *cause* (not the "normalized value"
symptom string) **fails** for F3.

**Suggested primer correction (precise):** keep `django-13212 F3` as the worked example of
tell #3, but annotate it: *"F3 is a genuine intent/normalization divergence on `URLValidator`'s
IDN path (the tell is real), but it is **orthogonal to this instance's graded failure**; the
instance's actual root cause (an over-eager `DecimalField.validate()` NaN short-circuit in
`django/forms/fields.py`, deleted by gold) is **MISSING** from the artifacts — a tell-#7
scope-induced false-negative. Use F3 to illustrate the *shape* of tell #3, not as evidence the
instance was solved/solvable from its findings."* This prevents the same over-reading that
made django-10554 a decoy.

### What the artifacts DID cover vs. the remaining gap (partial-pass precision)

The artifacts cover the parts that **passed**: F1/F2 named the two validators whose
validator-layer fix made char/integer/null/file and the three decimal `max_*` sub-cases pass.
They do **not** cover the part that **stayed failing** (NaN), because that lives in a file the
spec never admitted. So the headroom question — about the *remaining* failure — resolves to
MISSING.

---

## 4. How FVK could surface it (prose, general, no-exec)

The miss is a **scope/domain** failure, not a notation failure, so the fix is in how FVK picks
its spec domain — exactly the kind of thing a better, de-noising FVK could do without execution:

1. **Trace the obligation to the actual raise site, across files.** The intent is a property of
   *the value the user sees in `form.errors`*. Honoring it requires following the value from the
   field's `clean` pipeline (`to_python -> validate -> run_validators`) to **every** site that
   can raise for that field — including `DecimalField.validate()` and `*Field.to_python`. A
   spec scoped to "validators that already exist in `core/validators.py`" silently assumes the
   only reject sites are validators; the issue's own examples (DecimalField, FileField) cross
   the forms layer. FVK should let the *intent* (user-visible value), not the *file it started
   editing*, define the domain.

2. **Distrust a domain that exactly matches V1.** When the contract is declared "clean and
   total" on precisely the set of lines V1 touched, treat "total" as **vacuous** until the
   domain is cross-checked against the issue's full surface (here: a `DecimalField(... )` with
   `'NaN'` is an explicit public test case). A spec that cannot place the NaN input on any
   modeled path is admitting an unmodeled reject site, not proving completeness.

3. **Promote the NaN observation it already half-had.** F6 noticed the NaN branch is anomalous
   ("no `code`") but routed it to OUT-OF-SCOPE. A de-noising pass should ask "where else can a
   NaN `DecimalField` reject?" — which leads straight to `DecimalField.validate()` and the
   missing-params short-circuit. The signal was one inference away; FVK stopped at the file
   boundary.

(Reachable from public data; the gap is surfacing/scoping, so this counts as an FVK
improvement target even though it does **not** count toward *latent-in-artifacts* headroom.)
