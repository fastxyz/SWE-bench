module MINI-PASTEBIN-SYNTAX
  imports STRING-SYNTAX

  syntax PasteAction ::= createPasteRequest(String)
  syntax Request ::= request(String, String, String, String)
  syntax KResult ::= Request
endmodule

module MINI-PASTEBIN
  imports MINI-PASTEBIN-SYNTAX
  imports STRING

  configuration <k> $PGM:PasteAction </k>

  // Abstraction of repo/src/_pytest/pastebin.py:create_new_paste lines 80-86.
  // The observable under audit is the request target plus form fields.
  rule <k> createPasteRequest(CONTENTS:String)
        => request("https://bpaste.net", CONTENTS, "text", "1week")
      </k>
endmodule
