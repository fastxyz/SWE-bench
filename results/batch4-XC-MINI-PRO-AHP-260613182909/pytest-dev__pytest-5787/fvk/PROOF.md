# PROOF.md — constructed proof of the pytest-5787 round-trip contract

**Status: constructed, NOT machine-checked** (FVK MVP — `kprove` is not run here).
Proves the claims in `fvk/report_serial-spec.k` against `fvk/report_serial.k` by
symbolic execution + structural-induction circularities. Obligations are named per
`fvk/PROOF_OBLIGATIONS.md`.

---

## 1. What is proved (plain language)

> For every report whose serialized entries all carry a known type tag
> (`ReprEntry`/`ReprEntryNative`), `from_json(to_json(report))` reproduces the
> report: same rendered traceback text, same `reprcrash`/`reprtraceback`/`sections`,
> and — crucially — the **entire exception chain**, not just its last link. A report
> whose payload carries an unknown tag (in the top-level traceback **or** any chain
> link) raises `RuntimeError`, exactly as before.

That chain clause is the bug fix: under xdist the master now re-renders every
"During handling of the above exception…" / "direct cause…" segment.

## 2. Proof of the leaf round-trips (PO-RT-C, PO-RT-D, PO-RT-E)

**RT-C.** `deC(serC(C))`. Case `C = noCrash`: `serC` → `jNoCrash`, `deC` → `noCrash`
✓. Case `C = mkCrash(L)`: `serC` → `jCrash(L)`, `deC` → `mkCrash(L)` ✓. (Both rules
total; **no** precondition — this is the `None`-tolerant crash path, V1’s fix to a
latent V0 `None.__dict__` crash.) **RT-D** identical over `noDescr|mkDescr`.

**RT-E.** `deE(serE(mkE(K,Dt)))` with `serE` → `jE(K,Dt)`. Case-split `K` (#Or):
`ReprEntry` → `deE` rule → `mkE(ReprEntry,Dt)` ✓; `ReprEntryNative` → `mkE(...)` ✓;
`Unknown` → **no `deE` rule** ⇒ goal is *out of domain*. The claim’s
`requires isKnown(K)` removes the `Unknown` branch by Consequence (Z3:
`isKnown(K) ⇒ K∈{ReprEntry,ReprEntryNative}`). ✓.

## 3. Circularity #1 — the reprentries list (PO-RT-ES)

Claim `deEs(serEs(ES)) ⇒ ES  requires allKnownEs(ES)`. K adds it to the hypotheses;
guarded coinduction:

- **Base** `ES = .Es`: `serEs(.Es)` → `.JEs` (Axiom), `deEs(.JEs)` → `.Es` (Axiom).
  Reaches `.Es` ✓. (Closed without the hypothesis — guardedness respected.)
- **Step** `ES = E : ES'`: the genuine `=>⁺` step is the `serEs` cons-unfold
  `serEs(E:ES') ⇒ serE(E) : serEs(ES')`, then `deEs(serE(E):serEs(ES')) ⇒
  deE(serE(E)) : deEs(serEs(ES'))`. Now:
  - `deE(serE(E)) ⇒ E` by **RT-E**, whose precond `isKnown(kind(E))` follows from
    `allKnownEs(E:ES') = isKnown(kind(E)) ∧ allKnownEs(ES')` (Consequence/Z3).
  - `deEs(serEs(ES')) ⇒ ES'` by the **coinductive hypothesis** on the tail
    (legal: ≥1 genuine step already taken), precond `allKnownEs(ES')` from the same
    conjunction.
  Result `E : ES' = ES` ✓.

## 4. Traceback round-trip (PO-RT-TB)

`deTb(serTb(mkTb(ES,X)))`: `serTb` → `jTb(serEs(ES),X)`, `deTb` →
`mkTb(deEs(serEs(ES)),X)`; `deEs(serEs(ES)) ⇒ ES` by **RT-ES** (precond
`allKnownEs(ES) = allKnownTb(mkTb(ES,X))`). Reaches `mkTb(ES,X)` ✓. `X` (opaque
extraline+style) is carried by framing, unchanged.

## 5. Circularity #2 — the chain list (PO-RT-LS)

Claim `deLs(serLs(LS)) ⇒ LS  requires allKnownLs(LS)`. Same coinductive shape:

- **Base** `LS = .Ls`: `serLs(.Ls)` → `.JLs`, `deLs(.JLs)` → `.Ls` ✓.
- **Step** `LS = mkLink(TB,C,D) ; LS'`: genuine step is the `serLs` cons-unfold ⇒
  `jLink(serTb(TB),serC(C),serD(D)) ; serLs(LS')`; then `deLs` ⇒
  `mkLink(deTb(serTb(TB)), deC(serC(C)), deD(serD(D))) ; deLs(serLs(LS'))`.
  - head: `deTb(serTb(TB)) ⇒ TB` by **RT-TB** (precond `allKnownTb(TB)` from
    `allKnownLs` head conjunct); `deC(serC(C)) ⇒ C` by **RT-C**;
    `deD(serD(D)) ⇒ D` by **RT-D**. ⇒ `mkLink(TB,C,D)`.
  - tail: `deLs(serLs(LS')) ⇒ LS'` by the **hypothesis** (precond `allKnownLs(LS')`).
  Result `mkLink(TB,C,D) ; LS' = LS` ✓.

## 6. Top-level contract (PO-RT-LR) and the "process both" VC (PO-NOSPUR)

- `lrNone`: `serLR`→`jNull`, `deLR`→`lrNone` ✓.  `lrStr(S)`: →`jStr(S)`→`lrStr(S)` ✓.
- **`single(TB,C,SE)`** (native): `serLR` ⇒ `jObj(serTb(TB),serC(C),SE,jChainNull)`.
  The `deLR` `jChainNull` rule fires under `allKnownJTb(serTb(TB))`, which by lemma
  **L-SERKIND** equals `allKnownTb(TB)` = the claim’s precond (Consequence). ⇒
  `single(deTb(serTb(TB)), deC(serC(C)), SE)` = `single(TB,C,SE)` by RT-TB, RT-C ✓.
- **`chained(LS,SE)`** (the bug case): `serLR` ⇒
  `jObj(serTb(tbOfLast(LS)), serC(crashOfLast(LS)), SE, jChain(serLs(LS)))`.
  The `deLR` `jChain` rule’s guard is
  `allKnownJTb(serTb(tbOfLast(LS))) ∧ allKnownJLs(serLs(LS))`. Discharge by
  Consequence:
  - 2nd conjunct = `allKnownLs(LS)` (lemma **L-SERKIND**) = precond. ✓
  - 1st conjunct = `allKnownTb(tbOfLast(LS))` (L-SERKIND), discharged by **L-NOSPUR**
    = **PO-NOSPUR**: `allKnownLs(LS) ∧ LS≠[] ⟹ allKnownTb(tbOfLast(LS))`. Proof: induct
    on `LS`; `tbOfLast` returns the single link’s `TB` at `[ _ ; .Ls ]` (covered by
    `allKnownLs`’ head conjunct) and recurses into the tail otherwise (covered by
    its tail conjunct + IH). ✓
  Guard satisfied, rule fires ⇒ `chained(deLs(serLs(LS)), SE)` =
  `chained(LS, SE)` by **RT-LS** ✓.

  This is the formal heart of the audit: V1 deserialises the **discarded** top-level
  traceback purely for its validation side-effect, and PO-NOSPUR proves that side
  effect is benign on every well-formed chain — so the chain (not the top-level)
  faithfully determines the output, while corruption in *either* slot is still
  caught (PO-VALIDATE).

## 7. Composition

By Transitivity, `deLR ∘ serLR = id` on the in-domain inputs (PO-RT-LR), resting on
the two circularities (PO-RT-ES, PO-RT-LS), the leaf round-trips, and PO-NOSPUR. The
code-level obligations (PO-SCHEMA-PRODUCER, PO-CLASS, PO-NONEMPTY, PO-JSON-SAFE,
PO-NO-ALIAS, PO-IDENT-V0) are discharged by inspection in PROOF_OBLIGATIONS.md. **No
obligation failed; no clean-spec difficulty arose** → by the FVK "spec-difficulty =
bug signal" criterion this is positive evidence the V1 fix is correct.

## 8. Residual risk

- **Trusted base (SPEC §5):** the three modeling abstractions (opaque-leaf-verbatim,
  tuple↔list transport, `ReprTracebackNative`≅`ReprTraceback`); the K reachability
  metatheory + `kprove`; the SMT/`[simplification]` oracle (lemmas L-NOSPUR,
  L-SERKIND, asserted sound — they are pure structural facts).
- **Partial vs total:** the fragment is finite structural recursion ⇒ terminating by
  construction, so partial/total coincide here; no separate variant needed. (Real
  code likewise has no unbounded loop — the chain and entry lists are finite.)
- **Constructed, not machine-checked:** the artifacts emit but do not run the
  toolchain. PO-EXC and PO-LIST-INDUCTION (PROOF_OBLIGATIONS §D) name the two spots a
  machine check would scrutinise (exception modelling; the `List{}` induction
  framing).

## 9. Reproduce the machine check

```sh
kompile fvk/report_serial.k --backend haskell        # compile the fragment semantics
kast    --backend haskell fvk/report_serial-spec.k   # (optional) confirm the claims parse
kprove  fvk/report_serial-spec.k                      # discharge the claims; expected: #Top
```

A `#Top` from `kprove` upgrades every claim above from *constructed* to
*machine-verified*; only then are the §10 test-removal recommendations safe to act on.

## 10. Test-redundancy recommendation (benefit 1) — recommendation only, NEVER auto-delete

Mapping the visible serialization tests in `repo/testing/test_reports.py` onto the
proved contract (conditioned on the machine check above):

| test | verdict | reason |
|---|---|---|
| `test_xdist_report_longrepr_reprcrash_130` | **subsumed** by PO-RT-LR (`chained`) + PO-RT-TB/RT-C | a single in-domain round-trip point asserting `reprcrash.*`/`reprtraceback.*` survive |
| `test_reprentries_serialization_170` | **subsumed** by PO-RT-ES | a `ReprEntry`-list round-trip point |
| `test_reprentries_serialization_196` | **subsumed** by PO-RT-ES + `single` (native) | a `ReprEntryNative`-list round-trip point |
| `test_xdist_longrepr_to_str_issue_241` | **keep** | asserts the *serialized dict shape* (`["longrepr"]["reprtraceback"]["style"]`) + the `None` longrepr path, not covered by the abstract round-trip |
| `test_unserialization_failure` | **keep** | exercises the **out-of-domain** `Unknown`-tag path (PO-VALIDATE) — exactly the boundary the contract excludes; this is where a regression would hide |
| `test_itemreport_outcomes`, `test_collectreport_*`, `test_extended_report_deserialization`, `test_paths_support` | **keep** | outcomes/keywords/extra-attr/path-stringification — orthogonal to the longrepr round-trip |
| any **chained-exception** round-trip test (the FAIL_TO_PASS this fix targets) | **keep** | it is the headline guarantee; keep it as the executable witness of PO-RT-LR `chained` until `kprove` is green |

Estimated CI saving if the three "subsumed" rows are removed *after* a green
`kprove`: negligible (three fast unit tests) — so the honest recommendation is to
**keep all of them** until machine-checked; the value here is benefit 2 (the audit),
not benefit 1.
