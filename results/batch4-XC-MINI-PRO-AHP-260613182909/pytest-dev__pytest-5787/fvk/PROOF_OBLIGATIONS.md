# PROOF_OBLIGATIONS.md — pytest-5787 V1

The verification conditions the round-trip contract (SPEC.md) generates. Each is
tagged **[code]** (a fact about `repo/src/_pytest/reports.py`, dischargeable by
reading the code / grep) or **[arith/struct]** (a VC inside the K proof, discharged
in PROOF.md). Status: ✅ discharged · ⚠️ discharged-with-caveat · 🔎 escalation note.

---

## A. Core round-trip VCs (inside the proof) — [arith/struct]

- **PO-RT-C** ✅ `deC(serC(C)) = C`. Case split `noCrash | mkCrash(L)`; two
  one-step rewrites. Covers the V1 `None`-tolerant `serialize_repr_crash` /
  `deserialize_repr_crash`. (Finding F2.)
- **PO-RT-D** ✅ `deD(serD(D)) = D`. Case split `noDescr | mkDescr`.
- **PO-RT-E** ✅ `deE(serE(mkE(K,Dt))) = mkE(K,Dt)` **requires `isKnown(K)`**.
  Case split on `K`; the `Unknown` branch is out of domain (deE undefined) — that
  is PO-VALIDATE, not a counterexample.
- **PO-RT-ES** ✅ (circularity #1, the `reprentries` comprehension)
  `deEs(serEs(ES)) = ES` **requires `allKnownEs(ES)`**. Structural induction: base
  `.Es`; step `E:ES` uses PO-RT-E on the head (precond from `allKnownEs`) and the
  coinductive hypothesis on the tail.
- **PO-RT-LS** ✅ (circularity #2, the chain reconstruction loop)
  `deLs(serLs(LS)) = LS` **requires `allKnownLs(LS)`**. Structural induction: base
  `.Ls`; step `mkLink(TB,C,D);LS` uses PO-RT-TB / PO-RT-C / PO-RT-D on the head and
  the hypothesis on the tail.
- **PO-RT-TB** ✅ `deTb(serTb(TB)) = TB` **requires `allKnownTb(TB)`**. One unfold
  `mkTb(ES,X)` → PO-RT-ES.
- **PO-RT-LR** ✅ top-level, all four shapes — see §B for the two interesting ones.

## B. The two obligations that are specific to the V1 design

- **PO-NOSPUR** ✅ ("process both" is sound) `allKnownLs(LS) ∧ LS≠[] ⟹
  allKnownTb(tbOfLast(LS))`. In the `chained` branch V1 first runs
  `deserialize_repr_traceback(reprtraceback)` on the **top-level** (outermost)
  traceback and *discards* the result, using only its validation side-effect. This
  PO says that discarded call can **never spuriously raise** on a well-formed chain:
  if every link is all-known, so is the outermost (`= chain[-1] = tbOfLast`).
  Discharged by the lemma `L-NOSPUR` (induction on `LS`: `tbOfLast` selects one
  link, `allKnownLs` covers all links). → makes PO-RT-LR `chained` reduce to
  PO-RT-LS alone. (Findings F3, F7.)
- **PO-VALIDATE** ✅ ("process both" detects corruption) For
  `jObj(JT, _, _, CH)`: deLR is **undefined** (⇒ `RuntimeError`) when
  `¬allKnownJTb(JT)` (top-level corrupt) **or** when `CH=jChain(JLS) ∧
  ¬allKnownJLs(JLS)` (a chain link corrupt). This is the model of
  `_report_unserialization_failure`. It is what keeps
  `test_unserialization_failure` (which corrupts `data["longrepr"]["reprtraceback"]
  ["reprentries"][0]`, the **top-level** slot, on a single-exception report whose
  reconstruction is otherwise driven by the chain) passing — and is robust whether
  the corruption is placed in the top-level slot or in a chain link. (Findings F1,
  F8.)

## C. Code-level obligations (no proof needed; discharged by inspection/grep) — [code]

- **PO-SCHEMA-PRODUCER** ✅ Every dict that reaches `_from_json` was produced by
  `_to_json`, so the `"chain"` key is always present. Grep: `_from_json` is reached
  only via `pytest_report_from_serializable` (`reports.py:468/470`), whose data
  comes from `pytest_report_to_serializable → _to_json` (`reports.py:460`), plus
  the tests `rep._to_json(); _from_json(d)`. No other code constructs the dict
  (grep `_to_json|_from_json` → only `reports.py`). ⚠️ Caveat: across *different*
  pytest versions (e.g. a persisted `pytest-reportlog` file) an old payload lacks
  `"chain"` ⇒ `KeyError`. The hookspec explicitly disclaims cross-version stability
  ("subject to change between pytest releases, even bug fixes"; "restores a report
  previously serialized with pytest_report_to_serializable()"), so this is
  in-contract. Recorded as Finding F4; **not** patched (see fvk_notes).
- **PO-CLASS** ✅ Changing the deserialized class for non-native reports from
  `ReprExceptionInfo` (V0) to `ExceptionChainRepr` (V1) breaks no consumer. Grep of
  `repo/src` for `longrepr.reprcrash` / `longrepr.reprtraceback` / `isinstance(...
  longrepr...)`: `terminal.py:688,694,730,965`, `junitxml.py:223`, `pastebin.py:88`
  use only the shared `ExceptionRepr` interface (`.reprcrash`, `.reprtraceback`,
  `.sections`, `.toterminal`); the **only** `isinstance` test is
  `isinstance(report.longrepr, str)` (`junitxml.py:224`), unaffected. V1 is in fact
  *more* faithful (master rebuilds the worker’s actual class). (Finding F5.)
- **PO-NONEMPTY** ✅ `ExceptionChainRepr(chain)` is constructed only when
  `reportdict["longrepr"]["chain"]` is truthy (non-empty list), so `chain[-1]` in
  its `__init__` never `IndexError`s. An empty/`None` chain falls to the
  `ReprExceptionInfo` branch — graceful. (Finding F6.)
- **PO-JSON-SAFE** ✅ Every value emitted is JSON-serialisable: dicts, lists,
  `str`, `int`, `None`; chain links and `sections` are tuples (→ lists under JSON),
  read back by positional unpacking. No object survives that JSON could not carry.
  (Finding F7.)
- **PO-NO-ALIAS** ✅ The discarded top-level deserialization (PO-NOSPUR) cannot
  corrupt the chain reconstruction: `serialize_repr_traceback` does
  `.__dict__.copy()` + a fresh `reprentries` list per call, so the top-level dict
  and `chain[-1]`'s dict are distinct objects; `deserialize_repr_traceback`'s
  in-place `reprentries` rebind touches only its own argument. Shared leaf `lines`
  lists are read-only in deserialize. (Finding F7.)
- **PO-IDENT-V0** ✅ For `lrNone`, `lrStr`, and `single` (native), V1 emits a
  byte-identical dict to V0 and rebuilds an identical object (the helper bodies are
  the old inline code verbatim; `"chain"=None` is the only addition, and it routes
  to the unchanged `ReprExceptionInfo` branch). So V1 is a *conservative* extension:
  no regression on the paths V0 already handled. (Finding F5.)

## D. Out-of-scope / escalation notes — 🔎

- **PO-EXC** 🔎 The `RuntimeError` control flow is modelled as deserialiser
  partiality, not as a thrown/caught exception (exceptions are outside the mini-X
  fragment, per `formalize.md`). Adequate here because the only observable is
  "raises vs. returns", which partiality captures; a full proof that the *specific*
  `RuntimeError` message is produced would need an exception-bearing semantics
  (escalation).
- **PO-LIST-INDUCTION** 🔎 PO-RT-ES / PO-RT-LS / PO-NOSPUR are structural
  inductions over user-defined cons-lists. These sit just past the "counting-loop"
  fast path but squarely inside the **recursion-circularity** pattern the kit now
  covers (`(REC)`): the recursive call is the guard, base = nil, step invokes the
  hypothesis on the tail. They need **no** multiset/sortedness reasoning, so they
  are *not* a `[ESCALATION BOUNDARY]` — but they are flagged so a reviewer knows the
  induction principle in play and machine-checking should confirm the `List{}`
  framing.
