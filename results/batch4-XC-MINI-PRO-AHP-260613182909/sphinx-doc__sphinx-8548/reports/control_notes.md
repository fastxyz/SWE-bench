# Control notes — V2 review outcome for sphinx-doc__sphinx-8548

This documents the V2 decisions after a systematic review of V1. Each decision
cites numbered findings in `review/FINDINGS.md`.

## Summary

The review concluded that **V1 is functionally correct and complete** for the
reported issue (and the related inherited-instance-attribute case), with no
identified regressions. Exactly **one** source change was made in V2 — a
zero-behavior-change rename to remove a variable-shadowing smell. Both behavioral
edits from V1 stand.

## The single code change made in V2

### De-shadow the `analyzer` parameter in `get_class_members` (importer.py)

- **What:** Renamed the per-class loop-local from `analyzer` to `cls_analyzer`,
  and added a comment noting that the `objpath`/`analyzer` parameters are kept
  only for backward compatibility.
- **Why / trace:** **F18** flagged that V1 reused the parameter name `analyzer`
  as a loop variable, shadowing the (now vestigial) parameter — a readability
  hazard a reviewer would call out. Renaming removes the shadow while keeping the
  public 4-argument signature intact (required by the only caller,
  `ClassDocumenter.get_object_members`, and by any external/test callers; see
  F18). This is a pure rename with **no behavioral effect**, which matters given
  there is no execution environment to test with.
- **Why not remove the unused params instead:** Removing `objpath`/`analyzer`
  would break positional callers and is unnecessary for the fix (F18, F19).

## Behavioral edits from V1 that were confirmed and kept

### Keep `get_class_members` MRO walk (importer.py)

- **Trace:** **F1, F3, F6, F7.** Walking the MRO and matching
  `analyzer.attr_docs` by each class's `__qualname__` is what makes inherited
  class-level attributes carry their comment docstring (F1) and inherited
  instance attributes appear at all (F3). F6 verified `ns == cls.__qualname__` is
  the correct key comparison against the parser's `(".".join(qualname[:-1]),
  name)` keys. F7 verified the most-derived-wins ordering via the
  `elif members[name].docstring is None` guard. No change needed.
- **Error handling kept as-is:** F11 confirmed `except (AttributeError,
  PycodeError): continue` safely skips builtins/C/unanalyzable base modules
  (`for_module` funnels all import errors into `PycodeError`). F12 confirmed
  `attr_docs` is never `None` after a non-raising `analyze()`, so the
  `.items()` access needs no extra guard and stays consistent with the existing
  `get_attribute_comment` pattern. I deliberately did **not** add defensive
  `or {}` noise.
- **No over-inclusion:** F5 (non-`:inherited-members:` still excludes inherited
  attrs via `class_` comparison) and F8 (private inherited members still gated by
  `:private-members:`) confirmed correctness.

### Keep the `AttributeDocumenter.get_doc` comment check (`__init__.py`)

- **Trace:** **F2, F4, F13, F14, F15.** F2 established this edit is *required*:
  for a real-valued inherited attribute (e.g. `ham == True`, not
  `UNINITIALIZED_ATTR`), the pre-existing
  `UninitializedInstanceAttributeMixin.get_doc` returns nothing, so without the
  top-of-`get_doc` comment check the primary example would still render empty.
  F4 confirmed it also fixes `autoattribute` on inherited attributes. F13
  verified the new `_find_signature`→`get_doc` interaction has no visible effect
  (args are discarded; `retann` is never rendered for attributes; the comment is
  returned directly, bypassing `_new_docstrings`). F14 confirmed the
  comment-over-`__doc__` precedence matches the existing local-attribute
  behavior and leaves the #7805 guard intact. F15 confirmed no other documenter
  needs an analogous change. No change needed.

## Things considered and deliberately left unchanged

- **Empty `#:` comments on inherited attributes (F10):** a tiny inconsistency
  vs. local attributes. Not fixed — empty comments are non-documentation,
  dropping them is arguably more correct, and matching the local quirk would
  require an MRO `attr_docs` scan inside `filter_members`, i.e. disproportionate
  complexity and risk for no real-world benefit.
- **Redundant comment check in `UninitializedInstanceAttributeMixin.get_doc`
  (F16):** now dead for `AttributeDocumenter` but harmless; removing it would
  change the mixin's standalone contract for no functional gain, so it is kept to
  minimize blast radius.
- **Deprecated importer `get_object_members` (F19):** not on the class path and
  cannot carry docstrings without an API change; out of scope.
- **`bysource` ordering of inherited members (F17):** pre-existing behavior, not
  introduced by this fix.

## Net result

`reports/baseline_notes.md` (V1) remains an accurate description of the fix. The
V2 source tree differs from V1 only by the `analyzer` → `cls_analyzer` rename and
its explanatory comment in `sphinx/ext/autodoc/importer.py`; behavior is
identical to V1, which the review validated as correct.
