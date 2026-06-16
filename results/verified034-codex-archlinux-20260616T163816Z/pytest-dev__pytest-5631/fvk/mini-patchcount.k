// Constructed FVK artifact for pytest-dev__pytest-5631.
// This is a deliberately small K-style semantics fragment for the audited
// predicate in _pytest.compat.num_mock_patch_args. It is not a full Python
// semantics and has not been machine-checked in this session.

module MINI-PATCHCOUNT
  imports INT
  imports BOOL
  imports LIST
  imports K-EQUAL

  configuration <k> $PGM:Int </k>

  // Object atoms represent Python object identities, not Python == results.
  // In particular, arrayNew is an explicit new= object whose equality behavior
  // is intentionally outside this model because the fixed code must not invoke
  // it while deciding whether it is a DEFAULT sentinel.
  syntax Obj ::= "defaultMock" | "defaultUnittest" | "arrayNew" | "otherNew"

  // First Bool: true means p.attribute_name is truthy/present.
  // false means not p.attribute_name, so this patch may inject a mock argument
  // if and only if its new object is one of the DEFAULT sentinel identities.
  syntax Patch ::= "patch" "(" Bool "," Obj ")"

  syntax Bool ::= identityIn(Obj, List) [function]
  rule identityIn(O:Obj, .List) => false
  rule identityIn(O:Obj, ListItem(O) SS:List) => true
  rule identityIn(O:Obj, ListItem(S:Obj) SS:List) => identityIn(O, SS)
    requires notBool (O ==K S)

  syntax Int ::= patchCount(List, List) [function]
  rule patchCount(.List, SS:List) => 0
  rule patchCount(ListItem(patch(true, O:Obj)) PS:List, SS:List)
    => patchCount(PS, SS)
  rule patchCount(ListItem(patch(false, O:Obj)) PS:List, SS:List)
    => 1 +Int patchCount(PS, SS)
    requires identityIn(O, SS) ==Bool true
  rule patchCount(ListItem(patch(false, O:Obj)) PS:List, SS:List)
    => patchCount(PS, SS)
    requires identityIn(O, SS) ==Bool false
endmodule
