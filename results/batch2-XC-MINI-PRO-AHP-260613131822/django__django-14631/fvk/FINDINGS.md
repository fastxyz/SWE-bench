# FINDINGS.md — django__django-14631

Plain-language findings from formalizing the V1 fix. Each is `input → observed vs
expected`. The Findings report does **not** depend on machine-checking (FVK honesty
gate). "V0" = original code at `84400d2e9db7c5…`; "V1" = the fix under audit.

---

## F1 — [FIXED by V1] Disabled field: `cleaned_data` ≠ `form[name].initial` for a callable initial
**Severity:** the bug the ticket is about. **Status:** resolved by V1.

- **Input:** `dt = DateTimeField(initial=datetime.datetime.now, disabled=True)`;
  `form = DateTimeForm({})`.
- **Observed (V0):** `_clean_fields()` computes the disabled value with a *direct*
  `self.get_initial_for_field(field, name)` call → evaluates `datetime.datetime.now()`
  once (say `T1`, with microseconds). Later, `form['dt'].initial` (a `cached_property`)
  calls `get_initial_for_field` **again** → `datetime.datetime.now()` a *second* time
  (`T2 ≠ T1`), then strips microseconds (DateTimeInput `supports_microseconds=False`).
  So `form.cleaned_data['dt']` (≈`T1`) `!=` `form['dt'].initial` (`nix(T2)`).
- **Expected:** they denote the same initial and should be equal.
- **Why V1 fixes it:** `_clean_fields` now reads `bf.initial`, the *cached*
  `BoundField.initial`. The first read caches `nix(T1)`; `form['dt'].initial` is then a
  cache **hit** returning the same `nix(T1)`. Evidence: claims `(CLEAN-DISABLED-
  CONSISTENCY)` + `(BF-INIT-HIT)`; `mini-forms.k` rules `bfInitial` (miss/hit) and
  `getRawInitial` (impure counter).
- **Spec-difficulty signal (benefit 2):** a clean spec for V0 is *impossible* — you
  cannot write `cleaned_data[n] == form[n].initial` as a theorem because
  `get_initial_for_field` is impure and called from two sites. That impossibility is
  precisely the bug; V1 removes the second call site, restoring provability.

## F2 — [INTENDED behavior change] Disabled datetime/time: microseconds now normalized in `cleaned_data`
**Severity:** intended; verify expectation. **Status:** deliberate consequence of V1.

- **Input:** `dt = DateTimeField(initial=lambda: datetime.datetime(2006,10,25,14,30,45,123456), disabled=True)`.
- **Observed (V0):** `cleaned_data['dt']` keeps microseconds (`…45.123456`).
- **Observed (V1):** `cleaned_data['dt'] == form['dt'].initial == …45.000000` (nixed),
  because `BoundField.initial` strips microseconds for widgets without microsecond
  support (`boundfield.py` `initial`, `#22502`).
- **Expected (per ticket):** `cleaned_data` should match `form[name].initial` — V1 is
  correct. The repo's *current* `test_datetime_clean_initial_callable_disabled`
  (asserts `cleaned_data == {'dt': now}` with microseconds) is the test the ticket says
  "can be adjusted"; the adjusted form asserts `cleaned_value == bf.initial`. Tests are
  hidden/fixed here; this finding records that the change is **by design**, not a
  regression. See `ITERATION_GUIDANCE.md` UP-1.

## F3 — [POSITIVE] All non-disabled / non-consistency paths are behavior-preserving
**Severity:** none (confirms no regression). **Evidence:** `PROOF_OBLIGATIONS.md`
PO-DATA, PO-NONDIS, PO-FILE, PO-HASCHANGED, PO-SHOWHIDDEN, PO-ORDER, PO-HOOK.

- `bf.data` is *definitionally* `self._field_data_value(field, self.add_prefix(name))`
  (`bf.html_name = form.add_prefix(name)`), so the non-disabled `_clean_fields` value
  and the `changed_data` data value are unchanged.
- `_has_changed` is V0's inner loop body moved verbatim onto `BoundField`; the
  `show_hidden_initial` branch uses `self.html_initial_name`
  (`= form.add_initial_prefix(name)`) and the same `to_python`/`ValidationError ⇒
  changed` short-circuit; the else branch uses `self.initial` (`= self[name].initial`).
- `changed_data` returns `keep(fields)` — same names, same order as V0's appended list.

## F4 — [DECISION, behavior-neutral] Method named `_has_changed`, ticket sketch said `_did_change`
**Severity:** none. **Status:** intentional.

- The ticket prose says it "could be called *something like* `bf.did_change()`"
  (explicitly tentative) while its code sketch writes `bf._did_change()`. V1 names it
  `BoundField._has_changed()`.
- **Rationale:** it is a private helper exercised only through the public
  `changed_data`/`has_changed`/`cleaned_data` (behavior); no caller references the name.
  `_has_changed` mirrors the `Field.has_changed(initial, data)` it delegates to,
  keeping wrapper and delegate aligned. No proof obligation depends on the spelling.
- If strict fidelity to the sketch is required, rename both occurrences (one in
  `forms.py`, one in `boundfield.py`) — purely mechanical. Tracked in
  `ITERATION_GUIDANCE.md` UP-2.

## F5 — [LOW-RISK assumption] V1 newly relies on `bf.field is self.fields[name]`
**Severity:** low. **Status:** holds for core Django; documented assumption.

- **Observed:** V1 reads `field = bf.field` instead of iterating `self.fields.items()`.
  If a custom `Field.get_bound_field` returned a `BoundField` wrapping a *different*
  field object, `_clean_fields`/`changed_data` would use that field's `disabled`/
  `clean`. **Audit:** in `repo/django` only the base `Field.get_bound_field` exists
  (returns `BoundField(form, self, name)`, so `bf.field is self`), and there is a single
  `BoundField` class with no `data`/`initial` overrides.
- **Why acceptable:** V0's `changed_data` already routed initial through
  `self[name].initial` (i.e. through `get_bound_field`); V1 only extends that existing
  reliance to `bf.field`/`bf.data`. The BoundField contract is "a Field plus data," so
  this is the intended direction (it is the ticket's stated goal). Recorded, not blocking.

## F6 — [POSITIVE side effect] Fewer evaluations of a side-effecting callable initial
**Severity:** none (improvement). For a disabled field, V0 evaluated a callable
`initial` **twice** (once in `_clean_fields`, once in `BoundField.initial`; a disabled
`FileField` even thrice). V1 evaluates it **once** (shared cache). If `initial` has
side effects (rare; e.g. logging), V1 reduces and de-duplicates them. Strictly fewer,
never more — see PO-EVALCOUNT.

## F7 — [SCOPE note, not a V1 bug] `Field.has_changed` None/'' folding abstracted
The fragment models `fieldHasChanged` for the non-disabled case as `initial =/= data`,
abstracting the `None`-vs-`''` normalization and per-subclass overrides
(`MultiValueField`, `JSONField`, …). This is sound for the refinement claim because
V0 and V1 call the *same* `field.has_changed(initial_value, data_value)` with equal
arguments; the abstraction `hcPred(N)` stands for whatever that field computes. No
finding against V1; noted so the abstraction is explicit.

---

### Proof-derived findings from `/verify`
- The only obligation whose discharge is *not* a syntactic equality is
  `(CLEAN-DISABLED-CONSISTENCY)` — and it is exactly where V0 failed. Its proof needs
  the cache-coherence lemma `(BF-INIT-HIT)`; that this lemma is *needed* is the formal
  fingerprint of F1. (`PROOF.md` §3.)
- No VC required an *invented* precondition for V1 (contrast: V0 admits none either,
  but its target equality is simply false). The single genuine side condition is
  `N ∉ initCache` on the first read, discharged by the empty-cache form at form init.
- Termination of the two loops is not proved (partial correctness); both iterate the
  finite `self.fields` list and obviously terminate — recommendation, not obligation.
