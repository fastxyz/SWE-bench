module MINI-REQUESTS-BODY-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Bytes ::= bytes(String)

  syntax Data ::= noData()
                | rawBytes(Bytes)
                | rawText(String)
                | formData(String)
                | fileLike()
                | streamData()

  syntax Files ::= noFiles() | hasFiles()
  syntax Native ::= nativeText(String)
                  | toNative(Bytes)
                  | urlEncode(String)

  syntax Query ::= noQuery() | query(Native)

  syntax Body ::= noBody()
                | bodyBytes(Bytes)
                | bodyText(String)
                | bodyForm(Native)
                | bodyFile()
                | bodyStream()

  syntax CType ::= noCType() | formCType()
  syntax Prepared ::= prepared(Body, CType, Int)
  syntax UrlPrepared ::= urlPrepared(Query)

  syntax Exp ::= encodeParams(Data)
               | prepareBody(Data, Files)
               | prepareUrlParams(Data, Query)

  syntax Int ::= len(Bytes) [function]
  syntax Int ::= lenString(String) [function]
  syntax Int ::= lenNative(Native) [function]
  syntax Bool ::= nonEmpty(Bytes) [function]
  syntax Bool ::= asciiBytes(Bytes) [function]

  syntax KResult ::= Bytes | String | Native | Prepared | UrlPrepared
endmodule

module MINI-REQUESTS-BODY
  imports MINI-REQUESTS-BODY-SYNTAX
  imports INT
  imports BOOL
  imports STRING

  configuration <k> $PGM:Exp </k>

  // _encode_params: bytes are already encoded and remain bytes.
  rule <k> encodeParams(rawBytes(B:Bytes)) => B ... </k>

  // _encode_params: native text remains native text.
  rule <k> encodeParams(rawText(S:String)) => S ... </k>

  // _encode_params: form data is represented by an abstract URL-encoded string.
  rule <k> encodeParams(formData(F:String)) => urlEncode(F) ... </k>

  // prepare_body on the audited raw-bytes branch.
  rule <k> prepareBody(rawBytes(B:Bytes), noFiles())
        => prepared(bodyBytes(B), noCType(), len(B)) ... </k>
    requires nonEmpty(B)

  // prepare_body frame: raw text remains a raw body.
  rule <k> prepareBody(rawText(S:String), noFiles())
        => prepared(bodyText(S), noCType(), lenString(S)) ... </k>

  // prepare_body frame: form data remains form encoded.
  rule <k> prepareBody(formData(F:String), noFiles())
        => prepared(bodyForm(urlEncode(F)), formCType(), lenNative(urlEncode(F))) ... </k>

  // prepare_url on the audited params-bytes branch.
  rule <k> prepareUrlParams(rawBytes(B:Bytes), noQuery())
        => urlPrepared(query(toNative(B))) ... </k>
    requires asciiBytes(B)
endmodule
