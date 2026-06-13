# SPEC.md — Formal specification of the V1 fix (sphinx-doc__sphinx-9229)

> Status: **constructed, not machine-checked.** No K toolchain is run here (no
> execution environment); the `kompile`/`kprove` commands are emitted in
> `PROOF.md` and reasoned about, per the FVK MVP honesty gate.

## 0. Scope — what is being formalized

The V1 fix touches **two methods of `ClassDocumenter`** in
`repo/sphinx/ext/autodoc/__init__.py`, plus it relies on an **integration
invariant** with the inherited `Documenter.add_content`:

```python
# (A) new method
def get_variable_comment(self) -> Optional[List[str]]:
    try:
        key = ('.'.join(self.objpath[:-1]), self.objpath[-1])
        analyzer = ModuleAnalyzer.for_module(self.modname)
        analyzer.analyze()
        return list(analyzer.attr_docs.get(key, []))
    except PycodeError:
        return []

# (B) changed branch of get_doc (doc_as_attr case only)
def get_doc(self, ignore=None):
    if self.doc_as_attr:
        # Don't show the docstring of the class when it is an alias.
        comment = self.get_variable_comment()
        if comment:
            return [comment]
        else:
            return None
    ... # (unchanged non-alias path below)
```

These are **straight-line, branching, total** functions: **no loops and no
recursion**, so the FVK *Circularity* machinery (§3/§5 of
`reachability-and-circularities.md`) does **not** apply — there is **no loop
invariant to discharge**. Each contract is a one-shot reachability rule
`φ_pre ⇒ φ_post` proved by symbolic execution (Axiom + Transitivity +
Case-Analysis + Consequence) with **no coinduction**. That absence is itself a
positive signal (see FINDINGS F0).

## 1. Intent (from PROBLEM.md, the conversation, and code names)

The issue: a *type/class alias* documented with its own doc-comment
(`#: ...` before, or next-line `"""..."""` after the assignment) sometimes
shows only the auto-generated `alias of ...` text and drops the user's comment.
The intended, *consistent* behaviour is:

- **I1.** If the alias variable has its **own** documentation comment, that
  comment is rendered **in addition to** `alias of <target>` (mirrors the
  already-correct behaviour of `DataDocumenter`, asserted by
  `test_autodata_GenericAlias`).
- **I2.** The **aliased class's own `__doc__`** must **not** be rendered for an
  alias (that was the point of the original `return None`).
- **I3.** A **comment-less** alias renders **only** `alias of <target>`, and
  does **not** fire the `autodoc-process-docstring` event (pinned by
  `test_class_alias`, whose handler `raise`s to assert it is never called).
- **I4.** The comment must be rendered **exactly once** (no duplication with the
  analyzer-driven path inside `Documenter.add_content`).

## 2. Mini-Python K fragment (the constructs the code uses)

Only the fragment actually exercised is modeled (the "mini-X" stopgap). Two
constructs that exceed the bundled arithmetic fast-path are handled per the
kit's guidance rather than fully modeled — see the **trusted base** at the end
of this section and `PROOF_OBLIGATIONS.md` PO-T1/PO-T2.

```k
// mini-autodoc.k  (fragment semantics — constructed, not machine-checked)
module MINI-AUTODOC-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX
  imports LIST            // models Python list[str] and the objpath list
  imports STRING-SYNTAX

  syntax Val  ::= Bool | Int | String | KList | "None" | "PycodeError"
  syntax Exp  ::= Val | Id
                | Exp "." Id                       [strict(1)]   // attribute read
                | "join" "(" Exp ")"               [strict]      // '.'.join(list)
                | "init"  "(" Exp ")"              [strict]      // list[:-1]  (all but last)
                | "last"  "(" Exp ")"              [strict]      // list[-1]
                | "pair"  "(" Exp "," Exp ")"      [seqstrict]   // (a, b) tuple key
                | "attrdocs" "(" Exp "," Exp ")"   [seqstrict]   // analyzer oracle (see below)
                | "copy"  "(" Exp ")"              [strict]      // list(L) shallow copy
                | "wrap"  "(" Exp ")"              [strict]      // [x]  singleton list
  syntax Stmt ::= Id "=" Exp                                      // local binding
                | "return" Exp                     [strict]
                | "if" Exp "{" Stmt "}" "else" "{" Stmt "}"        // truthiness branch
                | Stmt Stmt                         [left]
  syntax KResult ::= Val
endmodule

module MINI-AUTODOC
  imports MINI-AUTODOC-SYNTAX
  imports MAP
  configuration
    <k>      $PGM:Stmt        </k>
    <self>   $SELF:Map        </self>   // field name |-> Val : doc_as_attr, objpath, modname
    <ret>    .K               </ret>    // delivered return value

  // --- attribute read from the receiver object ---
  rule <k> self . F:Id => V ... </k> <self> ... F |-> V ... </self>

  // --- list ops used to build the attr_docs key (value semantics) ---
  rule join(L:KList)  => #join(L)                 // '.'.join(L), '' for empty
  rule init(L:KList)  => #init(L)                 // L[:-1]
  rule last(L:KList)  => #last(L)                 // L[-1]   (requires L nonempty, see PO-G1)
  rule pair(A, B)     => #pair(A, B)              // 2-tuple value
  rule copy(L:KList)  => L                         // list(L): fresh copy, value-equal to L
  rule wrap(V:Val)    => ListItem(V) .List         // [V]

  // --- the analyzer oracle (TRUSTED EXTERNAL, see trusted base) ---
  //   attrdocs(M, K) = the doc-comment line-list the ModuleAnalyzer of module M
  //   records under key K, or .List when absent / when M is not analyzable.
  //   This abstracts ModuleAnalyzer.for_module(M).analyze().attr_docs.get(K, []).
  rule attrdocs(M, K) => #oracleAttrDocs(M, K)

  // --- control / binding ---
  rule <k> X:Id = V:Val => .K ... </k> <self> S => S [ X <- V ] </self>
  rule <k> if C:Val { S1 } else { S2 } => S1 ... </k> requires truthy(C)
  rule <k> if C:Val { S1 } else { S2 } => S2 ... </k> requires notBool truthy(C)
  rule <k> return V:Val => .K ... </k> <ret> _ => V </ret>
  rule <k> S1:Stmt S2:Stmt => S1 ~> S2 ... </k>

  // Python truthiness for the values we use: non-empty list / non-None / true.
  syntax Bool ::= truthy(Val) [function]
  rule truthy(.List)          => false
  rule truthy(ListItem(_) _)  => true
  rule truthy(None)           => false
  rule truthy(true)           => true
  rule truthy(false)          => false
endmodule
```

**`try/except PycodeError` is modeled as a guard, not as exception semantics**
(per `formalize.md` §5 "Input-validation guards & exceptions"): on the verified
**in-domain** (analyzable-module) path the `try` body runs to completion; the
`except` arm is a *totalizing guard* whose effect (`return []`) is captured by
making the oracle `#oracleAttrDocs(M, K) = .List` whenever `M` is not analyzable.
This is recorded as **FINDING F2** (a *positive* guard finding) rather than
modeled as `raise`.

**Trusted base (this fragment's adequacy assumptions):**
- **PO-T1 — analyzer oracle.** `#oracleAttrDocs(M,K)` faithfully equals
  `list(ModuleAnalyzer.for_module(M).analyze().attr_docs.get(K, []))` on
  analyzable `M`, and `.List` otherwise (i.e. when `for_module`/`analyze` raise
  `PycodeError`). The parser/analyzer that populates `attr_docs` is upstream and
  unchanged by this fix.
- **PO-T2 — key adequacy.** The analyzer stores a module/class variable comment
  under key `(parent_qualname, name)`; for the documented object that key equals
  `('.'.join(self.objpath[:-1]), self.objpath[-1])`. (Established by reading
  `VariableCommentPicker.add_variable_comment` in `repo/sphinx/pycode/parser.py`;
  it is the *same* key the inherited analyzer path computes.)

## 3. Function contracts (reachability rules)

Logical (symbolic) variables are uppercase; program names lowercase. `OP` is the
symbolic `objpath` list, `M` the symbolic `modname`, `DAA` the symbolic
`doc_as_attr` flag. `K0 ≡ #pair(#join(#init(OP)), #last(OP))` is the lookup key,
and `C0 ≡ #oracleAttrDocs(M, K0)` the resolved comment.

### (GVC) — `get_variable_comment`
```k
claim
  <k> KEY = pair(join(init(self . objpath)), last(self . objpath))
      ANALYZER = self . modname
      return copy(attrdocs(ANALYZER, KEY))
    => .K ... </k>
  <self> ... objpath |-> OP  modname |-> M ... </self>
  <ret> _ => C0 </ret>
  requires OP =/=K .List            // PO-G1 : objpath is non-empty
  [all-path]
```
**Plain English:** for a non-empty `objpath`, `get_variable_comment()` returns
exactly the analyzer's comment list `C0` for key `K0` of the **alias's own
module** `M = self.modname` (a fresh copy; value-equal to the cached list), and
`.List` (`[]`) when that key is absent or `M` is unanalyzable.

### (GETDOC-COMMENT) — `get_doc`, alias branch, comment present
```k
claim
  <k> if (self . doc_as_attr) {
        COMMENT = «get_variable_comment»
        if COMMENT { return wrap(COMMENT) } else { return None }
      } else { «non-alias path» }
    => .K ... </k>
  <self> ... doc_as_attr |-> true  objpath |-> OP  modname |-> M ... </self>
  <ret> _ => ListItem(C0) .List </ret>
  requires (OP =/=K .List) andBool (C0 =/=K .List)
  [all-path]
```
**Plain English:** when documenting an alias (`doc_as_attr = true`) that **has** a
non-empty own comment `C0`, `get_doc()` returns `[C0]` — i.e. the comment is
delivered to `add_content` as a one-block docstring.

### (GETDOC-NONE) — `get_doc`, alias branch, no comment
```k
claim
  <k> if (self . doc_as_attr) {
        COMMENT = «get_variable_comment»
        if COMMENT { return wrap(COMMENT) } else { return None }
      } else { «non-alias path» }
    => .K ... </k>
  <self> ... doc_as_attr |-> true  objpath |-> OP  modname |-> M ... </self>
  <ret> _ => None </ret>
  requires (OP =/=K .List) andBool (C0 ==K .List)
  [all-path]
```
**Plain English:** for a comment-less alias, `get_doc()` returns `None`. This is
what suppresses both the aliased class's `__doc__` (I2) and the
`autodoc-process-docstring` event (I3).

## 4. Integration invariant — NO-DOUBLE (the property that makes the fix correct)

`get_doc` runs **inside** the inherited `Documenter.add_content`, which renders a
variable comment by **two** mutually-exclusive paths:

```python
if self.analyzer:                              # PATH-1 (analyzer-driven)
    attr_docs = self.analyzer.find_attr_docs() #   self.analyzer is for self.real_modname
    if self.objpath:
        key = ('.'.join(self.objpath[:-1]), self.objpath[-1])
        if key in attr_docs:
            no_docstring = True                #   <-- guards PATH-2 off
            ... render attr_docs[key] ...
if not no_docstring:                           # PATH-2 (get_doc-driven)
    docstrings = self.get_doc()
    if docstrings is None: pass
    else: ... render docstrings ...
```

Specified as a reachability claim over a mini-model of `add_content`'s control
(`A` = `self.analyzer`'s module = `self.real_modname`; `out` = list of rendered
docstring-blocks):

### (NO-DOUBLE)
```k
claim
  <k> «add_content alias body» => .K ... </k>
  <self> ... doc_as_attr |-> true  objpath |-> OP  modname |-> M
             real_modname |-> A  analyzer_present |-> P ... </self>
  <out> .List =>
     #renderedBlocks(P, A, M, K0)   // see postcondition table below
  </out>
  requires OP =/=K .List
  [all-path]
```
with the postcondition `#renderedBlocks` defined by case on whether **PATH-1**
fires (`P = true` ∧ `K0 ∈ attrdocs(A,·)`):

| PATH-1 fires? | comment `C0` (from `M`) | rendered comment-blocks | `get_doc` even called? |
|---|---|---|---|
| yes (`K0 ∈ attrdocs(A,·)`) | (any) | `attrdocs(A,K0)` once, via PATH-1 | **no** (`no_docstring=True`) |
| no  | `C0 ≠ []` | `[C0]` once, via PATH-2/get_doc | yes |
| no  | `C0 = []` | none (`get_doc=None`) | yes |

**Key invariant (I4):** PATH-1 sets `no_docstring=True` *iff* it renders, and
that flag gates PATH-2 off. Hence **at most one** path renders the comment — the
two are exhaustive and disjoint, so the comment appears **exactly once or zero
times**, never twice. When `A = M` (same-module / `automodule`-forced
`real_modname`) PATH-1 serves it; when `A ≠ M` (direct documentation of an alias
to a class in another module / a builtin / an unanalyzable module) PATH-1 misses
and PATH-2/`get_doc` serves it from `M = self.modname`. This case split is the
whole point of using `self.modname` (not `self.get_real_modname()`) in (GVC) —
see FINDINGS F6.

## 5. What is deliberately *not* specified (honest scope)

- **No termination obligation beyond the trivial.** All three functions are
  loop-free and call only terminating helpers (`for_module`/`analyze` terminate
  or raise; both are caught), so partial = total correctness here; nothing to
  prove. (Contrast the arithmetic examples whose loops need a variant.)
- **Full Python object/exception semantics, and the analyzer/parser internals,
  are trusted** (PO-T1/PO-T2), not re-derived — `[ESCALATION BOUNDARY]`, routed
  to the upstream `sphinx.pycode` parser which this fix does not change.
- **Rendering/`process_doc`/`autodoc-process-docstring`** are modeled only to the
  granularity needed for I3/I4 (whether `get_doc` returns `None` vs a list);
  their internals are out of scope.
