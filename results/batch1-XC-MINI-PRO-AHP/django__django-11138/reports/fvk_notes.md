# reports/fvk_notes.md — FVK audit outcome for django__django-11138

## Summary verdict

**V1 stands unchanged.** The FVK audit formalized the four changed helpers,
constructed correctness proofs, and concluded that V1 is correct on the entire
in-scope domain. The one open obligation surfaced (the SQLite pytz-`.replace`
imprecision) is a documented edge case whose only available "fix" is a net
regression, so no source file was edited. Every decision below is traced to
`fvk/FINDINGS.md` and `fvk/PROOF_OBLIGATIONS.md`.

No code under `repo/` was modified in this pass. The five `fvk/` artifacts plus
the two `.k` files are the deliverable evidence package.

## How the fix was formalized

The changed code is four **straight-line** helpers (no loops, no recursion), so
the kit's circularity/loop-invariant machinery does not apply; I wrote a
**function contract** per helper instead (`fvk/SPEC.md` §2). The shared intended
behaviour, from `PROBLEM.md` + `docs/topics/i18n/timezones.txt`, is the single
specification value

```
SPEC(F, C, T) = wallOf(instant(F, C), T)
```

— re-express the stored wall-clock `F` from the database zone `C`
(`connection.timezone_name`) into the active Django zone `T` (`tzname`). The V1
bug being fixed was the hard-coded source zone `"UTC"` in place of `C`, plus an
always-emitted conversion even when `C = T`. The mini-X semantics
(`fvk/tzconvert.k`) models the timezone algebra with two axioms — **RT**
(`wallOf(instant(W,Z),Z)=W`) and **UTC** (`instReplace(W,"UTC")=instant(W,"UTC")`)
— and each generator as a function; the claims are in `fvk/tzconvert-spec.k`.

## Decision-by-decision (each traced to the artifacts)

### D1 — Keep MySQL `_convert_field_to_tz` as in V1
**Trace:** claims `MYSQL`; obligations **VC-M1a/M1b/M1c, VC-M2, VC-EQ**;
`FINDINGS.md` **F2, F5, F8** (positive).
**Why:** the proof (`PROOF.md` §3) discharges the contract for **all** `F, C, T`
with no side condition — branch `C≠T` denotes `SPEC` directly (VC-M1a, Z3),
branch `C=T` collapses by axiom RT (VC-M1b). F8/VC-EQ confirms the *string* guard
`connection.timezone_name != tzname` is a **sound** trigger for that identity
branch (both sides are canonical Olson names; an alias only forgoes the
optimization, never correctness). F2 shows the default config (`C="UTC"`) is
byte-for-byte the old behaviour or strictly better, and F5 shows the `C≠T` guard
is exactly what removes the MySQL time-zone-table dependency the report
complained about. Nothing to change.

### D2 — Keep Oracle `_convert_field_to_tz` as in V1
**Trace:** claims `ORACLE` (= MySQL model); obligations **VC-O1/O2** (✅),
**VC-O3** (⚠️ accepted); `FINDINGS.md` **F3** (accepted), **PD3**.
**Why:** identical contract and proof to MySQL (the `convert` term models
`FROM_TZ..AT TIME ZONE`, same denotation). The default `'0:00'`→`'UTC'` surface
change is denotationally identical (F2). VC-O3/F3 note that `C` is interpolated
without the `_tzname_re` guard that `T` gets; **accepted** because `C` comes from
trusted `settings.DATABASES`, never request data — the same trust boundary the
pre-fix literal had. Optional hardening is logged in `ITERATION_GUIDANCE.md`, not
applied.

### D3 — Keep SQLite `_convert_tznames_to_sql` + the four `datetime_*_sql` builders
**Trace:** obligation **VC-S3**; `FINDINGS.md` **F4** (positive).
**Why:** the audit verified the emitted argument order `(field, T_sql, C_sql)`
matches the Python signature `(dt, tzname, conn_tzname)` and the bumped
`create_function` arities (3 and 4). A swap would invert the conversion; it is
correct. No change.

### D4 — Keep SQLite `_sqlite_datetime_parse` (the `.replace` line) — the one real judgement call
**Trace:** claim `SQLITE`; obligations **VC-S1, VC-S1', VC-S4** (✅) and **VC-S2**
(❌ OPEN); `FINDINGS.md` **F1** (imprecision), **F6** (DST totality), **PD2**.
**Why kept rather than "fixed":**
- The contract is **proved** on the whole in-scope domain: `C = T` (the report's
  legacy app=DB=`Europe/Paris` case, VC-S1' via RT) and `C = "UTC"` (every default
  deployment, VC-S1 via the UTC axiom). These cover `PROBLEM.md` entirely.
- VC-S2 — the residual `C` named-non-UTC with `C ≠ T` — is **OPEN** because
  `instReplace(W,C) ≠ instant(W,C)` for such `C` (pytz attaches LMT, not the real
  offset). Per the kit I did **not** admit it as `[trusted]`; I reported it as F1
  with a concrete `input → observed vs expected` example.
- The only alternative,
  `make_aware(dt.replace(tzinfo=None), pytz.timezone(C))`, is **identical on every
  in-scope input** (it changes nothing when `C=T` is skipped or `C="UTC"`), yet it
  **adds** a failure mode: `AmbiguousTimeError`/`NonExistentTimeError` on
  DST-edge stored values that `.replace` tolerates (F6). Trading a rare silent
  imprecision for a new exception path — and diverging from the established
  backend behaviour — is not a net improvement.

Hence the FVK-justified outcome is to **keep V1** and route the question to the
intent layer (PD2 / `ITERATION_GUIDANCE.md`): only if a maintainer rules that the
named-non-UTC-cross-zone SQLite case must be *exact* should the `make_aware`
variant (with an explicit `is_dst` policy) be applied.

### D5 — Confirm the fix is correctly scoped (no edits to read/write or non-datetime paths)
**Trace:** `FINDINGS.md` **F7** (positive); `ITERATION_GUIDANCE.md` "What NOT to
touch".
**Why:** the audit confirmed the read/write path
(`adapt_datetimefield_value`/`convert_datetimefield_value`) already honours the
per-DB `TIME_ZONE` via `connection.timezone` (which is why the report's plain `=`
filter worked while only the `__date` transform failed). V1 touches only the
transform helpers, so there is no double-conversion and no regression. Confirming
this scope was part of the audit; it required and got no change.

## Residual risk carried forward (from `PROOF.md` §5)

The result is **constructed, not machine-checked** — `kprove` was not run (no
execution environment). The trusted base is: the RT/UTC algebra axioms, the
DB-engine equivalence of `CONVERT_TZ`/`FROM_TZ` with `wallOf∘instant`, and the
DST-totality abstraction (F6). The single known imprecision is F1/VC-S2, scoped
and documented. The `kompile`/`kprove` commands to upgrade "constructed" to
"machine-verified" are in `PROOF.md` §7, and the conditioned test-redundancy
recommendation is in `PROOF.md` §6 (keep all tests until `#Top`).
