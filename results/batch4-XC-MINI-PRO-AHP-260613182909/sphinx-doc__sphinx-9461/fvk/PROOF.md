# PROOF.md — constructed correctness proof for the sphinx-9461 fix

**Constructed, not machine-checked.** Symbolic execution is carried out against the
mini-Python descriptor semantics in SPEC.md §1; the K commands that would machine-
check it are in §8. No execution environment is used (per task constraints).

The end-to-end theorem is operational: *a `@classmethod @property` defined in a
class's own `__dict__`, with a docstring, is documented as a property carrying its
docstring, a `:classmethod:` marker, and (when annotated) a `:type:`* — and nothing
else changes. We prove it as the composition GCM → keep → dispatch → IMP → HDR.

---

## 1. Setup

Let `C = subject.__dict__`, and fix a member name `n` with
`C[n] = cmeth(prop(V))` (a classmethod-wrapped property whose getter yields value
`V` and carries docstring `doc(V) ≠ None`). Logical variables uppercase.

The four model rules of SPEC §1 are the only descriptor axioms used:
- (1) `getattr(C,n) ⇒ plain-value` when `C[n]=plain(_)`;
- (2) `getattr(C,n) ⇒ prop(V)` when `C[n]=prop(V)`;            ← plain property
- (3) `getattr(C,n) ⇒ computed` when `C[n]=cmeth(prop(_))`;    ← **the bug**
- (4) `getattr(C,n) ⇒ computed` when `C[n]=cmeth(plain(_))`.

---

## 2. GCM and keep-by-filter (PO-1, PO-2)

Symbolic execution of the `get_class_members` body on `n`:

```
value = getattr(C, n)
   ──(Axiom rule 3)──▶  value = computed
raw = lookup(C, n)
   ──(Axiom)──▶        raw = cmeth(prop(V))
if isCMProp(raw):      isCMProp(cmeth(prop(V))) = true        (Case Analysis, true-branch)
   value = func(raw)
   ──(Axiom func)──▶   value = prop(V)
members[unmangle(n)] = ObjectMember(unmangle(n), value, class_=subject)
   ──▶                 members[n].object = prop(V),  members[n].class_ = subject
```

So `memberVal(n) = prop(V)` — **PO-1**. The `False`-branch (any non-`isCMProp`
member) skips `value = func(raw)`, leaving `value = getattr(C,n)` unchanged: the
other half of PO-1.

`hasDoc(prop(V)) = true` (the property exposes `fget.__doc__ = doc(V) ≠ None`, and
`doc(V) ≠ property.__doc__`, so `filter_members`' `cls_doc == doc` guard is false).
Therefore `has_doc = True` and the member is **kept** — **PO-2**. Contrast the pre-fix
world: rule (3) left `value = computed`, `hasDoc(computed) = false`, member dropped —
this is exactly Finding F-03.

### Loop circularity (the one loop)

The body above is the loop body of `for name in dir(subject)`. INV(k) from SPEC §3
holds at entry (k=0, vacuous). The genuine `=>⁺` step is the loop's iteration step
(advancing the `dir` cursor); the body then either takes the `isCMProp` branch (shown
above) or the no-op branch, both re-establishing INV for the new prefix, and the
coinductive hypothesis (the loop claim itself) closes the tail. There is **no counter
arithmetic** — the accumulator is a `Map` keyed by name and the only side condition is
`0 ≤ k ≤ len(dir(subject))`, discharged by Z3 trivially. Exit (`k = len`) yields GCM
for every name. (This is the FVK loop pattern with a degenerate, VC-free invariant.)

---

## 3. Dispatch (PO-3)

With `member = prop(V)`:
- `PropertyDocumenter.can_document_member`: `parent isa ClassDocumenter` (framed
  true), `isproperty(prop(V)) = true` ⇒ returns **True** by the first disjunct.
- `MethodDocumenter.can_document_member`: `isroutine(property) = false` ⇒ **False**.
- `AttributeDocumenter.can_document_member`: **True** but priority `10`.
- Selection sorts by priority; `PropertyDocumenter.priority = 11 > 10` ⇒ chosen.

`A ⊢ φ ⇒ PropertyDocumenter`. **PO-3.**

---

## 4. import_object and add_directive_header (PO-4, PO-5)

`import_object`:
```
ret = super().import_object()            ▶ ret = True; getattr(C,n) ⇒ computed (rule 3)
                                           ⇒ self.object = computed, self.parent = subject
not isproperty(self.object)              ▶ not isproperty(computed) = true   (enter block)
obj = self.parent.__dict__[objpath[-1]]  ▶ obj = C[n] = cmeth(prop(V))
isinstance(obj,classmethod) ∧ isproperty(obj.__func__)
                                         ▶ true ∧ isproperty(prop(V)) = true
self.object = obj.__func__               ▶ self.object = prop(V)
self.isclassmethod = True ; return True
```
Post-state: `isproperty(self.object) = true ∧ self.isclassmethod = true ∧ ret = True`
— **PO-4** (the IMP contract). (For a plain property, rule (2) makes
`isproperty(self.object)` true immediately, the block is skipped, `isclassmethod =
False` — the PO-6 branch.)

`add_directive_header` then executes its guarded `add_line`s in textual order:
1. `isabstractmethod(prop(V))` → `:abstractmethod:` iff the getter is abstract;
2. `self.isclassmethod (= True)` → `:classmethod:` emitted;
3. `fget` present ∧ typehints≠none ∧ return-annotation present → `:type: T`.
Order abstractmethod ≺ classmethod ≺ type. **PO-5.** `get_doc` reads
`getdoc(self.object=prop(V)) = doc(V)`, so the body shows the real docstring.

Composing §2–§4 by Transitivity gives the end-to-end theorem for own-`__dict__`
classmethod-properties. ∎ (partial correctness; see §9)

---

## 5. Totality of `isclassmethod` (PO-TOT)

V2 adds `class PropertyDocumenter: isclassmethod: bool = False`. Hence the attribute
is resolved on the **class** for any instance, independent of which `import_object`
return path ran. The two assigning paths set a `bool`; the `else: return False` path
and the `not ret` path leave the class default `False`. So at every state reachable by
`add_directive_header` (only after `import_object` returned `True`), `self.isclassmethod
∈ {True, False}` is defined. **PO-TOT.** This upgrades V1's accidental safety (relying
on `generate()` aborting on a `False` return) to a structural guarantee — Finding F-01.

---

## 6. Prefix totality (PO-PREFIX) — finite enumeration

`get_signature_prefix` (V2) builds `['property']`, inserts `'class'` at 0 if
`classmethod`, then `'abstract'` at 0 if `abstractmethod`:

| abstractmethod | classmethod | list | string |
|---|---|---|---|
| – | – | `[property]` | `property ` |
| – | ✓ | `[class, property]` | `class property ` |
| ✓ | – | `[abstract, property]` | `abstract property ` |
| ✓ | ✓ | `[abstract, class, property]` | `abstract class property ` |

Total, deterministic, matches SPEC (DIR-prefix). The single-option rows reproduce the
pre-existing `abstract property` / new `class property`; the combined row is
`abstract class property`, abstract-first — consistent with `PyMethod` and with the
`:abstractmethod:`≺`:classmethod:` emission order of §4. **PO-PREFIX**, Finding F-08.

---

## 7. Non-regression (PO-6..PO-9)

For any member with `¬isCMProp(C[n])`:
- `get_class_members`: surfacing guard false ⇒ `value` untouched (PO-6/7/8/9 share
  this step).
- `can_document_member`: refactor is `isproperty(member) ∨ (classmethod-property via
  __dict__)`. When `isproperty(member)` (plain/cached property) the result is `True`
  via the first disjunct — identical to the original `isproperty(member) ∧ isinstance(
  parent, ClassDocumenter)`. When `member` is a method/attribute, both disjuncts are
  false ⇒ `False`, identical to original.
- `import_object`: for a plain/cached property, `isproperty(self.object)` after
  `super()` is true ⇒ new block skipped ⇒ `self.object` unchanged, `isclassmethod =
  False`. For non-properties, `can_document_member` already excluded them.

No observable output differs for non-classmethod-property members. **PO-6..PO-9.** ∎

---

## 8. Reproduce the machine check (commands — not run here)

The mini fragment + claims would be checked with:

```sh
# (artifacts: fvk/mini-python-descriptors.k  +  fvk/mini-python-descriptors-spec.k,
#  whose bodies are the fenced K in SPEC.md §1-§3)
kompile mini-python-descriptors.k --backend haskell      # compile the fragment
kast    --backend haskell mini-python-descriptors-spec.k # (optional) parse-check claims
kprove  mini-python-descriptors-spec.k                   # expected: #Top (all proved)
```

Expected `kprove` result: `#Top` for GCM, CDM, IMP, HDR, and the loop circularity —
all VCs are Boolean/case-analysis with no `/Int` or inductive obligation, so no
custom `[simplification]` lemma beyond the `hasDoc`/`isCMProp` `[function]` rules is
needed. **Label: constructed, not machine-checked.**

---

## 9. Residual risk

- **Partial vs total correctness.** The loop is over the finite `dir(subject)`, so it
  terminates; the proof is effectively total for the surfacing loop. The *overall*
  documentation pipeline (filter, dispatch, render) is straight-line. No unbounded
  recursion is introduced.
- **Trusted base.** (a) Adequacy of the mini-Python *descriptor* model — in
  particular model rule (3), the CPython ≥3.9 fact that
  `classmethod(property(f)).__get__(None, C)` calls the getter and returns its value.
  This is the documented behavior the issue itself cites; the fix's correctness is
  *relative to* it. (b) The reachability metatheory / `kprove` (not run). (c) The
  `hasDoc`/`isCMProp` abstraction faithfully mirroring `filter_members`' docstring
  guard and `inspect.isproperty`.
- **Scope boundaries (NOT discharged):** inherited / metaclass classmethod-properties
  (PO-INH, F-04/F-05) and name-mangled ones (PO-MANGLE, F-02). These are stated, not
  hidden, and lie outside the spec domain.
- **Constructed, not machine-checked** — §8 upgrades it to machine-verified.

---

## 10. The two FVK payoffs (plain language)

- **Hidden-bug surfacing (benefit 2).** Specifying `isclassmethod` as a *total* field
  exposed F-01 (a latent undefined-attribute path, live only one mangled-name corner
  away); writing the prefix as a total function over the 2×2 option grid exposed F-08
  (the combined prefix contradicted intent and the directive's own emission order).
  Both are now fixed. The spec was otherwise easy to write, corroborating that V1's
  core approach is sound (FINDINGS §D).
- **Test-redundancy (benefit 1).** Once `kprove` returns `#Top`, the in-domain
  rendering assertions become subsumed by GCM+IMP+HDR; out-of-domain tests (inherited,
  mangled) must be **kept**. Full mapping in ITERATION_GUIDANCE.md — conditioned on the
  machine check (Honesty gate).
