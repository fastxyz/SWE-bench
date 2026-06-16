requires "mini-viewcode.k"

module VIEWCODE-SPEC
  imports MINI-VIEWCODE

  // SPEC-PROVENANCE:
  // - from_prompt: "viewcode creates pages for epub even if
  //   `viewcode_enable_epub=False` on `make html epub`" => the disabled EPUB
  //   path must not emit module pages, even when module entries already exist.
  // - from_docs: "By default `epub` builder doesn't support this extension" =>
  //   disabled EPUB is the default contract.
  // - from_code: EPUB uses the HTML collect-pages event, so collect_pages is the
  //   generation boundary that must enforce the opt-in.
  claim
    <k> collectPages(true, false, HAS_MODULES:Bool, ENTRIES:Entries) => .K </k>
    <yielded> _ => .Pages </yielded>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt/docs: the change is about EPUB disabled by default, not about
  //   disabling normal HTML-related builders.
  // - from_code: when the guard is false, V1 falls through to existing logic.
  claim
    <k> collectPages(false, ENABLE_EPUB:Bool, true, ENTRIES:Entries) => .K </k>
    <yielded> _ => pagesFor(ENTRIES) </yielded>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: "If this is True, viewcode extension is also enabled even if you
  //   use epub builders" => explicit EPUB opt-in preserves generation.
  claim
    <k> collectPages(true, true, true, ENTRIES:Entries) => .K </k>
    <yielded> _ => pagesFor(ENTRIES) </yielded>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: pre-existing collect_pages returns without output when the
  //   environment has no _viewcode_modules cache.
  // - from_frame_condition: V1 must not create pages out of no module data.
  claim
    <k> collectPages(IS_EPUB:Bool, ENABLE_EPUB:Bool, false, ENTRIES:Entries) => .K </k>
    <yielded> _ => .Pages </yielded>
    requires notBool (IS_EPUB andBool notBool ENABLE_EPUB)
    [all-path]
endmodule
