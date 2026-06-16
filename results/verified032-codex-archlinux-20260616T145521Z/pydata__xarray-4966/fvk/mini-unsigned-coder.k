module MINI-UNSIGNED-CODER-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports LIST

  syntax Kind ::= "kindI" | "kindU" | "kindOther"
  syntax Marker ::= "mAbsent" | "mTrueString" | "mFalseString"
                  | "mBoolTrue" | "mBoolFalse" | "mOther"
  syntax MaybeInt ::= "noFill" | "fill" "(" Int ")"
  syntax Warns ::= ".Warns" | "warnUnsignedNonInteger" Warns [right]
  syntax Cmd ::= "decode" | "done"
  syntax KResult ::= "done"
endmodule

module MINI-UNSIGNED-CODER
  imports MINI-UNSIGNED-CODER-SYNTAX
  imports INT
  imports BOOL
  imports LIST

  configuration
    <k> $PGM:Cmd </k>
    <kind> kindOther </kind>
    <itemsize> 1 </itemsize>
    <values> .List </values>
    <fill> noFill </fill>
    <attrsUnsigned> mAbsent </attrsUnsigned>
    <encodingUnsigned> mAbsent </encodingUnsigned>
    <warnings> .Warns </warnings>

  syntax Bool ::= isIntegerKind(Kind) [function]
  rule isIntegerKind(kindI) => true
  rule isIntegerKind(kindU) => true
  rule isIntegerKind(kindOther) => false

  syntax Bool ::= isUnsignedMarker(Marker) [function]
  rule isUnsignedMarker(mTrueString) => true
  rule isUnsignedMarker(mBoolTrue) => true
  rule isUnsignedMarker(mFalseString) => false
  rule isUnsignedMarker(mBoolFalse) => false
  rule isUnsignedMarker(mOther) => false
  rule isUnsignedMarker(mAbsent) => false

  syntax Bool ::= isSignedMarker(Marker) [function]
  rule isSignedMarker(mFalseString) => true
  rule isSignedMarker(mBoolFalse) => true
  rule isSignedMarker(mTrueString) => false
  rule isSignedMarker(mBoolTrue) => false
  rule isSignedMarker(mOther) => false
  rule isSignedMarker(mAbsent) => false

  syntax Bool ::= shouldConvert(Marker, Kind) [function]
  rule shouldConvert(M, kindI) => isUnsignedMarker(M)
  rule shouldConvert(M, kindU) => isSignedMarker(M)
  rule shouldConvert(_, kindOther) => false

  syntax Kind ::= targetKind(Marker, Kind) [function]
  rule targetKind(M, kindI) => kindU requires isUnsignedMarker(M)
  rule targetKind(M, kindU) => kindI requires isSignedMarker(M)
  rule targetKind(M, K) => K requires notBool shouldConvert(M, K)

  syntax List ::= castValues(Kind, Int, List) [function]
  syntax MaybeInt ::= castFill(Kind, Int, MaybeInt) [function]
  syntax Int ::= castValue(Kind, Int, Int) [function]

  rule castValues(K, W, .List) => .List
  rule castValues(K, W, ListItem(V:Int) REST:List)
    => ListItem(castValue(K, W, V)) castValues(K, W, REST)

  rule castFill(_, _, noFill) => noFill
  rule castFill(K, W, fill(V)) => fill(castValue(K, W, V))

  // Abstract NumPy dtype casts. The concrete one-byte cases used by the issue
  // are stated by simplification rules in the spec file.
  rule castValue(K, _, V) => V [owise]

  rule
    <k> decode => done </k>
    <attrsUnsigned> mAbsent </attrsUnsigned>

  rule
    <k> decode => done </k>
    <kind> K:Kind => targetKind(M, K) </kind>
    <itemsize> W:Int </itemsize>
    <values> VS:List => castValues(targetKind(M, K), W, VS) </values>
    <fill> F:MaybeInt => castFill(targetKind(M, K), W, F) </fill>
    <attrsUnsigned> M:Marker => mAbsent </attrsUnsigned>
    <encodingUnsigned> _ => M </encodingUnsigned>
    requires isIntegerKind(K) andBool shouldConvert(M, K)

  rule
    <k> decode => done </k>
    <kind> K:Kind </kind>
    <attrsUnsigned> M:Marker => mAbsent </attrsUnsigned>
    <encodingUnsigned> _ => M </encodingUnsigned>
    requires isIntegerKind(K) andBool notBool shouldConvert(M, K) andBool M =/=K mAbsent

  rule
    <k> decode => done </k>
    <kind> kindOther </kind>
    <attrsUnsigned> M:Marker => mAbsent </attrsUnsigned>
    <encodingUnsigned> _ => M </encodingUnsigned>
    <warnings> WS:Warns => warnUnsignedNonInteger WS </warnings>
    requires M =/=K mAbsent
endmodule
