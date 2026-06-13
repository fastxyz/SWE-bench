# ITERATION_GUIDANCE.md — feedback for the next pass (sphinx-doc__sphinx-9229)

`/verify` as a critic for the generate→formalize→verify loop. Each item:
**Evidence · Classification · UltimatePowers question · Recommended change ·
Tests.**

**Bottom line:** the audit produced **no actionable correctness change** — V1
discharges every behavioural and integration obligation. The items below are
(1) the one decision to keep V1 unchanged, justified; (2) trusted-base
boundaries to remember; and (3) optional hardening the maintainers *might* want,
clearly marked non-blocking.

---

## G1 — KEEP V1 UNCHANGED (primary outcome)

- **Evidence:** `PROOF.md` §A–§C discharge (GVC), (GETDOC-COMMENT),
  (GETDOC-NONE), and NO-DOUBLE; `PROOF_OBLIGATIONS.md` shows no blocked VC.
  FINDINGS F1 (bug fixed), F4 (exactly-once), F5 (regression-safe).
- **Classification:** confirmed-correct; no code bug.
- **UltimatePowers question:** none required.
- **Recommended change:** **none.** V1's two methods stay exactly as written. A
  cosmetic clarification of the inline comment was *considered and rejected* —
  the comment `# Don't show the docstring of the class when it is an alias.`
  still correctly describes the `return None` (no-comment) arm, and editing it
  would add churn the proof shows is unnecessary (see `reports/fvk_notes.md`).
- **Tests:** keep the existing alias tests (they double as `None`/event guards,
  F5/PO-D2); ensure any new hidden test covers the **direct external-alias-with-
  comment** path (the F1 case PATH-2 serves).

## G2 — `self.modname` vs `get_real_modname()` is load-bearing — keep it

- **Evidence:** FINDINGS F6 + PO-I2. Counter-input `IntAlias = int`:
  `get_real_modname() = 'builtins'` (unanalyzable) would re-break F1; `self.modname`
  finds the comment.
- **Classification:** design invariant to protect against well-meaning refactors.
- **UltimatePowers question:** "When an alias targets a class from another module,
  whose source file holds the alias's *own* doc-comment?" → the alias's defining
  module (`self.modname`), always.
- **Recommended change:** none; add a code comment only if a future refactor
  tempts someone to "unify" with `real_modname` (non-blocking).
- **Tests:** a regression test aliasing a class from a *different* module (or a
  builtin) with a `#:`/`"""` comment, documented directly, asserting the comment
  renders — this is the test that distinguishes `self.modname` from
  `get_real_modname()`.

## G3 — Trusted-base boundaries (remember, do not silently re-trust)

- **Evidence:** PO-T1 (analyzer/parser oracle), PO-T2 (key adequacy), PO-T3
  (Python value/exception semantics). `[ESCALATION BOUNDARY]`.
- **Classification:** proof-capability gap, **not** a code bug.
- **UltimatePowers question:** none for this fix; relevant only if the
  `sphinx.pycode` parser changes how it keys variable comments.
- **Recommended change:** none. If the parser's comment-keying ever changes,
  re-verify PO-T2 against both `add_content`'s PATH-1 key and
  `get_variable_comment`'s key **together** (they must stay identical).
- **Tests:** keep the `tests/test_pycode_parser.py` comment-picker tests as the
  oracle for PO-T1/PO-T2.

## G4 — `objpath` non-empty precondition (optional hardening, non-blocking)

- **Evidence:** FINDINGS F7 / PO-G1. `self.objpath[-1]` would `IndexError` on an
  empty `objpath`; not caught by `except PycodeError`.
- **Classification:** latent precondition, **pre-existing and shared** with
  `DataDocumenter.get_doc` and `ClassDocumenter.import_object`; *not* introduced
  or widened by V1, and unreachable in practice (a `ClassDocumenter`'s object is
  always a `type`, so `import_object` already indexed `objpath[-1]`).
- **UltimatePowers question:** "Is there any path that builds a `ClassDocumenter`
  with an empty `objpath`?" Expected answer: no.
- **Recommended change:** **do not add a guard in this fix** (would diverge from
  the sibling pattern and the minimal-change goal). If the project ever wants
  defensive uniformity, guard it *once* at the shared call sites, not per-method.
- **Tests:** none needed; the case is unreachable.

## G5 — empty-but-present comment renders an empty block (optional, cross-cutting)

- **Evidence:** FINDINGS F3. `attr_docs[key] = ['']` makes `if comment:` true, so
  an empty docstring block is processed (event fires) instead of being treated as
  "no comment".
- **Classification:** consistency NOTE — V1 **matches** `DataDocumenter`; changing
  only `ClassDocumenter` would *introduce* an inconsistency.
- **UltimatePowers question:** "Should a bare `#:` / `""""""` on an alias be
  treated as 'documented (empty)' or 'undocumented'?" (Same question already
  applies to `DataDocumenter`.)
- **Recommended change:** if ever desired, normalize *across* Data/Attribute/Class
  documenters at once (e.g. treat a whitespace-only comment as absent) — **out of
  scope** for this issue.
- **Tests:** none added here.

## G6 — re-exported aliases (documented scope gap, no regression)

- **Evidence:** FINDINGS F9 / PO-I2. Comment of a `from B import Alias`
  re-export, documented from `A`, is in `B`'s analyzer; neither `self.modname`
  nor `get_real_modname()` recovers it.
- **Classification:** scope limitation; behaviour **identical to V0** (showed
  nothing then too).
- **UltimatePowers question:** "Should re-exported aliases surface the original
  module's doc-comment?" — likely out of scope / rare.
- **Recommended change:** none now; if ever wanted, follow `__module__` of the
  *binding* (hard, import-order dependent).
- **Tests:** none.

---

## Loop / Termination summary

No loops, no recursion → no circularity, no decreasing-measure obligation
(`SPEC.md` §5, `PROOF.md` §5). Partial = total correctness for all three
contracts. There is nothing here for a future "prove termination" pass to do.

## One-line feedback to the code generator

> The fix is correct and minimal as-is; the only thing to *protect* in future
> edits is the use of `self.modname` (not `real_modname`) in
> `get_variable_comment` and the `None`-not-`[]` return in the no-comment arm —
> both are load-bearing (G2, F5/PO-D2). No new code is warranted.
