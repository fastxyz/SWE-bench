// mini-python.k
// =============================================================================
// Minimal K semantics fragment for the *parent-link selection loop* extracted
// from django/db/models/base.py (ModelBase.__new__), as patched by V1.
//
// The V1 loop (per processed base, over base._meta.local_fields) is:
//
//     for field in base._meta.local_fields:
//         if isinstance(field, OneToOneField):
//             related     = resolve_relation(new_class, field.remote_field.model)
//             related_key = make_model_tuple(related)
//             existing    = parent_links.get(related_key)
//             if existing is not None and existing.remote_field.parent_link:
//                 continue
//             parent_links[related_key] = field
//
// MODELLING ABSTRACTION (provenance: from_code; soundness argument in PROOF.md):
//  * The dict `parent_links` is keyed by *target model*; the body for one key
//    never touches another key.  So we fix ONE key K and model only the
//    sub-sequence of OneToOneFields that target K, in processing order
//    (= bases in `reversed([new_class] + parents)`, x each base's local_fields).
//  * A field is modelled by its `parent_link` boolean flag plus its position in
//    that sub-sequence (positions are distinct, so position == identity).  The
//    input is therefore a list `L` of booleans b_1,...,b_n (b_j = the j-th
//    OneToOneField-to-K's parent_link flag, in processing order).
//  * `parent_links.get(key)` -> the currently chosen field (None == absent) is
//    modelled by `chosen` (0 == None, else the 1-based position) and `cpl`
//    (the chosen field's parent_link flag).  `parent_links[key] = field` is a
//    store of (chosen := position, cpl := flag).
//
// This fragment models ONLY the constructs that loop uses: Int/Bool/None values,
// a cons-list of booleans with head/tail/isEmpty, the boolean ops not/and/or/==,
// integer +, variable assignment, `if`, `while`, and statement sequencing.
// No general dicts, classes, functions, or exceptions are modelled (none are
// needed for the selection property).  It is a deliberate "mini-X" placeholder
// for real Python-in-K, kept small, faithful, and commented.
// =============================================================================

module MINI-PYTHON-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX

  // Runtime values and a cons-list of booleans (the parent_link flags).
  syntax Val   ::= Int | Bool | "None"
  syntax BList  ::= ".BList" | Bool ":" BList            [right]

  // Expressions (only what the loop evaluates).
  syntax Exp ::= Val | BList | Id
              | "head" "(" Exp ")"      [strict]
              | "tail" "(" Exp ")"      [strict]
              | "isEmpty" "(" Exp ")"   [strict]
              | "not" Exp               [strict]
              > Exp "and" Exp           [seqstrict]
              | Exp "or"  Exp           [seqstrict]
              | Exp "==" Exp            [seqstrict]
              | Exp "+"  Exp            [seqstrict]
              | "(" Exp ")"             [bracket]

  // Statements.
  syntax Stmt ::= Id "=" Exp ";"                         [strict(2)]
              | "if" "(" Exp ")" "{" Stmt "}"
              | "while" "(" Exp ")" "{" Stmt "}"
              | "skip" ";"
              > Stmt Stmt                                [right]
endmodule

module MINI-PYTHON
  imports MINI-PYTHON-SYNTAX
  imports INT
  imports BOOL
  imports MAP

  // <k> holds the remaining program; <store> maps program variables to values.
  configuration
    <k> $PGM:Stmt </k>
    <store> .Map </store>

  // ---- variable lookup ----
  rule <k> X:Id => V ...</k> <store>... X |-> V ...</store>

  // ---- boolean list primitives ----
  rule head(B:Bool : _:BList)   => B
  rule tail(_:Bool : T:BList)   => T
  rule isEmpty(.BList)          => true
  rule isEmpty(_:Bool : _:BList) => false

  // ---- boolean / integer operators ----
  rule not true   => false
  rule not false  => true
  rule true  and B:Bool  => B
  rule false and _:Bool  => false
  rule true  or  _:Bool  => true
  rule false or  B:Bool  => B
  rule I1:Int  == I2:Int  => I1 ==Int  I2
  rule B1:Bool == B2:Bool => B1 ==Bool B2
  rule I1:Int  +  I2:Int  => I1 +Int I2

  // ---- assignment (value or list) ----
  rule <k> X:Id = V:Val ; => . ...</k>
       <store> S => S [ X <- V ] </store>
  rule <k> X:Id = L:BList ; => . ...</k>
       <store> S => S [ X <- L ] </store>

  // ---- sequencing / skip ----
  rule <k> S1:Stmt S2:Stmt => S1 ~> S2 ...</k>
  rule <k> skip ; => . ...</k>

  // ---- if ----
  rule <k> if (true)  { S } => S ...</k>
  rule <k> if (false) { _ } => . ...</k>

  // ---- while (unrolls to a guarded if; the loop claim discharges it) ----
  rule <k> while (C) { S } => if (C) { S ~> while (C) { S } } ...</k>
endmodule
