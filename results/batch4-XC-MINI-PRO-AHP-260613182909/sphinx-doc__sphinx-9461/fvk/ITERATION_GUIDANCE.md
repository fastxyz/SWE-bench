# ITERATION_GUIDANCE.md — sphinx-9461

Feedback package for the next generate→formalize→verify pass. Each item: evidence →
classification → the question intent-elicitation should ask → recommended next change
→ tests. Recommendations are advisory; nothing here was auto-applied except the two
V2 edits already justified in FINDINGS (F-01, F-08).

---

## 1. Applied in V2 (this pass)

### G-1 ← F-01 (needed code guard)
- **Evidence:** `PropertyDocumenter.import_object`'s `else: return False` path left
  `self.isclassmethod` unset; `add_directive_header` reads it.
- **Change made:** declared `isclassmethod: bool = False` at class scope.
- **Tests:** no new test required; covered by any classmethod-property render test plus
  any plain-property test (both now exercise a defined attribute). Keep existing
  property tests.

### G-2 ← F-08 (underspecified intent → resolved)
- **Evidence:** combined `:abstractmethod:`+`:classmethod:` prefix was `class abstract
  property`, reversing the directive's own option-emission order and the demo's
  `*_abstract_class_property` naming.
- **Change made:** reordered to emit `abstract class property` (insert `class`, then
  `abstract`).
- **UltimatePowers question:** "For a member that is both abstract and a classmethod
  property, is the intended rendered prefix `abstract class property`?" (V2 assumes
  yes.)
- **Tests:** a `test_domain_py` case asserting `abstract class property ` for a property
  with both options would pin this; today only the single-option `abstract property `
  is asserted upstream.

---

## 2. Deferred (out of spec domain — would need a larger change)

### G-3 ← F-04 / F-05 (capability gap: inherited & metaclass classmethod-properties)
- **Evidence:** PO-INH `[SCOPE BOUNDARY]`. Own-`__dict__` surfacing only; a classmethod-
  property reachable on a subclass/instance-class via the (class or metaclass) MRO is
  dropped under `:inherited-members:`, unlike a plain inherited `@property`.
- **Classification:** capability gap, **not** a correctness bug for the reported issue
  (which documents each member under its defining class — fully handled).
- **UltimatePowers question:** "Should `:inherited-members:` also surface classmethod-
  properties inherited from base classes and/or metaclasses, to match plain inherited
  `@property` behavior?"
- **Recommended next change (if yes):** in `get_class_members`, when `name ∉ obj_dict`,
  walk `subject.__mro__` (and, for metaclass members, `type(subject).__mro__`) to find
  the defining class's raw entry and surface `func()` if it is a classmethod-property;
  mirror the lookup in `PropertyDocumenter.import_object` (search the MRO instead of only
  `self.parent.__dict__`). Keep it guarded so plain members are untouched.
- **Why deferred:** doubles the surface area, must disambiguate base-class vs metaclass
  MRO and re-tag `class_` for the inherited-members filter — beyond "minimal and
  targeted," and unneeded for the issue. Revisit only if intent says yes.
- **Tests:** **keep** any future inherited/metaclass tests as out-of-domain; they pin
  behavior the current contract does not cover.

### G-4 ← F-02 (name-mangled classmethod-property)
- **Evidence:** PO-MANGLE `[SCOPE BOUNDARY]`. `import_object` indexes `__dict__` with the
  unmangled `objpath[-1]`.
- **Classification:** pre-existing limitation, identical to `MethodDocumenter`.
- **Recommended next change (only if a use-case appears):** index with
  `mangle(self.parent, self.objpath[-1])` in both `can_document_member` and
  `import_object` — but do it for `MethodDocumenter` too, in one consistent commit,
  rather than diverging the two.
- **Why deferred:** private dunder members are excluded by default; F-01's class default
  already makes the path crash-safe (member is simply skipped, not an exception).

---

## 3. Test-redundancy report (benefit 1) — CONDITIONED ON MACHINE-CHECKING

Per the Honesty gate, these are **recommendations only**; do not remove tests until
`kprove` returns `#Top` (§8 of PROOF.md). The kit also never edits test files, and the
project's tests are fixed/hidden here — so this is purely advisory mapping.

**Would become subsumed (in-domain rendering points entailed by GCM+IMP+HDR+PO-PREFIX):**
- A test asserting a non-abstract classmethod-property renders
  `:classmethod:` (+ docstring, + `:type:`) → entailed by IMP+HDR.
- A test asserting `class property ` / `abstract class property ` prefixes → entailed by
  PO-PREFIX.
- A test asserting an abstract classmethod-property emits both `:abstractmethod:` and
  `:classmethod:` in that order → entailed by HDR.
- *Estimated CI saving:* a handful of `do_autodoc`/`restructuredtext.parse` round-trips
  (small; these are seconds each). The value is correctness assurance, not CI time.

**Must be KEPT (outside the verified domain or about wiring/termination):**
- Plain `@property`, `cached_property`, plain `@classmethod`, attribute tests — they pin
  the non-regression boundary (PO-6..9) and the dispatch priorities.
- Any inherited-members / metaclass test (G-3) and any name-mangled test (G-4) —
  out-of-domain (PO-INH, PO-MANGLE).
- Integration tests (autosummary stub generation, full `make html`) — the proof covers
  the unit, not the wiring.

---

## 4. Residual-risk reminders for the next pass

- The proof is **relative to** the CPython ≥3.9 descriptor fact (model rule 3). On
  Python < 3.9 a `classmethod(property(...))` is degenerate; the fix is harmless there
  (it would document a property) but the issue does not arise — no action.
- Everything is **constructed, not machine-checked**; run §8's `kompile`/`kprove` to
  upgrade and to unlock the test-redundancy removals above.
- No termination, overflow, `/Int`, or inductive-predicate obligation exists in this
  fix — no escalation to the μ-logic / sortedness tier is required (contrast
  `examples/12-insertion-sort`). The only open obligations are the two **scope
  boundaries**, which are intent decisions, not capability limits of the kit.
