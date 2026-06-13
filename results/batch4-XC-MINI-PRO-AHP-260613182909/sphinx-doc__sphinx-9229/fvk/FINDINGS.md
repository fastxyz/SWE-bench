# FINDINGS.md — plain-language findings for the V1 fix (sphinx-doc__sphinx-9229)

Each finding is `input → observed vs expected`, readable without the proof.
Severity: **BUG** (must fix) · **RISK** (latent / edge) · **OK** (positive — a
guard/precondition that is correctly handled) · **NOTE** (design rationale).

The headline result of the audit: **a clean specification *was* writable for all
three functions with no awkward case-splits and no invented preconditions** — by
the kit's own "spec-difficulty = bug signal" rule, that is positive evidence the
V1 fix is well-formed. The findings below are the corner cases that writing it
surfaced; **none is an unaddressed correctness bug in V1.**

---

## F0 — OK (structural): no loops, no recursion ⇒ no circularity risk

- The two edited functions are **straight-line + branching**; `add_content`'s
  comment logic is two `if`s. There is **no loop and no recursion**, so there is
  **no loop invariant / coinductive hypothesis to get wrong** (the classic
  source of off-by-one and non-preservation bugs). Symbolic execution terminates
  in a fixed number of steps. → Expected and observed: trivially terminating,
  partial = total correctness.

## F1 — BUG (the one V1 fixes): alias's own comment was discarded

- **input:** a class alias with its own doc-comment whose aliased class lives in
  a **different module**, documented directly, e.g.
  ```python
  #: docstring for the alias
  IntAlias = int            # int.__module__ == 'builtins'
  ```
  `do_autodoc(app, 'class', 'target.…​.IntAlias')`.
- **observed (V0 / pre-fix):** only `alias of :class:\`int\``. The base
  `add_content` analyzer path uses `self.analyzer`, built from
  `self.real_modname = int.__module__ = 'builtins'` (or `None`, since `builtins`
  has no analyzable source), so it never finds the comment; and
  `ClassDocumenter.get_doc()` returned `None` unconditionally → comment dropped.
- **expected (I1):** the docstring **and** `alias of int` are both rendered (the
  behaviour `DataDocumenter` already has, asserted by `test_autodata_GenericAlias`).
- **why it matched the reporter's "1 of 3 works":** on the reporter's Python 3.6,
  `Dict[str, Any]` and `Callable[...]` are `type` instances (`typing.GenericMeta`/
  `CallableMeta`) routed through `ClassDocumenter` (alias of a `typing`-module
  class) → dropped; `Union[str, None]` is **not** a `type` → routed through
  `DataDocumenter` → kept.
- **V1 resolution:** `get_doc` now returns the alias's own comment via the new
  `get_variable_comment`, looked up from **`self.modname`** (the alias's defining
  module). Proven by spec **(GETDOC-COMMENT)**.

## F2 — OK (positive guard): `try/except PycodeError` totalizes the lookup

- **input:** alias to a class whose `self.modname` has **no analyzable source**
  (C/extension module, egg edge case, syntactically broken source).
- **observed:** `ModuleAnalyzer.for_module(self.modname)`/`.analyze()` raise
  `PycodeError`; the `except` returns `[]`, so `get_doc` returns `None` and the
  alias still renders `alias of …` (no crash). Verified that `analyze()` wraps
  *all* exceptions as `PycodeError` and `for_module` raises only `PycodeError`,
  so nothing else escapes the `except`.
- **expected:** graceful degradation to "no comment" — matched.
- **Finding type:** the guard **enforces totality**, exactly the
  "input-validation guard ⇒ positive finding" pattern. Recorded as trusted-base
  assumption **PO-T1**. (Note: this mirrors the established
  `DataDocumenter.get_module_comment`, which uses the same `except PycodeError`.)

## F3 — NOTE (consistency): empty-but-present comment renders an empty block

- **input:** an alias whose key *is* present in `attr_docs` but with an **empty**
  comment value `['']` (e.g. a bare `#:` line or `""""""`).
- **observed:** `get_variable_comment` returns `['']`; `if comment:` is **true**
  (non-empty list), so `get_doc` returns `[['']]` → an empty docstring block is
  processed (and `autodoc-process-docstring` fires).
- **expected vs observed:** arguably one might want this treated as "no comment".
  **But this is identical to `DataDocumenter.get_module_comment` + `DataDocumenter.get_doc`**
  (`if comment: return [comment]`), so V1 is **consistent with the sibling
  documenter**, not a new divergence. → Severity NOTE, not BUG. Changing it would
  be a cross-cutting behaviour change to Data/Attribute/Class documenters, out of
  scope for this issue.

## F4 — OK (the correctness keystone): the comment renders **exactly once**

- **input:** any alias with a comment, in any documentation path.
- **observed:** the base `add_content` renders a comment by **two** paths —
  analyzer-driven (PATH-1) and `get_doc`-driven (PATH-2) — but PATH-1 sets
  `no_docstring = True` *iff* it renders, and `if not no_docstring:` gates PATH-2.
  The paths are **exhaustive and disjoint**, so the comment is rendered **0 or 1
  times, never 2**. Same-module / `automodule` (analyzer points at the right
  module) → PATH-1 serves it; direct external alias (analyzer points elsewhere or
  is `None`) → PATH-2 serves it. → Expected (I4) matched. Proven by spec
  **(NO-DOUBLE)**.
- **adversarial check performed:** searched for a state where PATH-1 renders *and*
  `get_doc` is still called — impossible, because PATH-1's render and its
  `no_docstring=True` are in the same `if key in attr_docs:` block.

## F5 — OK (regression guard): comment-less aliases unchanged + event not fired

- **input:** `Alias = Foo` with **no** doc-comment, e.g. the existing
  `target.classes.Alias` used by `test_class_alias` (whose connected
  `autodoc-process-docstring` handler **raises** to assert it is never called).
- **observed (V1):** `get_variable_comment` → `[]` → `get_doc` → `None` →
  `add_content` PATH-2 hits `if docstrings is None: pass` → `process_doc` is
  **not** called → handler **not** invoked → output is exactly
  `alias of :class:\`target.classes.Foo\``. → matches I3 and `test_class_alias`.
- This is why `get_doc` must return **`None`** (not `[]`) in the no-comment case:
  returning `[]` would make `add_content` append a dummy `[[]]` and **fire** the
  event. Proven by spec **(GETDOC-NONE)**; PO-D2 records the `None`≠`[]`
  distinction.

## F6 — NOTE (the load-bearing design decision): `self.modname`, not `get_real_modname()`

- The alias's **own** comment lives in the source file where the **alias is
  assigned** = `self.modname`. `self.get_real_modname()` returns the **aliased
  class's** module (`self.object.__module__`), which for an external/builtin
  alias is the wrong file and, for builtins, is *unanalyzable* (→ `PycodeError`).
- **counter-input that rules out `get_real_modname()`:** `IntAlias = int`:
  `get_real_modname() == 'builtins'` → no source → comment never found (F1 not
  fixed). `self.modname == 'target.classes'` → comment found. → V1's
  `self.modname` is **required**, not stylistic.
- This also matches the sibling `DataDocumenter.get_module_comment`, which uses
  `ModuleAnalyzer.for_module(self.modname)`.

## F7 — RISK (latent precondition, *not introduced* by V1): `objpath` non-empty

- `get_variable_comment` evaluates `self.objpath[-1]`; on an **empty** `objpath`
  that raises `IndexError`, which is **not** caught by `except PycodeError`.
- **Can it happen?** No, on the reachable path: `get_doc` runs only after
  `import_object` succeeded, and `ClassDocumenter.import_object` itself evaluates
  `self.objpath[-1]` (in `self.doc_as_attr = self.objpath[-1] != self.object.__name__`)
  for every `type` object — and a `ClassDocumenter`'s object is always a `type`
  (`can_document_member` = `isinstance(member, type)`), so it always has
  `__name__`. Therefore by the time `get_doc` runs, `objpath` is non-empty.
- **Severity RISK, not BUG:** this precondition is **pre-existing and shared** —
  `DataDocumenter.get_doc` does `self.get_module_comment(self.objpath[-1])`, and
  `import_object` itself indexes `objpath[-1]`. V1 does **not** widen the
  assumption. Recorded as side-condition **PO-G1**; no defensive guard added
  (would diverge from the established sibling pattern and the minimal-change
  goal). UltimatePowers question logged in ITERATION_GUIDANCE.

## F8 — OK (no cache corruption): the returned comment is a fresh copy

- **input:** any alias with a comment, with an `autodoc-process-docstring`
  extension that **mutates** the docstring lines in place (e.g. napoleon).
- **observed:** `get_variable_comment` returns `list(analyzer.attr_docs.get(...))`
  — a **shallow copy** — so the extension mutates the copy, never the analyzer's
  cached `attr_docs`. This matches the base `add_content` PATH-1, which likewise
  copies (`docstrings = [list(attr_docs[key])]`). → no cross-document cache
  poisoning.

## F9 — NOTE (scope/limitation, no worse than V0): re-exported aliases

- **input:** module `A` does `from B import SharedAlias` where `SharedAlias`'s
  comment lives in `B`; document `A.SharedAlias`.
- **observed:** `self.modname == 'A'`, but the comment is recorded under `B`'s
  analyzer, so `get_variable_comment('A')` → `[]` → no comment shown. Neither
  `self.modname` nor `get_real_modname()` can recover a re-exported comment.
- **expected vs observed:** identical to V0 (which also showed nothing). V1 does
  **not regress** this extreme edge; fixing it would require following the import
  to `B`, which is out of scope. Severity NOTE.

---

## Proof-derived findings from `/verify`

See `PROOF.md`. Constructing the proof produced **no blocked correctness VC** for
the in-domain contracts: every step is Axiom/Consequence over the fragment, the
arithmetic content is nil (no `/Int`, no products), and the only `[ESCALATION
BOUNDARY]` items are the **trusted base** PO-T1 (analyzer oracle) and PO-T2 (key
adequacy), which are *upstream and unchanged by this fix*. The proof obstacle
that would have signalled a bug — "the comment can render twice" — was
**discharged** by the `no_docstring` disjointness argument (F4 / NO-DOUBLE), not
papered over. Net: **the audit confirms V1; no code change is required.**
