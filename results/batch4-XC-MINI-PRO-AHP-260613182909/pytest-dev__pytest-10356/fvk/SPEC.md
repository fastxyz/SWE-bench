# SPEC — `get_unpacked_marks` / `store_mark` (pytest-dev__pytest-10356)

**Status: constructed, not machine-checked.** No K toolchain was run (no execution
environment). The `.k` fragments below are written to be `kompile`/`kprove`-ready and
are reasoned about by hand. This file is the output of `/formalize` applied to the V1
fix that lives in `repo/src/_pytest/mark/structures.py`.

---

## 1. Target and intent

### 1.1 Code under verification (V1)

`repo/src/_pytest/mark/structures.py`:

```python
def get_unpacked_marks(obj, *, consider_mro=True):
    if isinstance(obj, type):
        if not consider_mro:
            mark_lists = [obj.__dict__.get("pytestmark", [])]
        else:
            mark_lists = [
                x.__dict__.get("pytestmark", []) for x in reversed(obj.__mro__)
            ]
        mark_list = []
        for item in mark_lists:
            if isinstance(item, list):
                mark_list.extend(item)
            else:
                mark_list.append(item)
    else:
        mark_attribute = getattr(obj, "pytestmark", [])
        if isinstance(mark_attribute, list):
            mark_list = mark_attribute
        else:
            mark_list = [mark_attribute]
    return list(normalize_mark_list(mark_list))

def store_mark(obj, mark):
    assert isinstance(mark, Mark), mark
    obj.pytestmark = [*get_unpacked_marks(obj, consider_mro=False), mark]
```

`normalize_mark_list(it)` maps each element `e` to `getattr(e, "mark", e)` and
requires the result to be a `Mark` (else `TypeError`). It is unchanged from baseline.

### 1.2 Intended behavior (from the issue + maintainer comments, not the code alone)

- Issue #7792 / PR #10356: *"Consider MRO when obtaining marks for classes."* When a
  class inherits from several marked base classes, **all** of their marks must be
  collected, not just the first found along the attribute-lookup chain.
- Maintainer ruling in-thread: *"The marks have to transfer with the mro, its a well
  used feature and its a bug that it doesn't extend to multiple inheritance."* and the
  confirmed example: for `C(A, B)` with `@a` on `A`, `@b` on `B`, `@c` on `C`, the
  marks of `test_d` should include both `a` **and** `b` (and `c`).
- Long-standing baseline behavior for *single* inheritance (`B(A)`) already yields
  base-before-derived order `[a, b]`; the fix must preserve that.

So the intended contract is: **the marks of a class are the concatenation of the
own-marks of every class in its MRO, each class contributing once, ordered
base-class-first (so that single inheritance is unchanged).**

---

## 2. Abstraction vocabulary (spec-only functions)

Let `obj` be a class. Define, over the model:

- `mro(obj)`  — the tuple `obj.__mro__` (C3 linearization). **Language guarantee
  (MRO-DISTINCT):** every ancestor class occurs in `mro(obj)` **exactly once**, with
  `obj` first and `object` last. Cited as a Python-language fact, not proved here.
- `own(c)`    — the normalized own-marks of a single class `c`: take
  `v = c.__dict__.get("pytestmark", [])`; if `v` is a `list`, `own(c)=normalize(v)`;
  otherwise `own(c)=normalize([v])`. Reads **only** `c`'s own `__dict__`, never
  inherited attributes.
- `flatten(MLS)` — for a list `MLS` whose elements are each either a list of marks or a
  single mark:
  ```
  flatten([])                = []
  flatten([item] ++ rest)    = item   ++ flatten(rest)   if isinstance(item, list)
  flatten([item] ++ rest)    = [item] ++ flatten(rest)   otherwise
  ```
- `revmap_own(obj) = [ own(c) for c in reversed(mro(obj)) ]`.

With these, the intended class contract is exactly:

```
get_unpacked_marks(obj, consider_mro=True) = flatten(revmap_own(obj))
```

Because each `own(c)` is already a flat list of marks, `flatten(revmap_own(obj))`
equals the plain concatenation `own(c_k) ++ … ++ own(c_1)` for
`reversed(mro(obj)) = [c_k, …, c_1]`.

---

## 3. Function contracts (reachability rules)

Read `φ_pre ⇒ φ_post` as "every execution from a `φ_pre` state reaches a `φ_post`
state."

### C-CLASS-MRO  (the bug-fix contract)
```
requires: isinstance(obj, type) ∧ consider_mro = True
          ∧ MRO-DISTINCT(obj)            // language guarantee
get_unpacked_marks(obj, consider_mro=True)
   ⇒  result = flatten([ own(c) for c in reversed(mro(obj)) ])
post:     every mark in every own(c), c ∈ mro(obj), occurs in result   (completeness)
      ∧   for each c, own(c)'s marks occur in result with their own multiplicity,
          not multiplied by #subclasses                                  (no struct. dup)
      ∧   result is base-class-first, declaration-order within a class   (ordering)
      ∧   every element of result is a Mark                              (type safety)
```

### C-CLASS-OWN  (used by `store_mark`)
```
requires: isinstance(obj, type) ∧ consider_mro = False
get_unpacked_marks(obj, consider_mro=False)  ⇒  result = own(obj)
```

### C-NONCLASS  (modules, functions, methods — unchanged from baseline)
```
requires: ¬ isinstance(obj, type)
get_unpacked_marks(obj, _)  ⇒
   result = normalize( as_list(getattr(obj, "pytestmark", [])) )
   where as_list(v) = v if isinstance(v,list) else [v]
post: identical to the baseline implementation (behavior preserved).
```

### C-STORE  (store_mark, the second half of the fix)
```
store_mark(obj, m):  obj.pytestmark := get_unpacked_marks(obj, consider_mro=False) ++ [m]
post (class obj):   own(obj)_after = own(obj)_before ++ [m]
                ∧   own(c) unchanged for every c ≠ obj
                ∧   no inherited mark is copied into obj.__dict__
```
C-STORE is the invariant that keeps C-CLASS-MRO duplication-free across repeated
collection: each class's `__dict__["pytestmark"]` holds *only* that class's own marks,
so the MRO walk in C-CLASS-MRO never sees the same mark via two different classes'
own-dicts.

---

## 4. Mini-Python K semantics for the verified core

The verified core is the flattening fold (the body of the `isinstance(obj, type) ∧
consider_mro` branch), with `mark_lists` supplied as a symbolic argument. `own`,
`reversed`, `mro`, and `normalize_mark_list` are handled at the abstraction level
(§2, §6) — the fold is the only control flow that needs symbolic execution.

`mini-python-marks.k` (constructed; covers only the constructs the core uses):

```k
module MINI-PYTHON-MARKS-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX
  imports LIST

  // Values: opaque marks (tagged by Int), and Python lists (K List of Vals).
  syntax MarkV ::= "mark" "(" Int ")"
  syntax Val   ::= MarkV | List            // List = a Python list value

  syntax Exp  ::= Id | Val
                | "[" "]"                                  // empty-list literal
                | "isinstance" "(" Exp "," "list" ")" [strict(1)]
                | Id "(" Exp ")"                  [strict(2)]   // call f(arg)
  syntax Stmt ::= Id "=" Exp                      [strict(2)]
                | Id "." "append" "(" Exp ")"     [strict(2)]
                | Id "." "extend" "(" Exp ")"     [strict(2)]
                | "for" Id "in" Exp ":" Block     [strict(2)]
                | "if" Exp ":" Block "else" ":" Block [strict(1)]
                | "return" Exp                    [strict]
                | "def" Id "(" Id ")" ":" Block
                > Stmt Stmt                        [left]
  syntax Block  ::= "{" Stmt "}"
  syntax KResult ::= Val
endmodule

module MINI-PYTHON-MARKS
  imports MINI-PYTHON-MARKS-SYNTAX
  imports INT
  imports BOOL
  imports MAP
  imports LIST

  configuration
    <k> $PGM:Stmt </k>
    <store> .Map  </store>     // Id |-> Val
    <funcs> .Map  </funcs>     // Id |-> def
    <stack> .List </stack>     // saved (continuation, store) frames

  // --- expressions ---
  rule <k> X:Id => V ... </k> <store> ... X |-> V ... </store>
  rule <k> [] => .List:List ... </k>                       // empty list value
  rule <k> isinstance(_:List, list) => true  ... </k>
  rule <k> isinstance(_:MarkV, list) => false ... </k>

  // --- statements ---
  rule <k> X:Id = V:Val => .K ... </k>
       <store> STORE => STORE [ X <- V ] </store>
  rule <k> X:Id . append(V:Val) => .K ... </k>
       <store> ... X |-> (L:List => L ListItem(V)) ... </store>
  rule <k> X:Id . extend(L2:List) => .K ... </k>
       <store> ... X |-> (L1:List => L1 L2) ... </store>   // List concat = juxtaposition
  rule <k> { S:Stmt } => S ... </k>
  rule <k> S1:Stmt S2:Stmt => S1 ~> S2 ... </k>
  rule <k> if true  : B1 else : _  => B1 ... </k>
  rule <k> if false : _  else : B2 => B2 ... </k>

  // --- for-loop: freeze the remaining list and step it one element at a time ---
  rule <k> for X:Id in L:List : B:Block => #forLoop(X, L, B) ... </k>
  rule <k> #forLoop(_, .List, _) => .K ... </k>
  rule <k> #forLoop(X, (ListItem(V) REST):List, B)
         => X = V ~> B ~> #forLoop(X, REST, B) ... </k>
  syntax KItem ::= "#forLoop" "(" Id "," List "," Block ")"

  // --- def / call / return  (Lesson 1.22 style, single parameter) ---
  rule <k> def F:Id ( P:Id ) : B:Block => .K ... </k>
       <funcs> FS => FS [ F <- def F(P): B ] </funcs>
  rule <k> F:Id ( V:Val ) ~> K => B </k>
       <funcs> ... F |-> def F(P:Id): B ... </funcs>
       <store> STORE => P |-> V </store>
       <stack> .List => ListItem(state(K, STORE)) ... </stack>
  rule <k> return V:Val ~> _ => V ~> K </k>
       <stack> ListItem(state(K, STORE)) => .List ... </stack>
       <store> _ => STORE </store>
  syntax KItem ::= "state" "(" K "," Map ")"
endmodule
```

> MVP stopgap, as the kit prescribes: this is a minimal *mini-Python*, not real
> CPython semantics. It faithfully covers list values, `isinstance(_, list)`,
> `append`/`extend` (K `List` concatenation), `for`, `if/else`, and call/return — and
> *nothing else*, because the verified core uses nothing else.

---

## 5. The claims (`mini-python-marks-spec.k`)

```k
requires "mini-python-marks.k"

module MINI-PYTHON-MARKS-SPEC-SYNTAX
  imports MINI-PYTHON-MARKS-SYNTAX
endmodule

module VERIFICATION
  imports MINI-PYTHON-MARKS-SPEC-SYNTAX
  imports MINI-PYTHON-MARKS
  imports LIST
  imports K-EQUAL

  // spec-only flatten: the intended result as a function of the input list-of-lists.
  syntax List ::= flatten(List) [function]
  rule flatten(.List) => .List
  rule flatten(ListItem(L:List) REST) => L          flatten(REST)          // list item: spread
  rule flatten(ListItem(M:MarkV) REST) => ListItem(M) flatten(REST)        // single mark: keep

  // K's List concatenation is associative with unit .List BY CONSTRUCTION, so the two
  // verification conditions below are structural, not nonlinear arithmetic:
  //   (ACC L) flatten(REST)        == ACC (L flatten(REST))            [assoc]
  //   ACC flatten(.List) == ACC .List == ACC                          [unit]
  // No truncating-division lemma is required (contrast the sum example).
endmodule

module MINI-PYTHON-MARKS-SPEC
  imports VERIFICATION

  // (LOOP) circularity — generalized over accumulator ACC and remaining list REST.
  // No counter side condition is needed: the fold terminates for finite REST and the
  // invariant "acc becomes acc ++ flatten(rest)" holds for ALL ACC, REST.
  claim
    <k> #forLoop(item, REST:List,
          { if isinstance(item, list): { mark_list . extend(item) }
            else: { mark_list . append(item) } })
        => .K ... </k>
    <store>
      ... mark_list |-> (ACC:List => ACC flatten(REST))
          item      |-> (_:Val   => ?_:Val)
      ...
    </store>
    [all-path]

  // (GUC) function contract — the class+consider_mro core, mark_lists = MLS symbolic.
  claim
    <k> def guc ( mark_lists ) :
          { mark_list = []
            for item in mark_lists :
              { if isinstance(item, list): { mark_list . extend(item) }
                else: { mark_list . append(item) } }
            return mark_list }
        ~> guc ( MLS:List )
        => flatten(MLS) ... </k>
    <store> _ => ?_:Map </store>
    [all-path]
endmodule
```

---

## 6. Reduction of the full contracts to the verified core

The K core proves `guc(MLS) ⇒ flatten(MLS)` for a symbolic list-of-lists `MLS`. The
remaining steps connect that to the four contracts of §3:

1. **C-CLASS-MRO.** Instantiate `MLS := revmap_own(obj) = [own(c) for c in
   reversed(mro(obj))]`. Then `result_core = flatten(revmap_own(obj))`, which is the
   contract's RHS. The three post-properties follow:
   - *Completeness (PO1).* `flatten` concatenates **every** `own(c)`; `reversed(mro)`
     ranges over **all** classes in the MRO ⇒ no class's marks are dropped.
   - *No structural duplication (PO2).* By MRO-DISTINCT each `c` appears once in
     `mro(obj)`, and `own(c)` reads only `c.__dict__` ⇒ each own-list is concatenated
     once. (Same-named marks declared on *different* classes are kept separately — see
     FINDINGS F4; this matches baseline single-inheritance behavior.)
   - *Ordering (PO3).* `reversed(mro)` is base-class-first; for single inheritance
     `B(A)` it is `[object, A, B]`, giving `own(A) ++ own(B) = [a, b]`, identical to the
     baseline accumulation. (A *forward* MRO walk would give `[b, a]` and break
     compatibility — this is what forces `reversed`.)
2. **C-CLASS-OWN.** With `consider_mro=False`, `mark_lists=[own(obj)]` (a single list),
   so the fold's first iteration `extend`s it and the result is `own(obj)`. Trivial
   one-iteration instance of (LOOP).
3. **C-NONCLASS.** Pure case analysis on `isinstance(obj, type)=False`; the `else`
   branch is the baseline algorithm verbatim (only the `isinstance` test is inverted),
   so behavior is preserved by inspection. Not part of the loop proof.
4. **C-STORE / PO4.** `store_mark` assigns `obj.pytestmark := own(obj)_before ++ [m]`
   using **C-CLASS-OWN** (own-only). Hence `own(obj)_after = own(obj)_before ++ [m]`
   and no other class's own-dict changes. This is the invariant that makes repeated
   C-CLASS-MRO collection idempotent (no cross-class duplicate accumulation).
5. **Type safety (PO6).** `normalize_mark_list` wraps the core result; every element is
   forced to be a `Mark` or a `TypeError` is raised. Unchanged from baseline.

---

## 7. `kompile` / `kprove` commands (constructed, NOT executed)

```sh
kompile mini-python-marks.k --backend haskell        # compile the fragment semantics
kast    --backend haskell mini-python-marks-spec.k   # (optional) parse check
kprove  mini-python-marks-spec.k                     # expected: #Top  (both claims proved)
```

These are written for a human to machine-check later. They were **not** run here (no
execution environment). A `#Top` from `kprove` would upgrade the result from
*constructed* to *machine-verified*; until then, treat the proof as constructed.

---

## 8. Spec note (plain English)

`get_unpacked_marks(obj)` returns the list of pytest marks that apply to `obj`.
- If `obj` is a **class**, the marks are gathered by walking the **whole MRO** of the
  class from the most-derived to the root and concatenating each class's *own* marks
  (those declared directly on that class), so marks from *all* base classes — including
  multiple-inheritance siblings — are included, base-class marks first. Each class
  contributes its marks exactly once. With `consider_mro=False` only the class's own
  marks are returned.
- If `obj` is **not a class** (a module or function), the behavior is unchanged: read
  the `pytestmark` attribute and normalize it.
`store_mark(obj, m)` appends `m` to `obj`'s **own** marks only, so applying a marker to
a subclass never copies inherited marks into the subclass.
