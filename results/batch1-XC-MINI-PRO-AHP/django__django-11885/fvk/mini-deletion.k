// fvk/mini-deletion.k
// CONSTRUCTED, NOT MACHINE-CHECKED.  Mini-X K fragment (see
// fvk_materials/commands/formalize.md step 3): it models ONLY the constructs the
// heart of the V1 fix uses — the fold in Collector.related_objects:
//
//     predicate = reduce(or_, [Q(f__in objs) for f in related_fields])
//
// desugared to the imperative loop actually run by functools.reduce:
//
//     acc = atom(0)
//     i = 1
//     while i < n:
//         acc = acc or atom(i)
//         i = i + 1
//     return acc
//
// `atom(K)` abstracts the single-field FK-IN filter  Q(field_K __in objs);
// `_or_`    abstracts operator.or_ on querysets (the SQL OR of two WHERE clauses).
// The row-set meaning of a predicate is the spec-only abstraction `rows(_)`
// declared in mini-deletion-spec.k (cf. isSorted/bag in the insertion-sort
// example).  This deliberately small fragment is the MVP stopgap; a full
// Python-in-K is the roadmap.

module MINI-DELETION-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX

  // The disjunctive predicate the fold builds.  Once its operands are values it
  // is itself a value (KResult): `_or_` is a pure constructor that is never
  // rewritten away — exactly like operator.or_ on querysets only *records* the
  // OR, it does not collapse the two IN-lists.
  syntax Pred ::= "noPred"
                | "atom" "(" IExp ")"        [strict]
                > Pred "or" Pred             [seqstrict, left]

  syntax IExp ::= Id | Int
                | "(" IExp ")"               [bracket]
                > IExp "<" IExp              [seqstrict, left]
                > IExp "+" IExp              [seqstrict, left]

  syntax Stmt ::= Id "=" Pred                [strict(2)]   // acc = <predicate>
                | Id "=" IExp                [strict(2)]   // i   = <int>
                | "if" IExp "{" Stmt "}" "else" "{" Stmt "}"   [strict(1)]
                | "while" IExp "{" Stmt "}"
                | "skip"
                | "return" Id
                > Stmt Stmt                  [left]

  syntax KResult ::= Int | Bool | Pred
endmodule

module MINI-DELETION
  imports MINI-DELETION-SYNTAX
  imports INT
  imports BOOL
  imports MAP

  configuration
    <k>     $PGM:Stmt </k>
    <store> .Map       </store>
    <out>   noPred     </out>

  // --- expressions ---
  rule <k> X:Id => V ... </k> <store> ... X |-> V ... </store>
  rule <k> I1:Int <  I2:Int => I1  <Int I2 ... </k>
  rule <k> I1:Int +  I2:Int => I1 +Int I2 ... </k>
  // atom(Int) and (Pred or Pred) need NO rule: with their operands evaluated
  // they are KResults — the built AST is the normal form (the recorded OR).

  // --- statements ---
  rule <k> X:Id = P:Pred => .K ... </k>
       <store> STORE => STORE [ X <- P ] </store>
    requires isKResult(P)
  rule <k> X:Id = I:Int => .K ... </k>
       <store> STORE => STORE [ X <- I ] </store>
  rule <k> S1:Stmt S2:Stmt => S1 ~> S2 ... </k>
  rule <k> skip => .K ... </k>
  rule <k> if true  { S1 } else { _  } => S1 ... </k>
  rule <k> if false { _  } else { S2 } => S2 ... </k>
  // `while` keeps the guard TEXTUAL (frozen) and re-evaluates a FRESH copy each
  // turn — the frozen-guard requirement from k-framework.md §3.
  rule <k> while B { S } => if B { S while B { S } } else { skip } ... </k>
  rule <k> return X:Id => .K ... </k>
       <store> ... X |-> V ... </store>
       <out> _ => V </out>
endmodule
