module MINI-MODEL-FORMSET-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Action ::= save(Bool, Int, Int)
                  | saveNewObjects(Bool, Int)
                  | factory(Bool)
  syntax KResult ::= Int | Bool
endmodule

module MINI-MODEL-FORMSET
  imports MINI-MODEL-FORMSET-SYNTAX
  imports INT
  imports BOOL

  configuration
    <k> $PGM:Action </k>
    <created> 0 </created>
    <newObjects> 0 </newObjects>
    <result> 0 </result>
    <editOnly> false </editOnly>

  // save(editOnly, existingSaved, eligibleNew) abstracts
  // BaseModelFormSet.save(commit): existingSaved is the number of existing
  // objects saved/deleted through the existing-object path, and eligibleNew is
  // the number of changed, non-deleted extra forms that would create objects.
  rule
    <k> save(true, E:Int, N:Int) => .K </k>
    <created> _ => 0 </created>
    <newObjects> _ => 0 </newObjects>
    <result> _ => E </result>
    <editOnly> _ => true </editOnly>
    requires E >=Int 0 andBool N >=Int 0

  rule
    <k> save(false, E:Int, N:Int) => .K </k>
    <created> _ => N </created>
    <newObjects> _ => N </newObjects>
    <result> _ => E +Int N </result>
    <editOnly> _ => false </editOnly>
    requires E >=Int 0 andBool N >=Int 0

  // Direct calls to the base save_new_objects() method are also guarded.
  rule
    <k> saveNewObjects(true, N:Int) => .K </k>
    <created> _ => 0 </created>
    <newObjects> _ => 0 </newObjects>
    <result> _ => 0 </result>
    <editOnly> _ => true </editOnly>
    requires N >=Int 0

  rule
    <k> saveNewObjects(false, N:Int) => .K </k>
    <created> _ => N </created>
    <newObjects> _ => N </newObjects>
    <result> _ => N </result>
    <editOnly> _ => false </editOnly>
    requires N >=Int 0

  // factory(edit_only) abstracts each public factory assigning the class flag.
  rule
    <k> factory(B:Bool) => .K </k>
    <editOnly> _ => B </editOnly>
endmodule
