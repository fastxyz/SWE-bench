# ITERATION_GUIDANCE.md — sphinx-doc__sphinx-8548

Actionable next-iteration guidance from the FVK audit. Each entry: **evidence →
classification → UltimatePowers question → recommended change → tests**. The
verdict for this pass is at the bottom.

---

## G1 — Keep V1's two-site MRO design (do not collapse to one site)

- **evidence:** FINDINGS F1; PROOF.md §1 (the bug needs *both* `get_class_members`
  discovery — so `filter_members` keeps the member — *and* `get_doc` emission).
- **classification:** confirmed-correct design.
- **UltimatePowers question:** none.
- **recommended change:** none. A one-site fix is insufficient: discovery without
  emission renders an empty body; emission without discovery never reaches the
  documenter (member filtered as undocumented).
- **tests:** keep an end-to-end `autoclass … :inherited-members:` test *and* a
  direct `autoattribute Sub.inherited_attr` test — they exercise the two sites
  independently.

## G2 — Do NOT widen scope to `is_filtered_inherited_member` (issue #6415)

- **evidence:** FINDINGS F2; PROOF_OBLIGATIONS F2 note.
- **classification:** out-of-scope limitation (separate issue), not a regression.
- **UltimatePowers question:** "Should `:members:` + `:inherited-members:` document
  inherited *instance* attributes (defined as `self.x` in a base `__init__`), or is
  that intentionally deferred to #6415?"
- **recommended change (deferred):** if pursued, teach `is_filtered_inherited_member`
  to treat a name present in any MRO class's `attr_docs` (comment/instance var) as
  "defined there," so the MRO walk stops before reaching `object`. **Risk:** that
  function backs the `:inherited-members: <ClassName>` *limit* feature and has its
  own tests; changing it risks regressions unrelated to this issue. Hence excluded
  from this minimal fix.
- **tests:** keep the existing instance-attribute behavior tests; add a *kept*
  (out-of-domain) test pinning today's behavior so #6415 can flip it deliberately.

## G3 — Record the override-inherits-comment decision (F3)

- **evidence:** FINDINGS F3; PROOF_OBLIGATIONS GD-COMMENT.
- **classification:** intended-but-arguable behavior.
- **UltimatePowers question:** "When a subclass re-binds an attribute *without* its
  own `#:` comment, should it inherit the base class's comment (current) or render
  as undocumented?"
- **recommended change:** none now; if "stop at override" is desired later, the
  single lever is `get_attribute_comment` (have it stop at the first MRO class that
  *binds* the name, even without a comment).
- **tests:** add one test pinning the current inherit-the-comment behavior.

## G4 — `[ESCALATION BOUNDARY]`: analyzer adequacy (F-A)

- **evidence:** FINDINGS F-A; PROOF.md §5 trusted base.
- **classification:** proof-capability/adequacy gap, **not** a code bug.
- **recommended change:** none to the code. Roadmap: replace the `AD`/`noSource`
  oracle with a real Python-source-comment semantics so the literal
  `ModuleAnalyzer` path is verified rather than abstracted.
- **tests:** keep `ModuleAnalyzer`/`pycode` parser tests (they pin the oracle's
  real implementation that the proof abstracts).

## G5 — Optional cosmetic only (no functional change)

- **evidence:** the rewritten `get_class_members` reassigns the loop-local
  `analyzer`, shadowing the now-unused `analyzer`/`objpath` parameters (kept for
  backward-compat).
- **classification:** style; FINDINGS F6 confirmed this hides no bug.
- **recommended change:** *optional* — rename the loop-local to make the dead
  parameter explicit. **Not done:** it changes no behavior, traces to no
  correctness obligation, and would enlarge the diff against the "minimal,
  targeted" instruction. Left as-is intentionally.

---

## Verdict for this pass: **CONFIRM V1 — no source changes**

The audit discharged every correctness obligation (PROOF_OBLIGATIONS A–C) against
the spec, with the only open item an explicit adequacy boundary (F-A). The
decisive guarantee is **GD-EQ**: V1 differs from V0 *only* when an attribute has a
(possibly inherited) comment, and on that input it produces precisely the intended
result (F1). No finding rises to a bug *introduced by* V1:

- F1 is the fix working as intended;
- F2 is a pre-existing, separately-tracked limitation (no regression) — widening to
  it is explicitly rejected (G2) on scope+risk grounds;
- F3 is an accepted, internally-consistent judgement call;
- F4/F5/F6/F7 are corner cases the proof shows are handled.

Therefore V1 **stands unchanged**. The justification is the FINDINGS dispositions
plus the discharged obligations, not an absence of analysis.
