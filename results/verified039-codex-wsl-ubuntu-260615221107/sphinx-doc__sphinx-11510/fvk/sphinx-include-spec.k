requires "mini-sphinx-include.k"

module SPHINX-INCLUDE-SPEC
  imports MINI-SPHINX-INCLUDE
  imports MAP-SYMBOLIC
  imports K-EQUAL

  // SPEC-PROVENANCE:
  // - E1/E2/E3/E5/E7: managed include insertion must use source-read result.
  // - E9: include path bookkeeping is framed outside this abstraction.
  claim [managed-include]:
    <k> includeRun(false, "index", "something-to-include.rst")
      => .K ... </k>
    <files> "something-to-include.rst" |-> "&REPLACE_ME;" </files>
    <pathdocs> "something-to-include.rst" |-> "something-to-include" </pathdocs>
    <inserted> .Map
      => .Map [ "something-to-include.rst"
                <- sourceRead("something-to-include", "&REPLACE_ME;") ] </inserted>
    <events> .List
      => ListItem("something-to-include:&REPLACE_ME;") </events>
    <fileInput> "orig" => "orig" </fileInput>
    <directFileInput> "none" => "none" </directFileInput>
    <currentDoc> "" => "index" </currentDoc>
    [all-path]

  // SPEC-PROVENANCE:
  // - I7: no source docname falls back to the current document name.
  claim [managed-include-fallback-doc]:
    <k> includeRun(false, "index", "snippet.inc") => .K ... </k>
    <files> "snippet.inc" |-> "TOKEN" </files>
    <pathdocs> .Map </pathdocs>
    <inserted> .Map => .Map [ "snippet.inc" <- sourceRead("index", "TOKEN") ] </inserted>
    <events> .List => ListItem("index:TOKEN") </events>
    <fileInput> "orig" => "orig" </fileInput>
    <directFileInput> "none" => "none" </directFileInput>
    <currentDoc> "" => "index" </currentDoc>
    [all-path]

  // SPEC-PROVENANCE:
  // - E8/I5: docutils standard includes are unchanged by Sphinx wrapping.
  claim [standard-include-frame]:
    <k> includeRun(true, "index", "<isonum.txt>") => baseIncludeRead("<isonum.txt>") ... </k>
    <events> .List => .List </events>
    <fileInput> "orig" => "orig" </fileInput>
    <directFileInput> "none" => "none" </directFileInput>
    <currentDoc> "" => "" </currentDoc>
    [all-path]

  // SPEC-PROVENANCE:
  // - F-001/PO-4: direct FileInput global must be intercepted and restored.
  claim [direct-fileinput-coverage]:
    <k> includeRun(false, "index", "direct.rst") => .K ... </k>
    <files> "direct.rst" |-> "RAW" </files>
    <pathdocs> "direct.rst" |-> "direct" </pathdocs>
    <inserted> .Map => .Map [ "direct.rst" <- sourceRead("direct", "RAW") ] </inserted>
    <events> .List => ListItem("direct:RAW") </events>
    <fileInput> "orig" => "orig" </fileInput>
    <directFileInput> "orig" => "orig" </directFileInput>
    <currentDoc> "" => "index" </currentDoc>
    [all-path]

  // SPEC-PROVENANCE:
  // - F-002/PO-6: duration preserves the first source-read timestamp.
  claim [duration-first-read]:
    <k> durationOnSourceRead(20) => .K ... </k>
    <durationStarted> true => true </durationStarted>
    <startedAt> 10 => 10 </startedAt>
    [all-path]
endmodule
