# FINDINGS.md — sphinx-doc__sphinx-8548 (V1 audit)

Plain-language findings from formalizing the V1 fix. Format: `input → observed vs
expected`. Findings are **non-blocking advice**; the proof-derived ones are added
in the `/verify` section. Each is tagged with a disposition:
**[FIXED]**, **[INTENDED]**, **[OUT-OF-SCOPE]**, **[ADEQUACY]**, or **[WATCH]**.

---

## F1 — the target bug: inherited class attribute is dropped as "undocumented" [FIXED]

- **input:** `autoclass example.Inherited` with `:inherited-members:`, where
  ```python
  class Base:
      #: A base attribute.
      ham = True
  class Inherited(Base): ...
  ```
- **observed (V0 / pre-fix):** `ham` is **absent** from the rendered docs. The
  inherited method `Base.eggs` *does* appear.
- **expected:** `ham` documented with `:value: True` and body "A base attribute."
- **root cause:** the `#:` comment is stored by the analyzer under key
  `('Base','ham')`, but every lookup used the *current* class namespace
  (`('Inherited','ham')` in `filter_members`/`add_content`, and `namespace == ns`
  in `get_class_members`). So `ham` had `has_doc = False` and `filter_members`
  removed it.
- **V1 status:** **resolved.** `get_class_members` now MRO-walks and attaches
  `Base`'s comment to `ham` (⇒ `has_doc = True`, kept); `AttributeDocumenter.get_doc`
  MRO-walks via `get_attribute_comment` and emits it. Traced in PROOF.md as the
  `(GAC)` + `(GCM)` composition. This is benefit-2's primary hit: a concrete input
  the names/docstrings promised but the code did not deliver.

## F2 — inherited *instance* attribute still filtered under `:members:` + `:inherited-members:` [OUT-OF-SCOPE]

- **input:** `autoclass example.Derived` with **both** `:members:` and
  `:inherited-members:`, where
  ```python
  class Base:
      def __init__(self):
          self.x = 1   #: an inherited instance attribute
  class Derived(Base): ...
  ```
- **observed (V1):** `x` is discovered by `get_class_members` (good) **but
  `filter_members` still drops it.** In the `members is ALL` branch it calls
  `is_filtered_inherited_member('x')`, which walks `Derived`'s MRO; because `x` is
  *not* in any class `__dict__` nor in `__annotations__`, the walk reaches `object`
  and returns `True` ⇒ `keep = False`.
- **expected (ideal):** `x` documented with its comment.
- **classification:** **pre-existing limitation, not a V1 regression.** V0 never put
  `x` in `members` at all, so V0 also omitted it; V1 leaves the end result
  unchanged for this exact directive combination. This is the separately-tracked
  issue **#6415** ("inherited *instance* attributes"), explicitly called out as
  distinct in `PROBLEM.md`.
- **note:** with `:inherited-members:` **alone** (the directive in the issue's own
  reproduction), `members is ALL` is **false** (`options.members == []`), so
  `is_filtered_inherited_member` is *not* consulted, the `has_doc` branch keeps
  `x`, and V1 *does* document it. So V1 strictly *improves* the instance-attribute
  case; only the `:members:`+`:inherited-members:` combination remains limited.
- **decision:** do **not** modify `is_filtered_inherited_member` — see
  ITERATION_GUIDANCE.md (scope + regression risk). Documented, not hidden.

## F3 — overridden-without-comment attribute inherits the base comment [INTENDED]

- **input:**
  ```python
  class Base:
      #: base doc
      attr = 1
  class Derived(Base):
      attr = 2          # overridden, NO new comment
  ```
  `autoclass Derived :inherited-members:` (or `autoattribute Derived.attr`).
- **observed (V1):** `Derived.attr` (value `2`) is documented with **"base doc"**.
- **expected:** judgement call. V1's behavior is **consistent** with (a) how
  *methods* already inherit docstrings, and (b) `get_attribute_comment`, which
  already did exactly this for annotation-only inherited attributes in V0. Whether
  it shows depends on `get_attribute_comment`, *independently* of the
  `get_class_members` change, so V1 is internally consistent: discovery and
  rendering agree.
- **decision:** accept as intended. Flagged so a future maintainer who wants
  "override silently drops the inherited doc" semantics knows where to change it
  (a single MRO-stop rule in `get_attribute_comment`).

## F4 — corner case: builtin / source-less classes in the MRO [FIXED / covered]

- **input:** any class whose MRO contains `object` (always) or a C-extension base.
- **observed (V1):** `ModuleAnalyzer.for_module('builtins')` raises `PycodeError`
  (and `for_module` caches+re-raises it); the `try/except (AttributeError,
  PycodeError): continue` skips that class. No crash, no spurious members.
- **expected:** exactly that. Verified against `pycode/__init__.py:111-128`
  (`for_module` raises/caches `PycodeError`) and `:161-184` (`analyze` raises
  `PycodeError`). This is the `noSource(...)` rule in the mini-K and obligation
  **GCM-VC-skip** in PROOF_OBLIGATIONS.md.

## F5 — get_doc now feeds `_find_signature`; comments are inert there [WATCH]

- **input:** any attribute with a `#:` comment, when
  `autodoc_docstring_signature` is on (default). `DocstringStripSignatureMixin.
  format_signature` → `_find_signature` → `get_doc()` now returns the comment.
- **observed (V1):** for ordinary prose comments ("A base attribute.") the
  signature regex does not match ⇒ no signature/return-annotation is extracted ⇒
  output unchanged. `_find_signature`'s mutation of `_new_docstrings` is **not**
  consulted by `AttributeDocumenter.get_doc` (which returns the comment up front,
  and otherwise short-circuits at `NonDataDescriptorMixin.get_doc`), so the body
  text is unaffected regardless.
- **expected vs risk:** a *contrived* comment whose first line parses as
  `name(args) -> ret` could set a spurious return annotation on the attribute.
  Extremely unlikely for `#:` comments; **no realistic regression.**
- **decision:** accept; recorded as a WATCH item, no code change.

## F6 — spec-difficulty smell: two-phase discovery ("complete if `None`") [WATCH]

- The merge loop must both *add* absent instance attributes **and** *complete* the
  `None` docstring of already-`dir()`-discovered class attributes
  (`elif members[name].docstring is None`). A single clean "insert" was not
  expressible because `dir()` populates class attributes earlier with `doc=None`.
- Per FVK "spec-difficulty = bug signal," we checked whether this awkwardness hides
  a bug: it does **not**. The `is None` guard is exactly what makes the MRO fold
  *most-derived-wins* and idempotent (obligation **GCM-VC-idem**). Recorded as a
  structural note, not a defect.

## F7 — precondition surfaced: `self.parent` / `self.objpath` for get_doc [INTENDED]

- `AttributeDocumenter.get_doc` assumes `self.parent` is the owning class (or
  `None`) and `self.objpath` is non-empty (`get_attribute_comment` uses
  `self.objpath[-1]`). Verified: `import_object` always runs before `get_doc` in
  `generate()` and sets `self.parent`; `objpath` is non-empty for any class-level
  documenter. The `None`/non-class `parent` case is total (empty MRO ⇒ `None`).
  This is precondition **GAC-PRE** in PROOF_OBLIGATIONS.md.

---

## Proof-derived findings from `/verify`

## PF1 — `(GD-EQ)` discharges the no-regression worry [evidence: PROOF.md §4]

- **evidence:** obligation **GD-EQ** — on the `C = NONE` branch, V1's `get_doc`
  reduces *syntactically* to V0's body (the added prefix is `if NONE: …` which is
  dead). Classification: **not a bug**; this is the formal statement of "V1 ⊇ V0,
  differing only when a comment exists."
- **UltimatePowers question:** none.
- **next change:** none.
- **tests:** the V0 attribute tests (no-comment attributes, descriptors, slots,
  typevars, enums) are **preserved** by GD-EQ and should be **kept** — they pin the
  exactly-unchanged branch.

## PF2 — `(GCM)` soundness side conditions are *positive* findings [evidence: PROOF_OBLIGATIONS.md GCM-VC-idem, GCM-VC-skip]

- **evidence:** the fold is well-defined only because (i) the inner update is
  idempotent under the `is None` guard (most-derived-wins) and (ii) source-less
  classes contribute nothing. Both discharge; neither forced an *invented*
  precondition on user input ⇒ no hidden missing-precondition bug in V1.
- **classification:** proof-capability-clean; the only escalation is the analyzer
  abstraction (F-A below), which is an *adequacy* boundary, not a code bug.

## F-A — adequacy boundary: the analyzer is modelled as an oracle [ESCALATION BOUNDARY]

- The mini-K abstracts `ModuleAnalyzer.for_module(...).attr_docs` into the partial
  map `AD` and the `try/except continue` into `noSource`. The faithfulness of that
  abstraction (that `AD[(m,q,a)]` is defined **iff** module `m`'s real source has a
  comment for `(q,a)`, and that a `PycodeError` ⇔ `noSource`) is **assumed**, not
  derived from a Python-in-K semantics. Stated explicitly, **not** admitted as
  `[trusted]` silently. Routed to the roadmap "full per-language semantics."
