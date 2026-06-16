module MINI-VIEWCODE-SYNTAX
  imports BOOL-SYNTAX

  syntax Entries ::= "modules"
  syntax Pages ::= ".Pages" | "pagesFor" "(" Entries ")"
  syntax Cmd ::= "collectPages" "(" Bool "," Bool "," Bool "," Entries ")"
  syntax KResult ::= Pages
endmodule

module MINI-VIEWCODE
  imports MINI-VIEWCODE-SYNTAX
  imports BOOL

  configuration
    <k> $PGM:Cmd </k>
    <yielded> .Pages </yielded>

  // V1 guard: if this is an EPUB builder and EPUB viewcode is not enabled,
  // collect_pages returns before inspecting any reused module cache.
  rule
    <k> collectPages(true, false, HAS_MODULES:Bool, ENTRIES:Entries) => .K </k>
    <yielded> _ => .Pages </yielded>

  // Existing no-module behavior, reached only when the EPUB-disabled guard is false.
  rule
    <k> collectPages(IS_EPUB:Bool, ENABLE_EPUB:Bool, false, ENTRIES:Entries) => .K </k>
    <yielded> _ => .Pages </yielded>
    requires notBool (IS_EPUB andBool notBool ENABLE_EPUB)

  // Existing generation behavior, reached only when the EPUB-disabled guard is false.
  // The concrete page contents are outside this issue; the observable here is that
  // extension pages are emitted from available module entries.
  rule
    <k> collectPages(IS_EPUB:Bool, ENABLE_EPUB:Bool, true, ENTRIES:Entries) => .K </k>
    <yielded> _ => pagesFor(ENTRIES) </yielded>
    requires notBool (IS_EPUB andBool notBool ENABLE_EPUB)
endmodule
