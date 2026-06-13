# PROOF.md — constructed correctness proof (django__django-11138 V1)

**CONSTRUCTED, NOT MACHINE-CHECKED.** The FVK MVP builds the proof and emits the
`kompile`/`kprove` commands but does not run the toolchain. A `#Top` from
`kprove` would upgrade this from *constructed* to *machine-verified*.

Artifacts: [`tzconvert.k`](tzconvert.k), [`tzconvert-spec.k`](tzconvert-spec.k).
Obligations: [`PROOF_OBLIGATIONS.md`](PROOF_OBLIGATIONS.md).

---

## 1. What is proved

For the **SQL backends** (MySQL & Oracle), *for every* stored wall-clock `F`,
database zone `C`, and active zone `T`, with `USE_TZ` true:

> the transform `_convert_field_to_tz` emits SQL whose database denotation is
> exactly `SPEC(F,C,T) = wallOf(instant(F,C), T)` — the stored instant re-read in
> the active zone. With `USE_TZ` false it emits the bare column (no conversion).

For **SQLite**, the in-process `_sqlite_datetime_parse` returns exactly
`SPEC(F,C,T)` **whenever `C = T` or `C = "UTC"`** (which includes every scenario
in `PROBLEM.md` and every default deployment); the remaining slice — named
non-UTC `C` with `C ≠ T` — is *not* proved and is reported as Finding **F1**
(pytz LMT), an intentional, documented imprecision shared with upstream.

No loops or recursion appear in the changed code, so there are **no circularity
claims and no termination obligation** — each contract is a terminating
straight-line/branch execution.

## 2. The claims (reachability rules)

```
(MYSQL/ORACLE)  denote(gen(true,  C, T), F, C)  =>  wallOf(instant(F, C), T)      [all-path]
(SQL-OFF)       denote(gen(false, C, _), F, C)  =>  F                              [all-path]
(SQLITE)        parse(F, C, T)                  =>  wallOf(instant(F, C), T)
                  requires (C ==String T orBool C ==String "UTC") andBool C =/=String ""   [all-path]
(SQLITE-OFF)    parse(F, "", _)                 =>  F                              [all-path]
```

## 3. Proof — short English

**(MYSQL/ORACLE).** Evaluate `gen(true, C, T)`. Its definition splits on the
guard `C ==String T` (Case Analysis); the split is exhaustive (VC-M1c).

- *Branch `C ≠ T`.* `gen ⇒ convert(field, C, T)` (one Axiom step — guardedness is
  irrelevant, no hypothesis is reused). Apply the `denote` rule for `convert`:
  `denote(convert(field,C,T),F,C) ⇒ wallOf(instant(denote(field,F,C),C),T)`, then
  the `denote(field,…) ⇒ F` rule gives `wallOf(instant(F,C),T)` = RHS. ∎ (VC-M1a, Z3)
- *Branch `C = T`.* The guard is **string** equality; it is a *sound* trigger
  (VC-EQ / F8: equal canonical names ⟹ equal zones), so `T = C` may be
  substituted. `gen ⇒ field`; `denote(field,F,C) ⇒ F`. The goal RHS is
  `wallOf(instant(F,C),T)`; with `T = C` apply axiom **RT**
  `wallOf(instant(F,C),C) ⇒ F`. Both sides are `F`. ∎ (VC-M1b, LEMMA RT)

Both branches reach the same post-state ⇒ by Case Analysis the claim holds for
all `F, C, T`. Oracle is the identical derivation (`convert` models its
`FROM_TZ..AT TIME ZONE` form; same denotation).

**(SQL-OFF).** `gen(false,…) ⇒ field`; `denote(field,F,C) ⇒ F`. ∎ (VC-M2)

**(SQLITE).** Evaluate `parse(F, C, T)` under the precondition
`(C = T ∨ C = "UTC") ∧ C ≠ ""`. Case-split:

- *`C = T`.* `parse ⇒ F` (equal-zone rule). RHS `wallOf(instant(F,C),C) ⇒ F` by
  **RT**. ∎ (VC-S1')
- *`C = "UTC"`, `C ≠ T`.* `parse ⇒ wallOf(instReplace(F,"UTC"),T)`; axiom **UTC**
  rewrites `instReplace(F,"UTC") ⇒ instant(F,"UTC")`, giving `wallOf(instant(F,
  "UTC"),T)` = RHS (since `C = "UTC"`). ∎ (VC-S1)

The precondition makes the split exhaustive, so the claim holds on its stated
domain. **(SQLITE-OFF)** is the single rule `parse(F,"",_) ⇒ F`. ∎ (VC-S4)

**The open obligation (VC-S2).** Off-domain (`C ≠ "UTC" ∧ C ≠ T`), closing the
claim would need `instReplace(F,C) = instant(F,C)`, which is **false** (pytz LMT).
Not discharged, not trusted → Finding F1. See §5.

## 4. Machine-detailed sketch (for `kprove`)

`gen`, `parse`, `denote` are `[function]`; `instant`, `wallOf`, `instReplace` are
`[function, functional]` (total). The prover:

1. unfolds `gen`/`parse` by the matching defining rule, generating the guard as a
   path condition (`#And`-ed `requires`);
2. for `convert`, applies the `denote` `[simplification]`-style rewrite, then the
   `denote(field,…)` rule;
3. discharges the equal-zone and UTC collapses with the **RT** / **UTC**
   `[simplification]` lemmas;
4. closes each branch to `#Top`; `K-EQUAL` reduces the cell `#Equals` to the
   scalar `Int` equality, dispatched by Z3.

No `[simplification]` lemma reduces `instReplace(_, Z)` for general `Z`, so the
off-domain SQLite goal stays open by construction (intended).

## 5. Residual risk (and the one engineering decision)

- **Partial vs total correctness:** N/A — no loops; nothing to not-terminate.
- **Trusted base:** the algebra axioms RT/UTC, the DB-side equivalence of
  `CONVERT_TZ`/`FROM_TZ`, the DST-totality abstraction (F6), and the
  *constructed-not-checked* status. See `PROOF_OBLIGATIONS.md` "Trusted base".
- **F1 / VC-S2 — kept deliberately.** The audit could not write a clean SQLite
  contract for *named non-UTC DB zone under a different active zone* — by the
  kit's "spec-difficulty = bug signal" rule that is surfaced, not hidden. The fix
  was **not** changed because the only alternative
  (`make_aware(dt.replace(tzinfo=None), pytz.timezone(C))`):
  1. is **identical** to V1 on every in-scope input (`C=T` skips it; `C="UTC"`
     has no LMT), so it would not change any behaviour the issue or default
     deployments exercise; and
  2. **adds a failure mode** — `AmbiguousTimeError`/`NonExistentTimeError` on
     DST-edge stored values that `.replace` tolerates (F6) — and diverges from
     the existing backend behaviour.

  Trading a rare silent imprecision for a new exception path is not an
  improvement, so **V1 stands** with F1 documented and routed to UltimatePowers
  question PD2. This is the FVK "stop with the evidence package" outcome, not a
  silent patch.

> **Input → observed vs expected (the F1 example), kept visible per the kit:**
> `F=2017-07-06 20:50:00, C='Europe/Paris', T='America/New_York'` → observed
> `2017-07-06 16:40:39` (LMT path); expected `2017-07-06 14:50:00`. In-scope
> inputs (`C=T`, or `C='UTC'`) → observed == expected.

## 6. Test-redundancy recommendation (benefit 1)

**Recommendation only — never auto-delete; conditioned on first running
`kprove` to `#Top`.** Mapping the proved contracts onto typical tests:

- **Subsumed once machine-checked** — single-point assertions on the *SQL string*
  or result of a date/time lookup that fall **inside** a proved domain:
  - any MySQL/Oracle `__date`/`__hour`/`Trunc` assertion with a fixed `(C,T)`
    (incl. the equal-zone "no `CONVERT_TZ`" string) ← claim `MYSQL`/`ORACLE`,
    proved for *all* `C,T`;
  - any SQLite assertion with `C = T` or `C = 'UTC'` ← claim `SQLITE` on-domain.
  Each is one in-domain point of a universally-proved contract.
- **Keep — outside the verified domain or trusted base (high value):**
  - **SQLite, named non-UTC `C` with `C ≠ T`** — the F1/VC-S2 corner; the proof
    says nothing here, so these tests are exactly where a regression would show.
  - tests asserting the **DB-engine** semantics of `CONVERT_TZ`/`FROM_TZ`
    (trusted-base assumption #2, not proved);
  - **DST-boundary** behaviour (F6, abstracted);
  - integration/migration tests that set `DATABASES[...]['TIME_ZONE']` end-to-end.

No machine check has been run, so **keep all tests for now**; revisit removals
only after `kprove` returns `#Top`.

## 7. Reproduce the machine check

```sh
kompile fvk/tzconvert.k --backend haskell          # compile the mini-X semantics
kast    --backend haskell fvk/tzconvert-spec.k     # (optional) parse-check the claims
kprove  fvk/tzconvert-spec.k                        # expect #Top for MYSQL/ORACLE/SQL-OFF/SQLITE/SQLITE-OFF
```

Expected: the four on-domain claims reduce to `#Top`. VC-S2 is intentionally not
posed as a claim (it is false off-domain); it lives in `FINDINGS.md` F1.

## Benefit payoffs (plain language)

- **Benefit 2 (bugs/risk):** writing the spec proved the SQL-backend fix correct
  for *all* zones, and pinpointed the *exact* input class where SQLite is
  imprecise (named non-UTC DB zone, different active zone — pytz LMT), with a
  concrete failing example — value even if you never read the K.
- **Benefit 1 (fewer tests):** the universal SQL-backend contract subsumes
  per-`(C,T)` point tests once machine-checked; the SQLite off-domain corner and
  the DB-engine/DST assumptions are explicitly **kept**.
