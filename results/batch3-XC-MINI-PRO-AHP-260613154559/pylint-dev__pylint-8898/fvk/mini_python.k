// mini-Python fragment semantics for pylint._check_regexp_csv
// -----------------------------------------------------------------------------
// "mini-X" stopgap (see fvk_materials/commands/formalize.md step 3): a MINIMAL K
// semantics covering ONLY the constructs the target function uses. Constructed,
// not machine-checked (the MVP does not run kompile/kprove).
//
// Target (repo/pylint/utils/utils.py, str branch of _check_regexp_csv):
//
//     regexps = [None]
//     open_curly = False
//     for char in value:
//         if char == "{":
//             open_curly = True
//         elif char == "}" and open_curly:
//             open_curly = False
//         if char == "," and not open_curly:
//             regexps.append(None)
//         else:
//             current = regexps[-1]
//             if current is None:
//                 regexps.append([char])
//             else:
//                 current.append(char)
//     for regexp in regexps:                       # (V2 result loop)
//         if regexp is None: continue
//         stripped = "".join(regexp).strip()
//         if stripped: yield stripped
//
// Fragment constructs actually used: a `for` loop over a string (a List of
// single-char tokens), char equality, boolean and/not, a List of "segments"
// where each segment is either the sentinel `none` or a List of chars,
// list append, last-element read, `is none`, string join, strip, and the
// emptiness test. NOTHING else is modelled.

module MINI-PYTHON-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX
  imports ID-SYNTAX

  // Expressions
  syntax Exp ::= Id | Int | Bool | String
               | "none"                                  // the sentinel
               | "(" Exp ")"                 [bracket]
               | Exp "==" Exp                [seqstrict]  // char/str equality
               | "not" Exp                   [strict]
               > Exp "and" Exp               [strict(1)]  // short-circuit on left
               | Exp "is" "none"             [strict(1)]
               | Exp "[" Exp "]"             [seqstrict]  // index (here: [-1])
               | "join" "(" Exp ")"          [strict]     // "".join(seg)
               | "strip" "(" Exp ")"         [strict]     // str.strip()

  // Statements
  syntax Stmt ::= Id "=" Exp                              [strict(2)]
               | Id "." "append" "(" Exp ")" [strict(2)]  // list.append
               | "yield" Exp                 [strict]
               | "continue"
               | "pass"
               | "if" Exp ":" Stmt "else" ":" Stmt        [strict(1)]
               | "if" Exp ":" Stmt                        [strict(1)]
               | "for" Id "in" Exp ":" Stmt  [strict(2)]  // iterate a value
               > Stmt Stmt                   [left]       // sequencing (loosest)

  syntax KResult ::= Int | Bool | String | Vals
endmodule

module MINI-PYTHON
  imports MINI-PYTHON-SYNTAX
  imports INT
  imports BOOL
  imports STRING
  imports LIST
  imports MAP

  // A program value: an Int/Bool/String, the sentinel `none`, or a List value
  // (used both for the input string-as-char-list and for `regexps`, a list of
  // segments). We keep List as K's builtin value sort (see k-framework.md
  // "Lists / arrays"): copy semantics & non-aliasing fall out for free EXCEPT
  // for the in-place `current.append(char)` alias, modelled explicitly below.
  syntax Val  ::= Int | Bool | String | "none" | List
  syntax Vals ::= List{Val, ","}                 [klabel(vals)]

  configuration
    <k> $PGM:Stmt </k>
    <store> .Map </store>      // Id |-> Val   (program variables)
    <out>   .List </out>       // the yielded result sequence

  // --- variables, literals -------------------------------------------------
  rule <k> X:Id => V ... </k> <store> ... X |-> V ... </store>
  rule <k> none => none ... </k>                                    [structural]

  // --- equality / boolean --------------------------------------------------
  rule <k> S1:String == S2:String => S1 ==String S2 ... </k>
  rule <k> not B:Bool => notBool B ... </k>
  rule <k> true  and E => E   ... </k>                              // short-circuit
  rule <k> false and _ => false ... </k>
  rule <k> V:Val is none => V ==K none ... </k>

  // --- list index  L[-1]  (last element) -----------------------------------
  rule <k> (L:List) [ I:Int ] => L { I } ... </k>                   // builtin index w/ neg support
  // (K's List supports L[I]; here only I = -1 is ever used, the last element.)

  // --- assignment ----------------------------------------------------------
  rule <k> X:Id = V:Val => pass ... </k>
       <store> STORE => STORE [ X <- V ] </store>

  // --- list.append(v) : rebind X to the extended list ----------------------
  // Plain append on a freshly-bound list variable.
  rule <k> X:Id . append ( V:Val ) => pass ... </k>
       <store> ... X |-> (L:List => L ListItem(V)) ... </store>

  // --- yield ---------------------------------------------------------------
  rule <k> yield V:Val => pass ... </k>
       <out> OUT => OUT ListItem(V) </out>

  // --- control flow --------------------------------------------------------
  rule <k> pass => .K ... </k>                                      [structural]
  rule <k> continue => .K ... </k>                                  [structural]
  rule <k> S1:Stmt S2:Stmt => S1 ~> S2 ... </k>                     [structural]
  rule <k> if true  : S          => S    ... </k>
  rule <k> if false : _          => .K   ... </k>
  rule <k> if true  : S else : _ => S    ... </k>
  rule <k> if false : _ else : S => S    ... </k>

  // --- for over a List value (the string is a List of 1-char Strings) ------
  // Bounded iteration: a `for` over a value List is structural and ALWAYS
  // terminates (its length is fixed) -- this gives TOTAL correctness, not just
  // partial, for both loops in the function.
  rule <k> for X in (ListItem(V:Val) Rest:List) : S
        => (X = V) ~> S ~> for X in Rest : S ... </k>
  rule <k> for _ in .List : _ => .K ... </k>                        [structural]

  // --- join / strip : spec vocabulary over a char-list segment -------------
  // join(.List)="" ; join(ListItem(c) R)= c +String join(R) ; strip = trim WS.
  rule <k> join ( L:List ) => joinChars(L) ... </k>
  rule <k> strip ( S:String ) => trimWS(S) ... </k>

  syntax String ::= joinChars(List) [function]
  rule joinChars(.List) => ""
  rule joinChars(ListItem(C:String) R:List) => C +String joinChars(R)

  syntax String ::= trimWS(String) [function]   // strip leading/trailing WS
endmodule
