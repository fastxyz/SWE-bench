// Constructed, not machine-checked.
// Exact commands, not executed in this task:
//   kompile fvk/mini-validator.k --backend haskell
//   kast --backend haskell fvk/validators-spec.k
//   kprove fvk/validators-spec.k

requires "fvk/mini-validator.k"

module VALIDATORS-SPEC
  imports MINI-VALIDATOR
  imports K-EQUAL
  imports MAP-SYMBOLIC

  // SPEC-PROVENANCE:
  // - prompt: "Make validators include the provided value in ValidationError"
  //   => every invalid in-domain validator call must expose the submitted value.
  // - prompt: "use a %(value)s placeholder" and docs example params={'value': value}
  //   => the exposed key is exactly value.
  // - docs: django.core.validators contains callable validators for model/form fields;
  //   django.contrib.postgres.validators documents KeysValidator.
  // - code: V1 uses params={'value': value} or merges 'value' into existing params.
  claim
    <k> validate(VALIDATOR:Validator, VALUE:Value)
        => error(messageOf(VALIDATOR), codeOf(VALIDATOR),
                 withValue(baseParams(VALIDATOR, VALUE), VALUE)) ... </k>
    requires isInvalid(VALIDATOR, VALUE)
    [all-path]

  // SPEC-PROVENANCE:
  // - prompt: "provided value" means the original submitted value, not a normalized
  //   URL, email domain, IP fragment, extension, or key set.
  // - code: URL and Email validators may derive sub-values internally, but V1 keeps
  //   the top-level VALUE in the final params map.
  claim
    <k> validate(VALIDATOR:Validator, VALUE:Value)
        => error(messageOf(VALIDATOR), codeOf(VALIDATOR),
                 PARAMS:Map [ value <- VALUE ]) ... </k>
    requires isInvalid(VALIDATOR, VALUE)
    [all-path]
endmodule
