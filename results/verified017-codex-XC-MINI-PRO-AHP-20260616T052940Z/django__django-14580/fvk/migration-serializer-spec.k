requires "mini-migration-serializer.k"

module MIGRATION-SERIALIZER-SPEC
  imports MINI-MIGRATION-SERIALIZER

  // SPEC-PROVENANCE:
  // - INT-1: generated migrations must be valid Python.
  // - INT-2: the public issue shows "models.Model" in bases raising
  //   NameError because "models" is not defined.
  // - INT-4: the public hint localizes the issue to TypeSerializer's
  //   models.Model special case.
  // CLAIM: SERIALIZE-MODELS-MODEL
  claim
    <k> serializeType(ModelsModel)
      => ser("models.Model", SetItem("from django.db import models"))
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - Frame condition: preserve unrelated special-case behavior.
  // CLAIM: SERIALIZE-NONE-TYPE
  claim
    <k> serializeType(NoneType)
      => ser("type(None)", .Set)
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - Frame condition: preserve custom type serialization.
  // - Supports the "app.models.MyMixin" half of the public reproducer.
  // CLAIM: SERIALIZE-CUSTOM-TYPE
  claim
    <k> serializeType(CustomType(M:String, Q:String))
      => ser(M +String "." +String Q, SetItem("import " +String M))
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - INT-2: reported bases text contains both app.models.MyMixin and
  //   models.Model.
  // - INT-3: bases must carry their own imports even when fields do not add
  //   "from django.db import models".
  // CLAIM: SERIALIZE-REPORTED-BASES
  claim
    <k> serializeTuple2(CustomType("app.models", "MyMixin"), ModelsModel)
      => ser("(app.models.MyMixin, models.Model)",
             SetItem("import app.models") SetItem("from django.db import models"))
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - INT-1 and INT-2 require the final migration imports to bind "models"
  //   whenever "models.Model" appears in the generated body.
  // - IMPL-2 shows MigrationWriter already merges this token into the
  //   django.db import line.
  // CLAIM: RENDER-WITH-MODELS
  claim
    <k> renderDjangoDbImport(SetItem("import app.models") SetItem("from django.db import models"))
      => "from django.db import migrations, models"
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - Frame condition: do not add the models import when no serializer
  //   requested it.
  // CLAIM: RENDER-WITHOUT-MODELS
  claim
    <k> renderDjangoDbImport(SetItem("import app.models"))
      => "from django.db import migrations"
    </k>
    [all-path]
endmodule
