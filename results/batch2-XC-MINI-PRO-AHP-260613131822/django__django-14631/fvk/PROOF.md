# PROOF.md — constructed correctness proof for django__django-14631

**CONSTRUCTED, NOT MACHINE-CHECKED (FVK MVP).** Symbolic execution against
`fvk/mini-forms.k`; claims in `fvk/mini-forms-spec.k`. The MVP builds the proof and
emits the run-commands but does not invoke `kompile`/`kprove`.

## What is proved (plain language)

1. **The fix is real.** For a disabled field, `_clean_fields()` stores into
   `cleaned_data[name]` a value taken from the *same cached* `BoundField.initial`
   that `form[name].initial` returns; a callable `initial` is evaluated exactly once.
   Therefore `cleaned_data[name]` and `form[name].initial` can no longer disagree the
   way V0 allowed (`test_datetime_clean_initial_callable_disabled`).
2. **The refactor is safe.** On every other path V1 reduces, by equals-for-equals
   substitution and identical symbolic execution, to V0: `changed_data` returns the
   same ordered list of names, `_clean_fields` produces the same `cleaned_data`, and
   `_has_changed` computes V0's per-field predicate.

---

## 1. Proof of (BF-INIT-MISS) and (BF-INIT-HIT) — `BoundField.initial` is single-evaluation

**(BF-INIT-MISS).** Goal `⟨k⟩ bfInitial(N) ⇒ nix(iv(N,C)) …` with `N ∉ initCache`,
`evalCount[N] = C`.
- Axiom `bfInitial`-miss (side condition `notBool (N in_keys(Cache))` holds): `⟨k⟩`
  becomes `getRawInitial(N) ~> #nixStore(N)`. **(genuine `=>` step #1)**
- Axiom `getRawInitial`: head `⇒ iv(N,C)`, framing carries `#nixStore(N)`; the
  `<evalCount>` cell rewrites `C => C +Int 1`. Now `⟨k⟩ = iv(N,C) ~> #nixStore(N)`.
- Axiom `#nixStore`: `iv(N,C) ~> #nixStore(N) ⇒ nix(iv(N,C))`, and `<initCache>`
  rewrites `Cache => Cache[N <- nix(iv(N,C))]`.
- Reflexivity. ∎ Result: returns `nix(iv(N,C))`, caches it, `evalCount[N] = C+1`.

**(BF-INIT-HIT).** Goal `⟨k⟩ bfInitial(N) ⇒ V …` with `N ↦ V ∈ initCache`.
- Axiom `bfInitial`-hit: matches `N |-> V` in `<initCache>`, head `⇒ V`; **no** other
  cell rewrites — `<evalCount>` is untouched (framing). Reflexivity. ∎

**Corollary (single-evaluation).** Any read sequence `bfInitial(N) … bfInitial(N)`:
the first is a MISS (`evalCount`: `C→C+1`, cache `→ nix(iv(N,C))`); every later read
matches HIT and returns `nix(iv(N,C))` with `evalCount` frozen. So the callable
`initial` fires once and all readers agree. This is the lemma F1/PO-CACHE rests on.

---

## 2. Proof of (CHANGED-LOOP) by guarded coinduction, then (CHANGED-DATA)

**(CHANGED-LOOP).** Goal, generalized over `Ns, Acc`:
`⟨k⟩ #changedLoop(Ns, Acc) ⇒ .K …  ⟨changed⟩ _ ⇒ Acc keep(Ns)`.

K registers this very claim as a **circularity** (coinduction hypothesis), usable only
after ≥1 genuine step (guardedness). Case-split on `Ns`:

- **`Ns = .List` (base).** Axiom `#changedLoop(.List,Acc)`: `⟨k⟩ ⇒ .K`, `⟨changed⟩ _ ⇒
  Acc`. Consequence: `keep(.List) = .List` (def), so `Acc = Acc keep(.List)`. ∎ branch.
- **`Ns = ListItem(N) Rest` (step).** Axiom `#changedLoop`(cons): `⟨k⟩ ⇒ hasChanged(N)
  ~> #decide(N,Rest,Acc)` **(genuine step — earns the hypothesis).** Evaluate
  `hasChanged(N)`; by the `[simplification]` `hasChanged(N) ⇒ hcPred(N)` it cools to the
  Bool `B = hcPred(N)`. Case-split (`#Or`) on `B`:
  - `B = true`: Axiom `#decide`-true ⇒ `#changedLoop(Rest, Acc ListItem(N))`. **Invoke
    the circularity** on the shifted state: reaches `⟨changed⟩ (Acc ListItem(N))
    keep(Rest)`. Consequence with `keep` def (`hcPred(N)` true): `ListItem(N) keep(Rest)
    = keep(ListItem(N) Rest)`, so target `Acc keep(Ns)`. ✓
  - `B = false`: Axiom `#decide`-false ⇒ `#changedLoop(Rest, Acc)`. Invoke circularity:
    `⟨changed⟩ Acc keep(Rest)`. Consequence (`hcPred(N)` false): `keep(Rest) =
    keep(ListItem(N) Rest)`, target `Acc keep(Ns)`. ✓

  Both branches land on the claimed post-state; the appeal to the hypothesis followed a
  genuine `=>` step, so guardedness holds. ∎

**(CHANGED-DATA).** `⟨k⟩ changedData() ⇒ .K …  ⟨changed⟩ _ ⇒ keep(Ns)` with
`⟨fields⟩ Ns`.
- Axiom `changedData`: `⇒ #changedLoop(Ns, .List)`.
- Use **(CHANGED-LOOP)** as a lemma at `Acc = .List`: reaches `⟨changed⟩ .List keep(Ns)
  = keep(Ns)`. ∎

This is the refactored `[name for name, bf in self._bound_items() if bf._has_changed()]`
returning the field-ordered changed names — equal to V0's appended `data` list
(`hcPred(N)` is V0's per-field predicate, PO-HASCHANGED).

---

## 3. Proof of (CLEAN-DISABLED-CONSISTENCY) — the core fix

Goal: `⟨k⟩ cleanOne(N) ⇒ .K`, with `disabled[N]=true`, `isFile[N]=false`,
`N ∉ initCache`, `evalCount[N]=C`, ending
`⟨initCache⟩ … N ↦ nix(iv(N,C))` and `⟨cleaned⟩ … N ↦ cl(nix(iv(N,C)))`.

- Axiom `cleanOne`-disabled (`disabled[N]=true`): `⟨k⟩ ⇒ bfInitial(N) ~> #file(N)`.
- Evaluate `bfInitial(N)` by **(BF-INIT-MISS)** (lemma, §1): cools to `nix(iv(N,C))`;
  `<initCache>` now holds `N ↦ nix(iv(N,C))`, `evalCount[N]=C+1`. State:
  `nix(iv(N,C)) ~> #file(N)`.
- Axiom `#file`-nonfile (`isFile[N]=false`): `⇒ cleanVal(nix(iv(N,C))) ~> #store(N)`.
- Axiom `cleanVal`: `⇒ cl(nix(iv(N,C)))`. State: `cl(nix(iv(N,C))) ~> #store(N)`.
- Axiom `#store`: `⇒ .K`, `<cleaned>` rewrites `Cl => Cl[N <- cl(nix(iv(N,C)))]`.
- Reflexivity. ∎

**Compose with (BF-INIT-HIT) to get the ticket property.** After `cleanOne(N)`,
`initCache[N] = nix(iv(N,C))`. A subsequent `form[N].initial` is `bfInitial(N)` →
**HIT** → `nix(iv(N,C))`. Meanwhile `cleaned_data[N] = cl(nix(iv(N,C)))`. By PO-CLEAN-ID
(`cl` fixes a valid initial — `DateTimeField.to_python(datetime)=datetime`),
`cleaned_data[N] = nix(iv(N,C)) = form[N].initial`. **QED — V1 satisfies the adjusted
`test_datetime_clean_initial_callable_disabled`.**

**Contrast (why V0 fails this VC).** V0 `cleanOne` would fire `getRawInitial(N) ⇒
iv(N,C)` (no `#nixStore`, counter `C→C+1`) and store `cl(iv(N,C))`; the later
`form[N].initial` MISS evaluates `getRawInitial(N) ⇒ iv(N,C+1)` and caches
`nix(iv(N,C+1))`. The post-state equality `cl(iv(N,C)) = nix(iv(N,C+1))` is **false**
(`C ≠ C+1`, and the missing `nix`), so no proof exists. The unprovability *is* F1.

---

## 4. Composition — `full_clean` level

`full_clean` (unchanged) calls, in order: optionally `has_changed()` (→ `changed_data`
→ §2, which also warms `initCache` via `_has_changed`'s `self.initial` reads), then
`_clean_fields()` (→ §3 per field, plus the verbatim non-disabled / FileField /
`clean_<name>` / `add_error` steps, PO-NONDIS/PO-FILE/PO-HOOK by EQ). Because every
`bf.initial` read after the first is a HIT (§1), the warming order is irrelevant:
`_clean_fields`, `changed_data`, and template rendering all observe the one cached
initial. This closes the cross-method consistency the ticket asked for ("reduce the
number of code paths").

---

## 5. Residual risk (honesty gate)

- **Constructed, not machine-checked.** Upgrade by running the commands below to a
  `#Top`. Until then, treat the proof as a rigorous hand construction.
- **Partial correctness.** Termination of the two `self.fields` loops is obvious
  (finite list, strictly shrinking remainder) but not formally discharged (PO-TERM,
  recommendation).
- **Trusted base.** (i) Adequacy of the `mini-forms.k` fragment — it models caching,
  impurity, ordering, and the two loops, abstracting widgets/validators into pure
  `dv/cl/nix/hcPred`; (ii) PO-CLEAN-ID and PO-FIELD-ID (SPEC §5); (iii) K reachability
  metatheory + Z3 / `[simplification]` oracle.
- **Spec-difficulty = bug signal (benefit 2).** The only obligation needing more than
  syntactic equality is the one V0 violated (§3); its proof *requires* the
  cache-coherence lemma. That asymmetry is the formal evidence the fix is both
  necessary and sufficient.

---

## 6. Test-redundancy (recommendation only — conditioned on machine-checking)

> Per the FVK honesty gate this **never deletes tests**; it advises. Tests here are
> hidden/fixed and must not be modified — treat this as analysis of the *kind* of
> coverage the proof subsumes, for the next iteration.

- **Subsumed-if-machine-checked** (in-domain points the contracts cover):
  - `test_datetime_clean_initial_callable_disabled` (adjusted: `cleaned_value ==
    bf.initial`) ⊑ `(CLEAN-DISABLED-CONSISTENCY)`+`(BF-INIT-HIT)` — proved for *all*
    disabled fields with a valid initial, not just `datetime`.
  - `test_datetime_changed_data_callable_with_microseconds` (`changed_data == []` for a
    disabled field) ⊑ `(CHANGED-DATA)` + PO-HC-DISABLED (`fieldHasChanged ⇒ false` when
    disabled).
- **Keep regardless:**
  - `show_hidden_initial` change-detection tests (`test_forms.py` ~2018/2798) — exercise
    the `to_python`/`ValidationError ⇒ changed` branch (PO-SHOWHIDDEN); keep until that
    branch's `hcPred` abstraction is concretized.
  - FileField / ModelForm integration (clear-checkbox, `bound_data`) — integration, not
    the unit contract.
  - Any test pinning the *old* microsecond-preserving disabled behavior is **out of
    domain** for V1 (F2) and must be the adjusted version, not kept as-is.
- **CI estimate:** negligible; this fix's value is correctness (benefit 2), not test
  reduction (benefit 1).

## Reproduce the machine check
```sh
kompile fvk/mini-forms.k --backend haskell        # compile the fragment semantics
kast    --backend haskell fvk/mini-forms-spec.k   # (optional) confirm the claims parse
kprove  fvk/mini-forms-spec.k                      # expected: #Top  (all claims proved)
```
A `#Top` upgrades every result above from *constructed* to *machine-verified*.
