requires "mini-default-pk.k"

module DEFAULT-PK-SPEC
  imports MINI-DEFAULT-PK
  imports BOOL

  // SPEC-PROVENANCE:
  // - prompt: "models.W042 is raised on inherited manually specified primary key."
  // - prompt: "These models should not use auto-created primary keys! I already
  //   defined the primary key in the ancestor of the model."
  // - code: parent-link primary keys have pk.auto_created=true but are not
  //   the model's _meta.auto_field.
  // - obligation: an inherited parent-link primary key must not emit W042.
  claim
    <k> checkDefaultPk(true, false, false, false) => false </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - public-test: check_framework ModelDefaultAutoFieldTests.test_auto_created_pk
  //   expects W042 for a model with an implicit default auto primary key.
  // - code: Options._prepare() creates pk_class(..., auto_created=True), and
  //   AutoFieldMixin.contribute_to_class() records that field as _meta.auto_field.
  // - obligation: an implicit default auto primary key emits W042 when neither
  //   DEFAULT_AUTO_FIELD nor AppConfig.default_auto_field was overridden.
  claim
    <k> checkDefaultPk(true, true, false, false) => true </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - public-test: explicit primary key tests expect no W042.
  // - code: explicit AutoField primary keys are _meta.auto_field, but
  //   field.auto_created is false.
  // - obligation: explicit primary keys do not emit W042.
  claim
    <k> checkDefaultPk(false, true, false, false) => false </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - existing check behavior and public tests suppress W042 when the project
  //   overrides DEFAULT_AUTO_FIELD.
  // - obligation: preserve setting-level suppression.
  claim
    <k> checkDefaultPk(true, true, true, false) => false </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - existing check behavior and public tests suppress W042 when the app
  //   overrides AppConfig.default_auto_field.
  // - obligation: preserve app-level suppression.
  claim
    <k> checkDefaultPk(true, true, false, true) => false </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - derived from the intent and compatibility obligations above.
  // - obligation: the full decision predicate is exactly the conjunction used
  //   by Model._check_default_pk() after the V1 fix.
  claim
    <k> checkDefaultPk(
      PK_AUTO_CREATED:Bool,
      PK_IS_AUTO_FIELD:Bool,
      DEFAULT_SETTING_OVERRIDDEN:Bool,
      APP_DEFAULT_AUTO_FIELD_OVERRIDDEN:Bool
    )
    => warnCondition(
      PK_AUTO_CREATED,
      PK_IS_AUTO_FIELD,
      DEFAULT_SETTING_OVERRIDDEN,
      APP_DEFAULT_AUTO_FIELD_OVERRIDDEN
    ) </k>
    [all-path]
endmodule
