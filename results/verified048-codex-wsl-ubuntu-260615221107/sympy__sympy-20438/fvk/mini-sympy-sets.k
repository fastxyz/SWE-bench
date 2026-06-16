requires "domains.md"

module MINI-SYMPY-SETS-SYNTAX
  imports INT

  syntax Tri ::= "T" | "F" | "U"
  syntax FiniteFlag ::= "finiteTrue" | "finiteFalse" | "finiteUnknown"
  syntax Elem ::= Int | "(" Elem "," Elem ")" [klabel(pairElem)]
  syntax Elems ::= ".Elems" | Elem "," Elems
  syntax EnumResult ::= "enum" "(" Elems ")" | "enumTypeError" | "enumValueError"
  syntax Set ::= "FSet" "(" Elems ")" | "PSet" "(" FiniteFlag "," EnumResult ")"

  syntax KItem ::= "subset" "(" Set "," Set ")"
                 | "eqset" "(" Set "," Set ")"
                 | "containsAll" "(" Elems "," Set ")"
                 | "contains" "(" Set "," Elem ")"
                 | "and3" "(" Tri "," Tri ")"
                 | "tfn" "(" Tri ")"
endmodule

module MINI-SYMPY-SETS
  imports MINI-SYMPY-SETS-SYNTAX

  configuration <k> $PGM:K </k>

  rule <k> subset(PSet(finiteFalse, ER), FSet(ES)) => F ... </k>
  rule <k> subset(PSet(finiteUnknown, ER), FSet(ES)) => U ... </k>
  rule <k> subset(PSet(finiteTrue, enum(ES)), FSet(TES)) => containsAll(ES, FSet(TES)) ... </k>
  rule <k> subset(PSet(finiteTrue, enumTypeError), FSet(ES)) => U ... </k>
  rule <k> subset(PSet(finiteTrue, enumValueError), FSet(ES)) => U ... </k>

  rule <k> containsAll(.Elems, FS) => T ... </k>
  rule <k> containsAll(E , REST, FS) => and3(contains(FS, E), containsAll(REST, FS)) ... </k>

  // contains is an abstract oracle standing for SymPy FiniteSet.contains.
  // The spec file constrains only its fuzzy result shape.
  rule <k> and3(F, X) => F ... </k>
  rule <k> and3(T, X) => X ... </k>
  rule <k> and3(U, F) => F ... </k>
  rule <k> and3(U, T) => U ... </k>
  rule <k> and3(U, U) => U ... </k>

  rule <k> tfn(T) => T ... </k>
  rule <k> tfn(F) => F ... </k>
  rule <k> tfn(U) => U ... </k>

  rule <k> eqset(PSet(FF, ER), FSet(ES)) => tfn(and3(subset(PSet(FF, ER), FSet(ES)), subset(FSet(ES), PSet(FF, ER)))) ... </k>
  rule <k> eqset(FSet(ES), PSet(FF, ER)) => tfn(and3(subset(FSet(ES), PSet(FF, ER)), subset(PSet(FF, ER), FSet(ES)))) ... </k>
endmodule
