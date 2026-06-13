# FVK audit notes — sphinx-doc__sphinx-8548

This documents the FVK audit of my V1 fix and every decision it produced. The
verdict is **CONFIRM V1 — no source changes** (see `fvk/ITERATION_GUIDANCE.md`).
Each decision below is traced to specific `fvk/FINDINGS.md` (F*) and
`fvk/PROOF_OBLIGATIONS.md` (VC) entries.

## What V1 is (recap)

Two source edits on top of `dd1615c`:
1. `sphinx/ext/autodoc/importer.py` — `get_class_members` final block rewritten to
   walk the MRO, loading each class's module analyzer and merging its
   comment-docstrings into `members` (add inherited instance attrs; complete the
   `None` docstring of inherited class attrs). Plus `PycodeError` import.
2. `sphinx/ext/autodoc/__init__.py` — `AttributeDocumenter.get_doc` now returns the
   nearest-MRO attribute comment (via the existing `get_attribute_comment`) before
   its legacy body.

## How I formalized it

The fix is set/map plumbing, not arithmetic, so the mini-K fragment
(`fvk/SPEC.md` §1) models the analyzer as an oracle map `AD` and the
`try/except (AttributeError, PycodeError): continue` as "source-less classes
contribute no `AD` keys" (`noSource`). I verified this abstraction against the real
code before relying on it: `pycode/__init__.py:111-128` shows `for_module` raising
*and caching* `PycodeError` (so `object`/builtins always miss), and `:161-184`
shows `analyze()` either fully populating `attr_docs` keyed `(qualname, attrname)`
or raising `PycodeError`. That keys/equivalence assumption is the one explicit
**[ESCALATION BOUNDARY]** (FINDINGS **F-A**), stated, not `[trusted]`-faked.

I wrote three contracts — `(GAC)` first-match MRO search, `(GCM)` the merge fold,
`(GD)` the `get_doc` guard — each with its loop circularity, and discharged the
obligations in `fvk/PROOF_OBLIGATIONS.md` by guarded coinduction + def-equality +
map/Z3 lemmas (`fvk/PROOF.md`).

## Decisions and their justification

### D1 — Keep the `get_class_members` MRO-merge edit. → F1; GCM-VC-add/-complete/-idem/-preserve/-skip

Formalizing the target bug (F1) confirmed both *why* V0 failed (comment keyed to
`('Base','ham')`, looked up as `('Inherited','ham')`) and that the merge fold is
correct: `GCM-VC-add` (insert at nearest commenting class), `GCM-VC-complete`
(fill a `None` docstring), `GCM-VC-idem` (most-derived-wins; the `is None` guard is
the idempotence witness — this is the formal resolution of the F6 "two-phase
discovery" smell, which the audit confirmed hides **no** bug), and `GCM-VC-preserve`
(never overwrite `__slots__`/enum docstrings). I re-derived the end-to-end trace for
the canonical Block-1 example under **both** `:inherited-members:` alone and
`:members:`+`:inherited-members:`, and for a **cross-module** base class; all
render `ham` with "A base attribute." Kept unchanged.

### D2 — Keep the `AttributeDocumenter.get_doc` edit, in its exact ordering. → F1, F5, F7; GD-EQ, GD-COMMENT, GD-INSTANCEATTR-order, GAC-PRE

The decisive obligation is **GD-EQ**: when there is no comment, the inserted prefix
(`comment = None; if comment: …`) is dead, so V1 `get_doc` is *syntactically* the
V0 body. This is the formal no-regression guarantee — V1 differs from V0 only on
inputs with a (possibly inherited) comment. `GD-COMMENT` confirms the comment is
emitted once and respects `Documenter.add_content`'s existing comment-over-docstring
priority (no double emission for local attributes, which take the
`attr_docs[(namespace,A)]` path before `get_doc` is consulted).
`GD-INSTANCEATTR-order` confirms the comment check must precede the
`if self.object is INSTANCEATTR: return []` line so a commented instance attribute
still shows its comment — V1's ordering is correct. `GAC-PRE` (F7) confirms the
`self.parent`/`self.objpath` preconditions hold (set by `import_object` before
`get_doc`; non-class/`None` parent is total → empty MRO → `None`). **F5** (the
`get_doc` value now also feeds `_find_signature`) was checked and is inert for
prose `#:` comments — recorded as WATCH, no change.

### D3 — Do NOT modify `is_filtered_inherited_member`. → F2; G2

This is the one decision where I deliberately *declined* to widen the fix. The
audit (F2) found that an inherited **instance** attribute (e.g. `self.x` in a base
`__init__`) is now *discovered* by V1 but, under `:members:`+`:inherited-members:`,
is still dropped by `is_filtered_inherited_member`: I verified at
`__init__.py:669-680` that the MRO walk, finding `x` in no class `__dict__` nor
`__annotations__`, reaches `object` and returns `True` (line 770-771 filter). I
confirmed this is **not a V1 regression** (V0 never discovered `x` at all → also
omitted) and is the separately-tracked issue **#6415**, which `PROBLEM.md`
explicitly calls out as distinct from this issue's *class-level data members*. I
also confirmed the in-scope class attribute `ham` is **not** affected (it *is* in
`Base.__dict__`, so `is_filtered` returns `False` at line 675) and that the
instance-attribute case *does* work under `:inherited-members:` **alone** (then
`members != ALL`, the line-770 filter is not consulted, and `has_doc` keeps it).
Changing `is_filtered_inherited_member` would touch the `:inherited-members:
<ClassName>` limit feature (its own logic + tests) and enlarge the diff beyond the
"minimal, targeted" instruction, so it is excluded and documented (G2) rather than
hidden.

### D4 — Accept "overridden-without-comment inherits the base comment". → F3; G3, GD-COMMENT

The audit surfaced that a subclass re-binding `attr` without its own `#:` comment
now inherits the base's comment. This is decided by `get_attribute_comment`
(independently of the `get_class_members` change, so discovery and rendering are
consistent), matches how methods already inherit docstrings, and matches V0's
pre-existing behavior for annotation-only inherited attributes. Accepted as
intended; the single lever to change it later (stop at the first MRO class that
*binds* the name) is recorded in G3.

### D5 — Rely on builtin-skip; no guard added. → F4; GCM-VC-skip

Source-less MRO classes (`object`, C extensions) are handled by the existing
`try/except (AttributeError, PycodeError): continue`, verified against
`for_module`'s caching re-raise. No code needed.

### D6 — Leave the now-unused `analyzer`/`objpath` parameters (and the loop-local shadowing) as-is. → F6; G5

Kept for backward compatibility of the semi-public `get_class_members` signature;
the loop-local `analyzer` reassignment is harmless. The audit (F6) confirmed this
structural point hides no bug. A cosmetic rename traces to no correctness
obligation and would enlarge the diff, so it is intentionally **not** done (G5).

## Honesty gate

The proof is **constructed, not machine-checked** — no `kompile`/`kprove` was run
(no execution environment). `fvk/PROOF.md` §7 emits the exact commands. The
test-redundancy output is **recommendation-only**; its dominant recommendation is to
**keep** the existing no-comment attribute tests, because they are precisely the
`GD-EQ` regression net for this fix. Nothing is deleted, and the project's hidden
test suite was not touched.

## Bottom line

Every correctness obligation for the in-scope bug (#8548, inherited class-level data
members) discharges against the spec; the only open item is the explicit analyzer
adequacy boundary. No finding is a bug *introduced by* V1. **V1 stands unchanged.**
