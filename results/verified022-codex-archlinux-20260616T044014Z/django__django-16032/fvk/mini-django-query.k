module MINI-DJANGO-QUERY-SYNTAX
  imports BOOL-SYNTAX

  syntax Field ::= "pk" | "target" | "explicit"
  syntax Select ::= "defaultCols" | "emptySelect" | "pkSelect"
                  | "targetSelect" | "explicitSelect"
  syntax Mask ::= "maskNone" | "maskEmpty" | "maskAnnotation"
  syntax QueryState ::= "query(" Bool "," Select "," Mask ")"

  syntax Cmd ::= "annotate"
               | "aliasAfterAnnotate"
               | "setValues(" Field ")"
               | "inPrep"
               | "exactPrepOne"
               | "relatedInPrep(" Bool "," Bool ")"
               | "clone"
               | Cmd ";" Cmd [left]

  syntax KResult ::= QueryState
endmodule

module MINI-DJANGO-QUERY
  imports MINI-DJANGO-QUERY-SYNTAX
  imports BOOL

  configuration
    <k> $PGM:Cmd </k>
    <q> query(false, defaultCols, maskNone) </q>

  rule <k> C1:Cmd ; C2:Cmd => C1 ~> C2 ... </k>

  // Query.add_annotation(..., select=True) does not create values-style
  // selected fields.
  rule <k> annotate => .K ... </k>
       <q> query(H:Bool, S:Select, M:Mask)
        => query(H, S, M)
       </q>

  // Query.add_annotation(..., select=False), as used by QuerySet.alias(),
  // can materialize the annotation mask but must not mark explicit selection.
  rule <k> aliasAfterAnnotate => .K ... </k>
       <q> query(H:Bool, S:Select, _:Mask)
        => query(H, S, maskAnnotation)
       </q>

  rule <k> setValues(pk) => .K ... </k>
       <q> query(_:Bool, _:Select, _:Mask)
        => query(true, pkSelect, maskEmpty)
       </q>

  rule <k> setValues(target) => .K ... </k>
       <q> query(_:Bool, _:Select, _:Mask)
        => query(true, targetSelect, maskEmpty)
       </q>

  rule <k> setValues(explicit) => .K ... </k>
       <q> query(_:Bool, _:Select, _:Mask)
        => query(true, explicitSelect, maskEmpty)
       </q>

  // In.get_prep_lookup(): an RHS Query with no explicit select fields is
  // narrowed to pk. This is default lookup behavior, not a values() call, so
  // has_select_fields remains false in the abstract state.
  rule <k> inPrep => .K ... </k>
       <q> query(false, _:Select, _:Mask)
        => query(false, pkSelect, maskEmpty)
       </q>

  rule <k> inPrep => .K ... </k>
       <q> query(true, S:Select, M:Mask)
        => query(true, S, M)
       </q>

  // Exact.get_prep_lookup() with a one-row RHS has the same select-field
  // behavior as In.get_prep_lookup().
  rule <k> exactPrepOne => .K ... </k>
       <q> query(false, _:Select, _:Mask)
        => query(false, pkSelect, maskEmpty)
       </q>

  rule <k> exactPrepOne => .K ... </k>
       <q> query(true, S:Select, M:Mask)
        => query(true, S, M)
       </q>

  // RelatedIn.get_prep_lookup() special-cases non-primary-key relation
  // targets by using set_values(target), then delegates to In.get_prep_lookup().
  // The second Bool models the one-to-one same-model branch; both branches are
  // represented by targetSelect because both are relation-specific fields.
  rule <k> relatedInPrep(false, _:Bool) => setValues(target) ~> inPrep ... </k>
       <q> query(false, S:Select, M:Mask) </q>

  // If the relation target is already the primary key, RelatedIn delegates to
  // the base In behavior.
  rule <k> relatedInPrep(true, _:Bool) => inPrep ... </k>
       <q> query(false, S:Select, M:Mask) </q>

  rule <k> relatedInPrep(_:Bool, _:Bool) => inPrep ... </k>
       <q> query(true, S:Select, M:Mask) </q>

  // Query.clone() is abstracted as state preservation. In the implementation
  // this follows from obj.__dict__ = self.__dict__.copy().
  rule <k> clone => .K ... </k>
       <q> Q:QueryState => Q </q>
endmodule
