# FINDINGS.md — sphinx-9461 fix audit

Plain-language findings, each as `input → observed vs expected`, classified, with a
recommendation. Findings are independent of machine-checking. "V1" = the fix as left
after the first task; "V2" = after the two refinements in this audit (see
`reports/fvk_notes.md`).

Legend for **Status**: `fixed-in-V2` / `confirmed-correct` (V1 already right) /
`documented-limitation` (out of spec domain, kept by design).

---

## A. Findings that drove a V2 code change

### F-01 — `isclassmethod` could be read before assignment on one return path
- **Where:** `PropertyDocumenter.import_object` (the `else: return False` branch) and
  `add_directive_header` (`if self.isclassmethod:`).
- **Input → observed vs expected:** a name-mangled classmethod-property (F-02), or any
  future caller that reaches `add_directive_header` without `import_object` having set
  the attribute → *observed (V1):* `self.isclassmethod` is an undefined instance
  attribute on the `else: return False` path; reading it would raise `AttributeError`.
  *Expected:* the attribute is always defined.
- **Why it did not crash in V1:** `generate()` aborts when `import_object()` returns
  `False`, so `add_directive_header` is not reached on that path. The bug is *latent*,
  not live — but the contract (C-3a / TOT in SPEC) is "isclassmethod is total", and V1
  satisfied it only by an external control-flow accident.
- **Classification:** needed code guard (robustness / latent undefined attribute).
- **Status:** **fixed-in-V2** — declared class-level default `isclassmethod: bool =
  False`, making (TOT) hold structurally rather than by accident.

### F-08 — combined signature prefix ordering contradicted intent and PyMethod
- **Where:** `PyProperty.get_signature_prefix`.
- **Input → observed vs expected:** a property with **both** `:abstractmethod:` and
  `:classmethod:` → *observed (V1):* prefix `"class abstract property "` (classmethod
  inserted at position 0 last). *Expected (intent):* `"abstract class property "` —
  (i) the demo's member names literally read `*_abstract_class_property`; (ii)
  `PyMethod` renders "abstract classmethod" (abstract first); (iii) autodoc emits
  `:abstractmethod:` *then* `:classmethod:`, so V1's prefix order was the reverse of its
  own option-emission order.
- **Classification:** underspecified intent resolved by three converging signals;
  internal-consistency defect.
- **Status:** **fixed-in-V2** — insert `class` first, then `abstract`, yielding
  `abstract class property`. Single-option cases unchanged (`abstract property`,
  `class property`); existing `test_pyproperty` (`abstract property`) still satisfied.

---

## B. Findings confirmed correct in V1 (no change needed, justify standing)

### F-03 — root cause is correctly neutralised (the central positive finding)
- **Input → observed vs expected:** `BaseClass.baseclass_class_property` (a
  `@classmethod @property` with a docstring) → *observed before any fix:* not
  documented at all — `getattr(cls, name)` returns the getter's computed value
  (e.g. a `str`), whose `__doc__` equals `str.__doc__`, so `filter_members` nulls the
  doc (`has_doc == False`) and drops it before any documenter is chosen. *Observed with
  fix:* documented as a property with its real docstring, `:classmethod:`, and `:type:`.
- **Classification:** the original bug; fix verified against contracts (GCM)+(IMP)+(HDR).
- **Status:** **confirmed-correct.** Proof: PROOF.md §2–§4.

### F-06 — no regression for plain properties, cached_property, classmethods, attrs
- **Input → observed vs expected:** an ordinary `@property`, a `functools.cached_property`,
  a plain `@classmethod`, a data/instance attribute → *expected & observed:* byte-for-byte
  identical documentation to before the fix.
  - `get_class_members`: the surfacing guard `isinstance(raw, classmethod) and
    isproperty(raw.__func__)` is **false** for all of these (a plain classmethod has a
    function `__func__`, not a property; the others are not classmethods), so `value` is
    untouched.
  - `can_document_member`: a plain property hits `isproperty(member) → True` (same as the
    original single-expression form); everything else falls to the `__dict__` check, which
    is `False` for non-classmethod-properties — identical truth value to the original.
  - `import_object`: a normal property satisfies `isproperty(self.object)` after `super()`,
    so the new block is skipped entirely; `isclassmethod` is set `False`.
- **Classification:** regression analysis.
- **Status:** **confirmed-correct.** Proof obligations PO-6..PO-9.

### F-07 — selection priority resolves to PropertyDocumenter
- **Input → observed vs expected:** surfaced member is now a `property` object →
  `PropertyDocumenter` (priority `AttributeDocumenter.priority + 1 = 11`) outranks
  `AttributeDocumenter` (10), and `MethodDocumenter.can_document_member` is `False`
  (`isroutine(property)` is `False`). Expected: property documenter chosen. Observed: yes.
- **Classification:** dispatch correctness.
- **Status:** **confirmed-correct.** PROOF.md §3.

### F-09 — `:type:` extraction is correct for a classmethod-property
- **Input → observed vs expected:** `def f(cls) -> str: ...` under `@classmethod
  @property` → after `import_object`, `self.object` is the `property`; `self.object.fget`
  is the underlying function whose `signature().return_annotation` is `str`; so
  `:type: str` is emitted. Expected and observed match; the `cls` parameter is irrelevant
  (properties never render an arg list).
- **Classification:** feature completeness.
- **Status:** **confirmed-correct.**

### F-10 — undocumented classmethod-property behaves like an undocumented property
- **Input → observed vs expected:** a `@classmethod @property` with **no** docstring →
  surfaced as `prop(V)` with `__doc__ == None`; `filter_members` keeps it only under
  `:undoc-members:`, exactly as for a plain undocumented property. Expected: consistent
  with plain properties. Observed: consistent.
- **Classification:** corner case (empty docstring) — no special-casing needed.
- **Status:** **confirmed-correct.**

---

## C. Documented limitations (out of the spec's domain — kept by design)

### F-04 — inherited classmethod-properties are not surfaced
- **Input → observed vs expected:** `class Sub(Base)` where `Base` defines
  `baseclass_class_property` as `@classmethod @property`; document `Sub` **with
  `:inherited-members:`** → *observed:* `baseclass_class_property` is **not** documented
  on `Sub` (it is in `Base.__dict__`, not `Sub.__dict__`, so the own-`__dict__` surfacing
  guard does not fire; `getattr(Sub, name)` returns the computed value and
  `filter_members` drops it). *Expected within the reported issue:* documented under its
  defining class `Base` — which **does** happen. Documenting it again on `Sub` is only
  relevant under the opt-in `:inherited-members:`.
- **Asymmetry noted:** a *plain* inherited `@property` *does* work under
  `:inherited-members:` because `getattr(Sub, name)` returns the property descriptor
  itself; the classmethod wrapper is what breaks the symmetry.
- **Classification:** out-of-domain (spec domain = own-`__dict__` members); known
  capability gap, not a correctness bug for the reported issue.
- **Status:** **documented-limitation.** Fixing it requires MRO-walking in both
  `get_class_members` and `import_object` (and disambiguating base-class vs metaclass
  MRO); deferred as a larger, non-minimal change. See ITERATION_GUIDANCE.md.

### F-05 — metaclass-defined classmethod-property on an instance class
- **Input → observed vs expected:** `class A(metaclass=Meta)` where `Meta` has a
  `@classmethod @property`; document `A` → the member appears in `dir(A)` but is in
  `Meta.__dict__`, not `A.__dict__`; not surfaced on `A`. *Expected per issue:*
  documented on `Meta` itself (the demo's `MetaClass`), which works because there it is
  an own-`__dict__` member. Observed: matches.
- **Classification:** same root as F-04 (inheritance via the metaclass MRO).
- **Status:** **documented-limitation.**

### F-02 — name-mangled (`__name`) classmethod-property
- **Input → observed vs expected:** a private `@classmethod @property` named `__p` inside
  `class Foo` (stored as `_Foo__p` in `__dict__`) → `can_document_member` may approve it
  (surfaced as a property by `get_class_members`, which uses the mangled `dir()` name to
  index `__dict__`), but `import_object` looks up `self.parent.__dict__[self.objpath[-1]]`
  with the **unmangled** `__p` → `KeyError`→`None` → returns `False` → member dropped.
- **Severity:** negligible. Such a member is private and dunder-prefixed, hence excluded
  by default (`:private-members:` off). Crucially, **`MethodDocumenter.import_object` has
  the identical limitation** (it indexes `self.parent.__dict__.get(self.object_name)` with
  the unmangled name), so V1/V2 are *consistent* with the existing codebase, not newly
  broken.
- **Classification:** pre-existing limitation, consistent with `MethodDocumenter`.
- **Status:** **documented-limitation** (declined: matching `MethodDocumenter` is the
  minimal, consistent choice; F-01's class default makes even this path crash-safe).

---

## D. Spec-difficulty signals (the "hard to spec = smell" check)

Writing the spec was **not** hard, which is itself evidence the fix is well-scoped:
the one loop has a trivial, counter-free invariant (no `/Int`/overflow VCs), every
function contract is a clean total function of the class `__dict__`, and the only
genuine ambiguities were *intent* choices (F-08 prefix wording, F-04/F-05 inheritance
scope), each resolvable from explicit signals (member names, `PyMethod`, the issue's
"each under its defining class"). No awkward case-splits or missing-precondition
surprises emerged in the surfacing logic. The clean spec corroborates that V1's
approach is sound and that the residual items are scope decisions, not defects.
