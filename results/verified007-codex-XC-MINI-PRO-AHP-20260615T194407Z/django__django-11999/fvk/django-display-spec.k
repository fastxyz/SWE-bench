requires "mini-django-model-construction.k"

module DJANGO-DISPLAY-SPEC
  imports MINI-DJANGO-MODEL-CONSTRUCTION
  imports INT

  // SPEC-PROVENANCE:
  // - from_prompt: "I should be able to override this function."
  // - from_code: ModelBase creates the class with direct methods before field
  //   contribution, so directDisplay=user models an explicit class-body method.
  claim
    <k> contribute(FID:Int, true) => .K </k>
    <directDisplay> user </directDisplay>
    <inheritedDisplay> INHERITED:Method </inheritedDisplay>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: every choices field has get_FOO_display().
  // - from_code: V1 installs partialmethod(cls._get_FIELD_display, field=self)
  //   when the display name is absent from cls.__dict__.
  claim
    <k> contribute(FID:Int, true) => .K </k>
    <directDisplay> none => generated(FID) </directDisplay>
    <inheritedDisplay> INHERITED:Method </inheritedDisplay>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_frame: non-choice fields are outside the issue's changed behavior.
  claim
    <k> contribute(FID:Int, false) => .K </k>
    <directDisplay> DIRECT:Method </directDisplay>
    <inheritedDisplay> INHERITED:Method </inheritedDisplay>
    [all-path]
endmodule
