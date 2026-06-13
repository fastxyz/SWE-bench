// constraints.k — mini-Python fragment for the django__django-16560 V1 fix.
//
// SCOPE: this fragment models ONLY the language constructs that the V1 fix
// actually touches in django/db/models/constraints.py and
// django/contrib/postgres/constraints.py:
//
//   * attribute read with class-attribute fallback   (self.violation_error_code)
//   * guarded attribute assignment                   (if x is not None: self.a = x)
//   * the `None` value and `is not None` test
//   * dict/kwargs build + "lookup-with-default"       (deconstruct kwargs)
//   * method call / return                            (clone = Class(**deconstruct))
//   * an ABSTRACTED `raise` that records (message, code) in an <error> cell
//   * equality of two constraint records             (__eq__)
//
// NOTE (faithfulness / trusted base): the changed code paths contain NO loops and
// NO recursion. The pre-existing loops in validate() (iterating over fields /
// expressions / constraints) and the deprecated `*args` branch in __init__ are NOT
// re-implemented here; they are modeled by their *in-domain reduction* (FINDINGS
// F1, F2) and by opaque framing of the prefix that precedes the raise. Real Python
// exception control flow is NOT modeled; `raise` is abstracted to "write the
// (message, code) pair and stop" — see PROOF.md §Residual risk.

module CONSTRAINTS-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX
  imports STRING-SYNTAX

  // null models Python None. A constraint attribute value is a String code, the
  // sentinel null, or (for other fields) any Val.
  syntax Val  ::= Int | Bool | String | "null"

  syntax Exp  ::= Val | Id
               | "self" "." Id                       [strict(0)]   // attribute read
               | "kwget" "(" String ")"                             // kwargs.get(k, None)
               > Exp "isNotNull"                       [strict]      // `x is not None`
               > left:
                 Exp "===" Exp                         [seqstrict]   // structural equality

  syntax Stmt ::= "self" "." Id "=" Exp ";"            [strict(2)]   // attribute assign
               | "kwput" "(" String "," Exp ")" ";"    [strict(2)]   // kwargs[k] = v
               | "if" Exp ":" Stmt                     [strict(1)]   // guard, no else
               | "raiseErr" "(" Exp "," Exp ")" ";"    [seqstrict]   // raise ValidationError(m, c)
               | Stmt Stmt                             [left]
               | "skip" ";"
               | "return" Exp ";"                      [strict]

  syntax KResult ::= Val
endmodule

module CONSTRAINTS
  imports CONSTRAINTS-SYNTAX
  imports MAP
  imports K-EQUAL

  configuration
    <k> $PGM:Stmt </k>
    <self>  .Map </self>     // instance attributes:  Id  |-> Val   (missing key = class default)
    <kwargs>.Map </kwargs>   // deconstruct() output:  String |-> Val
    <error> null:Val </error>// abstracted raised error payload: null | errpair(Message, Code)
    <out>   null:Val </out>  // return value

  // --- attribute read: instance attr if present, else the class default `null`.
  //     (BaseConstraint declares `violation_error_code = None` at class level, and
  //      __init__ only sets the instance attr when a non-None code was passed.)
  rule <k> self . X => V ... </k> <self> ... X |-> V ... </self>
  rule <k> self . X => null ... </k> <self> SELF </self>
    requires notBool (X in_keys(SELF))

  // --- `x is not None`
  rule <k> null isNotNull => false ... </k>
  rule <k> V:Val isNotNull => true  ... </k> requires V =/=K null

  // --- structural equality of two evaluated values
  rule <k> V1:Val === V2:Val => V1 ==K V2 ... </k>

  // --- attribute assignment
  rule <k> self . X = V:Val ; => skip ; ... </k> <self> SELF => SELF [ X <- V ] </self>

  // --- kwargs build and "lookup with default None"
  rule <k> kwput ( S , V:Val ) ; => skip ; ... </k> <kwargs> KW => KW [ S <- V ] </kwargs>
  rule <k> kwget ( S ) => V ... </k> <kwargs> ... S |-> V ... </kwargs>
  rule <k> kwget ( S ) => null ... </k> <kwargs> KW </kwargs>
    requires notBool (S in_keys(KW))

  // --- guard (if with no else)
  rule <k> if true  : St => St   ... </k>
  rule <k> if false : St => skip ; ... </k>

  // --- abstracted raise: record (message, code) and stop the computation.
  //     errpair is an uninterpreted constructor used only to read the code back.
  syntax Val ::= "errpair" "(" Val "," Val ")"
  rule <k> raiseErr ( M:Val , C:Val ) ; ~> _ => .K </k> <error> null => errpair(M, C) </error>

  // --- sequencing, skip, return
  rule <k> skip ; => .K ... </k>
  rule <k> St1:Stmt St2:Stmt => St1 ~> St2 ... </k>
  rule <k> return V:Val ; ~> _ => .K </k> <out> _ => V </out>
endmodule
