# SPEC.md — Formal specification of the django__django-14631 fix

**Status:** constructed, not machine-checked (FVK MVP). Fragment semantics in
`fvk/mini-forms.k`; K claims in `fvk/mini-forms-spec.k`.

## 0. Scope — what was formalized

The V1 fix touches four units. Their *intended* behavior (from `benchmark/PROBLEM.md`,
the ticket hint, and the surrounding code) is specified below, together with the
formal contract that captures it.

| Unit | File | Role |
|---|---|---|
| `BaseForm._bound_items()` | `forms.py` | generator yielding `(name, self[name])` in field order |
| `BaseForm._clean_fields()` | `forms.py` | populate `cleaned_data` from each `BoundField` |
| `BaseForm.changed_data` | `forms.py` | list of names whose data changed |
| `BoundField._has_changed()` | `boundfield.py` | per-field change predicate (moved off the form) |

The single semantic fact the whole ticket turns on, and which the fragment models
faithfully, is the contrast between two ways of reading a field's initial value:

- **`get_initial_for_field(field, name)`** is *impure* for a callable `initial`
  (`initial=datetime.datetime.now`, `initial=lambda: now`): it calls the callable
  **every** time, so two calls can return two different values. Modeled as
  `getRawInitial(N) ⇒ iv(N, C)` with a side-effecting per-name counter `C`.
- **`BoundField.initial`** is a `@cached_property` that (a) evaluates
  `get_initial_for_field` **once** and caches, and (b) normalizes microseconds for
  datetime/time whose widget has `supports_microseconds == False`. Modeled as
  `bfInitial(N) ⇒ nix(iv(N, C))` with a cache (`<initCache>`): miss evaluates+stores,
  hit is a pure read.

## 1. Intent contracts

### `_bound_items()` — ordered, cache-stable pairing
**Intent:** yield `(name, bf)` for every field, in `self.fields` order, where each
`bf` is the *cached* `BoundField` (`self[name]` populates/reads `_bound_fields_cache`).
**Contract:** the sequence of names equals the order of `<fields>`; `bf` for a name is
referentially stable across `_clean_fields`, `changed_data`, and template access (same
object ⇒ same cached `.initial`). This stability is what makes §3 hold.

### `_clean_fields()` — clean each field through its BoundField
**Precondition (domain):** `is_bound`; the empty-permitted short-circuit already
handled by `full_clean`. **Postcondition:** for each field `name`, in order,
```
value      = bf.initial            if field.disabled
           = bf.data               otherwise
cleaned    = field.clean(value, bf.initial)   if FileField
           = field.clean(value)               otherwise
cleaned_data[name] = clean_<name>() if defined else cleaned   (on success)
add_error(name, e)                  on ValidationError
```
Formal claim **(CLEAN-DISABLED-CONSISTENCY)**: for a disabled non-File field whose
initial is not yet cached, after `cleanOne(N)` we have
`cleaned_data[N] = cl(nix(iv(N,C)))` **and** `initCache[N] = nix(iv(N,C))` — i.e.
`cleaned_data[N]` and `form[N].initial` are computed from the *one* cached evaluation.

### `changed_data` — names that changed, in order
**Postcondition:** `changed_data == keep(fields)`, the field-ordered sublist of names
with `_has_changed()` true. Formal claims **(CHANGED-LOOP)** (loop circularity) and
**(CHANGED-DATA)** (function contract).

### `BoundField._has_changed()` — the per-field predicate
**Postcondition** (`hasChanged(N)` in the fragment):
```
if field.show_hidden_initial:
    iv = to_python(hidden-widget value at html_initial_name)
    if that raised ValidationError: return True
    return field.has_changed(iv, self.data)
else:
    return field.has_changed(self.initial, self.data)
```
This is exactly the body lifted out of V0's `changed_data` loop (`PO-HASCHANGED`).

## 2. The two reachability claims for `BoundField.initial`

- **(BF-INIT-MISS)** `bfInitial(N)` with `N ∉ initCache` ⇒ returns `nix(iv(N,C))`,
  caches it, and increments `evalCount[N]` by exactly 1.
- **(BF-INIT-HIT)** `bfInitial(N)` with `N ↦ V ∈ initCache` ⇒ returns `V`, **no**
  change to `evalCount`.

Corollary (single-evaluation): across any number of reads of `bf.initial`, the
callable `initial` is evaluated at most once, and every reader observes the same value.

## 3. The core consistency theorem (what V1 establishes, V0 violated)

> For a disabled field `name`, the value stored in `cleaned_data[name]` by
> `_clean_fields()` is derived from the **same cached** `BoundField.initial` that
> `form[name].initial` returns. Hence they cannot disagree because of a second,
> independent evaluation of a callable `initial`, nor because of the microsecond
> normalization that only `BoundField.initial` applies.

Formally: compose **(CLEAN-DISABLED-CONSISTENCY)** with **(BF-INIT-HIT)**. After
`cleanOne(N)`, `initCache[N] = nix(iv(N,C))`, so a later `form[N].initial`
(`bfInitial(N)`) is a cache **hit** returning `nix(iv(N,C))`, the very value fed to
`field.clean` for `cleaned_data[N]`. With `cl` the identity on an already-valid
initial — the ticket's case, `DateTimeField.to_python(datetime) == datetime`
(`PO-CLEAN-ID`) — `cleaned_data[name] == form[name].initial` outright, matching the
adjusted `test_datetime_clean_initial_callable_disabled`.

## 4. Refinement claim (no regression on every other path)

V1 must equal V0 everywhere except the intended consistency change. The obligations
are enumerated in `fvk/PROOF_OBLIGATIONS.md`; in summary each rewritten expression is
a *definitional substitution of equals*:

- `bf.data` ≡ `self._field_data_value(field, self.add_prefix(name))` (since
  `bf.html_name == form.add_prefix(name)` and `bf.field is self.fields[name]`);
- non-disabled `_clean_fields` value, the `clean_<name>` hook, and the
  `ValidationError` handling are textually unchanged;
- `_has_changed` is V0's inner block verbatim, with `self.html_initial_name ==
  form.add_initial_prefix(name)` and `self.initial == self[name].initial`;
- `changed_data` order/membership = `keep(fields)` = V0's appended list.

## 5. Assumptions / trusted base

1. **Fragment adequacy.** `mini-forms.k` models the *relevant* fragment only
   (caching, impurity, ordering, the two loops). HTML/widget/validator behavior is
   abstracted into the pure symbols `dv`, `cl`, `nix`, `hcPred`.
2. **`bf.field is self.fields[name]`** and **no `BoundField` subclass overrides
   `data`/`initial`.** Verified for core Django (only `Field.get_bound_field` exists;
   one `BoundField` class). A third-party `get_bound_field` returning a BoundField
   that wraps a *different* field would break the refinement — recorded as F6.
3. **`cl` is a pure function**, and the **identity on already-valid initials**
   (`PO-CLEAN-ID`) for the outright-equality corollary.
4. **Partial correctness / constructed-not-checked**, per the FVK honesty gate.
