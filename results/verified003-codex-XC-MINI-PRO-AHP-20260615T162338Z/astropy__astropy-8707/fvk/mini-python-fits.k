requires "domains.md"

module MINI-PYTHON-FITS-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax PyObj ::= Str(String)
                 | Bytes(String)
                 | Header(String)
                 | Card(String)
                 | TypeError

  syntax Call ::= "Header.fromstring" "(" PyObj "," PyObj ")"
                | "Card.fromstring" "(" PyObj ")"

  syntax KResult ::= PyObj
endmodule

module MINI-PYTHON-FITS
  imports MINI-PYTHON-FITS-SYNTAX
  imports STRING
  imports BOOL

  configuration <k> $PGM:Call </k>

  // Abstract predicate: true when the wrapped string represents ASCII bytes.
  syntax Bool ::= ascii(String) [function]

  syntax PyObj ::= decodeAscii(PyObj) [function]
  rule decodeAscii(Str(S)) => Str(S)
  rule decodeAscii(Bytes(S)) => Str(S) requires ascii(S)

  syntax String ::= pad80(String) [function]

  // Abstract text parser: enough structure to distinguish the bug.
  syntax PyObj ::= parseHeader(PyObj, PyObj) [function]
  rule parseHeader(Str(DATA), Str(SEP)) => Header(DATA)
  rule parseHeader(Bytes(DATA), SEP) => TypeError
  rule parseHeader(DATA, Bytes(SEP)) => TypeError

  syntax PyObj ::= makeCard(PyObj) [function]
  rule makeCard(Str(IMAGE)) => Card(pad80(IMAGE))
  rule makeCard(Bytes(IMAGE)) => TypeError

  rule <k> Header.fromstring(DATA, SEP)
        => parseHeader(decodeAscii(DATA), decodeAscii(SEP))
       </k>

  rule <k> Card.fromstring(IMAGE)
        => makeCard(decodeAscii(IMAGE))
       </k>
endmodule

