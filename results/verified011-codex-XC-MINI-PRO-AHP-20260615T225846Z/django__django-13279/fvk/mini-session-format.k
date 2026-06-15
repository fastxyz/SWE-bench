module MINI-SESSION-FORMAT-SYNTAX
  imports STRING-SYNTAX

  syntax Alg ::= "SHA1" | "SHA256"
  syntax StoreClass ::= "storeClass" "(" String ")"
  syntax Data ::= "sessionData" "(" String ")"
  syntax Bytes ::= "serialized" "(" Data ")"
  syntax Digest ::= "legacyHash" "(" StoreClass "," Bytes ")"

  syntax Encoded ::= "legacyEncoded" "(" StoreClass "," Digest "," Bytes ")"
                   | "signedEncoded" "(" StoreClass "," Data ")"

  syntax Exp ::= Data
               | Encoded
               | "encode" "(" StoreClass "," Data "," Alg ")"
               | "legacyEncode" "(" StoreClass "," Data ")"
               | "decode" "(" StoreClass "," Exp ")" [strict(2)]
               | "legacyDecode" "(" StoreClass "," Exp ")" [strict(2)]

  syntax KResult ::= Data | Encoded
endmodule

module MINI-SESSION-FORMAT
  imports MINI-SESSION-FORMAT-SYNTAX

  configuration <k> $PGM:Exp </k>

  // SessionBase.encode() in transitional SHA1 mode uses the legacy encoder.
  rule <k> encode(C:StoreClass, D:Data, SHA1) => legacyEncode(C, D) ... </k>

  // SessionBase.encode() in default SHA256 mode keeps the Django 3.1 signed format.
  rule <k> encode(C:StoreClass, D:Data, SHA256) => signedEncoded(C, D) ... </k>

  // _legacy_encode(): base64(hash + ":" + serialized) is modeled by a constructor
  // that keeps all semantically relevant fields visible to the proof.
  rule <k> legacyEncode(C:StoreClass, D:Data)
        => legacyEncoded(C, legacyHash(C, serialized(D)), serialized(D))
        ... </k>

  // Older Django's legacy decoder accepts exactly the legacy payload shape.
  rule <k> legacyDecode(C:StoreClass, legacyEncoded(C, legacyHash(C, serialized(D)), serialized(D)))
        => D
        ... </k>

  // Django 3.1 decode accepts both the legacy payload and the signed payload.
  rule <k> decode(C:StoreClass, legacyEncoded(C, legacyHash(C, serialized(D)), serialized(D)))
        => D
        ... </k>

  rule <k> decode(C:StoreClass, signedEncoded(C, D:Data))
        => D
        ... </k>
endmodule

