module MINI-JAVA-GEO-SYNTAX
  imports INT
  imports BOOL

  syntax Axis ::= "lat" | "lon"
  syntax Relation ::= "outside" | "crosses" | "inside"
  syntax Exp ::= "decode" "(" Axis "," Int ")"
               | "lowerConservative" "(" Axis "," Float ")"
               | "upperConservative" "(" Axis "," Float ")"
               | "componentPredicateTest" "(" Int "," Int ")"
endmodule

module MINI-JAVA-GEO
  imports MINI-JAVA-GEO-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Exp </k>

  // Compact model placeholder for the Java fragment audited in the markdown artifacts.
  // The proof obligations treat decode monotonicity and Component2D.relate soundness as
  // explicit assumptions, then prove the conservative-bound shape of V1.
endmodule
