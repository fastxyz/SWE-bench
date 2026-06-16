// Constructed, not machine-checked.
// Minimal abstract K vocabulary for the URL rewrite proof obligations.

module MINI-URL-REWRITE-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax UrlExp ::= finalSvgHref(String, String, String)
                  | rootResolve(String, String)
                  | relFrom(String, String)
                  | resolvesFrom(String, String)

  syntax Bool ::= isLocalRelative(String) [function]
                | sameResolvedTarget(String, String) [function]
endmodule

module MINI-URL-REWRITE
  imports MINI-URL-REWRITE-SYNTAX
  imports STRING
  imports BOOL

  configuration <k> $PGM:UrlExp </k>

  // Abstract semantic rule: V2 composes inheritance root resolution with an
  // image-directory-relative SVG href rewrite.
  rule <k> finalSvgHref(CURRENT:String, REFURI:String, IMAGEDIR:String)
        => relFrom(IMAGEDIR, rootResolve(CURRENT, REFURI)) ... </k>
    requires isLocalRelative(REFURI)

  // Abstract semantic rule: resolving a relative path from the image directory
  // reaches the output-root target used to construct that relative path.
  rule <k> resolvesFrom(IMAGEDIR:String, relFrom(IMAGEDIR, TARGET:String))
        => TARGET ... </k>
endmodule
