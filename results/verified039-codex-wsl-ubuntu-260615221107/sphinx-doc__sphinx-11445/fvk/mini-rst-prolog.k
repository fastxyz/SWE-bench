// Constructed FVK artifact; not machine-checked in this session.
// Minimal semantics for the line-order property of prepend_prolog().

module MINI-RST-PROLOG-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax LineKind ::= "Docinfo" | "FieldTitle" | "Underline" | "Other" | "Generated" | "PrologLine"
  syntax Line ::= line(String, LineKind)
  syntax Lines ::= ".Lines" | consLine(Line, Lines) [right]
  syntax Prolog ::= ".Prolog" | consProlog(String, Prolog) [right]
  syntax Pgm ::= prepend(Prolog, Lines)
  syntax KResult ::= Lines | Int | Bool
endmodule

module MINI-RST-PROLOG
  imports MINI-RST-PROLOG-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Pgm </k>

  syntax Line ::= blank() [function]
  rule blank() => line("", Generated)

  syntax Bool ::= nonEmptyProlog(Prolog) [function]
  rule nonEmptyProlog(.Prolog) => false
  rule nonEmptyProlog(consProlog(_, _)) => true

  syntax Int ::= size(Lines) [function]
  rule size(.Lines) => 0
  rule size(consLine(_, LS)) => 1 +Int size(LS)

  syntax Line ::= nth(Lines, Int) [function]
  rule nth(consLine(L, _), 0) => L
  rule nth(consLine(_, LS), I) => nth(LS, I -Int 1) requires I >Int 0

  syntax Bool ::= regexDocinfo(Line) [function]
  rule regexDocinfo(line(_, Docinfo)) => true
  rule regexDocinfo(line(_, FieldTitle)) => true
  rule regexDocinfo(line(_, Underline)) => false
  rule regexDocinfo(line(_, Other)) => false
  rule regexDocinfo(line(_, Generated)) => false
  rule regexDocinfo(line(_, PrologLine)) => false

  // validUnderline(T, U) abstracts the code predicate:
  // U is one repeated non-alphanumeric, non-whitespace character and
  // length(U) >= length(T).
  syntax Bool ::= validUnderline(String, String) [function]

  syntax Bool ::= isSectionPair(Line, Line) [function]
  rule isSectionPair(line(T, FieldTitle), line(U, Underline)) => validUnderline(T, U)
  rule isSectionPair(line(_, Docinfo), _) => false
  rule isSectionPair(line(_, Underline), _) => false
  rule isSectionPair(line(_, Other), _) => false
  rule isSectionPair(line(_, Generated), _) => false
  rule isSectionPair(line(_, PrologLine), _) => false

  syntax Bool ::= sectionTitleAt(Lines, Int) [function]
  rule sectionTitleAt(LS, I) => false requires I +Int 1 >=Int size(LS)
  rule sectionTitleAt(LS, I) => isSectionPair(nth(LS, I), nth(LS, I +Int 1))
    requires I +Int 1 <Int size(LS)

  syntax Int ::= scan(Lines, Int) [function]
  rule scan(LS, I) => I requires I >=Int size(LS)
  rule scan(LS, I) => scan(LS, I +Int 1)
    requires I <Int size(LS)
     andBool regexDocinfo(nth(LS, I))
     andBool notBool sectionTitleAt(LS, I)
  rule scan(LS, I) => I
    requires I <Int size(LS)
     andBool (notBool regexDocinfo(nth(LS, I)) orBool sectionTitleAt(LS, I))

  syntax Lines ::= prologLines(Prolog) [function]
  rule prologLines(.Prolog) => .Lines
  rule prologLines(consProlog(S, P)) => consLine(line(S, PrologLine), prologLines(P))

  syntax Lines ::= append(Lines, Lines) [function]
  rule append(.Lines, LS) => LS
  rule append(consLine(L, LS1), LS2) => consLine(L, append(LS1, LS2))

  syntax Lines ::= take(Int, Lines) [function]
  rule take(0, _) => .Lines
  rule take(I, consLine(L, LS)) => consLine(L, take(I -Int 1, LS)) requires I >Int 0

  syntax Lines ::= drop(Int, Lines) [function]
  rule drop(0, LS) => LS
  rule drop(I, consLine(_, LS)) => drop(I -Int 1, LS) requires I >Int 0

  syntax Lines ::= insertAt(Int, Prolog, Lines) [function]
  rule insertAt(0, P, LS) => append(prologLines(P), consLine(blank(), LS))
  rule insertAt(I, P, LS) =>
    append(take(I, LS),
           consLine(blank(),
             append(prologLines(P), consLine(blank(), drop(I, LS)))))
    requires I >Int 0

  syntax Lines ::= prependResult(Prolog, Lines) [function]
  rule prependResult(.Prolog, LS) => LS
  rule prependResult(P, LS) => insertAt(scan(LS, 0), P, LS) requires nonEmptyProlog(P)

  rule <k> prepend(P, LS) => prependResult(P, LS) </k>
endmodule

