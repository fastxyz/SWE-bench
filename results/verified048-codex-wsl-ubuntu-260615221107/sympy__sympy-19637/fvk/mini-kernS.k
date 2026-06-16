// Constructed FVK core for kernS control-flow safety.
// This is a minimal K-style model of the local bookkeeping around `kern`.
// It abstracts full SymPy parsing as `sympify`.

module MINI-KERNS-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Result ::= sympify(String)
                  | clearSympify(String, String)
                  | sympifyError(String)

  syntax KItem ::= kernS(String)
                 | afterRewrite(String, String, Bool)
                 | afterPlaceholder(String, String, Bool)

  syntax Bool ::= quoted(String)       [function]
                | hasLParen(String)    [function]
                | balancedParens(String) [function]
                | hasHackSpace(String) [function]
                | sympifyTypeError(String) [function]

  syntax String ::= stripSpaces(String) [function]
                  | hackRewrite(String) [function]
                  | freshKern(String)   [function]
                  | replaceSpaces(String, String) [function]
endmodule

module MINI-KERNS
  imports MINI-KERNS-SYNTAX
  imports BOOL
  imports STRING

  configuration
    <k> $PGM:K </k>
    <hit> false </hit>
    <kern> "" </kern>
    <kernDefined> false </kernDefined>

  rule <k> kernS(S:String) => sympify(S) ... </k>
    requires notBool hasLParen(S) orBool quoted(S)

  rule <k> kernS(S:String) => sympifyError("unmatched left parenthesis") ... </k>
    requires hasLParen(S)
     andBool notBool quoted(S)
     andBool notBool balancedParens(S)

  rule <k> kernS(S:String)
        => afterRewrite(hackRewrite(stripSpaces(S)),
                        stripSpaces(S),
                        hasHackSpace(hackRewrite(stripSpaces(S)))) ... </k>
    requires hasLParen(S)
     andBool notBool quoted(S)
     andBool balancedParens(S)

  rule <k> afterRewrite(R:String, _Old:String, false) => sympify(R) ... </k>
       <hit> false </hit>
       <kernDefined> false </kernDefined>

  rule <k> afterRewrite(R:String, Old:String, true)
        => afterPlaceholder(replaceSpaces(R, freshKern(R)),
                            Old,
                            sympifyTypeError(replaceSpaces(R, freshKern(R)))) ... </k>
       <hit> false => true </hit>
       <kern> _ => freshKern(R) </kern>
       <kernDefined> false => true </kernDefined>

  rule <k> afterPlaceholder(R:String, _Old:String, false)
        => clearSympify(R, K) ... </k>
       <hit> true </hit>
       <kern> K:String </kern>
       <kernDefined> true </kernDefined>

  rule <k> afterPlaceholder(_R:String, Old:String, true) => sympify(Old) ... </k>
       <hit> true => false </hit>
       <kernDefined> true </kernDefined>
endmodule
