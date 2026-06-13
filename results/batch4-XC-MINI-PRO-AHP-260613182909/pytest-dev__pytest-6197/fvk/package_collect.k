// package_collect.k -- mini-Python fragment for verifying the *side-effect
// invariant* of `_pytest.python.Package.collect()` (the V1 fix for #6197).
//
// ==========================================================================
// CONSTRUCTED, NOT MACHINE-CHECKED (FVK MVP).
// This definition is written to be kompile/kprove-able, but the toolchain is
// NOT run in this environment (see the task constraints). Treat every result
// as "constructed, not machine-checked".
// ==========================================================================
//
// WHAT IS ABSTRACTED
// ------------------
// `Package.collect()` is a generator. The only state relevant to the property
// we care about is:
//   * mounted  -- whether self._mount_obj_if_needed() has run (0/1). The IMPORT
//                 of __init__.py is the side effect of the 0->1 transition.
//   * yielded  -- how many collectible nodes the generator has produced so far.
//
// Everything else the method touches -- the filesystem `visit`, `_recurse`,
// `_collectfile`, `pkg_prefixes`, the skip/`continue` branches -- contributes
// *zero* mounts and *zero* yields and is therefore invisible to this property.
// Each node the method actually yields is produced by the SAME two adjacent
// statements ("_mount_obj_if_needed(); yield x", and the init-module branch
// "_mount_obj_if_needed(); yield Module(init_module)").
//
// So, for the side-effect property, `collect()` is faithfully modelled by a
// single counting loop that, N times (N = total nodes yielded = init-module?
// 1:0 + sum over visited files of len(_collectfile(path))), performs
//   "mounted = 1 ; yielded = yielded + 1".
// `mounted = 1` is idempotent (mirrors the `if obj is None` guard inside
// _mount_obj_if_needed), so re-running it after the first node is a no-op.
//
// Only the constructs this model uses are defined below: Int/Bool/Id names,
// `+`, `<`, assignment, sequencing, and `while`. No functions/lists/maps
// beyond a flat <store>.

module PACKAGE-COLLECT-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX

  syntax AExp ::= Int | Id
                | "(" AExp ")"            [bracket]
                > AExp "+" AExp           [seqstrict, left]

  syntax BExp ::= Bool
                | AExp "<" AExp           [seqstrict]

  syntax Stmt ::= Id "=" AExp ";"         [strict(2)]
                | "while" "(" BExp ")" "{" Stmt "}"
                | "{" Stmt "}"            [bracket]
                > Stmt Stmt               [left]

  syntax KResult ::= Int | Bool
endmodule

module PACKAGE-COLLECT
  imports PACKAGE-COLLECT-SYNTAX
  imports INT
  imports BOOL
  imports MAP

  configuration
    <k> $PGM:Stmt </k>
    <store> .Map </store>

  // name lookup
  rule <k> X:Id => V ... </k> <store> ... X |-> V ... </store>

  // arithmetic and comparison (builtins)
  rule <k> I1:Int + I2:Int => I1 +Int I2 ... </k>
  rule <k> I1:Int < I2:Int => I1 <Int I2 ... </k>

  // assignment (mirrors both `mounted = 1` and `yielded = yielded + 1`)
  rule <k> X:Id = I:Int ; => .K ... </k>
       <store> STORE => STORE [ X <- I ] </store>

  // sequencing
  rule <k> S1:Stmt S2:Stmt => S1 ~> S2 ... </k>   [structural]

  // while: freeze an unevaluated copy of the guard, evaluate a fresh copy at
  // the head of <k> each iteration (the standard mini-X while pattern).
  syntax KItem ::= #while(BExp, Stmt) | #branch(BExp, Stmt)
  rule <k> while ( B:BExp ) { S:Stmt } => #while(B, S) ... </k>
  rule <k> #while(B:BExp, S:Stmt) => B ~> #branch(B, S) ... </k>
  rule <k> true  ~> #branch(B:BExp, S:Stmt) => S ~> #while(B, S) ... </k>
  rule <k> false ~> #branch(_:BExp, _:Stmt) => .K ... </k>
endmodule
