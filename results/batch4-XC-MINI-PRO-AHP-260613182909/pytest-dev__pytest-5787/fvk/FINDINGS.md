# FINDINGS.md — pytest-5787 V1

Plain-language findings from formalizing `_to_json`/`_from_json` (V1). Each is
`input → observed vs expected`. **No finding contradicts V1**; the formalization
proved the round-trip contract cleanly (a clean spec was writable — itself positive
evidence, per the kit). Findings are split into *positive* (the spec confirms a
deliberate, correct decision), *latent* (a real edge worth recording), and
*proof-derived* (what `/verify` surfaced for the next iteration).

---

## Positive findings — the spec confirms V1 is right

- **F0 — the core fix is the round-trip’s headline clause.** input: a worker
  `TestReport` whose `longrepr` is an `ExceptionChainRepr` with chain
  `[VE(1)→VE(2)→VE(3)]` → V0 observed: master re-renders only `VE(3)`; V1 +
  contract PO-RT-LR(`chained`): master re-renders all three links with their
  "direct cause/During handling" descriptions. Root cause was that `_to_json` only
  serialized the outermost `reprtraceback`/`reprcrash` and dropped `chain`. **V1
  serializes/deserializes the whole chain — correct.**

- **F1 — the malformed-tag guard is a *needed* guard (positive).** input: a payload
  with `entry["type"]="Unknown"` → observed/expected: `RuntimeError`
  (`_report_unserialization_failure`). Modelled as deserialiser partiality
  (PO-VALIDATE). The guard enforces the contract’s domain precondition `allKnown`.
  V1 preserves it — and extends it to chain links.

- **F2 — `None`-crash handling fixes a latent V0 crash.** input: a chain link whose
  exception has no traceback ⇒ `reprcrash is None` (see `repr_excinfo`’s native
  fallback) → V0 `disassembled_report` would have done `None.__dict__.copy()` ⇒
  `AttributeError` had it ever serialized such a link; V1’s `serialize_repr_crash` /
  `deserialize_repr_crash` round-trip `None` (PO-RT-C, unconditional). **V1 is
  strictly safer.**

- **F3 — "process both" is sound (no spurious failure).** input: a well-formed
  chained report → V1 deserialises the top-level (outermost) traceback and discards
  it, then rebuilds from the chain. expected: the discarded call never raises.
  Proved as **PO-NOSPUR**: `allKnownLs(LS) ⟹ allKnownTb(tbOfLast(LS))`. Correct.

- **F5 — the class change is safe and *more* faithful.** input: any non-native
  failure → V0 always rebuilt `ReprExceptionInfo`; V1 rebuilds the original
  `ExceptionChainRepr`. expected: no consumer breaks. Verified (**PO-CLASS**): all
  consumers (`terminal.py`, `junitxml.py`, `pastebin.py`) use only the shared
  `ExceptionRepr` interface; the sole `isinstance` check is against `str`. V1 makes
  master mirror the worker’s actual class — an improvement. And **PO-IDENT-V0**: for
  `None`/`str`/native, V1 emits a byte-identical dict and identical object to V0, so
  no regression on previously-handled paths.

- **F6 — empty/`None` chain degrades gracefully.** input: `chain` falsy → V1 takes
  the `ReprExceptionInfo` branch; `ExceptionChainRepr(chain)` (which does
  `chain[-1]`) is only built for a truthy chain ⇒ no `IndexError` (**PO-NONEMPTY**).

- **F7 — JSON-transport safe.** input: the dict is "converted to JSON" (hookspec) ⇒
  chain links & `sections` tuples become lists → V1 reads them by positional
  unpacking (`for a,b,c in chain`, `addsection(*s)`), tuple/list-insensitive
  (**PO-JSON-SAFE**); and the discarded top-level deserialization cannot corrupt the
  chain’s (distinct, separately-copied) dicts (**PO-NO-ALIAS**).

## Latent finding — recorded, not patched

- **F4 — `["chain"]` assumes the producer is the same pytest version.** input: a
  serialized payload from a *pre-fix* pytest (no `"chain"` key), fed to a post-fix
  `_from_json` (e.g. a persisted `pytest-reportlog` file read after upgrade) →
  observed: `KeyError: 'chain'`; expected (arguably): graceful fallback to the
  single-exception view. **Assessment:** out-of-contract. The hookspec says the data
  is restored from what *this* serializer produced and is "subject to change between
  pytest releases, even bug fixes"; xdist additionally pins matching versions. The
  rest of `_from_json` already accesses `["sections"]`/`["reprtraceback"]`/
  `["reprcrash"]` with the same bare-key assumption. **Decision: keep bare `["chain"]`**
  for consistency and to match the established schema contract; a `reportdict["longrepr"].get("chain")`
  guard is a *possible* hardening (zero-downside graceful degradation) but is
  declined here as out-of-scope gold-plating. See PO-SCHEMA-PRODUCER and fvk_notes.

## Proof-derived findings from `/verify` (feedback for the next iteration)

- **PD1 (test gap → keep)** The contract excludes the out-of-domain `Unknown`-tag
  case; `test_unserialization_failure` is the only guard on it. **Keep it.** A
  chained-exception round-trip test is the executable witness of PO-RT-LR(`chained`)
  — **keep it** until `kprove` is green (it is the FAIL_TO_PASS this fix targets).
- **PD2 (escalation note, not a bug)** PO-RT-ES/PO-RT-LS/PO-NOSPUR are structural
  inductions over `List{}` sorts (PO-LIST-INDUCTION). Within the recursion-circularity
  tier, but a machine check should confirm the `List{}` framing; the exception
  control-flow is modelled as partiality, not thrown exceptions (PO-EXC).
- **PD3 (intent question for UltimatePowers)** "When `_from_json` meets a payload
  from an *older* pytest that predates the `chain` key, should it raise (current),
  or fall back to single-exception rendering?" Resolving F4 explicitly would let the
  schema evolve safely; today it is correctly left to the experimental-hook latitude.
- **PD4 (no code bug found)** Constructing the proof required **no** invented side
  condition beyond the documented `allKnown` domain and the non-empty-chain fact
  (both already enforced by surrounding code). Per the kit’s "spec-difficulty = bug
  signal" rule, the *absence* of difficulty is the strongest available evidence the
  V1 fix is correct.
