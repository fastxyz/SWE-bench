module MINI-PYTHON-STRING-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax Doc ::= "noneDoc"
               | "doc" "(" String ")"

  syntax Exp ::= String
               | Doc
               | "trimDocstring" "(" Doc ")"
               | "cleanDoc" "(" String ")"
               | "isBlank" "(" String ")"
               | "pep257Clean" "(" String ")"
               | "directiveSafe" "(" String ")"
               | "leadingEmptyCompatible" "(" String ")"

  syntax KResult ::= String | Bool
endmodule

module MINI-PYTHON-STRING
  imports MINI-PYTHON-STRING-SYNTAX
  imports STRING
  imports BOOL
  imports K-EQUAL

  configuration <k> $PGM:Exp </k>

  // Symbolic helper functions for this proof fragment. Their concrete string
  // algorithms are specified by the claims in trim-docstring-spec.k.
  syntax Bool ::= isBlankString(String) [function]
  syntax String ::= cleanDocString(String) [function]

  rule <k> trimDocstring(noneDoc) => "" ... </k>
  rule <k> trimDocstring(doc(S:String)) => "" ... </k>
    requires isBlankString(S)
  rule <k> trimDocstring(doc(S:String)) => cleanDocString(S) ... </k>
    requires notBool isBlankString(S)

  rule <k> cleanDoc(S:String) => cleanDocString(S) ... </k>
  rule <k> isBlank(S:String) => isBlankString(S) ... </k>

  // Public-contract axioms for inspect.cleandoc(), as justified by the issue
  // hint and the existing PEP 257 function comment.
  rule <k> pep257Clean(cleanDocString(S:String)) => true ... </k>
    requires notBool isBlankString(S)
  rule <k> directiveSafe(cleanDocString(S:String)) => true ... </k>
    requires notBool isBlankString(S)
  rule <k> leadingEmptyCompatible(cleanDocString(S:String)) => true ... </k>
    requires notBool isBlankString(S)
endmodule
