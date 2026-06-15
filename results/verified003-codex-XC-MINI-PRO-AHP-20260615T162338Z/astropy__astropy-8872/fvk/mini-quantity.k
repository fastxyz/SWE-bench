module MINI-QUANTITY-SYNTAX
  imports BOOL-SYNTAX

  syntax DType ::= "float16" | "float32" | "float64" | "float128"
                 | "complex64" | "complex128"
                 | "intD" | "boolD" | "objectD" | "structuredD"
                 | "explicitD"

  syntax MaybeDType ::= "noDType" | "someDType" "(" DType ")"
  syntax Branch ::= "quantityCopy" | "quantityNoCopy" | "nonQuantity"
  syntax Exp ::= "construct" "(" Branch "," DType "," MaybeDType ")"
  syntax KResult ::= DType
endmodule

module MINI-QUANTITY
  imports MINI-QUANTITY-SYNTAX
  imports BOOL

  configuration <k> $PGM:Exp </k>

  syntax Bool ::= isInexact ( DType ) [function]
  rule isInexact(float16) => true
  rule isInexact(float32) => true
  rule isInexact(float64) => true
  rule isInexact(float128) => true
  rule isInexact(complex64) => true
  rule isInexact(complex128) => true
  rule isInexact(intD) => false
  rule isInexact(boolD) => false
  rule isInexact(objectD) => false
  rule isInexact(structuredD) => false
  rule isInexact(explicitD) => false

  syntax Bool ::= preserveDefault ( DType ) [function]
  rule preserveDefault(float16) => true
  rule preserveDefault(float32) => true
  rule preserveDefault(float64) => true
  rule preserveDefault(float128) => true
  rule preserveDefault(complex64) => true
  rule preserveDefault(complex128) => true
  rule preserveDefault(structuredD) => true
  rule preserveDefault(intD) => false
  rule preserveDefault(boolD) => false
  rule preserveDefault(objectD) => false
  rule preserveDefault(explicitD) => false

  rule <k> construct(B:Branch, D0:DType, someDType(D)) => D </k>
  rule <k> construct(quantityNoCopy, D, noDType) => D </k>
  rule <k> construct(quantityCopy, D, noDType) => D </k>
    requires preserveDefault(D)
  rule <k> construct(quantityCopy, D, noDType) => float64 </k>
    requires notBool preserveDefault(D)
  rule <k> construct(nonQuantity, D, noDType) => D </k>
    requires preserveDefault(D)
  rule <k> construct(nonQuantity, D, noDType) => float64 </k>
    requires notBool preserveDefault(D)
endmodule
