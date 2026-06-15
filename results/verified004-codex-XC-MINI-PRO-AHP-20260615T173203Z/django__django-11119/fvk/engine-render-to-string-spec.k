requires "mini-template-engine.k"

module ENGINE-RENDER-TO-STRING-SPEC
  imports MINI-TEMPLATE-ENGINE

  // SPEC-PROVENANCE:
  // - from_prompt: "Engine.render_to_string() should honor the autoescape attribute"
  //   => plain dict/None contexts created by the method use Engine.autoescape.
  // - from_prompt: "a Context is created without specifying the engine autoescape attribute"
  //   => the defect is the constructed-Context path, not caller-supplied Context objects.
  // - from_code: Engine.render_to_string() branches on template name before creating/rendering context.
  // - from_code: Template.render() consumes context.autoescape through template rendering.
  claim
    <k> renderToString(EA:Bool, TN:TemplateName, plain) => rendered(EA) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the reproducer uses autoescape=False and a non-Context context.
  // - discriminator: the legacy implementation would reach rendered(true) for this case.
  claim
    <k> renderToString(false, TN:TemplateName, plain) => rendered(false) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: comment in Engine.render_to_string() says existing Context objects are
  //   accepted for backwards compatibility and must not be rewrapped.
  // - from_public_compatibility: preserving caller-supplied Context.autoescape avoids
  //   changing existing explicit Context behavior.
  claim
    <k> renderToString(EA:Bool, TN:TemplateName, existing(CA:Bool)) => rendered(CA) </k>
    [all-path]
endmodule
