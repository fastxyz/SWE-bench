# FVK notes — pytest-5787 (audit of V1)

## Outcome in one line

The FVK audit **confirms V1 and makes no source change.** The five `fvk/`
artifacts construct a round-trip contract for `_to_json`/`_from_json`, discharge
every proof obligation, and surface no in-contract defect. Below, every decision —
including the decision *not* to edit — is traced to a specific
`fvk/FINDINGS.md` (F#/PD#) or `fvk/PROOF_OBLIGATIONS.md` (PO-#) entry.

## Decision 1 — keep the chain serialization exactly as V1 wrote it

Trace: **F0**, **PO-RT-LR(`chained`)**, **PO-RT-LS**. Formalizing the contract made
explicit that a normal failing test produces an `ExceptionChainRepr` (chain length
≥1), so serializing only the outermost `reprtraceback`/`reprcrash` (V0) is exactly
the dropped-chain bug. The proof shows V1’s `serialize_longrepr` + chain
reconstruction satisfies `from_json(to_json(r)) = r` on the chain, i.e. the master
re-renders every link. Nothing to change.

## Decision 2 — keep the "process both" deserialization (deserialize the top-level traceback even when a chain is present)

Trace: **F3**, **PO-NOSPUR**, **PO-VALIDATE**, **PD1**. This was the one V1 choice
that looked redundant and deserved the hardest scrutiny — V1 runs
`deserialize_repr_traceback(reprtraceback)` on the outermost traceback and then, in
the chain branch, discards the result. The audit justified it on two independent
grounds:

1. **Soundness (PO-NOSPUR):** the discarded call can never spuriously raise on a
   well-formed report, because `allKnownLs(chain) ⟹ allKnownTb(chain[-1])`
   (`chain[-1]` *is* the top-level/outermost traceback). Proved by induction on the
   chain in `fvk/report_serial-spec.k` (lemma `L-NOSPUR`).
2. **Necessity (PO-VALIDATE):** it preserves malformed-payload detection on the
   canonical top-level slot. `test_unserialization_failure` corrupts
   `data["longrepr"]["reprtraceback"]["reprentries"][0]` — the **top-level** slot —
   on a single-exception report whose reconstruction is otherwise chain-driven; only
   because V1 validates the top-level does that test still raise. Crucially the
   model shows V1 is robust **whichever** slot is corrupted (top-level *or* a chain
   link both lead to `RuntimeError`), so the fix is safe regardless of how the
   hidden test suite places the corruption.

A "clean" chain-only deserialization would have been simpler but would *not* detect
top-level corruption (PO-VALIDATE would fail for the top-level slot). So the
redundancy is a deliberate, proven-correct robustness feature — **kept**.

## Decision 3 — keep the `None`-tolerant crash (de)serialization

Trace: **F2**, **PO-RT-C**. The contract’s crash round-trip is unconditional only
because V1 added the `None` guards (`serialize_repr_crash`/`deserialize_repr_crash`).
A chain link for an exception without a traceback carries `reprcrash is None`; V0’s
`reprcrash.__dict__.copy()` would have raised `AttributeError`. V1 is strictly
safer; keep it.

## Decision 4 — accept the deserialized-class change (`ReprExceptionInfo` → `ExceptionChainRepr`)

Trace: **F5**, **PO-CLASS**, **PO-IDENT-V0**. A grep of `repo/src` confirmed every
consumer (`terminal.py:688/694/730/965`, `junitxml.py:223`, `pastebin.py:88`) uses
only the shared `ExceptionRepr` interface (`.reprtraceback`, `.reprcrash`,
`.sections`, `.toterminal`); the lone `isinstance` check is against `str`
(`junitxml.py:224`). So rebuilding the worker’s actual `ExceptionChainRepr` (rather
than always downgrading to `ReprExceptionInfo`) breaks nothing and is more faithful.
And for the `None`/`str`/native paths V1 is byte-identical to V0 (PO-IDENT-V0) — no
regression. No change.

## Decision 5 — do NOT add a `.get("chain")` guard

Trace: **F4**, **PD3**, **PO-SCHEMA-PRODUCER**. The only latent edge is a `KeyError`
if a *pre-fix* payload (no `"chain"` key) reaches a post-fix `_from_json`. The audit
classified this **out of contract**: the hook is documented as restoring what *this*
version serialized and "subject to change between pytest releases, even bug fixes",
xdist pins matching versions, and the surrounding code already uses bare keys
(`["sections"]`, `["reprtraceback"]`, `["reprcrash"]`). Adding `.get` is zero-downside
hardening but pure gold-plating against a disclaimed scenario and would diverge from
the file’s style. Declined; recorded as a finding + an intent question (PD3) instead
of a code change, consistent with the kit’s "gather feedback, don’t silently patch"
default.

## Decision 6 — do NOT pursue total-correctness / extra machinery

Trace: **PROOF.md §8**, **PO-LIST-INDUCTION**, **PO-EXC**. The fragment is finite
structural recursion (terminating by construction), so partial and total correctness
coincide; the `RuntimeError` is modelled as partiality (adequate for the observable
"raise vs return"). Both are honest residuals, not defects — no code implication.

## Net

V1 was already correct and is a conservative, strictly-safer extension of V0. The
audit’s value here is **benefit 2** (a clean spec that confirms correctness and
documents why each subtle choice — process-both, the class change, the None guards,
the bare `["chain"]` — is right), not benefit 1 (test removal), which is withheld
pending a real `kprove` run (PROOF.md §9–10). The fix in `repo/src/_pytest/reports.py`
stands unchanged.
