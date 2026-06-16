requires "mini-admin-checks.k"

module MINI-ADMIN-CHECKS-SPEC
  imports MINI-ADMIN-CHECKS
  imports INT
  imports STRING

  // SPEC-PROVENANCE:
  // - from_prompt: "include the field name in the readonly_fields checks"
  //   => invalid readonly_fields entries must appear in the admin.E035 message.
  // - from_prompt: "indicate the index of the value at fault"
  //   => the indexed readonly_fields label remains part of the message.
  // - from_code: _check_readonly_fields_item() accepts callables, admin attrs,
  //   model attrs, and model fields without errors.
  claim
    <k> checkReadonlyFieldsItem(
          ADMIN:String, MODEL:String, FIELD:String, LABEL:Label,
          false, false, false, false
        )
      => oneError("admin.E035", readonlyE035(LABEL, FIELD, ADMIN, MODEL))
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the indexed setting path is still required.
  // - from_code: _check_readonly_fields() passes "readonly_fields[%d]" to
  //   _check_readonly_fields_item() for each enumerated item.
  claim
    <k> checkReadonlyFieldsAt(
          ADMIN:String, MODEL:String, FIELD:String, INDEX:Int,
          false, false, false, false
        )
      => oneError("admin.E035", readonlyE035(readonlyLabel(INDEX), FIELD, ADMIN, MODEL))
    </k>
    requires INDEX >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: a callable readonly_fields entry is valid.
  claim
    <k> checkReadonlyFieldsItem(
          ADMIN:String, MODEL:String, FIELD:String, LABEL:Label,
          true, HASADMIN:Bool, HASMODEL:Bool, HASFIELD:Bool
        )
      => noErrors
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: a ModelAdmin attribute named by readonly_fields is valid.
  claim
    <k> checkReadonlyFieldsItem(
          ADMIN:String, MODEL:String, FIELD:String, LABEL:Label,
          false, true, HASMODEL:Bool, HASFIELD:Bool
        )
      => noErrors
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: a model class attribute named by readonly_fields is valid.
  claim
    <k> checkReadonlyFieldsItem(
          ADMIN:String, MODEL:String, FIELD:String, LABEL:Label,
          false, false, true, HASFIELD:Bool
        )
      => noErrors
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: a model field resolved by _meta.get_field() is valid.
  claim
    <k> checkReadonlyFieldsItem(
          ADMIN:String, MODEL:String, FIELD:String, LABEL:Label,
          false, false, false, true
        )
      => noErrors
    </k>
    [all-path]
endmodule
