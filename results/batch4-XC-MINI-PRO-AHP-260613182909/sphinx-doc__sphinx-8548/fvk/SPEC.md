# SPEC.md — formal specification of the sphinx-doc__sphinx-8548 V1 fix

> Status: **constructed, not machine-checked.** The K fragment below is a faithful
> *mini-Python* abstraction of exactly the code paths the V1 fix touches (no `if`,
> no exceptions modelled beyond the analyzer-miss abstraction). It is the FVK
> "mini-X" stopgap, not a full Python-in-K semantics.

## 0. What is being specified

The V1 fix changes/relies on three units. We give each an intended contract
(intent-spec mode: the contract captures *intended* behavior; the code is checked
against it):

- **`get_attribute_comment(self, parent)`** — `sphinx/ext/autodoc/__init__.py`
  (defined in `UninitializedInstanceAttributeMixin`, now also consumed by
  `AttributeDocumenter.get_doc`). A linear MRO search returning the first matching
  comment-docstring. *Unchanged source, but newly load-bearing — so it is
  specified.*
- **`get_class_members(subject, objpath, attrgetter, analyzer)` — final MRO merge
  loop** — `sphinx/ext/autodoc/importer.py`. The block rewritten by V1.
- **`AttributeDocumenter.get_doc(self, …)`** — `sphinx/ext/autodoc/__init__.py`.
  The 3-line prefix added by V1.

### Abstract state (the model)

- `MRO = [C_0, C_1, …, C_k]` — the method-resolution order of `subject`, `C_0 =
  subject`, finite, no duplicates. Each class `C` has `mod(C)` and `qual(C)`.
- `AD` — the *analyzer oracle*: a partial map
  `AD : (Module × Qualname × Name) ⇀ Doc`. `AD[(m,q,a)]` is defined iff the source
  analyzer for module `m` has an attribute comment for `(q,a)`. **Modeling of the
  `try/except (AttributeError, PycodeError): continue`:** a class `C` whose module
  has no analysable source contributes *no* `AD` keys at all (every lookup
  `AD[(mod(C),·,·)]` is undefined). This is exactly `for_module` raising
  `PycodeError` and the loop `continue`-ing. Builtins (`object`, …) are such
  classes.
- `members` — a map `Name ⇀ ClassAttribute(class_, value, doc)`; `doc` is a
  `Doc` or `⊥` (Python `None`). `INSTANCEATTR` / `True` etc. are opaque `Value`s.
- `join(D)` abbreviates `'\n'.join(D)` (total on `Doc` line-lists).

### Notation

`first(P, L)` = the least-index element of list `L` satisfying predicate `P`, or
`⊥` if none. `hasAD(C,a) ≜ (mod(C),qual(C),a) ∈ dom(AD)`.

---

## 1. Mini-K fragment semantics (`autodoc-frag.k`)

```k
module AUTODOC-FRAG-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX
  imports STRING-SYNTAX

  // ----- values -----
  syntax Val   ::= "INSTANCEATTR" | "NONE" | Int | Bool | String
  syntax KResult ::= Val | Bool

  // ----- the two loops we verify, as opaque statements over oracle cells -----
  // getAttrComment(parent attrname): linear MRO search, returns first AD hit or NONE
  syntax Stmt ::= "getAttrComment" "(" Id "," Id ")"     [strict(2)]
                | "mergeMRO"                              // get_class_members final loop
                | "ret" Exp                               // early return
  syntax Exp  ::= Id | Val
                | "ADlookup" "(" Int "," Id ")"   // AD[(mod(MRO[i]),qual(MRO[i]),a)] or NONE
                | "memberDoc" "(" Id ")"          // members[a].doc or "absent"
  syntax KResult ::= Val
endmodule

module AUTODOC-FRAG
  imports AUTODOC-FRAG-SYNTAX
  imports INT
  imports BOOL
  imports MAP
  imports LIST

  configuration
    <k> $PGM:Stmt </k>
    <i>   0:Int   </i>          // loop index into MRO
    <ret> NONE:Val </ret>       // result register (getAttrComment)
    <mro> $MRO:List </mro>      // [C_0, …, C_k]; ListItem(class(MOD,QUAL))
    <ad>  $AD:Map   </ad>       // (MOD,QUAL,NAME) |-> Doc        (the analyzer oracle)
    <mem> $MEM:Map  </mem>      // NAME |-> attr(CLASS,VALUE,DOC) (members)
    <attr> $A:Id    </attr>     // the attribute name being searched (objpath[-1])

  // ===== getAttrComment: for cls in MRO: if hasAD: return AD[..]; return NONE =====
  // (i) exhausted MRO -> NONE
  rule <k> getAttrComment(_, A) => ret NONE ... </k>
       <i> I </i> <mro> MRO </mro>
    requires I >=Int size(MRO)
  // (ii) current class hits AD -> return it
  rule <k> getAttrComment(P, A) => ret ADlookup(I, A) ... </k>
       <i> I </i> <mro> MRO </mro> <ad> AD </ad>
    requires I <Int size(MRO) andBool definedAD(MRO, AD, I, A)
  // (iii) current class misses -> advance
  rule <k> getAttrComment(P, A) => getAttrComment(P, A) ... </k>
       <i> I => I +Int 1 </i> <mro> MRO </mro> <ad> AD </ad>
    requires I <Int size(MRO) andBool notBool definedAD(MRO, AD, I, A)

  // ===== mergeMRO: get_class_members final loop =====
  // (i) exhausted MRO -> done
  rule <k> mergeMRO => .K ... </k>
       <i> I </i> <mro> MRO </mro>
    requires I >=Int size(MRO)
  // (ii) class C_I missing source (no AD keys) -> skip   [models try/except continue]
  rule <k> mergeMRO => mergeMRO ... </k>
       <i> I => I +Int 1 </i> <mro> MRO </mro> <ad> AD </ad>
    requires I <Int size(MRO) andBool noSource(MRO, AD, I)
  // (iii) class C_I has source -> fold its matching AD entries into <mem>, then advance
  //       (one logical step; mergeClass is the inner item-loop, specified below)
  rule <k> mergeMRO => mergeClass(I) ~> mergeMRO ... </k>
       <i> I </i> <mro> MRO </mro> <ad> AD </ad>
    requires I <Int size(MRO) andBool notBool noSource(MRO, AD, I)
  rule <k> mergeClass(I) => .K ... </k> <i> _ => I +Int 1 </i>   // advance after inner fold
  // mergeClass(I) merges every (qual(C_I),a) in AD into <mem>:
  //   if a ∉ mem:                  mem[a] := attr(C_I, INSTANCEATTR, join(AD[..]))
  //   elif mem[a].doc == NONE:     mem[a].doc := join(AD[..])
  //   else: unchanged
  // (the inner loop is the analyzer.attr_docs.items() iteration; its per-item
  //  rewrite is the obvious map-update, elided here and given as GCM-INNER below.)

  // helper predicates (spec-level functions over the oracle cells)
  syntax Bool ::= definedAD(List, Map, Int, Id) [function]
                | noSource(List, Map, Int)       [function]
endmodule
```

`definedAD(MRO,AD,I,A)` ≜ `(mod(MRO[I]),qual(MRO[I]),A) ∈ dom(AD)`.
`noSource(MRO,AD,I)` ≜ no key of `AD` has module `mod(MRO[I])` (the analyzer-miss
abstraction). These are spec-only `[function]`s in the `VERIFICATION` module.

---

## 2. Function contracts (reachability claims) — `autodoc-frag-spec.k`

### (GAC) `get_attribute_comment` contract

```k
claim
  <k> getAttrComment(P, A) => ret R ... </k>
  <i>   0 => ?I' </i>
  <ret> NONE => R </ret>
  <mro> MRO </mro> <ad> AD </ad> <attr> A </attr>
  ensures R ==K firstComment(MRO, AD, A, 0)
  [all-path]
```

where the spec function

```
firstComment(MRO, AD, A, I)
  = NONE                              if I >= size(MRO)
  = join(AD[(mod(MRO[I]),qual(MRO[I]),A)])   if definedAD(MRO,AD,I,A)
  = firstComment(MRO, AD, A, I+1)     otherwise
```

**Intended meaning:** `get_attribute_comment(parent, A)` returns the comment of the
**first** class in `parent`'s MRO (most-derived first) that documents `A`, or
`None`. (In the real code the returned line-list is later `'\n'`-joined by the
caller — `get_doc` wraps it as one docstring; we fold the join into `firstComment`
for a scalar postcondition.)

### (GAC-LOOP) loop circularity, generalized over the index

```k
claim
  <k> getAttrComment(P, A) => ret R ... </k>
  <i>   I => ?I' </i>
  <ret> NONE => R </ret>
  <mro> MRO </mro> <ad> AD </ad> <attr> A </attr>
  requires 0 <=Int I andBool I <=Int size(MRO)
  ensures  R ==K firstComment(MRO, AD, A, I)
  [all-path]
```

Side condition `0 ≤ I ≤ size(MRO)` is the soundness bound (counterpart of the sum
example's `I ≤ N+1`): outside it the closed form `firstComment` would index out of
range.

### (GCM) `get_class_members` merge-loop contract

```k
claim
  <k> mergeMRO => .K ... </k>
  <i>   0 => ?If </i>
  <mro> MRO </mro> <ad> AD </ad>
  <mem> MEM => mergeAll(MRO, AD, MEM, 0) </mem>
  [all-path]
```

where `mergeAll` folds the MRO left-to-right:

```
mergeAll(MRO, AD, M, I)
  = M                                            if I >= size(MRO)
  = mergeAll(MRO, AD, M, I+1)                     if noSource(MRO,AD,I)
  = mergeAll(MRO, AD, mergeClass(MRO,AD,M,I), I+1)   otherwise

mergeClass(MRO, AD, M, I) = fold over { a | (qual(MRO[I]),a) keyed in AD@mod(MRO[I]) }:
    for each such a with doc d = join(AD[(mod(MRO[I]),qual(MRO[I]),a)]):
      if a ∉ dom(M):           M := M[a <- attr(MRO[I], INSTANCEATTR, d)]
      elif M[a].doc == NONE:   M := M[a <- attr(M[a].class_, M[a].value, d)]
      else:                    M := M               // unchanged
```

### (GCM-INNER) inner item-loop circularity

The `for (ns,name),docstring in analyzer.attr_docs.items()` loop, generalized over
the remaining item set `S` and the partial map `M`, with postcondition
`mergeItems(S, M)` (the per-item case-split above). Standard finite-fold
circularity; soundness side condition: `S ⊆ dom(AD@mod(C_I))`.

### (GD) `AttributeDocumenter.get_doc` contract (composition)

`get_doc` is *not* a loop; it is a 2-way guard composed with the legacy body.
Contract, with `C = first-match comment = firstComment(MRO(parent), AD, A, 0)`:

```
get_doc()  ⇒  [C]                       if C ≠ NONE
           ⇒  []                        if C = NONE ∧ object = INSTANCEATTR
           ⇒  legacy_get_doc()          otherwise
```

where `legacy_get_doc()` is the V0 body (the `autodoc_inherit_docstrings`-guarded
`super().get_doc`). **Key obligation (GD-EQ):** on the `C = NONE` branch, V1 is
*observationally identical* to V0 — the comment prefix is a pure extension that is
inert exactly when there is no comment.

---

## 3. Human-readable spec (for a developer who never opens the `.k`)

- **`get_attribute_comment(parent, A)`** returns the attribute-comment for `A`
  taken from the **nearest** class in `parent`'s MRO that defines one, else `None`.
  Precondition: `parent` is a class or `None` (the `None`/non-class case yields an
  empty MRO ⇒ `None`). Classes without analysable source (builtins) are skipped,
  never crash.

- **`get_class_members`'s final loop** returns `members` such that, for every
  attribute name `a`:
  - if `a` already had a non-`None` docstring (from `__slots__` etc.), it is
    **unchanged**;
  - if `a` was present with `None` docstring (e.g. an inherited class attribute
    found via `dir()`), its docstring is filled in from the **nearest** MRO class
    that comments `a` (or left `None`);
  - if `a` was absent, and some MRO class comments `a` (an instance attribute only
    visible to the source analyzer), it is **added** as
    `ClassAttribute(C, INSTANCEATTR, comment)` for the nearest such class `C`.
  Precondition: `subject` is a class. Builtins in the MRO are skipped.

- **`AttributeDocumenter.get_doc`** returns the attribute comment (nearest MRO
  class) if one exists; otherwise it behaves exactly as before the fix.
  Precondition: `self.parent` is the owning class (set by `import_object`) or
  `None`; `self.objpath` is non-empty.

### Trusted base / residual risk

- **Partial correctness** — the loops are proved to deliver their postcondition
  *if they terminate*; termination is argued separately (finite MRO / finite
  `attr_docs`) in PROOF.md §Termination, not machine-checked.
- **Fragment adequacy** — the mini-K models the analyzer as an oracle `AD` and the
  `try/except … continue` as "no-source classes contribute no keys." Faithfulness
  of that abstraction is a trusted assumption (justified in FINDINGS F-A).
- **Constructed, not machine-checked** — no `kompile`/`kprove` was run (see
  PROOF.md for the exact commands).
