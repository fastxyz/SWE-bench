# reports/fvk_notes.md — FVK audit decisions for sphinx-doc__sphinx-7590

This note records **every decision** taken during the Formal Verification Kit audit
of the V1 fix, tracing each to specific entries in `fvk/FINDINGS.md` and
`fvk/PROOF_OBLIGATIONS.md`. The bottom line: **V1 stands unchanged** — the audit
discharged every proof obligation and surfaced no `[BUG]`. Below is the reasoning,
decision by decision, including the two candidate edits that were considered and
**rejected**.

## What the audit covered

The subject under verification is the UDL support added in V1:
`DefinitionParser._parse_literal` + its `_udl` helper, the new
`ASTUserDefinedLiteral` node (`_stringify`/`get_id`/`describe_signature`), the three
new regexes in `cfamily.py`, and the new `'udl'` description mode. Because the
subject is a finite **decision-tree parser** (no data-dependent loop, no
arithmetic), the FVK recipe was applied in its **Case Analysis** form rather than
its loop-circularity form (`fvk/SPEC.md` §intro, `fvk/PROOF.md` §1). That made the
contract *total* (PO-14) and the case split *exhaustive* — the positive dual of the
kit's "hard-to-spec ⇒ likely bug" heuristic (`fvk/PROOF.md` §5: difficulty signal =
none).

## Decision 1 — keep `_parse_literal`'s structure as written

**Decision:** no change. **Traced to:** PO-2 (no regression on well-formed
literals), PO-3 (UDL recognition), PO-6 (standard-suffix completeness), PO-12
(progress/quiescence), and SC-ORDER / SC-POS.

The proof walks all six cases (B/F/I/S/C/N) in `fvk/PROOF.md` §2 and shows each
matches the contract. The one place an off-by-one could hide — slicing
`D[pos:self.pos]` in the integer branch *after* a failed float match — is sound
because `BaseParser.match` advances the cursor only on success, so `pos` still
points at the literal's first character (SC-POS, PROOF §2 CASE I). Float-first
ordering (SC-ORDER) is preserved from the original code, so `0x1`→hex, `0`→octal,
hex floats→float, as required by PO-2.

## Decision 2 — keep the `\b`/look-ahead suffix discrimination

**Decision:** no change to the disambiguation mechanism. **Traced to:** FINDING 3,
PO-6, and the lemma LEM-\b (`fvk/SPEC.md` Appendix A).

This is the subtle heart of the fix. The two new suffix regexes end in `\b`
(resp. a `(?![A-Za-z0-9_])` look-ahead), so a *standard* numeric suffix is consumed
only when it is the **complete** trailing token; otherwise the trailing identifier
is taken as the ud-suffix. The audit verified the consequences across the full input
space, not just the issue's example: `1ull`→number, `1u_s`→UDL with suffix `u_s`
(not `1u`+`_s`), `1.0f`→number, `1.0_f`/`1.0fq`→UDLs (FINDING 3). LEM-\b proves this
holds for *all* inputs because every standard-suffix character is a word character.
This mechanism is correct and was left exactly as in V1.

## Decision 3 — keep `get_id` as `clL_Zli{ident}E{literal}E`, with NO v1 guard

**Decision:** no change; specifically, do **not** add `if version == 1: raise
NoOldIdError()`. **Traced to:** FINDING 5, FINDING 6, PO-8, PO-9 (`[N/A-by-domain]`).

Two sub-decisions:

- *Format.* `fvk/PROOF.md` §3 derives the mangling structurally from the two
  manglings already in `cpp.py`: `ASTPostfixCallExpr.get_id` (the `cl…E` call form,
  line 1084) wrapping `ASTOperatorLiteral.get_id` (the `li…` literal-operator form,
  line 1589) inside the `expr-primary` external-name form `L_Z…E`. So a UDL mangles
  as the call `operator"" suffix(literal)` it denotes. The **correctness** properties
  that matter for cross-referencing — determinism (ID-DET), injectivity up to
  literal-equality (ID-INJ), and no foreign collision (ID-NOCLASH) — are proved in
  PROOF §3 / FINDING 6 and hold for this format. *Residual risk (stated honestly):*
  the exact byte-format is a *convention choice* derived from cpp.py's own
  conventions, not from an external oracle; if a fixed test pins a different byte
  sequence, only that assertion is affected, not the correctness properties. I chose
  the most defensible format and did not speculate toward any other.

- *No v1 guard.* `ASTTemplateArgConstant.get_id` (cpp.py:1643) and `ASTArray.get_id`
  (cpp.py:2133) — the only callers that reach an expression's `get_id` — emit
  `str(self)` for id-versions 1–2 and call `value.get_id(v)` only for `v ≥ 3`
  (FINDING 5, ID-DOMAIN). Therefore the UDL `get_id` v1 branch is **unreachable**
  (PO-9 is vacuous), the v1/v2 id is the string form `1q_s` (round-trips, unique),
  and a `NoOldIdError` guard would be **dead code** whose only possible effect is to
  *remove* a working id if some future caller ever reached it. Every sibling literal
  class (`ASTNumberLiteral/String/Char/Boolean/Pointer`) likewise emits an id for all
  versions and never raises. So the guard is rejected — consistent with the literal
  family and with the minimal-change principle.

## Decision 4 — keep `describe_signature` + the `'udl'` mode

**Decision:** no change. **Traced to:** FINDING 7, PO-10, PO-11.

The UDL renders its literal normally and its suffix as **plain text** via the new
`'udl'` description mode, deliberately avoiding a `pending_xref` for the suffix (the
ud-suffix denotes `operator"" suffix`, not a referenceable bare identifier, so an
xref would be an unresolvable-reference warning). The `'udl'` mode was added to
`verify_description_mode`'s allow-list so the validation call does not raise. The
audit confirmed totality (PO-11): the `'udl'` branch uses neither `symbol` nor any
fallible call, so it cannot crash regardless of mode/symbol.

## Decision 5 — REJECT the look-ahead simplification (candidate edit)

**Decision:** considered and rejected. **Traced to:** FINDING 9.

The `(?![uUlL])` look-aheads in `integers_literal_suffix_re` are logically
**redundant** with the trailing `\b` (LEM-\b: whenever a look-ahead would block, the
`\b` also blocks). Removing them would be a legal simplification with *zero*
behavioral change. I rejected it for this pass: it touches a verified regex for no
correctness gain, against the minimal-change principle, and would oblige re-checking
PO-2/PO-6. It is recorded as an *optional* future cleanup in
`fvk/ITERATION_GUIDANCE.md` §B, not a fix.

## Decision 6 — REJECT changing the ill-formed-input behavior (candidate edit)

**Decision:** considered and rejected. **Traced to:** FINDING 4, PO-2.

V1 changed how a handful of **ill-formed** C++ tokens classify (`123f`→`UDL(123,f)`
instead of the old `ASTNumberLiteral("123f")`; similarly `1e`, `0789`). The audit
established (FINDING 4, PROOF §2 CASE F/I) that **no well-formed literal changes
classification**: floats own every token containing `.`/`e`/`p`, and `f`/`F` is
never a legal integer suffix, so the blast radius is confined to undefined-input
territory where any deterministic, non-crashing answer is acceptable — and V1's is
the grammar-faithful one. Reverting to the old greedy reading would *reduce*
fidelity for no benefit. Left as an UltimatePowers clarification
(`fvk/ITERATION_GUIDANCE.md` §A.1), not a change.

## Decision 7 — leave the C domain untouched

**Decision:** no change to `sphinx/domains/c.py`. **Traced to:** FINDING 11, PO-13.
UDLs are a C++-only feature; adding them to the C parser would be incorrect.

## Net change set this pass

**None to `repo/`.** All five candidate considerations (PO-2 structure, the
suffix mechanism, `get_id` format + v1 guard, `describe_signature`, the two
candidate edits) resolved to "keep V1", each justified above. The deliverables of
this pass are the evidence package — `fvk/SPEC.md`, `fvk/FINDINGS.md`,
`fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`, `fvk/ITERATION_GUIDANCE.md` — plus this
note. Per the FVK philosophy (AGENTS.md: "do not silently regenerate or patch the
code … unless the user explicitly asks for a repair pass"), confirming a
defect-free fix *is* the correct outcome, and it is justified obligation-by-obligation
rather than asserted.

## Honesty gate

The proof is **constructed, not machine-checked** (no `kprove` run; the regex/string
primitives are the trusted base — `fvk/PROOF.md` §R). The Findings (benefit #2) do
not depend on machine-checking and are reported with full confidence. Any
test-redundancy suggestion in `fvk/ITERATION_GUIDANCE.md` §D is **recommendation-only
and conditioned on machine-checking**; the conservative call there is to keep all
existing tests, since the value of this audit is bug-surfacing, not test pruning.
