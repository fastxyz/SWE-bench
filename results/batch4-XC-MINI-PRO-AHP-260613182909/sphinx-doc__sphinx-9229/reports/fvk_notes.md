# reports/fvk_notes.md — FVK audit decisions for sphinx-doc__sphinx-9229

This records every decision made during the FVK audit of the V1 fix, tracing each
to specific entries in `fvk/FINDINGS.md` and `fvk/PROOF_OBLIGATIONS.md`.

## Outcome in one line

**V1 stands unchanged.** The FVK audit found the fix correct, minimal, and
complete on its in-scope domain: every behavioural obligation (PO-D1..D4) and the
integration keystone (PO-I1, NO-DOUBLE) discharge against the spec, and the only
open obligations are upstream trusted-base boundaries (PO-T1/T2/T3) that this fix
does not touch. No source file under `repo/` was modified in this pass.

## The fix being audited (unchanged)

`ClassDocumenter.get_variable_comment` (new) + the `doc_as_attr` branch of
`ClassDocumenter.get_doc`, in `repo/sphinx/ext/autodoc/__init__.py`
(lines 1676–1692). Root cause and rationale are in `reports/baseline_notes.md`.

## Decision log (each traced to FINDINGS / PROOF_OBLIGATIONS)

### D1 — Keep the V1 logic exactly as written. *(no change)*
- **Traces to:** FINDINGS **F1** (the bug V1 fixes), **F4** (exactly-once
  rendering), **F5** (comment-less aliases unchanged, event not fired);
  PROOF_OBLIGATIONS **PO-D1/D3** (returns `[C0]` when a comment exists),
  **PO-D2** (returns `None`, not `[]`, when none), **PO-I1** (NO-DOUBLE).
- **Why:** all four discharge in `fvk/PROOF.md` §A–§C with no blocked VC. The
  one obstacle that *would* have signalled a bug — "the comment could render
  twice" — is discharged by the `no_docstring` disjointness argument. I verified
  the keystone against the real code: `repo/.../autodoc/__init__.py:613`
  (`no_docstring = True`) gated by `:622` (`if not no_docstring:`), and the
  event-suppression comment at `:625` ("Do not call autodoc-process-docstring on
  get_doc() returns None"). So nothing in the logic needs revision.

### D2 — Use `self.modname` (not `self.get_real_modname()`) in `get_variable_comment`. *(confirm V1's choice)*
- **Traces to:** FINDINGS **F6**; PROOF_OBLIGATIONS **PO-I2** (coverage),
  **PO-T2** (key adequacy).
- **Why:** the alias's *own* comment lives in the file where the alias is
  assigned = `self.modname`. The counter-input `IntAlias = int` (FINDINGS F6)
  shows `get_real_modname() = 'builtins'` is unanalyzable and would re-break the
  bug; `self.modname` finds the comment. I additionally confirmed
  `get_variable_comment`'s key `('.'.join(self.objpath[:-1]), self.objpath[-1])`
  is **byte-for-byte the same** key the inherited analyzer path computes
  (`__init__.py:611`), so the two render paths can never disagree on *which*
  comment (PO-T2). → V1's existing choice is correct and load-bearing; kept.

### D3 — Keep `return None` (not `[]`) for the comment-less alias arm. *(confirm V1's choice)*
- **Traces to:** FINDINGS **F5**; PROOF_OBLIGATIONS **PO-D2**.
- **Why:** `repo/.../autodoc/__init__.py:624–632` shows `get_doc()` returning
  `None` makes `add_content` *skip* `process_doc` (no `autodoc-process-docstring`
  event), whereas returning `[]` would append a dummy `[[]]` and *fire* the
  event. `test_class_alias` connects a handler that `raise`s to assert the event
  is never fired for a comment-less alias. So the `None` branch is essential and
  is kept exactly.

### D4 — Reject the cosmetic comment-clarification. *(considered, no change)*
- **Traces to:** PROOF_OBLIGATIONS **PO-D4**; ITERATION_GUIDANCE **G1**.
- **Why:** the inline comment `# Don't show the docstring of the class when it is
  an alias.` still accurately describes the `return None` arm (the class's own
  `__doc__` is never shown — PO-D4). Editing it for the new "show the *variable*
  comment" arm adds churn the proof shows is unnecessary, and risks confusing a
  reviewer diffing against the established phrasing. Minimal-change principle ⇒
  leave it.

### D5 — Do **not** add an `objpath`-non-empty guard. *(considered, no change)*
- **Traces to:** FINDINGS **F7**; PROOF_OBLIGATIONS **PO-G1**;
  ITERATION_GUIDANCE **G4**.
- **Why:** `self.objpath[-1]` could `IndexError` on an empty `objpath`, but that
  precondition is **upstream-enforced** (a `ClassDocumenter`'s object is always a
  `type`, so `import_object` already indexed `objpath[-1]` before `get_doc`
  runs) and is **pre-existing and shared** with `DataDocumenter.get_doc` /
  `import_object`. V1 does not widen it. Adding a guard would diverge from the
  sibling pattern and the minimal-change goal for an unreachable case. PO-G1 is
  discharged as an upstream-enforced precondition, not a missing guard.

### D6 — Do **not** change the empty-but-present-comment behaviour. *(considered, no change)*
- **Traces to:** FINDINGS **F3**; ITERATION_GUIDANCE **G5**.
- **Why:** an `attr_docs[key] = ['']` (bare `#:`/`""""""`) renders an empty
  block — but this is **identical to `DataDocumenter`**. Special-casing only
  `ClassDocumenter` would *introduce* an inconsistency across the documenters;
  any normalization belongs cross-cuttingly and is out of scope for this issue.

### D7 — Record re-exported aliases as a known, non-regressing scope gap. *(no change)*
- **Traces to:** FINDINGS **F9**; PROOF_OBLIGATIONS **PO-I2**.
- **Why:** a `from B import Alias` re-export documented from `A` keeps its
  comment in `B`'s analyzer; neither `self.modname` nor `get_real_modname()`
  recovers it. Behaviour is **identical to V0** (showed nothing then too), so V1
  is not a regression; fixing it is out of scope.

### D8 — Trusted-base / escalation boundaries acknowledged, not faked. *(no change)*
- **Traces to:** PROOF_OBLIGATIONS **PO-T1/T2/T3**; FINDINGS proof-derived
  section.
- **Why:** the `sphinx.pycode` analyzer/parser (PO-T1) and the comment-key
  convention (PO-T2) are upstream and unchanged by this fix; full Python value/
  exception semantics (PO-T3) exceed the mini-Python fragment. These are marked
  `[ESCALATION BOUNDARY]` and routed to the parser sources — **not** admitted as
  `[trusted]`-with-false-confidence — per the kit's honesty discipline.

## Verification status (honesty gate)

All proofs in `fvk/PROOF.md` are **constructed, not machine-checked** — no
`kompile`/`kprove` was run (no execution environment). The test-redundancy
recommendation is therefore **0 removals / keep all tests** until the emitted
commands return `#Top`; the durable value of this pass is benefit 2 (the audit
that confirms the fix and pins its load-bearing invariants), not test pruning.

## Net change in this pass

- Source code under `repo/`: **none** (V1 confirmed).
- New artifacts: `fvk/SPEC.md`, `fvk/FINDINGS.md`, `fvk/PROOF_OBLIGATIONS.md`,
  `fvk/PROOF.md`, `fvk/ITERATION_GUIDANCE.md`, and this `reports/fvk_notes.md`.
