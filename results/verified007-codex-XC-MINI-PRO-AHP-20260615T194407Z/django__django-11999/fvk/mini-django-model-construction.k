module MINI-DJANGO-MODEL-CONSTRUCTION-SYNTAX
  imports BOOL-SYNTAX
  imports INT-SYNTAX

  syntax Method ::= "none" | "user" | "generated" "(" Int ")"
  syntax Stmt ::= "contribute" "(" Int "," Bool ")"
endmodule

module MINI-DJANGO-MODEL-CONSTRUCTION
  imports MINI-DJANGO-MODEL-CONSTRUCTION-SYNTAX
  imports BOOL
  imports INT

  configuration
    <k> $PGM:Stmt </k>
    <directDisplay> none </directDisplay>
    <inheritedDisplay> none </inheritedDisplay>

  // A direct user-defined get_FOO_display() method is framed unchanged.
  rule <k> contribute(_:Int, true) => .K ... </k>
       <directDisplay> user </directDisplay>

  // If the direct class dictionary has no display method, generation occurs.
  // Inherited methods are intentionally not consulted by this transition.
  rule <k> contribute(FID:Int, true) => .K ... </k>
       <directDisplay> none => generated(FID) </directDisplay>

  // Fields without choices do not participate in get_FOO_display generation.
  rule <k> contribute(_:Int, false) => .K ... </k>
endmodule
