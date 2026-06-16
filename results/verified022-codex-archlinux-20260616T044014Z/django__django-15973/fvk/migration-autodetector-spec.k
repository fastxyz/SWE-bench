requires "mini-migration-deps.k"

module MIGRATION-AUTODETECTOR-SPEC
  imports MINI-MIGRATION-DEPS

  // SPEC-PROVENANCE:
  // - from_prompt: ManyToManyField target is "variavel.VariavelModel".
  // - from_prompt: explicit through is "fonte_variavel.FonteVariavelModel".
  // - obligation: generated dependencies include the target app and the through app.
  claim [EXPLICIT-THROUGH-CROSS-APP]:
    <k> deps(field(
          ref("variavel", "variavelmodel"),
          through(ref("fonte_variavel", "fontevariavelmodel")),
          notSwappable
        ))
      => dep("variavel", "variavelmodel", true),
         dep("fonte_variavel", "fontevariavelmodel", true),
         .Deps
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_intent: no explicit through means no explicit through dependency.
  // - obligation: preserve existing normal relation behavior.
  claim [NO-THROUGH]:
    <k> deps(field(
          ref("variavel", "variavelmodel"),
          noThrough,
          notSwappable
        ))
      => dep("variavel", "variavelmodel", true), .Deps
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: swappable targets use the setting dependency branch.
  // - from_intent: explicit concrete through still depends on the through model.
  // - obligation: preserve swappable target behavior while fixing through dependency.
  claim [SWAPPABLE-WITH-THROUGH]:
    <k> deps(field(
          ref("auth", "user"),
          through(ref("accounts", "membership")),
          swappable("AUTH_USER_MODEL")
        ))
      => dep("__setting__", "AUTH_USER_MODEL", true),
         dep("accounts", "membership", true),
         .Deps
    </k>
    [all-path]
endmodule
