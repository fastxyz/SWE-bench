module MINI-PYTHON-REGEX-SYNTAX
  imports BOOL-SYNTAX

  syntax CharCat ::= "asciiWord"
                   | "unicodeWord"
                   | "dot"
                   | "at"
                   | "plus"
                   | "hyphen"
                   | "underscore"
                   | "lf"
                   | "cr"
                   | "space"
                   | "other"

  syntax Chars ::= ".Chars"
                 | "cons" "(" CharCat "," Chars ")"

  syntax Validator ::= "asciiUsername" | "unicodeUsername"
  syntax Outcome ::= "valid" | "invalid"
  syntax KResult ::= Outcome | Bool

  syntax Exp ::= "validate" "(" Validator "," Chars ")"

  syntax Bool ::= "fullMatch" "(" Validator "," Chars ")" [function]
                | "allAllowed" "(" Validator "," Chars ")" [function]
                | "allowed" "(" Validator "," CharCat ")" [function]

  syntax Chars ::= "appendLF" "(" Chars ")" [function]
endmodule

module MINI-PYTHON-REGEX
  imports MINI-PYTHON-REGEX-SYNTAX
  imports BOOL

  configuration <k> $PGM:Exp </k>

  rule <k> validate(V, CS) => valid </k>
    requires fullMatch(V, CS)

  rule <k> validate(V, CS) => invalid </k>
    requires notBool fullMatch(V, CS)

  // Model of Python regex r'\A[\w.@+-]+\Z' after RegexValidator converts
  // the value to a string. The plus requires at least one character, and
  // \A...\Z requires the whole string to be consumed.
  rule fullMatch(V, .Chars) => false
  rule fullMatch(V, cons(C, REST)) => allowed(V, C) andBool allAllowed(V, REST)
  rule fullMatch(V, appendLF(CS)) => false [simplification]

  rule allAllowed(V, .Chars) => true
  rule allAllowed(V, cons(C, REST)) => allowed(V, C) andBool allAllowed(V, REST)
  rule allAllowed(V, appendLF(CS)) => false [simplification]

  rule allowed(asciiUsername, asciiWord) => true
  rule allowed(asciiUsername, unicodeWord) => false
  rule allowed(asciiUsername, dot) => true
  rule allowed(asciiUsername, at) => true
  rule allowed(asciiUsername, plus) => true
  rule allowed(asciiUsername, hyphen) => true
  rule allowed(asciiUsername, underscore) => true
  rule allowed(asciiUsername, lf) => false
  rule allowed(asciiUsername, cr) => false
  rule allowed(asciiUsername, space) => false
  rule allowed(asciiUsername, other) => false

  rule allowed(unicodeUsername, asciiWord) => true
  rule allowed(unicodeUsername, unicodeWord) => true
  rule allowed(unicodeUsername, dot) => true
  rule allowed(unicodeUsername, at) => true
  rule allowed(unicodeUsername, plus) => true
  rule allowed(unicodeUsername, hyphen) => true
  rule allowed(unicodeUsername, underscore) => true
  rule allowed(unicodeUsername, lf) => false
  rule allowed(unicodeUsername, cr) => false
  rule allowed(unicodeUsername, space) => false
  rule allowed(unicodeUsername, other) => false

  rule appendLF(.Chars) => cons(lf, .Chars)
  rule appendLF(cons(C, REST)) => cons(C, appendLF(REST))
endmodule
