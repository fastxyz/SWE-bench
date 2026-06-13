# PROOF_OBLIGATIONS.md — django__django-11138 V1

The verification conditions (VCs) generated while constructing the proofs in
`PROOF.md`, with discharge status. **Constructed, not machine-checked.**

Tiers (per `reachability-and-circularities.md` §6): **[Z3]** linear/equality fact
for the SMT oracle · **[LEMMA]** an algebra axiom (`[simplification]`) ·
**[BRANCH]** a case-analysis obligation · **[OPEN]** could not be discharged on
the stated domain (a finding).

---

## Claims (from `tzconvert-spec.k`)

- **MYSQL/ORACLE** `denote(gen(true, C, T), F, C) ⇒ wallOf(instant(F, C), T)`  — all `F,C,T`
- **SQL-OFF** `denote(gen(false, C, _), F, C) ⇒ F`
- **SQLITE** `parse(F, C, T) ⇒ wallOf(instant(F, C), T)`  — requires `C=T ∨ C="UTC"`, `C≠""`
- **SQLITE-OFF** `parse(F, "", _) ⇒ F`

## SQL-backend obligations (MySQL & Oracle share the model)

| VC | Where | Statement | Tier | Status |
|---|---|---|---|---|
| **VC-M1a** | `MYSQL`, branch `C ≠ T` | `denote(convert(field,C,T),F,C) = wallOf(instant(F,C),T)` | [Z3] via denote-rule | ✅ discharged |
| **VC-M1b** | `MYSQL`, branch `C = T` | `denote(field,F,C) = wallOf(instant(F,C),T)`, i.e. `F = wallOf(instant(F,C),C)` | [LEMMA] RT | ✅ discharged |
| **VC-M1c** | `MYSQL`, split | guard `C =/=String T  ∨  C ==String T` is total | [BRANCH] | ✅ exhaustive |
| **VC-M2** | `SQL-OFF` | `denote(field,F,C) = F` | [Z3] denote-rule | ✅ discharged |
| **VC-O1/2** | `ORACLE` | identical to VC-M1/VC-M2 (same model, `convert` ≡ FROM_TZ form) | as above | ✅ discharged |
| **VC-O3** | `ORACLE`, injection guard | `C` interpolated unvalidated by `_tzname_re` | side-condition gap | ⚠️ accepted (F3) — `C` trusted (settings) |

*VC-O3 is not a soundness VC of the contract; it is a defensive-coding obligation
the audit raises and accepts. Tracks FINDINGS F3 / PD3.*

## SQLite obligations

| VC | Where | Statement | Tier | Status |
|---|---|---|---|---|
| **VC-S1** | `SQLITE`, branch `C = "UTC"`, `C ≠ T` | `wallOf(instReplace(F,"UTC"),T) = wallOf(instant(F,"UTC"),T)` | [LEMMA] UTC | ✅ discharged |
| **VC-S1'** | `SQLITE`, branch `C = T` | `parse=F = wallOf(instant(F,C),C)` | [LEMMA] RT | ✅ discharged |
| **VC-S2** | `SQLITE`, branch `C ≠ "UTC"`, `C ≠ T` | `wallOf(instReplace(F,C),T) = wallOf(instant(F,C),T)` | needs `instReplace=instant` | ❌ **OPEN** |
| **VC-S3** | builders → base | arg order `(dt,T,C)` matches `(dt,tzname,conn_tzname)` & arities 3/4 | [Z3] structural | ✅ discharged (F4) |
| **VC-S4** | `SQLITE-OFF` | `parse(F,"",_) = F` | [Z3] rule | ✅ discharged |

### VC-S2 — the one open obligation

To close VC-S2 we would need the rewrite `instReplace(W, Z) ⇒ instant(W, Z)` for
an arbitrary named zone `Z`. It is **false** in the model (and in pytz): for a
named non-UTC `Z`, `.replace` attaches the LMT offset, so
`instReplace(W, Z) ≠ instant(W, Z)` by the LMT delta. Therefore VC-S2 is **not
discharged** and the `SQLITE` claim carries the side condition
`C = T ∨ C = "UTC"`.

- **Classification:** known imprecision, not a capability gap — the model *can*
  express it; the code is simply approximate here. = **FINDING F1**.
- **Domain covered without VC-S2:** `C = T` (issue's legacy case) and `C = "UTC"`
  (default config) — i.e. every scenario in `PROBLEM.md` and every existing
  deployment. The uncovered slice is "named non-UTC DB zone queried under a
  different active zone."
- **Resolution:** keep V1; do not admit VC-S2 as `[trusted]` (that would fake
  confidence). Routed to UltimatePowers question PD2.

## Cross-cutting guard-soundness obligation

| VC | Where | Statement | Tier | Status |
|---|---|---|---|---|
| **VC-EQ** | identity branch of all backends | `C ==String T ⟹ zone(C) = zone(T)` (so taking the no-op branch is sound) | [LEMMA] string-eq ⟹ zone-eq | ✅ discharged (F8) |

Only this *direction* is required: identical canonical strings denote the same
zone, so axiom **RT** applies. The converse is **not** an obligation — an alias
(`'GMT'` vs `'UTC'`) simply takes the conversion branch (a correct no-op), so no
unsound identity-branch case exists. Relies on `tzname` and
`connection.timezone_name` both being canonical Olson names (the normal config);
that normalization is part of trusted-base item 1.

## Trusted base (assumptions, not VCs)

1. **Algebra adequacy** — `instant`/`wallOf` faithfully abstract pytz+datetime,
   with exactly the axioms **RT** (`wallOf(instant(W,Z),Z)=W`) and **UTC**
   (`instReplace(W,"UTC")=instant(W,"UTC")`).
2. **DB equivalence** — MySQL `CONVERT_TZ(f,From,To)` and Oracle
   `CAST(FROM_TZ(f,From) AT TIME ZONE To AS TIMESTAMP)` both realise
   `wallOf(instant(f,From),To)` (engine manuals; assumed).
3. **Totality abstraction** — `instant` modelled total; real DST-edge partiality
   is abstracted (FINDINGS F6).
4. The proof is **constructed, not machine-checked** (no `kprove` run).

No loop/recursion ⇒ **no circularity obligation** and no termination VC
(every claim is a terminating branch contract).
