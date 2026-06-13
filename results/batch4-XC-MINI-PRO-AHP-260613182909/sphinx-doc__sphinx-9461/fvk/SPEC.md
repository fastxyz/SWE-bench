# SPEC.md — formal specification of the sphinx-9461 fix

**Status: constructed, not machine-checked.** Per the FVK MVP and the no-exec
constraint, the K fragment and claims below are written and reasoned about, not run
through `kompile`/`kprove`. The Findings (FINDINGS.md) do not depend on
machine-checking.

This spec is written in **intent-spec mode**: the contract captures the *intended*
behavior inferred from `benchmark/PROBLEM.md`, the member names in the reporter's
demo, and the surrounding code conventions; the V1 code is then checked against it.

---

## 0. Intent (from the issue)

Since Python 3.9 a member may be written `@classmethod @property` (a `classmethod`
whose `__func__` is a `property`). The intended behavior:

> A member that is a classmethod-wrapped property **must be documented like a
> property** — same docstring, same `:type:`, plus a `:classmethod:` marker — for
> every such member defined directly on the class being documented.

Reference members from the demo (each documented under its defining class):
`MetaClass.metaclass_class_property`, `…metaclass_abstract_class_property`,
`BaseClass.baseclass_class_property`, `…baseclass_abstract_class_property`,
`SubClass.subclass_class_property`, `…subclass_abstract_class_property`.

The member names read **"abstract class property"** — this is an intent signal for
the rendered signature prefix (see Finding F-08).

---

## 1. The language fragment that matters (mini-Python descriptor semantics)

The root cause lives in Python's **descriptor protocol**, so the mini-X fragment
must model exactly that. It is the smallest semantics in which the bug and the fix
are expressible: classes with a `__dict__`, the three descriptor flavors the fix
touches (`property`, `classmethod`, `classmethod`-wrapping-`property`), and
attribute read via `getattr`.

```k
// mini-python-descriptors.k  (fragment; constructed, not machine-checked)
module MINI-PY-DESC-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  // Descriptor values that can sit in a class __dict__.
  syntax Desc ::= "plain"   "(" Val ")"      // an ordinary attribute value
                | "prop"    "(" Val ")"      // property(fget) ; Val models fget's result
                | "cmeth"   "(" Desc ")"     // classmethod(inner)
  syntax Val  ::= String | "computed"        // 'computed' = a property getter's result
  syntax KResult ::= Val
endmodule

module MINI-PY-DESC
  imports MINI-PY-DESC-SYNTAX
  imports MAP

  // A class is a Map  name |-> Desc   (its __dict__).
  // getattr(C, n) models type.__getattribute__ on a *class object* (obj is None).

  // (1) plain attribute: returns the stored value.
  rule getattr(C:Map, N:String) => V
    requires N in_keys(C) andBool C[N] ==K plain(V:Val)

  // (2) property accessed on the class with obj=None: returns the descriptor itself.
  //     (property.__get__(None, C) is the property object)
  rule getattr(C:Map, N:String) => prop(V)
    requires N in_keys(C) andBool C[N] ==K prop(V:Val)

  // (3) classmethod wrapping a property, Python >= 3.9:
  //     classmethod.__get__(None, C) delegates to property.__get__(C, None),
  //     which CALLS the getter -> returns the *computed value*, NOT the descriptor.
  rule getattr(C:Map, N:String) => computed
    requires N in_keys(C) andBool C[N] ==K cmeth(prop(_))

  // (4) classmethod wrapping a plain function: returns a bound method (modelled
  //     opaquely as 'computed' too; irrelevant to the property fix).
  rule getattr(C:Map, N:String) => computed
    requires N in_keys(C) andBool C[N] ==K cmeth(plain(_))
endmodule
```

Rule (3) is the entire bug: `getattr(C, n)` for a `cmeth(prop(_))` yields
`computed`, so the `property` descriptor — and its docstring — is lost. Rules (1)
and (2) show why plain attributes and plain properties were never affected.

Spec-only abstraction predicates used below (declared `[function]`, spec
vocabulary only):

```k
syntax Bool ::= isCMProp(Desc)   [function]   // classmethod wrapping a property
rule isCMProp(cmeth(prop(_))) => true
rule isCMProp(_)              => false         [owise]

syntax Bool ::= hasDoc(Val)      [function]    // the value carries a usable docstring
// hasDoc(prop(V)) == true  (property exposes fget.__doc__)
// hasDoc(computed) == false (its __doc__ == its type's __doc__ -> nulled by filter_members)
```

---

## 2. Function contracts (reachability rules `φ_pre ⇒ φ_post`)

Notation: `C` is the class `__dict__` (a `Map name |-> Desc`); `n` a member name;
uppercase are logical variables.

### (C-1) `get_class_members` — member value surfacing  *(the central contract)*

For the loop body over `name in dir(subject)`, restricted to own-class names
(`n in_keys(C)`), the **recorded member object** `memberVal(n)` must be:

```
(GCM)  φ_pre:  n ∈ keys(C)
       ⇒
       φ_post: memberVal(n) = ( prop(V)        if C[n] = cmeth(prop(V))      // surfaced
                              | getattr(C, n)   otherwise )                  // unchanged
```

Equivalently, as a K claim over the loop body (`value` is the accumulator the loop
stores into `members`):

```k
claim
  <k> value = getattr(C, N) ~> RAW = lookup(C, N)
      ~> #if isCMProp(RAW) #then value = func(RAW) #else .K #fi => .K ... </k>
  <store> value |-> (_ => ?VOUT) ... </store>
  requires N in_keys(C)
  ensures  (isCMProp(C[N]) andBool ?VOUT ==K prop(?P))    // surfaced the property
        orBool ((notBool isCMProp(C[N])) andBool ?VOUT ==K getattr(C, N))
  [all-path]
```

where `func(cmeth(D)) = D` models `classmethod.__func__`.

**Postcondition consequence used downstream (the reason the fix works):**
`isCMProp(C[n]) ⇒ hasDoc(memberVal(n)) = true`. With `prop(V)` recorded,
`filter_members`'s docstring guard does **not** null the doc, so the member is
**kept** instead of dropped.

### (C-2) `PropertyDocumenter.can_document_member(member, membername, isattr, parent)`

```
(CDM)  returns True  ⇔  parent isa ClassDocumenter
                        ∧ ( isproperty(member)
                          ∨ isCMProp(parent.object.__dict__.get(membername)) )
```

Domain restriction: `parent isa ClassDocumenter` (properties are class members).
For any non-class parent the result is `False` (unchanged from the original).

### (C-3) `PropertyDocumenter.import_object()`  (post-state of `self`)

```
(IMP)  φ_pre:  super().import_object() = True
              ∧ ( isproperty(self.object)            // normal property, OR
                ∨ isCMProp(self.parent.__dict__[self.objpath[-1]]) )  // cm-property
       ⇒
       φ_post: isproperty(self.object) = True
              ∧ self.isclassmethod = isCMProp(self.parent.__dict__[self.objpath[-1]])
              ∧ return value = True
```

i.e. on success `self.object` is **always** a real `property` and
`self.isclassmethod` records whether it came from a classmethod wrapper. On any
other state the method returns the base result and leaves `self.isclassmethod`
at its declared default `False` (see C-3a).

### (C-3a) `isclassmethod` totality (the invariant add_directive_header relies on)

```
(TOT)  At every point where add_directive_header() may run (i.e. after
       import_object() returned True), self.isclassmethod is a defined Bool.
```

V2 discharges this with a class-level default `isclassmethod: bool = False`.

### (C-4) `PropertyDocumenter.add_directive_header(sig)` — emitted options

```
(HDR)  emits ':abstractmethod:'  ⇔ isabstractmethod(self.object)
       emits ':classmethod:'     ⇔ self.isclassmethod
       emits ':type: T'          ⇔ self.object.fget exists
                                    ∧ autodoc_typehints ≠ 'none'
                                    ∧ signature(fget).return_annotation ≠ empty
       order: ':abstractmethod:' precedes ':classmethod:' precedes ':type:'
```

### (C-5) `PyProperty` (py domain directive)

```
(DIR-opt)    option_spec ⊇ { abstractmethod: flag, classmethod: flag, type: text }
(DIR-prefix) get_signature_prefix(sig) =
               join(['abstract']?·['class']?·['property'], ' ') + ' '
             where 'abstract' present ⇔ ':abstractmethod:' set
                   'class'    present ⇔ ':classmethod:' set
             total over the 4 option subsets:
               {}                         -> "property "
               {abstractmethod}           -> "abstract property "
               {classmethod}              -> "class property "
               {abstractmethod,classmethod} -> "abstract class property "
```

The combined ordering is **abstract before class** (V2), aligning with
`PyMethod`'s "abstract classmethod" prefix order and with the (HDR) emission order.

---

## 3. The one loop and its circularity

The only loop the fix adds logic to is `for name in dir(subject):` in
`get_class_members`. Treat `members` as the accumulator.

**Loop invariant (circularity).** Let `D = dir(subject)` and let the loop have
processed the prefix `D[0:k]`. Then:

```
INV(k):  for every processed name n = D[j], j < k:
           n ∉ members_before  ⇒  members[unmangle(n)].object =
                  ( func(C[n])           if n ∈ keys(C) ∧ isCMProp(C[n])
                  | getattr(subject, n)  otherwise )
         and members for names not yet processed are unchanged,
         and the class_ tag is `subject` iff n ∈ keys(C) (unchanged by the fix).
```

`INV(0)` holds (no names processed). The body preserves `INV`: the only new
statement, `if isCMProp(C[n]): value = func(C[n])`, rewrites `value` exactly on the
`isCMProp` branch and is a no-op otherwise, matching the two cases of `INV`. At loop
exit (`k = len(D)`) `INV` gives contract (C-1) for every name. This is the
"closed form in the postcondition plays the role of the invariant" pattern from the
FVK recipe; there is no counter arithmetic, so the soundness side condition is
trivial (`0 ≤ k ≤ len(D)`), and no `/Int` VC arises.

---

## 4. Human-readable spec note (for a developer who never opens the `.k`)

- **`get_class_members`** now records, for any name defined in the class's own
  `__dict__` that is a `classmethod` wrapping a `property`, the **underlying
  property** as the member object (instead of the getter's computed value). Every
  other member is recorded exactly as before. Effect: such members keep a real
  docstring, so `filter_members` no longer silently drops them, and the
  property documenter is selected for them.
- **`PropertyDocumenter`** recognises a classmethod-property (directly or via the
  class `__dict__`), imports the real `property` object for it, records the fact in
  `isclassmethod` (default `False`), and emits `:classmethod:` in addition to the
  existing `:abstractmethod:`/`:type:`. `self.object` is always a genuine property
  on success, so docstring/type extraction is unchanged.
- **`PyProperty`** accepts the `:classmethod:` option and renders the signature
  prefix `class property` (or `abstract class property` when also abstract).
- **Domain restriction / out of scope:** members reachable on a class only by
  inheritance (from a base class or a metaclass) are **not** surfaced — only own-
  `__dict__` members. This matches the reported issue (each member documented under
  its defining class) and is consistent with autodoc's opt-in `:inherited-members:`
  model. See F-04/F-05.
