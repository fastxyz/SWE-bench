// mini-python.k — minimal K semantics for the fragment used by
// _pytest.mark.structures.get_unpacked_marks (the class / MRO branch).
//
// SCOPE (deliberately tiny, "mini-X" stopgap per FVK):
//   The verified core is the *flattening loop* that turns a list of per-class
//   mark lists (one entry per class in the MRO, in MRO order) into one flat
//   mark list by in-order concatenation:
//
//       def get_unpacked_marks(mark_lists):     # mark_lists : list[list[Mark]]
//           mark_list = []
//           i = 0
//           while i < len(mark_lists):
//               mark_list = mark_list + mark_lists[i]   # .extend(item)
//               i = i + 1
//           return mark_list
//
//   This is the essence of the V2 code:
//       mark_lists = [x.__dict__.get("pytestmark", []) for x in obj.__mro__]
//       mark_list  = []
//       for item in mark_lists:
//           mark_list.extend(item)          # (item already a list in the common case)
//       return list(normalize_mark_list(mark_list))
//
//   The list-comprehension that BUILDS `mark_lists` from `obj.__mro__` is modeled
//   as the loop's *input*: `mark_lists` is given in MRO order (most-derived first).
//   `normalize_mark_list` (MarkDecorator -> Mark) and the non-list guard are
//   identity on the verified domain (every entry already a list of Marks) and are
//   recorded as Findings F2/F4, not modeled here.
//
// Marks are modeled as opaque Int identifiers (their identity is irrelevant to the
// concatenation property; what matters is that every element of every input list is
// preserved, in order). A "list of marks" is a K List; `mark_lists` is a List whose
// items are themselves Lists (List is a value sort, so nesting is fine).

module MINI-PYTHON-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX
  imports LIST

  syntax Exp ::= Id | Int | List
               | "len" "(" Exp ")"          [strict]
               | Exp "[" Exp "]"            [seqstrict]   // mark_lists[i] : element read
               > Exp "+" Exp                [seqstrict, left]  // list concatenation (++)
               | Exp "<" Exp                [seqstrict, left]

  syntax Stmt ::= Id "=" Exp                [strict(2)]
                | "while" Exp ":" Stmt
                | "return" Exp              [strict]
                | Stmt Stmt                 [left]
                | "def" Id "(" Id ")" ":" Stmt
                | "call" Id "(" Exp ")"     [strict(2)]   // call with one (evaluated) arg

  syntax KResult ::= Int | Bool | List
endmodule

module MINI-PYTHON
  imports MINI-PYTHON-SYNTAX
  imports INT
  imports BOOL
  imports LIST
  imports MAP

  configuration
    <k> $PGM:Stmt </k>
    <store> .Map </store>        // program variable |-> value (Int | List)
    <funcs> .Map </funcs>        // function name    |-> def(param, body)
    <stack> .List </stack>       // saved (continuation, store) frames
    <out>   .K  </out>           // the returned value

  // --- variable lookup / assignment ---------------------------------------
  rule <k> X:Id => V ... </k> <store> ... X |-> V ... </store>
  rule <k> X:Id = V:KResult => .K ... </k>
       <store> STORE => STORE [ X <- V ] </store>

  // --- len() and element read ---------------------------------------------
  rule <k> len(L:List) => size(L) ... </k>
  rule <k> L:List [ I:Int ] => L[I] ... </k>     // I-th element (an inner List)

  // --- list concatenation: juxtaposition of two Lists ---------------------
  rule <k> L1:List + L2:List => L1 L2 ... </k>

  // --- comparison ----------------------------------------------------------
  rule <k> I1:Int < I2:Int => I1 <Int I2 ... </k>

  // --- statement sequencing -----------------------------------------------
  rule <k> S1:Stmt S2:Stmt => S1 ~> S2 ... </k>

  // --- while: keep a frozen guard, evaluate a fresh copy ------------------
  //   while B : S   ==>   if (B fresh) { S ; while B : S } else { }
  //   modeled with a #whileLoop wrapper so the frozen guard survives heating.
  syntax KItem ::= "#whileLoop" "(" Exp "," Stmt ")"
  rule <k> while B:Exp : S:Stmt => #whileLoop(B, S) ~> while B : S ... </k>
  rule <k> #whileLoop(B:Exp, S:Stmt) ~> while _ : _ => S ~> while B : S ... </k>
       <store> STORE </store>
       requires evalGuard(B, STORE)            // body-taken branch
  rule <k> #whileLoop(B:Exp, S:Stmt) ~> while _ : _ => .K ... </k>
       <store> STORE </store>
       requires notBool evalGuard(B, STORE)    // exit branch
  // (evalGuard is a spec-level convenience; in a full run the guard `i < len(ml)`
  //  reduces via the rules above. Declared in VERIFICATION as a [function].)
  syntax Bool ::= evalGuard(Exp, Map) [function]

  // --- functions: def / call / return -------------------------------------
  rule <k> def F:Id ( P:Id ) : Body:Stmt => .K ... </k>
       <funcs> FS => FS [ F <- def(P, Body) ] </funcs>
  rule <k> call F:Id ( V:KResult ) ~> CONT => Body ... </k>
       <funcs> ... F |-> def(P:Id, Body:Stmt) ... </funcs>
       <store> STORE => ( P |-> V ) </store>
       <stack> .List => ListItem(state(CONT, STORE)) ... </stack>
  rule <k> return V:KResult ~> _ => CONT ... </k>
       <store> _ => STORE </store>
       <stack> ListItem(state(CONT, STORE)) => .List ... </stack>
       <out> _ => V </out>

  syntax KItem ::= state(K, Map) | "def" "(" Id "," Stmt ")"
endmodule
