module MINI-PYTHON-SYNTAX
  imports STRING-SYNTAX

  syntax ModelRef ::= lazyRef(String, String)
                    | concreteRef(String, String)
  syntax SerializedRef ::= toRef(String, String)
  syntax Exp ::= serialize(ModelRef)
               | legacySerialize(ModelRef)
  syntax KResult ::= SerializedRef
endmodule

module MINI-PYTHON
  imports MINI-PYTHON-SYNTAX
  imports STRING

  configuration <k> $PGM:Exp </k>

  syntax String ::= lowerModelName(String) [function]

  // V1 behavior for the string branch of ForeignObject.deconstruct().
  rule <k> serialize(lazyRef(APP:String, MODEL:String))
        => toRef(APP, lowerModelName(MODEL)) </k>

  // Existing concrete-model branch through Options.label_lower.
  rule <k> serialize(concreteRef(APP:String, MODEL_LOWER:String))
        => toRef(APP, MODEL_LOWER) </k>

  // Pre-fix abstraction: self.remote_field.model.lower().
  rule <k> legacySerialize(lazyRef(APP:String, MODEL:String))
        => toRef(lowerModelName(APP), lowerModelName(MODEL)) </k>
endmodule

