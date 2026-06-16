// FVK artifact for scikit-learn__scikit-learn-15100.
// Constructed, not machine-checked. This mini semantics abstracts only the
// Unicode operations needed to distinguish the reported bug.

module MINI-PYTHON-UNICODE-SYNTAX
  imports BOOL-SYNTAX

  syntax UString
  syntax UString ::= nfkd(UString) [function]
                   | removeCombining(UString) [function]
                   | precomposedNTilde() [function]
                   | decomposedNTilde() [function]
                   | plainN() [function]

  syntax Bool ::= isCombiningFree(UString) [function]

  syntax Stmt ::= stripAccentsUnicode(UString)
  syntax KResult ::= UString
endmodule

module MINI-PYTHON-UNICODE
  imports MINI-PYTHON-UNICODE-SYNTAX
  imports BOOL

  configuration
    <k> $PGM:Stmt </k>
    <result> .K </result>

  // Current source model:
  // normalized = unicodedata.normalize('NFKD', s)
  // return ''.join([c for c in normalized if not unicodedata.combining(c)])
  rule
    <k> stripAccentsUnicode(S:UString) => .K </k>
    <result> _ => removeCombining(nfkd(S)) </result>

  // Abstract Unicode facts required by the public issue example.
  rule nfkd(precomposedNTilde()) => decomposedNTilde() [simplification]
  rule nfkd(decomposedNTilde()) => decomposedNTilde() [simplification]
  rule removeCombining(decomposedNTilde()) => plainN() [simplification]
  rule removeCombining(plainN()) => plainN() [simplification]
  rule isCombiningFree(removeCombining(S:UString)) => true [simplification]
endmodule

