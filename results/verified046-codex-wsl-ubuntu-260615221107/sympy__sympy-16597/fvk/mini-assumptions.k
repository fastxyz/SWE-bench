// FVK artifact for sympy__sympy-16597.
// Constructed, not machine-checked in this session.
//
// This is a deliberately small semantics for the old assumptions closure
// relevant to the issue. It preserves the observable property under audit:
// whether a starting assumption set reaches `finite`.

module MINI-ASSUMPTIONS-SYNTAX
  imports BOOL-SYNTAX
  imports SET-SYNTAX

  syntax Fact ::= "finite"
                | "rational"
                | "integer"
                | "even"
                | "odd"
                | "real"

  syntax KItem ::= "close" "(" Set ")"
                 | "done" "(" Set ")"
endmodule

module MINI-ASSUMPTIONS
  imports MINI-ASSUMPTIONS-SYNTAX
  imports BOOL
  imports SET

  configuration <k> $PGM:K </k>

  syntax Bool ::= has(Set, Fact) [function]
  rule has(FS:Set, F:Fact) => F in FS

  syntax Bool ::= canStep(Set) [function]
  rule canStep(FS:Set) =>
       (has(FS, even)     andBool notBool has(FS, integer))
  orBool (has(FS, odd)      andBool notBool has(FS, integer))
  orBool (has(FS, integer)  andBool notBool has(FS, rational))
  orBool (has(FS, rational) andBool notBool has(FS, finite))
  orBool (has(FS, rational) andBool notBool has(FS, real))

  // Projection of `even == integer & !odd`.
  rule <k> close(FS:Set) => close(FS SetItem(integer)) </k>
    requires has(FS, even) andBool notBool has(FS, integer)

  // Projection of `odd == integer & !even`.
  rule <k> close(FS:Set) => close(FS SetItem(integer)) </k>
    requires has(FS, odd) andBool notBool has(FS, integer)

  // Existing old-assumptions rule: `integer -> rational`.
  rule <k> close(FS:Set) => close(FS SetItem(rational)) </k>
    requires has(FS, integer) andBool notBool has(FS, rational)

  // V1 rule under audit: `rational -> finite`.
  rule <k> close(FS:Set) => close(FS SetItem(finite)) </k>
    requires has(FS, rational) andBool notBool has(FS, finite)

  // Existing old-assumptions rule kept for frame checking: `rational -> real`.
  rule <k> close(FS:Set) => close(FS SetItem(real)) </k>
    requires has(FS, rational) andBool notBool has(FS, real)

  rule <k> close(FS:Set) => done(FS) </k>
    requires notBool canStep(FS)
endmodule
