requires "mini-toctree.k"

module TOCTREE-GENERATED-PAGES-SPEC
  imports MINI-TOCTREE
  imports MAP
  imports SET
  imports LIST
  imports STRING
  imports BOOL

  // SPEC-PROVENANCE:
  // - E1/E2: issue names genindex, modindex, search as accepted toctree entries.
  // - E4: generated pages are entries, not includefiles.
  // Claim: PARSE-GENINDEX
  claim
    <k> parse("", "genindex") => .K ... </k>
    <foundDocs> FOUND:Set </foundDocs>
    <labels> "genindex" |-> label("genindex", "Index") </labels>
    <entries> .List => ListItem(entry("", "genindex")) </entries>
    <includefiles> .List => .List </includefiles>
    <warnings> .List => .List </warnings>
  requires notBool("genindex" in FOUND)
  [all-path]

  // SPEC-PROVENANCE:
  // - E1/E2/E5: modindex is accepted and maps through the std label to py-modindex.
  // Claim: PARSE-MODINDEX
  claim
    <k> parse("", "modindex") => .K ... </k>
    <foundDocs> FOUND:Set </foundDocs>
    <labels> "modindex" |-> label("py-modindex", "Module Index") </labels>
    <entries> .List => ListItem(entry("", "modindex")) </entries>
    <includefiles> .List => .List </includefiles>
    <warnings> .List => .List </warnings>
  requires notBool("py-modindex" in FOUND)
  [all-path]

  // SPEC-PROVENANCE:
  // - E1/E2: search is accepted as a generated page.
  // Claim: PARSE-SEARCH
  claim
    <k> parse("", "search") => .K ... </k>
    <foundDocs> FOUND:Set </foundDocs>
    <labels> "search" |-> label("search", "Search Page") </labels>
    <entries> .List => ListItem(entry("", "search")) </entries>
    <includefiles> .List => .List </includefiles>
    <warnings> .List => .List </warnings>
  requires notBool("search" in FOUND)
  [all-path]

  // SPEC-PROVENANCE:
  // - E3/E5: generated entries resolve to standard-domain targets and titles.
  // Claim: RESOLVE-GENINDEX
  claim
    <k> resolve("", "genindex") => .K ... </k>
    <foundDocs> FOUND:Set </foundDocs>
    <labels> "genindex" |-> label("genindex", "Index") </labels>
    <links> .List => ListItem(link("genindex", "Index")) </links>
    <warnings> .List => .List </warnings>
  requires notBool("genindex" in FOUND)
  [all-path]

  // SPEC-PROVENANCE:
  // - E3/E5: generated entries resolve to standard-domain targets and titles.
  // Claim: RESOLVE-MODINDEX
  claim
    <k> resolve("", "modindex") => .K ... </k>
    <foundDocs> FOUND:Set </foundDocs>
    <labels> "modindex" |-> label("py-modindex", "Module Index") </labels>
    <links> .List => ListItem(link("py-modindex", "Module Index")) </links>
    <warnings> .List => .List </warnings>
  requires notBool("py-modindex" in FOUND)
  [all-path]

  // SPEC-PROVENANCE:
  // - E3/E5: generated entries resolve to standard-domain targets and titles.
  // Claim: RESOLVE-SEARCH
  claim
    <k> resolve("", "search") => .K ... </k>
    <foundDocs> FOUND:Set </foundDocs>
    <labels> "search" |-> label("search", "Search Page") </labels>
    <links> .List => ListItem(link("search", "Search Page")) </links>
    <warnings> .List => .List </warnings>
  requires notBool("search" in FOUND)
  [all-path]

  // SPEC-PROVENANCE:
  // - E3: explicit toctree titles remain explicit titles.
  // Claim: RESOLVE-GENINDEX-EXPLICIT
  claim
    <k> resolve("General Index", "genindex") => .K ... </k>
    <foundDocs> FOUND:Set </foundDocs>
    <labels> "genindex" |-> label("genindex", "Index") </labels>
    <links> .List => ListItem(link("genindex", "General Index")) </links>
    <warnings> .List => .List </warnings>
  requires notBool("genindex" in FOUND)
  [all-path]

  // SPEC-PROVENANCE:
  // - E4/frame: real source documents still win and become includefiles.
  // Claim: SOURCE-DOC-WINS
  claim
    <k> parse("", "intro") => .K ... </k>
    <foundDocs> SetItem("intro") </foundDocs>
    <entries> .List => ListItem(entry("", "intro")) </entries>
    <includefiles> .List => ListItem("intro") </includefiles>
    <warnings> .List => .List </warnings>
  [all-path]

  // SPEC-PROVENANCE:
  // - E4/frame: unknown non-generated documents keep the old warning behavior.
  // Claim: UNKNOWN-STILL-WARNS
  claim
    <k> parse("", "missing") => .K ... </k>
    <foundDocs> .Set </foundDocs>
    <labels> .Map </labels>
    <entries> .List => .List </entries>
    <includefiles> .List => .List </includefiles>
    <warnings> .List => ListItem(warning("missing")) </warnings>
  [all-path]

  // SPEC-PROVENANCE:
  // - E6: section numbering must skip generated entries.
  // Claim: SECTION-SKIP-GENERATED
  claim
    <k> assignSection("search") => .K ... </k>
    <foundDocs> FOUND:Set </foundDocs>
    <labels> "search" |-> label("search", "Search Page") </labels>
    <sectionNumbers> SN:List => SN </sectionNumbers>
    <warnings> WS:List => WS </warnings>
  requires notBool("search" in FOUND)
  [all-path]

  // SPEC-PROVENANCE:
  // - E6: figure numbering must skip generated entries.
  // Claim: FIGURE-SKIP-GENERATED
  claim
    <k> assignFigure("genindex") => .K ... </k>
    <foundDocs> FOUND:Set </foundDocs>
    <labels> "genindex" |-> label("genindex", "Index") </labels>
    <figureNumbers> FN:List => FN </figureNumbers>
    <warnings> WS:List => WS </warnings>
  requires notBool("genindex" in FOUND)
  [all-path]
endmodule
