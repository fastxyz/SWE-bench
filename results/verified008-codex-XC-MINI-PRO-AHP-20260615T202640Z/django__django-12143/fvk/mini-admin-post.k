// Mini admin POST semantics for django__django-12143.
// Constructed, not machine-checked.

module MINI-ADMIN-POST-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax Entry ::= entry(String, String)
  syntax Entries ::= ".Entries"
                   | Entry ";" Entries [right]
  syntax Values ::= ".Values"
                  | vcons(String, Values)
                  | appendValue(Values, String) [function]

  syntax KItem ::= selectPks(Entries, String, String)
                 | scan(Entries, String, String, Values)

  syntax Bool ::= escapedPkRegexMatches(String, String, String) [function]
                | literalPkFieldName(String, String, String) [function]
endmodule

module MINI-ADMIN-POST
  imports MINI-ADMIN-POST-SYNTAX
  imports BOOL

  configuration <k> $PGM:K </k>

  // Start an order-preserving scan with an empty accumulator.
  rule <k> selectPks(POST, PREFIX, PK) => scan(POST, PREFIX, PK, .Values) ... </k>

  // Empty input returns the accumulated selected values.
  rule <k> scan(.Entries, PREFIX, PK, ACC) => ACC ... </k>

  // Matching entry: append the value to the output stream.
  rule <k> scan(entry(KEY, VALUE) ; REST, PREFIX, PK, ACC)
        => scan(REST, PREFIX, PK, appendValue(ACC, VALUE)) ... </k>
    requires escapedPkRegexMatches(KEY, PREFIX, PK)

  // Non-matching entry: skip it.
  rule <k> scan(entry(KEY, VALUE) ; REST, PREFIX, PK, ACC)
        => scan(REST, PREFIX, PK, ACC) ... </k>
    requires notBool escapedPkRegexMatches(KEY, PREFIX, PK)

  rule appendValue(.Values, VALUE) => vcons(VALUE, .Values)
  rule appendValue(vcons(HEAD, REST), VALUE) => vcons(HEAD, appendValue(REST, VALUE))
endmodule
