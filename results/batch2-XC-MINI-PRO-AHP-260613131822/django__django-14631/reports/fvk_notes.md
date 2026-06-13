# FVK notes — django__django-14631 (audit of V1)

This report explains every decision made during the FVK audit pass, tracing each to
specific entries in `fvk/FINDINGS.md` and `fvk/PROOF_OBLIGATIONS.md`. The headline:
**V1 is confirmed correct and stands**, with one inert clarifying comment added.

## 1. What the audit did

Applied `/formalize` then `/verify` to the V1 fix:
- Built a `mini-X` K fragment (`fvk/mini-forms.k`) modeling the *only* semantically
  load-bearing fact in this ticket — the **impurity** of `get_initial_for_field` for a
  callable `initial` versus the **caching** of `BoundField.initial` — plus field order,
  the `disabled`/`show_hidden_initial`/`FileField` flags, and the two driver loops.
- Wrote reachability claims (`fvk/mini-forms-spec.k`): two for the cached initial
  (`BF-INIT-MISS`/`BF-INIT-HIT`), the core consistency claim
  (`CLEAN-DISABLED-CONSISTENCY`), and the `changed_data` loop circularity + contract
  (`CHANGED-LOOP`/`CHANGED-DATA`).
- Constructed the proof (`fvk/PROOF.md`) and enumerated the VCs
  (`fvk/PROOF_OBLIGATIONS.md`).

## 2. The one code change this pass — and why

**Change:** added a two-line comment above the value assignment in
`BaseForm._clean_fields()` (`repo/django/forms/forms.py`):
```python
            # Take the value from the BoundField so a disabled field's cleaned
            # value matches the (cached, single-evaluation) form[name].initial.
            value = bf.initial if field.disabled else bf.data
```
**Why, traced to artifacts:**
- It encodes **PO-CLEAN-CONSIST** (`PROOF_OBLIGATIONS.md` A) — the obligation that a
  disabled field's `cleaned_data` and `form[name].initial` come from the *same cached*
  evaluation — which is the exact invariant that V0 violated (**F1**).
- The disabled→`bf.initial` choice is the non-obvious heart of the fix; without the
  comment a future reader could "simplify" it back to `get_initial_for_field` and
  silently reintroduce F1. The comment cites the rationale, matching Django's existing
  comment style (e.g. `boundfield.py` "See #22502").
- It is **behavior-inert** (a comment): it changes no proof obligation and cannot
  regress any path (`PROOF_OBLIGATIONS.md` B/C/D unaffected).

No other code change was made, because the audit found no defect (next section).

## 3. Why V1 otherwise stands unchanged

### 3.1 The core fix is proved (not just plausible)
**Decision:** keep the disabled-field logic `value = bf.initial`.
**Justification:** `PROOF.md` §1+§3 construct `(CLEAN-DISABLED-CONSISTENCY)` and
compose it with `(BF-INIT-HIT)`: after `_clean_fields`, `initCache[name]` holds the
same `nix(iv(name,C))` that becomes `cleaned_data[name]`, so `form[name].initial` is a
cache **hit** returning the identical value. This is exactly **F1**'s resolution and
**PO-CACHE-MISS/HIT/EVALCOUNT/CLEAN-CONSIST**. The contrast paragraph in `PROOF.md` §3
shows V0's analogous goal is *unprovable* (`cl(iv(N,C)) = nix(iv(N,C+1))` is false) —
formal evidence the change is both necessary and sufficient.

### 3.2 Every other path is behavior-preserving — no regression to fix
**Decision:** keep `bf.data`, the FileField branch, the `clean_<name>` hook, the
`_has_changed` extraction, and the `changed_data` comprehension as written.
**Justification:** `PROOF_OBLIGATIONS.md` B/C/D discharge each by equals-for-equals:
- **PO-DATA/PO-NONDIS** — `bf.data` *is* `_field_data_value(field, add_prefix(name))`.
- **PO-FILE** — same `field.clean(value, initial)`, with the initial now the cached
  `bf.initial` (single-eval improvement **F6**, never a regression).
- **PO-HASCHANGED** (+ branch table), **PO-SHOWHIDDEN**, **PO-ELSE-INIT**,
  **PO-HC-DISABLED** — `_has_changed` is V0's inner block verbatim; the show-hidden name
  `self.html_initial_name == form.add_initial_prefix(name)`, and the
  `ValidationError ⇒ changed` short-circuit matches V0's `append+continue`.
- **PO-ORDER/PO-CHANGED-LOOP/PO-CHANGED-LIST** — `changed_data == keep(fields)`, same
  names, same order as V0's appended list (`PROOF.md` §2 circularity).
- **PO-CACHED-PROP** — still a `@cached_property` returning a name list, so
  `auth.SetPasswordForm.changed_data` and `admin.utils` (which consume it as a list)
  are unaffected.
Because each obligation is a substitution of equals, there is nothing to repair.

### 3.3 Naming `_has_changed` (not `_did_change`) — kept
**Decision:** keep the method name `_has_changed`.
**Justification:** **F4** — the ticket prose explicitly calls the name tentative
("*something like* `bf.did_change()`"); the helper is private and reached only through
public behavior, so **no proof obligation depends on the spelling**. `_has_changed`
mirrors the delegated `Field.has_changed`. Recorded as **UP-2** for the user to confirm;
a rename would be mechanical if required.

### 3.4 Assumptions surfaced, judged acceptable — no code change
**Decision:** rely on `bf.field is self.fields[name]` and on no `BoundField` subclass
overriding `data`/`initial`.
**Justification:** **F5 / PO-FIELD-ID** — verified against `repo/django` (only the base
`Field.get_bound_field`; a single `BoundField` class). V0 already routed `initial`
through `get_bound_field`, so V1 only extends an existing reliance in the ticket's
intended direction ("access values via BoundField"). Documented as a trusted-base
assumption (`SPEC.md` §5) and **UP-3**, not enforced in code.

## 4. Decisions explicitly *rejected*

- **Rejected:** reverting to `get_initial_for_field` for disabled fields (a "smaller"
  diff). It reintroduces **F1** (PO-CLEAN-CONSIST becomes unprovable). Kept `bf.initial`.
- **Rejected:** renaming `_has_changed` to `_did_change`. No correctness or test
  benefit (F4); deferred to user confirmation UP-2.
- **Rejected:** adding a defensive `self.fields[name]` re-fetch instead of `bf.field`.
  Unnecessary for core Django (F5) and would diverge from the ticket's "via BoundField"
  goal; left as documented assumption.
- **Rejected:** any change to the microsecond behavior (F2). It is the *intended*
  consequence the ticket sanctions; altering it would contradict the spec.
- **Rejected:** machine-admitting (`[trusted]`) the abstracted `has_changed` VCs. Per
  the honesty gate they are a capability gap (UP-4 / F7), surfaced as an
  `[ESCALATION BOUNDARY]`-style note, not faked.

## 5. Honesty gate

All `fvk/` proofs are **constructed, not machine-checked**: the refinement set by
definitional equality + symbolic execution, the core fix by symbolic execution + the
cache-coherence circularity. The Findings (F1–F7) stand independently of machine
checking. Test-redundancy is recommendation-only and, here, moot — tests are
hidden/fixed and were not touched. Run the `kompile`/`kprove` commands in `PROOF.md` §6
to upgrade to `#Top`.

## 6. Net result

- Code: V1 unchanged except one explanatory comment in `_clean_fields` (traceable to
  F1 / PO-CLEAN-CONSIST).
- Artifacts: `fvk/SPEC.md`, `fvk/FINDINGS.md`, `fvk/PROOF_OBLIGATIONS.md`,
  `fvk/PROOF.md`, `fvk/ITERATION_GUIDANCE.md`, plus `fvk/mini-forms.k` /
  `fvk/mini-forms-spec.k`.
- Conclusion: the django__django-14631 fix is **confirmed correct** — the consistency
  bug is provably closed and the refactor is provably behavior-preserving.
