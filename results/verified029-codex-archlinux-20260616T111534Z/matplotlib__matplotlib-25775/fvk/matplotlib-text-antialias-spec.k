requires "mini-matplotlib-text.k"

module MATPLOTLIB-TEXT-ANTIALIAS-SPEC
  imports MINI-MATPLOTLIB-TEXT

  // SPEC-PROVENANCE:
  // - from_prompt: "Add get/set_antialiased to Text objects" =>
  //   Text stores an explicit per-artist antialiasing value.
  // - from_prompt: "unlike other artists" and existing Patch semantics =>
  //   None falls back to rcParams["text.antialiased"].
  claim <k> initText(NoneAA, RC) => . ... </k>
        <textAA> _ => RC </textAA>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "per-artist basis via set_antialiased" =>
  //   explicit values override the rcParam snapshot.
  claim <k> initText(AA(B), RC) => . ... </k>
        <textAA> _ => B </textAA>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "Add get/set_antialiased" =>
  //   setter replaces the stored value and getter observes the stored value.
  claim <k> setTextAA(AA(B), RC) => . ... </k>
        <textAA> _ => B </textAA>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "use that info in the drawing stage" =>
  //   Text.draw must write the stored value to the graphics context.
  claim <k> drawText(BACKEND) => . ... </k>
        <textAA> B </textAA>
        <gcAA> _ => B </gcAA>
        <backendAA> OBS => OBS[BACKEND <- B] </backendAA>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "adjusting Annotations accordingly" =>
  //   Annotation must use the same Text drawing contract.
  claim <k> drawAnnotation(BACKEND) => . ... </k>
        <textAA> B </textAA>
        <gcAA> _ => B </gcAA>
        <backendAA> OBS => OBS[BACKEND <- B] </backendAA>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt/backend hint: "AGG ... support customizing font antialiasing"
  //   and "replace the access ... by going through the GraphicsContext state" =>
  //   AGG normal text and raster mathtext consume the GC antialiasing value.
  claim <k> drawText(AggNormal) => . ... </k>
        <textAA> B </textAA>
        <gcAA> _ => B </gcAA>
        <backendAA> OBS => OBS[AggNormal <- B] </backendAA>
    [all-path]

  claim <k> drawText(AggMath) => . ... </k>
        <textAA> B </textAA>
        <gcAA> _ => B </gcAA>
        <backendAA> OBS => OBS[AggMath <- B] </backendAA>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt/backend hint: "Cairo backends support customizing font
  //   antialiasing" => Cairo text font options consume the GC value.
  claim <k> drawText(CairoText) => . ... </k>
        <textAA> B </textAA>
        <gcAA> _ => B </gcAA>
        <backendAA> OBS => OBS[CairoText <- B] </backendAA>
    [all-path]

  claim <k> drawText(CairoMath) => . ... </k>
        <textAA> B </textAA>
        <gcAA> _ => B </gcAA>
        <backendAA> OBS => OBS[CairoMath <- B] </backendAA>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: text path effects copy graphics contexts before drawing paths.
  // - proof-finding F1: copied Cairo GCs must synchronize copied antialiasing
  //   into the cairo context, otherwise path-effect text ignores Text AA.
  claim <k> copyCairoGC => . ... </k>
        <gcAA> B </gcAA>
        <copiedGcAA> _ => B </copiedGcAA>
        <backendAA> OBS => OBS[CairoPathEffectCopy <- B] </backendAA>
    [all-path]

  // SPEC-PROVENANCE:
  // - public compatibility: existing MathTextParser("agg").parse calls without
  //   the new keyword keep rcParam behavior.
  claim <k> parseRasterMath(NoneAA, RC) => . ... </k>
        <backendAA> OBS => OBS[AggMath <- RC] </backendAA>
    [all-path]

  claim <k> parseRasterMath(AA(B), RC) => . ... </k>
        <backendAA> OBS => OBS[AggMath <- B] </backendAA>
    [all-path]
endmodule
