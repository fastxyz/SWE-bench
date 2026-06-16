requires "mini-axis-color.k"

module AXIS-OFFSET-COLOR-SPEC
  imports MINI-AXIS-COLOR
  imports BOOL
  imports STRING
  imports MAP

  // SPEC-PROVENANCE:
  // - from_prompt: setting ytick.labelcolor / xtick.labelcolor in styles /
  //   rcParams should change the exponent label color as well.
  // - from_matplotlibrc: xtick.labelcolor and ytick.labelcolor may be
  //   "inherit", meaning inherit from the corresponding tick color.
  // - from_code: _get_tick_label_color implements the rcParams resolver used
  //   by Tick.__init__, XAxis._init, and YAxis._init.
  claim <k> resolveColor(T) => C ...</k>
        <rc> RC </rc>
    requires (T ==K "xtick" orBool T ==K "ytick")
     andBool notBool ({RC [labelColorKey(T)]} ==K "inherit")
     andBool C ==K {RC [labelColorKey(T)]}
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt_patch: explicit public hint uses tick.color only when
  //   labelcolor == "inherit".
  // - from_matplotlibrc: "inherit from xtick.color" / "inherit from
  //   ytick.color".
  claim <k> resolveColor(T) => C ...</k>
        <rc> RC </rc>
    requires (T ==K "xtick" orBool T ==K "ytick")
     andBool {RC [labelColorKey(T)]} ==K "inherit"
     andBool C ==K {RC [tickColorKey(T)]}
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the exponent / offset text should use the tick label color.
  // - from_code: XAxis._init and YAxis._init call offsetText.set(..., color=...).
  claim <k> initOffset(T) => . ...</k>
        <rc> RC </rc>
        <offsetColor> .Map => (T |-> resolveColorFromRc(RC, T)) </offsetColor>
    requires T ==K "xtick" orBool T ==K "ytick"
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_tests_and_docs: tick labels use labelcolor independently
  //   from tick marker color.
  // - from_code: Tick.__init__ uses the same resolver when labelcolor is not
  //   supplied.
  claim <k> initDefaultTickLabels(T) => . ...</k>
        <rc> RC </rc>
        <tickLabelColor> .Map => (T |-> resolveColorFromRc(RC, T)) </tickLabelColor>
    requires T ==K "xtick" orBool T ==K "ytick"
    [all-path]
endmodule
