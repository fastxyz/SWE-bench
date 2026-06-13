// mini-orm.k — a minimal K semantics for the *bug-relevant fragment* of the
// django__django-15957 fix.
//
// The fix (`_filter_prefetch_queryset` in
// django/db/models/fields/related_descriptors.py) replaces a Python slice
// `qs[low:high]` on a prefetch queryset with a window-function predicate
//
//     RowNumber() OVER (PARTITION BY <field> ORDER BY <ordering>)  in  (low, high]
//
// applied per partition (per parent row).  Everything that is genuinely
// Django/SQL machinery (join construction, the QUALIFY rewrite, ModelIterable,
// the in-memory grouping in prefetch_one_level) is part of the TRUSTED BASE and
// is *not* modelled here — see fvk/PROOF.md §"Trusted base".
//
// What IS modelled is the one piece of new arithmetic the fix introduces and the
// one place an off-by-one could hide: given a single partition that contains `m`
// related rows in queryset order (so the i-th row, 1-indexed, has RowNumber() = i),
// which rows does the predicate `RowNumber() > low AND RowNumber() <= high` keep,
// and is that exactly Python's `rows[low:high]`?
//
// We model the predicate as a counting loop `count_window_slice(m, low, high)`
// that walks k = 1..m and increments a counter whenever the SAME boolean the fix
// emits (`k > low and k <= high`) holds.  Proving its closed form equals the
// Python slice length `max(0, min(m,high) - low)` discharges the off-by-one.
//
// This is the "mini-X" stopgap mandated by the kit: only the constructs the
// fragment uses (Int, +, <=, >, and, if, while, =, +=, def, return, call).
// Constructed, NOT machine-checked (the MVP does not run kompile/kprove).

module MINI-ORM-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX

  syntax IExp ::= Id | Int
                | "(" IExp ")"            [bracket]
                > IExp "<=" IExp          [seqstrict, left]
                | IExp ">"  IExp          [seqstrict, left]
                | IExp "and" IExp         [seqstrict, left]
                > IExp "+"  IExp          [seqstrict, left]
                | Id "(" IExps ")"        [strict(2)]

  syntax Stmt ::= Id "=" IExp            [strict(2)]
                | Id "+=" IExp                                  // augmented assign
                | "if" IExp ":" Suite                          // single-armed if
                | "while" IExp ":" Suite
                | "def" Id "(" Ids ")" ":" Suite
                | "return" IExp           [strict]
                > Stmt Stmt               [left]

  syntax Suite ::= "{" Stmt "}"

  // Shared-spine argument lists so evaluated args cool to a KResult (Lesson 1.22).
  syntax Bot
  syntax Bots  ::= List{Bot,  ","}  [klabel(exps)]
  syntax Ints  ::= List{Int,  ","}  [klabel(exps)] | Bots
  syntax Ids   ::= List{Id,   ","}  [klabel(exps)] | Bots
  syntax IExps ::= List{IExp, ","}  [klabel(exps), seqstrict] | Ints | Ids

  syntax KResult ::= Int | Bool | Ints
endmodule

module MINI-ORM
  imports MINI-ORM-SYNTAX
  imports INT
  imports BOOL
  imports MAP
  imports LIST

  configuration
    <k> $PGM:Stmt </k>
    <store> .Map  </store>      // program variables   Id |-> Int
    <funcs> .Map  </funcs>      // function table       Id |-> def-closure
    <stack> .List </stack>      // call stack of state(continuation, store)

  syntax KItem ::= state(K, Map)

  // ---- expressions ----
  rule <k> X:Id => V ... </k> <store> ... X |-> V ... </store>
  rule <k> I1:Int +  I2:Int => I1 +Int  I2 ... </k>
  rule <k> I1:Int <= I2:Int => I1 <=Int I2 ... </k>
  rule <k> I1:Int >  I2:Int => I1 >Int  I2 ... </k>
  rule <k> B1:Bool and B2:Bool => B1 andBool B2 ... </k>

  // ---- assignment / augmented assignment ----
  rule <k> X:Id = I:Int => .K ... </k>
       <store> STORE => STORE [ X <- I ] </store>
  rule <k> X:Id += E:IExp => X = X + E ... </k>          // desugar

  // ---- if (single arm) ----
  rule <k> if true  : { S } => S ... </k>
  rule <k> if false : { _ } => .K ... </k>

  // ---- while: keep a frozen guard, re-evaluate a fresh copy each turn ----
  syntax KItem ::= "#whileLoop" "(" IExp "," Suite ")"
  rule <k> while B:IExp : S => #whileLoop(B, S) ... </k>
  rule <k> #whileLoop(B, { S }) => B ~> #branch(B, S) ... </k>
  syntax KItem ::= "#branch" "(" IExp "," Stmt ")"
  rule <k> true  ~> #branch(B, S) => S ~> #whileLoop(B, { S }) ... </k>
  rule <k> false ~> #branch(_, _) => .K ... </k>

  // ---- sequencing ----
  rule <k> S1:Stmt S2:Stmt => S1 ~> S2 ... </k>

  // ---- def / call / return ----
  rule <k> def F:Id ( PS:Ids ) : S => .K ... </k>
       <funcs> FS => FS [ F <- def F ( PS ) : S ] </funcs>
  rule <k> F:Id ( ARGS:Ints ) ~> CONT
        => bindParams(PS, ARGS) ~> S </k>
       <store> STORE => .Map </store>
       <funcs> ... F |-> def F ( PS:Ids ) : S ... </funcs>
       <stack> .List => ListItem(state(CONT, STORE)) ... </stack>
  rule <k> return I:Int ~> _ => I ~> CONT </k>
       <store> _ => STORE </store>
       <stack> ListItem(state(CONT, STORE)) => .List ... </stack>

  // bind a parameter list to an evaluated argument list, left to right
  syntax KItem ::= bindParams(Ids, Ints)
  rule <k> bindParams((P:Id, PS:Ids), (A:Int, AS:Ints)) => bindParams(PS, AS) ... </k>
       <store> STORE => STORE [ P <- A ] </store>
  rule <k> bindParams(.Ids, .Ints) => .K ... </k>
endmodule
