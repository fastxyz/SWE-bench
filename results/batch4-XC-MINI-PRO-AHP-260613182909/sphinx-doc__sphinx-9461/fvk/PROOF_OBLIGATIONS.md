# PROOF_OBLIGATIONS.md — sphinx-9461

The verification conditions (VCs) that, together, establish the contracts in
SPEC.md. Each lists the claim it supports, the discharge tier (Z3 = pure
Boolean/linear reasoning over the descriptor model; LEMMA = a stated simplification
fact; FRAME = unchanged-cell framing), and the proof location. "Tier" follows the
FVK §6 split; here every VC is in the bundled (Boolean / case-analysis) tier — there
is **no** non-linear or `/Int` arithmetic in this fix, so no VC-EXACT-style lemma is
needed.

Status: **constructed, not machine-checked.**

---

## Core obligations (the fix is correct)

**PO-1 (surfacing, GCM).** For all `C:Map`, `n` with `n ∈ keys(C)`:
`isCMProp(C[n]) ⇒ memberVal(n) = func(C[n]) = prop(V)` where `C[n] = cmeth(prop(V))`,
and `¬isCMProp(C[n]) ⇒ memberVal(n) = getattr(C,n)` (unchanged).
- Discharge: case-split on `isCMProp(C[n])` (Z3 / Boolean). The `True` branch is the
  new statement `value = func(C[n])`; the `False` branch is a no-op. PROOF.md §2.

**PO-2 (kept-by-filter).** `isCMProp(C[n]) ⇒ hasDoc(memberVal(n)) = true`, hence
`filter_members` does **not** null the docstring and the member is retained.
- Discharge: from PO-1, `memberVal(n) = prop(V)`; `hasDoc(prop(_)) = true` by the
  model rule (a property exposes `fget.__doc__`, distinct from `property`'s type doc,
  so the `cls_doc == doc` guard is false). Contrast `hasDoc(computed) = false`, which
  is exactly the pre-fix drop. PROOF.md §2.

**PO-3 (dispatch, CDM + priority).** A surfaced member (`prop(V)`) makes
`PropertyDocumenter.can_document_member` return `True`, and `PropertyDocumenter`
(priority 11) is selected over `AttributeDocumenter` (10); `MethodDocumenter`
returns `False`.
- Discharge: `isproperty(prop(V)) = true`; `isroutine(property) = false`; priority is
  a numeric comparison (Z3). FRAME: parent is a `ClassDocumenter`. PROOF.md §3.

**PO-4 (import recovers the property, IMP).** After `super().import_object()` for a
classmethod-property, `getattr` gave `computed`, so `isproperty(self.object) = false`;
the `__dict__` lookup yields `cmeth(prop(V))`, `isCMProp = true`, and the code sets
`self.object = func(...) = prop(V)` and `self.isclassmethod = true`, returning `True`.
- Discharge: rule (3) of the model gives `computed`; `isproperty(computed) = false`;
  `__dict__[n] = cmeth(prop(V))`; `func(cmeth(prop(V))) = prop(V)`;
  `isproperty(prop(V)) = true` restores the post. PROOF.md §4.

**PO-5 (header, HDR).** Given `self.object = prop(V)` and `self.isclassmethod = b`:
`:classmethod:` is emitted iff `b`; `:abstractmethod:` iff `isabstractmethod(prop(V))`;
`:type:` iff `fget` present ∧ typehints ≠ none ∧ return annotation present; and the
emission order is abstractmethod, classmethod, type.
- Discharge: direct reading of the three guarded `add_line` calls in textual order
  (Z3 / Boolean). PROOF.md §4.

---

## Totality / well-definedness obligations

**PO-TOT (C-3a).** `self.isclassmethod` is defined at every state where
`add_directive_header` can execute.
- Discharge: V2 declares the class attribute `isclassmethod: bool = False`, so the
  attribute is defined on the type before any instance method runs; every path through
  `import_object` either leaves the default or assigns a `bool`. PROOF.md §5. (V1
  discharged this only via the external fact "generate() aborts on False" — see F-01.)

**PO-PREFIX (C-5, DIR-prefix totality).** `get_signature_prefix` is total and returns
the intended string on all four option subsets.
- Discharge: finite enumeration of `{abstractmethod?} × {classmethod?}` (4 cases),
  each a deterministic list build. PROOF.md §6. Confirms F-08's table.

---

## Non-regression obligations (V1 behavior preserved off the new path)

**PO-6 (plain property).** `¬isCMProp(C[n]) ∧ isproperty-as-stored` ⇒ `get_class_members`
records the same value as before, `can_document_member` has the same truth value as the
original single expression, and `import_object` skips the new block.
- Discharge: the surfacing guard and the `import_object` guard both test
  `isinstance(.,classmethod) ∧ isproperty(.__func__)`, false for a bare property; the
  `can_document_member` refactor is `isproperty(member) ∨ X`, equal to the original when
  `isproperty(member)` is true. Boolean. PROOF.md §7.

**PO-7 (cached_property).** Same as PO-6: a `cached_property` is not a `classmethod`, so
untouched; `isproperty(cached_property) = true` keeps dispatch identical.

**PO-8 (plain classmethod / staticmethod / function).** `func(C[n])` is a function not a
property, `isCMProp = false`; member untouched; `MethodDocumenter` still wins. Boolean.

**PO-9 (data / instance attribute).** Not a classmethod; `isCMProp = false`; untouched;
`AttributeDocumenter` still selected. Boolean.

---

## Out-of-domain obligations (explicitly NOT discharged — documented limitations)

**PO-INH [SCOPE BOUNDARY] (F-04/F-05).** For `n ∉ keys(C)` but reachable on `subject`
by inheritance (base-class or metaclass MRO) with `isCMProp` of the *defining* class's
entry, the fix does **not** surface the property. This is **outside the spec domain**
(own-`__dict__` members only) and is **not** claimed. It is recorded as a scope
boundary, not faked as discharged. Closing it needs an MRO walk (ITERATION_GUIDANCE).

**PO-MANGLE [SCOPE BOUNDARY] (F-02).** For a name-mangled classmethod-property,
`import_object`'s unmangled `__dict__` index misses; the member is dropped. Outside the
default documented set (private dunder member) and consistent with
`MethodDocumenter`; not claimed discharged.

---

## VC summary

| VC | Supports | Tier | Discharged? |
|----|----------|------|-------------|
| PO-1 | GCM | Z3 case-split | yes |
| PO-2 | keep-by-filter | LEMMA(hasDoc) | yes |
| PO-3 | CDM + priority | Z3 + FRAME | yes |
| PO-4 | IMP | model rule(3) + Z3 | yes |
| PO-5 | HDR | Z3/Boolean | yes |
| PO-TOT | C-3a | structural (class attr) | yes (V2) |
| PO-PREFIX | C-5 | finite enum | yes |
| PO-6..9 | non-regression | Boolean | yes |
| PO-INH | — | — | **scope boundary, not claimed** |
| PO-MANGLE | — | — | **scope boundary, not claimed** |

No non-linear, `/Int`, overflow, or inductive-predicate VC arises in this fix.
