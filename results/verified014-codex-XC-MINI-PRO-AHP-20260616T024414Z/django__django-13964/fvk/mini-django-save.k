module MINI-DJANGO-SAVE-SYNTAX
  imports BOOL-SYNTAX

  syntax Val ::= NoneVal | EmptyVal | FooVal | OtherVal
  syntax Cache ::= Cached | NotCached
  syntax Outcome ::= Normal | ValueError
  syntax Stmt ::= prepare(Bool, Val, Val)
                | compareTarget(Val)
endmodule

module MINI-DJANGO-SAVE
  imports MINI-DJANGO-SAVE-SYNTAX
  imports BOOL
  imports K-EQUAL

  configuration
    <k> $PGM:Stmt </k>
    <att> NoneVal </att>
    <cache> NotCached </cache>
    <outcome> Normal </outcome>

  syntax Bool ::= isEmptyValue(Val) [function]
  rule isEmptyValue(NoneVal) => true
  rule isEmptyValue(EmptyVal) => true
  rule isEmptyValue(FooVal) => false
  rule isEmptyValue(OtherVal) => false

  // Field isn't cached: _prepare_related_fields_for_save() skips it.
  rule <k> prepare(_:Bool, _:Val, _:Val) => .K ... </k>
       <cache> NotCached </cache>

  // Cached relation exists but getattr(self, field.name, None) is falsey.
  rule <k> prepare(false, _:Val, _:Val) => .K ... </k>
       <cache> Cached </cache>

  // Existing unsaved-related-object guard.
  rule <k> prepare(true, NoneVal, _:Val) => .K ... </k>
       <cache> Cached </cache>
       <outcome> Normal => ValueError </outcome>

  // V1 fix: refresh from obj.pk when the local relation value is empty.
  rule <k> prepare(true, PK:Val, TARGET:Val) => compareTarget(TARGET) ... </k>
       <cache> Cached </cache>
       <att> ATT:Val => PK </att>
    requires PK =/=K NoneVal andBool isEmptyValue(ATT)

  // Non-empty local relation values keep existing behavior.
  rule <k> prepare(true, PK:Val, TARGET:Val) => compareTarget(TARGET) ... </k>
       <cache> Cached </cache>
       <att> ATT:Val </att>
    requires PK =/=K NoneVal andBool notBool isEmptyValue(ATT)

  // Cache remains valid when the target value and local attname agree.
  rule <k> compareTarget(TARGET:Val) => .K ... </k>
       <att> TARGET </att>
       <cache> Cached </cache>

  // Otherwise, clear the owner-side cached relation.
  rule <k> compareTarget(TARGET:Val) => .K ... </k>
       <att> ATT:Val </att>
       <cache> Cached => NotCached </cache>
    requires TARGET =/=K ATT
endmodule
