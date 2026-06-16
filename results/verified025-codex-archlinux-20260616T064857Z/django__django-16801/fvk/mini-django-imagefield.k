module MINI-DJANGO-IMAGEFIELD-SYNTAX
  imports BOOL-SYNTAX

  syntax Action ::= "contribute" "(" Bool "," Bool "," Bool ")"
                  | "updateDims" "(" Bool "," Bool "," Bool ")"
                  | "assignImage" "(" Bool ")"

  syntax Result ::= "connected" "(" Bool ")"
                  | "dimensionsChanged" "(" Bool ")"
                  | "forceUpdateCalled" "(" Bool ")"

  syntax KResult ::= Result
endmodule

module MINI-DJANGO-IMAGEFIELD
  imports MINI-DJANGO-IMAGEFIELD-SYNTAX
  imports BOOL

  configuration <k> $PGM:Action </k>

  // contribute(Abs, W, H) abstracts ImageField.contribute_to_class().
  rule <k> contribute(Abs:Bool, W:Bool, H:Bool)
        => connected(notBool Abs andBool (W orBool H)) </k>

  // updateDims(W, H, Deferred) abstracts the early return in
  // ImageField.update_dimension_fields().
  rule <k> updateDims(false, false, Deferred:Bool)
        => dimensionsChanged(false) </k>
  rule <k> updateDims(W:Bool, H:Bool, true)
        => dimensionsChanged(false) </k>
    requires W orBool H
  rule <k> updateDims(W:Bool, H:Bool, false)
        => dimensionsChanged(true) </k>
    requires W orBool H

  // assignImage(Prev) abstracts ImageFileDescriptor.__set__().
  rule <k> assignImage(Prev:Bool) => forceUpdateCalled(Prev) </k>
endmodule
