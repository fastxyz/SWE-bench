# PROOF_OBLIGATIONS.md — django__django-14631

The verification conditions that must hold for the V1 fix to be (a) the intended
consistency fix and (b) a behavior-preserving refactor on every other path. Each row:
the obligation, how it is discharged, and its status. Discharge tiers: **EQ** =
syntactic/definitional equality (equals-for-equals substitution), **SE** = symbolic
execution against `mini-forms.k`, **Z3** = linear side condition, **ASSUME** = trusted
base (stated in SPEC §5).

## A. Core consistency (the fix)

| ID | Obligation | Discharge | Status |
|---|---|---|---|
| **PO-CACHE-MISS** | First `bf.initial` read evaluates the initial once, normalizes, caches it. | SE: `bfInitial` miss → `getRawInitial` (counter+1) → `#nixStore`. Claim `(BF-INIT-MISS)`. | ✅ constructed |
| **PO-CACHE-HIT** | Later `bf.initial` reads return the cached value with no re-evaluation. | SE: `bfInitial` hit rule; `evalCount` untouched. Claim `(BF-INIT-HIT)`. | ✅ constructed |
| **PO-EVALCOUNT** | A callable `initial` is evaluated ≤ once per field per form (V0: up to 2–3×). | Z3 on `evalCount`: MISS sets it to `C+1`, HIT leaves it; monotone, single bump. | ✅ constructed |
| **PO-CLEAN-CONSIST** | For a disabled non-File field, `cleaned_data[N]` and `initCache[N]` come from the *same* cached evaluation. | SE: `(CLEAN-DISABLED-CONSISTENCY)` — `cleanOne(N)` writes `cl(nix(iv(N,C)))` to `<cleaned>` and `nix(iv(N,C))` to `<initCache>`. | ✅ constructed |
| **PO-CLEAN-ID** | Outright `cleaned_data[N] == form[N].initial` requires `field.clean` to fix the initial. | ASSUME: holds for valid initials, e.g. `DateTimeField.to_python(datetime) == datetime` — the ticket's case. Stated as precondition, not proved for arbitrary `cl`. | ✅ stated |

> **PO-CLEAN-CONSIST is the obligation V0 cannot meet.** Under V0, `cleanOne` would
> store `getRawInitial(N) = iv(N,C)` (no nix, fresh counter) while `form[N].initial`
> later caches `nix(iv(N,C+1))`. The two differ in *both* the counter and the `nix`,
> so the equality is unprovable — the formal statement of F1.

## B. Refinement — V1 ≡ V0 on all other paths (no regression)

| ID | Obligation | Discharge | Status |
|---|---|---|---|
| **PO-DATA** | `bf.data` == `self._field_data_value(field, self.add_prefix(name))`. | EQ: `BoundField.data` *is* `form._field_data_value(self.field, self.html_name)` and `html_name = form.add_prefix(name)`. | ✅ |
| **PO-NONDIS** | Non-disabled `_clean_fields` value unchanged. | EQ: V0 `value = _field_data_value(...)`; V1 `value = bf.data`; equal by PO-DATA. | ✅ |
| **PO-FILE** | FileField path unchanged up to the intended initial-caching. | EQ + PO-CACHE: V0 `field.clean(value, get_initial_for_field(...))`; V1 `field.clean(value, bf.initial)`. For non-callable initial `bf.initial == get_initial_for_field` (no nix on files); for callable, single-eval improvement (F6). | ✅ |
| **PO-HOOK** | `clean_<name>` override + `add_error`/`ValidationError` handling unchanged. | EQ: lines textually identical between V0 and V1. | ✅ |
| **PO-FIELD-ID** | `field = bf.field` is `self.fields[name]`. | ASSUME (F5): only base `get_bound_field`; `bf.field is self`. | ✅ stated |
| **PO-ORDER** | `_bound_items` / `changed_data` / `_clean_fields` iterate fields in `self.fields` order. | SE: loops drive over `<fields>` List head-first; `_bound_items` iterates `self.fields`. Claim `(CHANGED-DATA)` = `keep(fields)`. | ✅ constructed |

## C. `_has_changed` ≡ V0 inner loop body

| ID | Obligation | Discharge | Status |
|---|---|---|---|
| **PO-HASCHANGED** | `bf._has_changed()` computes V0's per-field predicate. | EQ branch-by-branch: see table below. Abstracted as `hcPred(N)`; both V0 and V1 reduce to it. | ✅ |
| **PO-SHOWHIDDEN** | show-hidden branch reads the same name and short-circuits identically. | EQ: `self.html_initial_name == form.add_initial_prefix(name)`; `to_python(...)` `ValidationError ⇒ True` mirrors V0 `append(name); continue`. SE rule `#hidden(verr) ⇒ true`. | ✅ |
| **PO-ELSE-INIT** | else branch initial == V0 `self[name].initial`. | EQ: `self.initial` on the cached BoundField is the same `cached_property` as `self[name].initial`. | ✅ |
| **PO-HC-DISABLED** | a disabled field is never reported changed. | SE: `fieldHasChanged(N,_,_) ⇒ false` when `disabled[N]` (mirrors `Field.has_changed` short-circuit). | ✅ |

### Branch correspondence for PO-HASCHANGED

| field state | V0 `changed_data` block | V1 `_has_changed` | equal? |
|---|---|---|---|
| `show_hidden_initial`, `to_python` OK | `field.has_changed(to_python(hidden), data_value)` | `field.has_changed(to_python(hidden), self.data)` | ✅ (PO-DATA, PO-SHOWHIDDEN) |
| `show_hidden_initial`, `to_python` raises | `data.append(name); continue` | `return True` | ✅ both ⇒ changed |
| not `show_hidden_initial` | `field.has_changed(self[name].initial, data_value)` | `field.has_changed(self.initial, self.data)` | ✅ (PO-ELSE-INIT, PO-DATA) |

## D. `changed_data` aggregation

| ID | Obligation | Discharge | Status |
|---|---|---|---|
| **PO-CHANGED-LOOP** | comprehension appends exactly the changed names, in order. | SE + Circularity `(CHANGED-LOOP)`: invariant `acc ++ keep(remaining)`; coinduction discharges the loop. | ✅ constructed |
| **PO-CHANGED-LIST** | `changed_data == keep(fields)` == V0's appended list. | Transitivity: `(CHANGED-DATA)` from `(CHANGED-LOOP)` at `Acc=.List`. | ✅ constructed |
| **PO-CACHED-PROP** | `changed_data` cached_property + `has_changed()` semantics preserved (returns list of names; `bool(list)`). | EQ: still a `@cached_property` returning a name list; `has_changed` unchanged; `auth.SetPasswordForm.changed_data`/`admin.utils` contracts intact. | ✅ |

## E. Termination (recommendation only — partial correctness default)
- **PO-TERM** (not required): both loops iterate the finite `self.fields`; each step
  consumes one `ListItem`, measure `size(remaining)` strictly decreases, bounded below
  by 0. Trivially terminating; flagged, not discharged (FVK default).

## Summary
All A–D obligations are discharged as **constructed (not machine-checked)**: the
refinement set (B/C/D) by definitional equality and symbolic execution; the core
fix (A) by symbolic execution plus the cache-coherence circularity. The only
non-mechanical assumptions are PO-CLEAN-ID, PO-FIELD-ID (SPEC §5 trusted base), both
satisfied for core Django and the ticket scenario.
