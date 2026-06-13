# SPEC.md — formal specification of the pyreverse type-hint fix (V1)

**Status: constructed, not machine-checked.** No K toolchain is run here; the K
fragment and claims below are written to be `kompile`/`kprove`-able and reasoned
about by hand. This is an *intent-spec* of the V1 fix for pylint issue #1548
("Use Python type hints for UML generation"), instance `pylint-dev__pylint-4551`.

## 0. What is being formalised

The fix touches four functions (plus one method-rendering loop). Each is
formalised below as a reachability claim `φ_pre ⇒ φ_post`; the two genuine loops
get loop-invariant *circularity* claims.

| # | Unit | File | Kind |
|---|------|------|------|
| F1 | `get_annotation_label(ann)` | `pylint/pyreverse/utils.py` | straight-line function |
| F2 | `get_annotation(node)` | `pylint/pyreverse/utils.py` | branch + bounded `zip` + 1 `infer` |
| F3 | `infer_node(node)` | `pylint/pyreverse/utils.py` | straight-line, returns a set |
| F4 | `ClassDiagram.class_names(nodes)` | `pylint/pyreverse/diagrams.py` | **loop** over `nodes` |
| F5 | `DotWriter.get_values(obj)` method section | `pylint/pyreverse/writer.py` | **outer loop** over methods, **inner loop** over args |

The inspector edits (`visit_assignname`, `handle_assignattr_type`) are not separate
contracts: they substitute `set(node.infer())` with `utils.infer_node(node)`, so
they are covered by F3 plus a *refinement* obligation (OB-INSP) that the
substitution preserves the observable type-map under the un-annotated domain.

## 1. Intent (from the issue, not just the code)

For

```python
class C:
    def __init__(self, a: str = None):
        self.a = a
```

the *intended* diagram shows attribute `a` typed from its PEP 484 hint rather than
from value inference (which yields `None`). The accepted reading — because the
default is `None` — is `a : Optional[str]`. The fix must additionally leave
un-annotated code rendering exactly as before (no regression), and must read
annotations from (i) annotated assignments (`x: T = ...`) and (ii) the constructor
parameter that backs `self.x = param`.

## 2. mini-Python K fragment (`pyreverse_fragment.k`)

We model astroid nodes as **opaque records**: a node is a `Map` from field name to
value. Field reads (`node.parent`, `node.name`, `node.annotation`, `node.value`,
`node.args`, `node.annotations`, `node.returns`, `node.attrname`) are map lookups;
an **undefined** field models the Python `AttributeError` that the code's
`try/except AttributeError` catches. `isinstance` tests read an immutable `kind`
field. `.infer()`, `.as_string()`, `.scope()`, `.startswith` are abstract symbols
with the algebraic laws stated below. This is a deliberate **mini-X stopgap**
(per `commands/formalize.md` §3): it covers exactly the constructs the five units
use and nothing else.

```k
module PYREVERSE-FRAGMENT-SYNTAX
  imports DOMAINS-SYNTAX
  // a Node is referenced by an Id bound in <store>; its fields live in <heap>.
  syntax Kind ::= "AnnAssign" | "AssignAttr" | "AssignName"
                | "Name" | "Subscript" | "ClassDef" | "Other"
  syntax Exp  ::= Int | Bool | String | Id | Kind
                | "none"                                   // Python None
                | field(Exp, String)        [strict(1)]    // node.<field>
                | isa(Exp, Kind)            [strict(1)]    // isinstance(node, Kind)
                | hasField(Exp, String)     [strict(1)]    // model of hasattr / try-guard
                | infer1(Exp)               [strict(1)]    // (default, *_) = node.infer()
                | inferSet(Exp)             [strict(1)]    // set(node.infer())
                | label(Exp)                [strict(1)]    // get_annotation_label(ann)
                | asString(Exp)             [strict(1)]    // ann.as_string()
                | startsOpt(String)         [strict(1)]    // label.startswith("Optional")
                | optWrap(String)           [strict(1)]    // "Optional[" + s + "]"
                | valueOf(Exp)              [strict(1)]    // getattr(default,"value","value")
  syntax KResult ::= Int | Bool | String | Kind | "none" | "undef"
endmodule

module PYREVERSE-FRAGMENT
  imports PYREVERSE-FRAGMENT-SYNTAX
  imports DOMAINS

  configuration
    <k> $PGM:K </k>
    <store> .Map </store>     // program var  Id |-> value
    <heap>  .Map </heap>      // (NodeId, field) |-> value ; missing = AttributeError
    <diagram> .Set </diagram> // node ids already in the diagram (for has_node)

  // ---- field read: defined field returns its value; undefined => undef (AttributeError)
  rule <k> field(N, F) => V ... </k> <heap> ... (N, F) |-> V ... </heap>
  rule <k> field(N, F) => undef ... </k> <heap> Rest </heap>
    requires notBool((N, F) in_keys(Rest))
  rule <k> hasField(N, F) => (N, F) in_keys(H) ... </k> <heap> H </heap>

  // ---- isinstance reads the immutable kind field
  rule <k> isa(N, KD) => field(N, "kind") ==K KD ... </k>

  // ---- get_annotation_label (F1): Name -> its name; Subscript -> as_string; else ""
  rule <k> label(N) => field(N, "name")  ... </k> requires field(N,"kind") ==K Name
  rule <k> label(N) => asString(N)       ... </k> requires field(N,"kind") ==K Subscript
  rule <k> label(N) => ""                ... </k>
    requires field(N,"kind") =/=K Name andBool field(N,"kind") =/=K Subscript

  // ---- infer1 abstracts (default,*_)=node.infer():
  //   AXIOM-INFER: node.infer() yields >= 1 result or raises InferenceError;
  //   it NEVER yields zero (astroid's @raise_if_nothing_inferred). So infer1 is
  //   either a value or the sentinel `inferErr`, never "unpack-empty".
  // valueOf models getattr(default,"value","value"): None iff the value is None.
  // (left abstract; constrained in the spec by AXIOM-INFER / AXIOM-VALUE)
endmodule
```

Stated algebraic axioms (used as `[simplification]`-style facts in the proof):

* **AXIOM-INFER** `infer1(N)` is total into `{some-node} ∪ {inferErr}`; it never
  produces an "empty-unpack". (Justification: astroid `infer()` is decorated
  `@raise_if_nothing_inferred`, so it yields ≥ 1 element or raises
  `InferenceError`; the code catches `InferenceError` ⇒ `default := ""`.)
* **AXIOM-VALUE** `valueOf(d) = none` iff `d` models Python `None`; otherwise
  `valueOf(d) ≠ none`. (Models `getattr(default, "value", "value")`.)
* **AXIOM-HEAP-DICT** every astroid node id has a writable `__dict__`: `heap[(N,F)]`
  may be created for *any* `F`, in particular `(N,"name")`. (Justification: the
  pre-existing inspector sets `node._handled`, `node.uid`, `node.locals_type`,
  `node.instance_attrs_type`, `node.implements` on real nodes — see OB8.)

## 3. F1 — `get_annotation_label` (reachability claim)

```k
claim <k> label(A:Id) => R:String ... </k>
  ensures (R ==K field(A,"name")  andBool field(A,"kind") ==K Name)
   orBool (R ==K asString(A)      andBool field(A,"kind") ==K Subscript)
   orBool (R ==K ""               andBool field(A,"kind") =/=K Name
                                  andBool field(A,"kind") =/=K Subscript)
  [all-path]
```

*Plain English:* total, pure function. `Name → .name`; `Subscript → as_string()`;
anything else (including `None`) `→ ""`. No precondition. Terminates (no loop).

## 4. F2 — `get_annotation` (reachability claim + side effect)

Precondition `requires`: `node.kind ∈ {AnnAssign-child, AssignAttr, AssignName}`
(the code is only ever called on `AssignName`/`AssignAttr` via F3).

Postcondition, as a disjunction of the reachable exit states:

```
get_annotation(node) =
  let ann =
        if   isa(node.parent, AnnAssign)              then node.parent.annotation
        elif isa(node, AssignAttr)                    then
              ( zip(node.parent.scope().locals,
                    node.parent.scope().args.annotations) ).get(node.parent.value.name)
              // any AttributeError in this block => ann = None
        else  return None
  in
  if ann == None: return None
  else:
     base := label(ann)
     L := (valueOf(infer1(node)) == none  andBool  notBool startsOpt(base))
            ? optWrap(base) : base
     if L != "":  heap[(ann,"name")] := L      // the mutation
     return ann
```

K claim (one representative all-path branch — the `AssignAttr`/`Optional` branch
that the issue exercises):

```k
claim
  <k> getAnnotation(NODE:Id) => ANN:Id ... </k>
  <heap>
    ... (NODE,"kind") |-> AssignAttr
        (NODE,"parent") |-> P:Id     (P,"kind") |-> Other
        (P,"value") |-> RHS:Id       (RHS,"name") |-> PN:String
        (ANN,"kind") |-> Name
        (ANN,"name") |-> (_ => OptL:String)        // <-- the mutation
        ...
  </heap>
  requires ANN ==K argAnnotationOf(NODE, PN)        // dict(zip(locals,annotations)).get(PN)
   andBool valueOf(infer1(NODE)) ==K none           // default is None
   andBool notBool startsOpt(BASE)
   andBool BASE ==K labelPure(ANN)                  // BASE = label before mutation
  ensures OptL ==K optWrap(BASE)                     // ann.name becomes Optional[BASE]
  [all-path]
```

*Plain English:*
* If `node.parent` is an `AnnAssign`, the annotation is `node.parent.annotation`.
* Else, if `node` is an `AssignAttr`, look the assigned RHS name up in the enclosing
  scope's `dict(zip(locals, args.annotations))`; **any** `AttributeError` while doing
  so (non-`Name` RHS such as a constant/`Call`/tuple, a scope with no `.args`, an
  undefined field) ⇒ `ann = None`.
* Else return `None`.
* If an annotation was found, its display label is `Optional[base]` when the
  inferred default value is `None` and it is not already `Optional…`, else `base`.
* **Side effect:** the chosen label is written to `ann.name` (only when non-empty),
  so downstream `class_names` can read it. The function returns the (possibly
  mutated) annotation node.

Side conditions / obligations: OB1–OB2, OB6, OB7, OB8 (see PROOF_OBLIGATIONS.md).

## 5. F3 — `infer_node` (reachability claim)

```k
claim <k> inferNode(NODE:Id) => RS:Set ... </k>
  ensures ( RS ==K SetItem(ANN)        andBool ANN ==K getAnnotation(NODE) andBool ANN =/=K none )
   orBool ( RS ==K inferSet(NODE)      andBool getAnnotation(NODE) ==K none andBool defined(NODE) )
   orBool ( RS ==K .Set                andBool getAnnotation(NODE) ==K none andBool inferErr(NODE) )
  [all-path]
```

*Plain English:* returns `{annotation}` if an annotation exists; otherwise the
inference set `set(node.infer())`; otherwise (an `InferenceError`) the empty set.
**Total: never raises.** Result is always a `Set`. This is the single behavioural
substitution made in the inspector.

**OB-INSP (refinement).** On the *un-annotated* domain (`getAnnotation(node) == none`),
`inferNode(node) = set(node.infer())` on success and `∅` on `InferenceError`, which is
exactly the pre-fix `set(node.infer())` value (the pre-fix code skipped the assignment
on error, leaving the defaultdict entry `[]`; `list(set(current) | ∅) = list(current)`
has the same *contents*). So observable type-maps are unchanged on un-annotated inputs.

## 6. F4 — `class_names` (loop circularity)

Loop: `for node in nodes: ... if isinstance(node,(ClassDef,Name,Subscript)) and
hasattr(node,"name") and not has_node(node): if node.name not in names: names.append(node.name)`.

Define the **accumulator invariant** as a function of the processed prefix:

```
keep(n)   ≡  (n.kind ∈ {ClassDef,Name,Subscript}) ∧ hasField(n,"name") ∧ ¬(n ∈ diagram)
names(P)  ≡  dedup([ n.name | n ∈ P, keep(n) ])          // first-occurrence order, unique
```

Loop circularity claim (generalised over the running list `NS` and accumulator `ACC`):

```k
claim
  <k> forNodes(NS:List, ACC:List) => ACC ++List names'(NS, ACC) ... </k>
  <diagram> D </diagram>
  [all-path]
// names'(NS,ACC): the new names contributed by NS, each kept node's name appended
// iff not already present in ACC and not already added earlier in NS (dedup).
```

*Plain English:* `class_names(nodes)` returns the list of `.name`s of the kept nodes,
in first-occurrence order, **with no duplicates**. Widening the type test to include
`Name` and `Subscript` is sound because (a) every `Name`/`Subscript` reaching the
type-maps came through `get_annotation`, which set `.name`, and (b) the
`hasattr(node,"name")` guard makes any stray node without a `name` a no-op.
Terminates because `nodes` is finite (one element consumed per step).

## 7. F5 — `get_values` method section (nested loop circularity)

Outer loop over `obj.methods`; for each method:

```
ret  = (func.returns ≠ None) ? ": " + label(func.returns) : ""
args = [a for a in func.args.args if a.name != "self"]            // NODES
amap = dict(zip(args, func.args.annotations[1:]))                  // arg-node |-> annotation|None
for a in args: amap[a] = (amap.get(a) ? label(amap[a]) : "")      // arg-node |-> label-string
argstr = ", ".join( (s=="" ? a.name : a.name+": "+s) for (a,s) in amap.items() )  // args order
label += func.name + "(" + argstr + ")" + ret + r"\l"
```

Inner-loop circularity (generalised over the remaining arg list and the partial join):

```k
claim <k> joinArgs(AS:List, ANNS:List, ACC:String) => ACC +String renderArgs(AS, ANNS) ... </k>
  [all-path]
// renderArgs zips AS with ANNS (None-padding via [1:]) and renders each as
// `name` or `name: label`, comma-separated, in AS order.
```

*Plain English & key obligation (OB5 — backward compatibility):* when a method has
**no** annotations (`func.returns == None` and every entry of `func.args.annotations`
is `None`), `ret = ""` and every `s = ""`, so `argstr = ", ".join(a.name ...)` and the
emitted string is exactly the legacy `func.name(p1, …, pk)\l`. For methods whose
**first** parameter is `self`/`cls` (every bound instance method), `args` (self
removed) lines up element-for-element with `annotations[1:]`, so annotations attach to
the correct parameter. Terminates (finite methods, finite args).

## 8. Trusted base

* Adequacy of the mini-Python fragment vs. real astroid/pyreverse (AXIOM-INFER,
  AXIOM-VALUE, AXIOM-HEAP-DICT capture the three astroid facts relied on).
* The K reachability metatheory + `kprove`; the Z3/`[simplification]` oracle.
* **Constructed, not machine-checked** (MVP): `kompile`/`kprove` not run — see PROOF.md
  for the exact commands.
