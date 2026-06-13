# FVK audit notes — sphinx-9461 (V1 → V2)

This explains every decision taken during the Formal Verification Kit pass: the two
code edits I made, and every part of V1 I deliberately left unchanged. Each decision
is traced to specific entries in `fvk/FINDINGS.md` and `fvk/PROOF_OBLIGATIONS.md`.

The FVK MVP **constructs** specs and proofs but does not run `kompile`/`kprove`
(and this session has no execution environment), so all artifacts are labeled
*constructed, not machine-checked*. The Findings, however, do not depend on the
machine check and are reported with full confidence.

---

## What the audit produced

- `fvk/SPEC.md` — a mini-Python *descriptor* semantics (the smallest fragment in
  which the bug is expressible: model rule (3), `getattr(C,n) ⇒ computed` for a
  `classmethod`-wrapped `property`), plus reachability contracts for the four changed
  functions and the one loop's circularity.
- `fvk/FINDINGS.md` — 10 findings (F-01..F-10), classified.
- `fvk/PROOF_OBLIGATIONS.md` — VCs PO-1..PO-9 plus PO-TOT/PO-PREFIX and two explicit
  `[SCOPE BOUNDARY]` non-obligations (PO-INH, PO-MANGLE).
- `fvk/PROOF.md` — constructed proof discharging them, with the (degenerate, VC-free)
  loop circularity and the `kprove` commands.
- `fvk/ITERATION_GUIDANCE.md` — applied vs deferred items, test-redundancy mapping.

Writing the spec was easy (FINDINGS §D): the loop invariant is counter-free (no
`/Int`/overflow VC) and every contract is a clean total function of the class
`__dict__`. That "clean spec writes itself" outcome is itself evidence V1's core
approach is sound — so the audit **confirms** V1's structure and changes only two
narrow things.

---

## Code change 1 — class-level `isclassmethod: bool = False`

**File:** `repo/sphinx/ext/autodoc/__init__.py`, `PropertyDocumenter`.

**Driven by:** `F-01` (latent undefined-attribute) and obligation **PO-TOT** (C-3a:
`self.isclassmethod` must be defined wherever `add_directive_header` can run).

**Reasoning.** `import_object` reads/writes `self.isclassmethod` as cross-method state
consumed by `add_directive_header`. V1 set it on its two normal paths but **not** on
`else: return False`. In V1 that path is reachable exactly for a name-mangled
classmethod-property (F-02): `can_document_member` approves it (the property was
surfaced by `get_class_members`), but `import_object`'s unmangled `__dict__` index
misses and returns `False`. V1 avoided a crash only because `generate()` aborts on a
`False` return, so `add_directive_header` is not reached — i.e. safety by external
control-flow accident, not by construction. Declaring the class attribute makes the
attribute total (PROOF.md §5 discharges PO-TOT structurally) and crash-safe even if
that path were ever reached directly. Minimal (one line), no behavior change on any
documented member.

## Code change 2 — prefix order `abstract class property` (not `class abstract property`)

**File:** `repo/sphinx/domains/python.py`, `PyProperty.get_signature_prefix`.

**Driven by:** `F-08` (combined-prefix ordering contradicted intent) and obligation
**PO-PREFIX** (totality + intended string over the 2×2 option grid).

**Reasoning.** V1 inserted `class` after `abstract`, yielding `class abstract
property` for a property that is both abstract and a classmethod. Three converging
signals say the intended order is **abstract first**: (i) the reporter's demo names
the members `metaclass_abstract_class_property`, `baseclass_abstract_class_property`,
`subclass_abstract_class_property` — literally "abstract class property"; (ii) the
analogous `PyMethod` renders "abstract classmethod" (abstract before classmethod);
(iii) autodoc's own `add_directive_header` emits `:abstractmethod:` *before*
`:classmethod:`, so V1's prefix reversed its own option order. I reordered to insert
`class` then `abstract`. The single-option outputs are unchanged — `abstract
property` (so the existing `test_pyproperty` assertion still holds) and `class
property` — verified by the finite enumeration in PROOF.md §6 (PO-PREFIX). This is an
*intent* correction (FVK formalizes intent, not minimal-diff), the one place the V1
write-up had explicitly flagged as a judgment call.

---

## What I deliberately kept from V1 (confirmed correct)

Each item below was checked against a contract and an obligation and left unchanged.

- **`get_class_members` surfacing the property** (importer.py). Confirmed by `F-03`
  (root cause neutralised) via **PO-1** (GCM) and **PO-2** (member kept by
  `filter_members` because `hasDoc(prop) = true`). This is the load-bearing change —
  without it the member is dropped before any documenter runs — and the proof shows it
  is exactly right. *Kept.*

- **`PropertyDocumenter.can_document_member` two-branch form.** Confirmed by `F-06`
  (non-regression) via **PO-3/PO-6**: equivalent to the original when
  `isproperty(member)`, and the new `__dict__` disjunct only ever adds classmethod-
  properties. *Kept.*

- **`import_object` recovering `obj.__func__`.** Confirmed by `F-03`/`F-09` via
  **PO-4** (IMP): `self.object` is always a real `property` on success, so docstring
  and `:type:` extraction are unchanged and correct. *Kept.*

- **`add_directive_header` emitting `:classmethod:`** (after `:abstractmethod:`,
  before `:type:`). Confirmed by **PO-5** (HDR); order is consistent with the existing
  staticmethod example and with change 2. *Kept.*

- **`PyProperty` accepting the `:classmethod:` flag**, and the doc/CHANGES updates.
  Confirmed by **PO-PREFIX** and dispatch finding `F-07`. *Kept.*

- **Dispatch priority** (PropertyDocumenter 11 > AttributeDocumenter 10; Method =
  False). Confirmed by `F-07` via **PO-3**. *Kept.*

- **Empty-docstring behavior.** `F-10`: an undocumented classmethod-property behaves
  like an undocumented plain property (needs `:undoc-members:`) — consistent, no
  special-casing. *Kept.*

---

## What I deliberately did NOT fix (scope boundaries, justified)

- **Inherited / metaclass classmethod-properties** — `F-04`, `F-05`; obligation
  **PO-INH `[SCOPE BOUNDARY]`**. Out of the spec's domain (own-`__dict__` members),
  which is exactly what the issue requires (each member documented under its defining
  class — all six demo members are own-class). Closing it needs MRO-walking in two
  places plus base-vs-metaclass disambiguation (ITERATION_GUIDANCE G-3) — non-minimal
  and unneeded for the issue. Stated as an open obligation, **not** faked as
  discharged.

- **Name-mangled classmethod-properties** — `F-02`; obligation **PO-MANGLE `[SCOPE
  BOUNDARY]`**. Private dunder members are excluded by default, and the same limitation
  exists verbatim in `MethodDocumenter`; matching it is the minimal, consistent choice.
  Change 1 makes even this path crash-safe (the member is skipped, never an exception).
  Deferred to a future consistent commit touching both documenters (G-4).

---

## Net result

V1's approach is **confirmed correct** for the reported issue's domain; the audit
made two narrow, intent-driven refinements (a totality guard, F-01/PO-TOT; a prefix
ordering, F-08/PO-PREFIX) and explicitly bounded two out-of-domain limitations rather
than silently leaving them ambiguous. No test files were touched; all proof artifacts
are *constructed, not machine-checked*, with the `kprove` commands emitted for later
confirmation.
