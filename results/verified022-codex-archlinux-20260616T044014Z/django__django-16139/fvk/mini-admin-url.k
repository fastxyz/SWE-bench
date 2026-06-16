module MINI-ADMIN-URL-SYNTAX
  imports STRING-SYNTAX

  syntax MaybePk ::= noPk() | hasPk(String)
  syntax Rel     ::= oldPasswordRel() | pkPasswordRel(String)
  syntax Url     ::= changeUrl(String, String) | passwordUrl(String, String)
  syntax Exp     ::= MaybePk | Rel | Url
                   | helpRel(MaybePk)
                   | resolve(Exp, Exp) [seqstrict]
                   | passwordKey(Exp) [strict]
                   | adminPasswordKey(MaybePk, String, String)
                   | oldAdminPasswordKey(String, String)

  syntax KResult ::= String | Rel | Url | MaybePk
endmodule

module MINI-ADMIN-URL
  imports MINI-ADMIN-URL-SYNTAX
  imports K-EQUAL

  configuration <k> $PGM:Exp </k>

  syntax String ::= adminQuote(String)   [function]
  syntax String ::= adminUnquote(String) [function]

  // Admin quote/unquote abstraction. The concrete escaping table lives in
  // django.contrib.admin.utils.quote(); the proof only needs the inverse law.
  rule adminUnquote(adminQuote(PK:String)) => PK [simplification]

  // Model of UserChangeForm.__init__ password help URL selection.
  rule <k> helpRel(noPk()) => oldPasswordRel() ... </k>
  rule <k> helpRel(hasPk(PK:String)) => pkPasswordRel(adminQuote(PK)) ... </k>

  // Browser-style relative resolution from <root>/<object>/change/.
  rule <k> resolve(changeUrl(ROOT:String, OBJ:String), oldPasswordRel())
        => passwordUrl(ROOT, OBJ) ... </k>
  rule <k> resolve(changeUrl(ROOT:String, OBJ:String), pkPasswordRel(PKQ:String))
        => passwordUrl(ROOT, PKQ) ... </k>

  // Model of UserAdmin.user_change_password() interpreting the path segment
  // as an admin-quoted primary key.
  rule <k> passwordKey(passwordUrl(ROOT:String, ID:String))
        => adminUnquote(ID) ... </k>

  // Composition helpers used by the spec claims.
  rule <k> adminPasswordKey(MPK:MaybePk, ROOT:String, OBJ:String)
        => passwordKey(resolve(changeUrl(ROOT, OBJ), helpRel(MPK))) ... </k>
  rule <k> oldAdminPasswordKey(ROOT:String, OBJ:String)
        => passwordKey(resolve(changeUrl(ROOT, OBJ), oldPasswordRel())) ... </k>
endmodule
