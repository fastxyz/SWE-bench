module MINI-SCHEMA-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Name ::= String
  syntax Cols ::= String

  // constraint(name, columns, index, unique, excluded)
  syntax Constraint ::= constraint(Name, Cols, Bool, Bool, Bool)
  syntax Constraints ::= ".Constraints"
                       | Constraint ";" Constraints [right]

  syntax Names ::= ".Names"
                 | Name "," Names [right]

  syntax Result ::= deleted(Name)
                  | wrongCount(Names)

  syntax Names ::= filterIndexOnly(Cols, Constraints) [function]
                 | filterIndexTogetherDelete(Cols, Constraints) [function]
  syntax Result ::= deleteOne(Names) [function]

  syntax Cmd ::= deleteIndexTogetherV0(Cols, Constraints)
               | deleteIndexTogetherV1(Cols, Constraints)

  syntax KResult ::= Result
endmodule

module MINI-SCHEMA
  imports MINI-SCHEMA-SYNTAX
  imports BOOL

  configuration <k> $PGM:Cmd </k>

  // V0 models the failing lookup: {'index': True}.
  rule filterIndexOnly(CS, .Constraints) => .Names
  rule filterIndexOnly(CS, constraint(N, CS, true, U, false) ; REST)
    => N , filterIndexOnly(CS, REST)
  rule filterIndexOnly(CS, constraint(N, CS, false, U, false) ; REST)
    => filterIndexOnly(CS, REST)
  rule filterIndexOnly(CS, constraint(N, CS, I, U, true) ; REST)
    => filterIndexOnly(CS, REST)

  // V1 models the repaired lookup: {'index': True, 'unique': False}.
  rule filterIndexTogetherDelete(CS, .Constraints) => .Names
  rule filterIndexTogetherDelete(CS, constraint(N, CS, true, false, false) ; REST)
    => N , filterIndexTogetherDelete(CS, REST)
  rule filterIndexTogetherDelete(CS, constraint(N, CS, true, true, false) ; REST)
    => filterIndexTogetherDelete(CS, REST)
  rule filterIndexTogetherDelete(CS, constraint(N, CS, false, U, false) ; REST)
    => filterIndexTogetherDelete(CS, REST)
  rule filterIndexTogetherDelete(CS, constraint(N, CS, I, U, true) ; REST)
    => filterIndexTogetherDelete(CS, REST)

  rule deleteOne(N , .Names) => deleted(N)
  rule deleteOne(.Names) => wrongCount(.Names)
  rule deleteOne(N1 , N2 , REST) => wrongCount(N1 , N2 , REST)

  rule <k> deleteIndexTogetherV0(CS, CONSTRAINTS)
        => deleteOne(filterIndexOnly(CS, CONSTRAINTS)) </k>
  rule <k> deleteIndexTogetherV1(CS, CONSTRAINTS)
        => deleteOne(filterIndexTogetherDelete(CS, CONSTRAINTS)) </k>
endmodule
