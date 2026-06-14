// mini-X (mini-print) semantics — the language fragment used by the matrix
// printers' _print_MatAdd / _print_MatMul, distilled to a string/list algebra.
//
// CONSTRUCTED, NOT MACHINE-CHECKED (FVK MVP: no kompile/kprove run here).
//
// Rationale for the fragment: the only datum _print_MatAdd reads from a term is
// its printed string  s = self._print(term)  and the single test
// s.startswith('-').  So a MatAdd term is modelled directly by its printed
// string.  _print_MatMul's relevant behaviour is "does the printed string begin
// with '-'?", which it controls through the sign of the numeric coefficient.
// We therefore model exactly: String concat (+String), the head-character test
// (startswith '-'), the tail (t[1:]), a working List l, pop(0), and a join.

module MATPRINT-SYNTAX
  imports STRING-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  // A program is one of the two routines under audit, applied to inputs.
  syntax Pgm ::= "printMatAdd" "(" Strings ")"      // str / latex _print_MatAdd
               | "printMatMul" "(" Coeff "," String ")" // sign-folding of _print_MatMul

  // Strings: the printed forms of the MatAdd terms, in canonical (already sorted)
  // order.  ".Strings" is the empty list.
  syntax Strings ::= List{String, ","}  [klabel(strs)]

  // Coeff: the numeric coefficient extracted by as_coeff_mmul().  We keep just
  // the trichotomy the code branches on, plus the "non-real" case the audit
  // found (e.g. the imaginary unit I).
  syntax Coeff ::= "neg"        // a negative real number (is_number & is_negative)
                 | "nonneg"     // zero or a positive real number
                 | "nonreal"    // a non-real number, e.g. I  (is_number true, is_negative FALSE)
                 | "sym"        // a non-number (symbolic) coefficient

  syntax KResult ::= String | Bool | Int
endmodule

module MATPRINT
  imports MATPRINT-SYNTAX
  imports STRING
  imports INT
  imports BOOL
  imports LIST

  configuration
    <k> $PGM:Pgm </k>
    <terms> .List </terms>   // remaining input term-strings (ListItem(String) ...)
    <l>     .List </l>       // working list: [sign_0, body_0, sign_1, body_1, ...]
    <res>   "" </res>        // assembled output string

  // ---- helpers on strings -------------------------------------------------
  // isNeg(S)  ==  S.startswith('-')
  syntax Bool   ::= isNeg(String)  [function]
  rule isNeg(S) => lengthString(S) >Int 0 andBool substrString(S, 0, 1) ==String "-"
  // tail(S)   ==  S[1:]
  syntax String ::= tail(String)   [function]
  rule tail(S) => substrString(S, 1, lengthString(S))

  // ======================= printMatAdd =====================================
  // Load the input list into <terms>, start the loop with empty <l>.
  rule <k> printMatAdd(SS:Strings) => #loop ... </k>
       <terms> _ => strs2list(SS) </terms>
       <l> _ => .List </l>

  // helper: turn the syntactic Strings list into a semantic List
  syntax List ::= strs2list(Strings) [function]
  rule strs2list(.Strings) => .List
  rule strs2list(S:String, SS:Strings) => ListItem(S) strs2list(SS)

  // The loop, faithful to:  for term in terms:
  //                             t = print(term)           (already the string S)
  //                             if t.startswith('-'): sign="-"; t=t[1:]
  //                             else: sign="+"
  //                             l.extend([sign, t])
  syntax KItem ::= "#loop" | "#assemble"

  rule <k> #loop => #loop ... </k>
       <terms> ListItem(S:String) => .List ... </terms>
       <l> ... .List => ListItem("-") ListItem(tail(S)) </l>
       requires isNeg(S)
  rule <k> #loop => #loop ... </k>
       <terms> ListItem(S:String) => .List ... </terms>
       <l> ... .List => ListItem("+") ListItem(S) </l>
       requires notBool isNeg(S)
  rule <k> #loop => #assemble ... </k>
       <terms> .List </terms>

  // Final assembly:  sign = l.pop(0); if sign=='+': sign=''; return sign + ' '.join(l)
  //   l after the loop = ListItem(sign_0) ListItem(body_0) ListItem(sign_1) ...
  //   pop(0) drops sign_0; head = "" if sign_0=="+" else "-".
  rule <k> #assemble => .K ... </k>
       <l> ListItem(SG0:String) REST:List => .List </l>
       <res> _ => (#head(SG0)) +String joinSp(REST) </res>

  syntax String ::= #head(String) [function]
  rule #head("+") => ""
  rule #head("-") => "-"

  // joinSp(L) == ' '.join(L)
  syntax String ::= joinSp(List) [function]
  rule joinSp(.List) => ""
  rule joinSp(ListItem(S:String)) => S
  rule joinSp(ListItem(S:String) ListItem(S2:String) REST:List)
       => S +String " " +String joinSp(ListItem(S2) REST)

  // ======================= printMatMul (sign-fold) =========================
  // Models str._print_MatMul's leading-sign decision and its TOTALITY.
  //   if c.is_number and c.is_negative:  sign="-"   (V2)
  //   else: sign=""
  // BODY is the '*'.join of the folded (non-negative) factors; it never starts
  // with '-'.  Output begins with '-' iff coefficient is a negative number.
  rule <k> printMatMul(neg, BODY:String) => "-" +String BODY ... </k>
  rule <k> printMatMul(nonneg, BODY:String) => BODY ... </k>
  rule <k> printMatMul(nonreal, BODY:String) => BODY ... </k>   // V2: no crash, sign=""
  rule <k> printMatMul(sym, BODY:String) => BODY ... </k>
  // NB (FINDING F1): V1 guarded with `c < 0`; on Coeff `nonreal` that test is a
  // TypeError, i.e. NO rule would fire — a stuck/aborted computation.  The
  // `nonreal` rule above exists only under the V2 guard `c.is_number & is_negative`.
endmodule
