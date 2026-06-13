# SPEC.md — formal specification of `get_child_arguments()`

**Target:** `repo/django/utils/autoreload.py`, function `get_child_arguments()`
(the V1 fix for django__django-13837 is applied).

**Mode:** intent-spec (align *issue intent* ↔ *code* ↔ *formal contract*), default
**partial correctness** (the function has no unbounded loop — see §6 — so termination is
in fact trivial and we get total correctness modulo the filesystem oracle).

> Status: **constructed, not machine-checked.** No K toolchain is run here; the `.k`
> blocks below are a faithful mini-Python model used to drive the case analysis in
> [`PROOF.md`](PROOF.md). The mini-X fragment is a deliberate stopgap (per the kit).

---

## 1. Intent (what the function must do)

Evidence: `benchmark/PROBLEM.md` (the ticket), the function name/docstring, the inline
comment added in V1, and the surrounding autoreload restart machinery
(`restart_with_reloader` → `subprocess.run(get_child_arguments(), …)`).

`get_child_arguments()` reconstructs the **argv that re-launches the *same* Python
program the *same* way it was originally started**, so the autoreloader's child process
behaves identically to the parent. The ticket's operational criterion for the `-m` case
is quoted verbatim and is the spec we adopt:

> Python was started with `-m pkg` **iff** `__main__.__spec__` is not `None` **and**
> `__main__.__spec__.parent == "pkg"`; for a directory/zipfile launch `__spec__` is not
> `None` but `__spec__.parent == ""`.

So the intended **contract** is a four-way branch on the launch mode (mutually exclusive,
evaluated in order):

| # | Launch mode (guard) | Required result |
|---|---|---|
| **M** | `-m` module launch: `spec ≠ None ∧ parent ≠ ""` | `[exe] ++ Wf(W) ++ ["-m", parent] ++ argv[1:]` |
| **X** | script path missing **and** `<py>.exe` exists (Windows console-script) | `[str(<py>.exe)] ++ argv[1:]` |
| **R** | script path missing **and** `<py>-script.py` exists | `[exe] ++ Wf(W) ++ [str(<py>-script.py)] ++ argv[1:]` |
| **S** | otherwise (normal script / dir / zipfile, `argv[0]` exists) | `[exe] ++ Wf(W) ++ argv` |
| **!** | script path missing and neither entry-point exists | raise `RuntimeError` |

where `exe = sys.executable`, `W = sys.warnoptions`, `Wf(W) = ['-W'+o for o in W]`,
`argv = sys.argv`, `<py> = Path(argv[0])`, `<py>.exe = <py>.with_suffix('.exe')`,
`<py>-script.py = <py>.with_name('%s-script.py' % <py>.name)`.

## 2. Precondition (the verified domain)

- **D1.** `len(sys.argv) ≥ 1` (so `sys.argv[0]` / `Path(sys.argv[0])` is defined).
- **D2.** `getattr(__main__, '__spec__', None)` is either `None` **or** a real
  `importlib.machinery.ModuleSpec` whose `.parent` is a `str`.
- **D3 (the `-m` sub-domain that makes branch M *faithful*).** When `spec ≠ None ∧
  parent ≠ ""`, the launch was `python -m <pkg>` where **`<pkg>` is a package** (has a
  `__main__.py`), i.e. `spec.name == parent + ".__main__"`. On this sub-domain
  `parent == <pkg>` and re-launching `-m parent` reproduces the original launch.
  *(The complement of D3 — running a non-package sub-module via `-m` — is **out of
  domain** and is recorded as Finding F1; see [`FINDINGS.md`](FINDINGS.md).)*

Rationale for D3: CPython's `ModuleSpec.parent` returns `name` for a package spec and
`name.rpartition('.')[0]` for a non-package spec. Running `python -m PKG` (PKG a package)
makes `__main__` the spec of `PKG.__main__` (a *non*-package), so `parent =
"PKG.__main__".rpartition('.')[0] = "PKG"` ✓. This is exactly the ticket's use case
("a package with its own `__main__` sub-module overriding runserver").

## 3. Postcondition

Exactly the result column of the §1 table for whichever guard holds. The guards
partition the input space (proof obligation **PO-EXH**, [`PROOF_OBLIGATIONS.md`](PROOF_OBLIGATIONS.md)),
so the postcondition is single-valued.

## 4. mini-Python fragment semantics — `autoreload.k` (constructed model)

Only the constructs `get_child_arguments` actually uses: list values + concatenation,
`if/elif/else`, attribute read (`.parent`), `is not None`, short-circuit `and`,
`return`, `raise`, and four **oracle functions** for the parts that are not where
correctness lives (filesystem existence, path surgery, the `-W` comprehension, list
head/tail). Oracles are uninterpreted `[function]` symbols — the proof never inspects
their internals, only that branch selection is faithful to the guards.

```k
// autoreload.k  — mini-Python fragment for get_child_arguments (branch logic)
module AUTORELOAD-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX
  imports ID-SYNTAX
  imports LIST

  syntax Val  ::= Bool | String | List | "None" | Spec
  syntax Spec ::= "spec" "(" String ")"            // a __spec__ object; arg is .parent

  syntax Exp ::= Val | Id
               | Exp "." "parent"          [strict]           // attribute read on a Spec
               | Exp "isNot" "None"        [strict]           // identity test vs None
               | Exp "and" Exp             [strict(1)]        // short-circuit (Python `and`)
               | Exp "++" Exp              [seqstrict]        // list concatenation
               | "exists" "(" Exp ")"      [strict]           // FS oracle  : Path -> Bool
               | "withExe" "(" Exp ")"     [strict]           // .with_suffix('.exe')
               | "withScr" "(" Exp ")"     [strict]           // .with_name('%s-script.py')
               | "str" "(" Exp ")"         [strict]           // str(path)
               | "hd" "(" Exp ")"          [strict]           // sys.argv[0]  (as 1-elt List)
               | "tl" "(" Exp ")"          [strict]           // sys.argv[1:]
               | "base" "(" Exp "," Exp ")"[strict]           // [exe] ++ ['-W'+o for o in W]

  syntax Stmt ::= Id "=" Exp               [strict(2)]
                | Id "+=" Exp              [strict(2)]
                | "return" Exp             [strict]
                | "raise" String
                | "if" Exp ":" Stmt "else" ":" Stmt   [strict(1)]
                | Stmt Stmt                [left]
  syntax KResult ::= Val
endmodule

module AUTORELOAD
  imports AUTORELOAD-SYNTAX
  imports BOOL
  imports STRING

  configuration
    <k> $PGM:Stmt </k>
    <store>  .Map </store>      // exe|->String  warn|->List  argv|->List  spec|->Val
    <out>    .K   </out>        // returned List, or #raise(String)

  // --- names & assignment ---
  rule <k> X:Id => V ... </k> <store> ... X |-> V ... </store>
  rule <k> X:Id = V:Val => .K ... </k> <store> STORE => STORE [ X <- V ] </store>
  rule <k> X:Id += L:List => .K ... </k>
       <store> ... X |-> (Old:List => Old ++ L) ... </store>

  // --- list concat (value level) ---
  rule <k> L1:List ++ L2:List => L1 L2 ... </k>      // K List is associative ++/.List

  // --- spec / guard primitives ---
  rule <k> None        isNot None => false ... </k>
  rule <k> spec(P)     isNot None => true  ... </k>
  rule <k> spec(P) . parent       => P     ... </k>
  rule <k> true  and E2 => E2    ... </k>            // short-circuit
  rule <k> false and _  => false ... </k>
  // the truthiness of a String guard `__main__.__spec__.parent`:
  rule <k> S:String => S =/=String "" ... </k>  [owise-as-bool-context]   // see note*

  // --- control flow ---
  rule <k> if true  : St else : _   => St ... </k>
  rule <k> if false : _  else : Sf  => Sf ... </k>
  rule <k> return V:Val => .K ... </k> <out> _ => V </out>
  rule <k> raise Msg    => .K ... </k> <out> _ => #raise(Msg) </out>
  rule <k> St1:Stmt St2:Stmt => St1 ~> St2 ... </k>
endmodule
```

`*` Note: Python uses the *string itself* as the `and` operand and its **truthiness**
(`"" → False`, non-empty → `True`) decides the branch. The model makes that explicit by
reducing the `parent` string to `S =/=String ""` in the boolean context of the `if`
guard; this is the one modelling choice and it is exactly Python's `bool(str)` rule.

## 5. Reachability claims — `autoreload-spec.k` (constructed model)

The program text below is the V1 body, transliterated into the fragment. `SP` is the
symbolic `__spec__` (`None` or `spec(P)`); `E`,`W`,`A` are symbolic `exe`,`warnoptions`,
`argv`. One `[all-path]` claim per reachable outcome; there is **no loop**, hence **no
circularity** — the proof is pure **Case Analysis** (see [`PROOF.md`](PROOF.md)).

```k
requires "autoreload.k"
module AUTORELOAD-SPEC
  imports AUTORELOAD
  imports K-EQUAL

  // body(SP) abbreviates the function body with spec = SP:
  //   args = base(exe,warn)
  //   if (spec isNot None) and (spec.parent) :
  //       args += ["-m"] ++ [spec.parent] ++ tl(argv) ; return args
  //   else:
  //       if not exists(hd(argv)):
  //           if   exists(withExe(hd(argv))): return [str(withExe(hd(argv)))] ++ tl(argv)
  //           else if exists(withScr(hd(argv))): return args ++ [str(withScr(hd(argv)))] ++ tl(argv)
  //           else: raise "Script ... does not exist."
  //       else:
  //           args += argv ; return args

  // (M) -m module launch
  claim <k> body(spec(P)) => .K </k>
        <store> exe|->E warn|->W argv|->A spec|->spec(P) </store>
        <out>  _ => base(E,W) ++ ListItem("-m") ++ ListItem(P) ++ tl(A) </out>
    requires P =/=String ""                                            [all-path]

  // (X) Windows .exe console-script entry point
  claim <k> body(SP) => .K </k>
        <store> exe|->E warn|->W argv|->A spec|->SP </store>
        <out>  _ => ListItem(str(withExe(hd(A)))) ++ tl(A) </out>
    requires (SP ==K None orBool specParentEmpty(SP))
     andBool exists(hd(A)) ==K false
     andBool exists(withExe(hd(A))) ==K true                           [all-path]

  // (R) -script.py entry point
  claim <k> body(SP) => .K </k>
        <store> exe|->E warn|->W argv|->A spec|->SP </store>
        <out>  _ => base(E,W) ++ ListItem(str(withScr(hd(A)))) ++ tl(A) </out>
    requires (SP ==K None orBool specParentEmpty(SP))
     andBool exists(hd(A)) ==K false
     andBool exists(withExe(hd(A))) ==K false
     andBool exists(withScr(hd(A))) ==K true                           [all-path]

  // (S) normal script / directory / zipfile launch
  claim <k> body(SP) => .K </k>
        <store> exe|->E warn|->W argv|->A spec|->SP </store>
        <out>  _ => base(E,W) ++ A </out>
    requires (SP ==K None orBool specParentEmpty(SP))
     andBool exists(hd(A)) ==K true                                    [all-path]

  // (!) error path — modelled as reaching #raise(_) (raise is at the fragment edge)
  claim <k> body(SP) => .K </k>
        <store> exe|->E warn|->W argv|->A spec|->SP </store>
        <out>  _ => #raise("Script does not exist.") </out>
    requires (SP ==K None orBool specParentEmpty(SP))
     andBool exists(hd(A)) ==K false
     andBool exists(withExe(hd(A))) ==K false
     andBool exists(withScr(hd(A))) ==K false                          [all-path]

  // helper: parent-empty test (folds spec(P) with P=="" into the else branch)
  syntax Bool ::= specParentEmpty(Val) [function]
  rule specParentEmpty(None)    => true            // None has no -m parent
  rule specParentEmpty(spec(P)) => P ==String ""
endmodule
```

## 6. Loops / recursion / termination

- The only repetition is the list comprehension `['-W%s' % o for o in sys.warnoptions]`,
  abstracted as the oracle `base(E,W)` / `Wf(W)`. Its own (trivial) obligation is a
  **structural list map** — `Wf([]) = []`, `Wf([h]++t) = ['-W'+h] ++ Wf(t)` — discharged
  by structural induction with **no side condition** (PO-WF in
  [`PROOF_OBLIGATIONS.md`](PROOF_OBLIGATIONS.md)). It is not where any finding lives.
- There is **no `while`/`for` over program state and no recursion**, so there is **no
  loop-invariant circularity**. Control flow is straight-line + nested `if`. Hence the
  function **always terminates** (modulo the total `base`/`exists`/path oracles), so the
  partial-correctness proof is in fact total here.

## 7. Trusted base / soundness assumptions

1. Adequacy of the mini-Python fragment (§4) to the real Python semantics of this body.
2. The four oracles (`exists`, `withExe`, `withScr`, `base`) faithfully model
   `Path.exists`, `Path.with_suffix('.exe')`, `Path.with_name(...-script.py)`, and the
   `[sys.executable] + ['-W'+o …]` prefix.
3. **D3** — the `-m` target is a *package* — is an *intent* assumption about the launch,
   not a checkable runtime fact; outside it, Finding **F1** applies.
4. Reachability proof-system metatheory + `kprove` (not run here: "constructed, not
   machine-checked").
