requires "mini-django-serializer.k"

module DJANGO-15525-SPEC
  imports MINI-DJANGO-SERIALIZER
  imports INT
  imports BOOL
  imports STRING

  // SPEC-PROVENANCE:
  // - E1/E2: loaddata into a non-default database must use that database for
  //   natural-key deserialization.
  // - E4/E5: natural_key() may follow a foreign key, and relation routing uses
  //   instance._state.db as the fallback database hint.
  // - E7: public hint says to specify db before checking natural_key().
  claim [NATURAL-PRIMARY-RELATED-DB]:
    <k> buildInstanceV1(naturalModel, data(missingPk, AID:Int, TITLE:String), DB:Db)
      => built(data(pk(existingPk(naturalModel, data(missingPk, AID, TITLE), DB)), AID, TITLE))
      ... </k>
    <probeDb> defaultDb => DB </probeDb>
    <relatedReadDb> defaultDb => DB </relatedReadDb>
    <lookupDb> defaultDb => DB </lookupDb>
    requires existsByNaturalKey(naturalModel, data(missingPk, AID, TITLE), DB)
    [all-path]

  // SPEC-PROVENANCE:
  // - E3/E6: if a primary key is already present, build_instance() must not
  //   perform natural-primary-key lookup.
  claim [FRAME-PK-PRESENT]:
    <k> buildInstanceV1(MODEL:ModelKind, data(pk(PK:Int), AID:Int, TITLE:String), DB:Db)
      => built(data(pk(PK), AID, TITLE))
      ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E6: if the model/manager lacks natural-primary-key support, behavior is
  //   framed and the input data is used for normal model construction.
  claim [FRAME-NO-NATURAL]:
    <k> buildInstanceV1(plainModel, data(missingPk, AID:Int, TITLE:String), DB:Db)
      => built(data(missingPk, AID, TITLE))
      ... </k>
    [all-path]
endmodule
