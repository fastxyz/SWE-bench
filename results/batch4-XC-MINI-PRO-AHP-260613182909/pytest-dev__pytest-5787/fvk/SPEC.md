# SPEC.md — formal specification of the pytest-5787 fix

**Target.** `BaseReport._to_json` (the nested `serialize_longrepr` /
`serialize_repr_*` helpers) and `BaseReport._from_json` (the nested
`deserialize_repr_*` helpers) in `repo/src/_pytest/reports.py`, as patched by V1.
These back the experimental hooks `pytest_report_to_serializable` /
`pytest_report_from_serializable`, which `pytest-xdist` uses to ship a `TestReport`
/ `CollectReport` from a worker process to the master.

**Mode.** Intent-spec mode (per `formalize.md` §2): the contract captures the
*intended* behaviour (the bug report wants the whole exception chain to survive the
worker→master trip); the code is checked against that contract.

**Formal artifacts.** `fvk/report_serial.k` (mini-X fragment semantics) and
`fvk/report_serial-spec.k` (the reachability claims). This note is the
plain-English reading for a developer who never opens the `.k` files.

---

## 1. What the code is

This is not an arithmetic loop; it is pure **(de)serialization of an algebraic
value**. `report.longrepr` is one of four shapes:

| shape | Python | when |
|---|---|---|
| `lrNone`  | `None` | passing test |
| `lrStr`   | a `str` / object without `reprtraceback` | e.g. a collection error string |
| `single`  | `ReprExceptionInfo(reprtraceback, reprcrash)` | `--tb=native` |
| `chained` | `ExceptionChainRepr(chain)` | **all default tb styles** |

The crucial fact for this bug: a normal failing test — even a *single*,
unchained exception — produces an **`ExceptionChainRepr`** (its `chain` has one
element). `ReprExceptionInfo` only appears for `--tb=native`. So the chain is the
common case, and dropping it (V0) was the bug.

`_to_json`/`serialize_longrepr` emits a dict
`{"reprcrash", "reprtraceback", "sections", "chain"}` where, for an
`ExceptionChainRepr`, `reprtraceback`/`reprcrash` are the **outermost** exception
(`chain[-1]`) and `"chain"` is the full list of
`(reprtraceback, reprcrash, description)` links; for everything else `"chain"` is
`None`. `_from_json` reconstructs the object from that dict.

## 2. The contract — a round-trip (inverse) property

> **Primary contract (RT-LR).** For every in-domain report `r`,
> `from_json(to_json(r))` is **semantically equal** to `r`: it renders the same
> `toterminal()` text and exposes the same `.reprtraceback` / `.reprcrash` /
> `.sections`, and for a chained exception it carries the **same full `.chain`**.

Formally (`report_serial-spec.k`), with `serLR`/`deLR` modelling
`serialize_longrepr`/`_from_json`:

```
deLR(serLR(LR)) = LR            for LR in {lrNone, lrStr(S)}                (unconditional)
deLR(serLR(single(TB,C,SE))) = single(TB,C,SE)     requires allKnownTb(TB)
deLR(serLR(chained(LS,SE)))  = chained(LS,SE)       requires LS≠[] ∧ allKnownLs(LS)
```

It decomposes into per-component round-trips, two of which are the **loops**:

- **RT-ES** (circularity #1) — `deEs(serEs(ES)) = ES`: the `reprentries` list
  (`[... for x in reprtraceback.reprentries]`). Structural induction.
- **RT-LS** (circularity #2) — `deLs(serLs(LS)) = LS`: the chain list
  (`for ... in chain`). Structural induction.
- **RT-TB / RT-E / RT-C / RT-D** — traceback, entry, crash, description.

## 3. Precondition (domain)

`allKnown` — every serialized entry’s `"type"` tag is one `_from_json` knows
(`"ReprEntry"` or `"ReprEntryNative"`). This is the in-domain assumption; the
out-of-domain case (an `"Unknown"` tag) is **deliberately** not a no-op — it must
raise (see §4, Finding F1/F8). For `chained`, the chain must also be **non-empty**
(`ExceptionChainRepr.__init__` does `chain[-1]`).

## 4. Postcondition obligations baked into the contract

- **Full-chain fidelity** — for a `chained` input the reconstructed object is an
  `ExceptionChainRepr` whose `chain` equals the original, so `toterminal()`
  re-emits every "During handling…/direct cause…" link. (This is the bug fix.)
- **Shape/type fidelity** — `single`↦`single` (`ReprExceptionInfo`),
  `chained`↦`chained` (`ExceptionChainRepr`); no collapse. (Consumers tolerate
  either via the shared `ExceptionRepr` interface — see PROOF_OBLIGATIONS PO-CLASS.)
- **Malformed-payload detection** — an `Unknown` entry tag anywhere the code
  validates ⇒ `RuntimeError` (`_report_unserialization_failure`). V1 validates the
  **top-level** traceback *and* every chain link ("process both"); modelled as the
  `allKnownJTb(JT) ∧ allKnownJLs(JLS)` guard on the chain rule.
- **`None`-crash tolerance** — a chain link without a traceback has
  `reprcrash is None`; serialize/deserialize must round-trip `None` (V1’s
  `serialize_repr_crash`/`deserialize_repr_crash` `None`-guards).

## 5. Modeling assumptions / trusted base

The abstract round-trip is exact **identity**; the real Python round-trip is
**identity-up-to-rendering**. Three abstractions make that sound, and are the
trusted base of this proof:

1. **Opaque leaves round-trip verbatim.** `lines`, `path`, `lineno`, `message`,
   `style`, `extraline`, `sections`, `description` are copied by `.__dict__.copy()`
   / re-passed to the constructor; the fix never inspects them. Modelled as `Int`
   tokens preserved by `ser`/`de`. (So e.g. the `RecursionError` `extraline` and
   every link’s `sections`-less payload survive — V1 fixes their loss too.)
2. **Transport coercion is invisible.** The hookspec says the dict must be "suitable
   for sending over the wire, e.g. converted to JSON", which turns tuples into
   lists. The chain links and `sections` are tuples that become lists in transit;
   deserialize reads them by positional unpacking (`for a,b,c in chain`,
   `addsection(*section)`), insensitive to tuple-vs-list. Modelled as one abstract
   `Link`/list sort.
3. **`ReprTracebackNative` ≅ `ReprTraceback`.** A native traceback deserialises to a
   `ReprTraceback` with `style="native"` + a `ReprEntryNative`; `toterminal` is
   inherited, so rendering is identical. Modelled as one `Tb` sort.

Also trusted: the K reachability metatheory + `kprove`; the SMT/`[simplification]`
oracle. **Python exceptions are out of the fragment** — the `RuntimeError` is
modelled as the deserialiser being *undefined* on an `Unknown` tag (matching-logic
partiality), per `formalize.md`’s guard guidance.

## 6. Scope

Partial-correctness style (the fragment is total/terminating by construction —
finite structural recursion — so termination is not at issue here; see PROOF.md
§ Residual risk). The contract is about the **unit** (`_to_json`/`_from_json`); the
xdist wire itself and `execnet` are integration concerns, not covered.
