// mini_python.k
// ---------------------------------------------------------------------------
// Minimal K semantics ("mini-Python") of the *only* language fragment the
// sympy Permutation subclassing fix depends on:
//
//   (1) class-tagged object creation via  Basic.__new__(C, a), and
//   (2) the three Python method-binding disciplines -- @classmethod,
//       @staticmethod, and instance method -- together with single-inheritance
//       attribute/method resolution (MRO).
//
// The verified question is purely about the *class* of the object that comes
// out of construction.  Everything that does NOT affect that class -- array
// validation, sizes, cycles vs. array form, exceptions, printing, caches --
// is deliberately abstracted away.  An object is modelled as its class tag
// plus its array form (`obj(C, A)`); a class is a name (`cls(C)`).
//
// Constructed, NOT machine-checked (FVK MVP).  The faithfulness of the four
// dispatch rules below to CPython's descriptor protocol is part of the trusted
// base, stated explicitly in PROOF.md.
// ---------------------------------------------------------------------------

module MINI-PYTHON-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX
  imports LIST

  syntax Kind ::= "cm" | "sm" | "im"     // classmethod | staticmethod | instance method

  // values
  syntax Val ::= Int | Bool | List
               | "cls" "(" Id ")"            // a class object, identified by name
               | "obj" "(" Id "," List ")"   // an instance: class tag + _array_form
               | "none"

  // expressions
  syntax Exp ::= Val | Id
               // the base constructor: object whose class is its FIRST argument
               | "Basic_new" "(" Exp "," Exp ")"            [seqstrict]
               // attribute/bound-method call  recv.M(arg)
               | "call" "(" Exp "," Id "," Exp ")"          [seqstrict(1,3)]
               // Python  C(arg)  i.e. type.__call__ -> C.__new__(C, arg)
               | "construct" "(" Exp "," Exp ")"            [seqstrict]
               | "classOf" "(" Exp ")"                      [strict]
               | "isinstance" "(" Exp "," Exp ")"           [strict]
               | "arrayForm" "(" Exp ")"                    [strict]   // a.array_form
               | "rangeList" "(" Exp ")"                    [strict]   // list(range(n+1))
               | "if" Exp "then" Exp "else" Exp             [strict(1)]
               | "ret" Exp                                  [strict]

  syntax KResult ::= Val
endmodule

module MINI-PYTHON
  imports MINI-PYTHON-SYNTAX
  imports INT
  imports BOOL
  imports MAP
  imports LIST

  // class table:  ClassName |-> classDef(ParentName, Methods)
  //   Methods :  MethodName |-> method(Kind, ExplicitParam, Body)
  //   __new__ is special: it takes TWO explicit params (the class, then args),
  //   modelled by methodNew(ClassParam, ArgParam, Body).
  syntax ClassDef ::= "classDef" "(" Id "," Map ")"
  syntax Method   ::= "method"    "(" Kind "," Id "," Exp ")"
                    | "methodNew" "(" Id "," Id "," Exp ")"

  configuration
    <k> $PGM:Exp </k>
    <env>     .Map        </env>     // current frame: Id |-> Val
    <classes> $CLASSES:Map </classes>
    <stack>   .List       </stack>   // saved caller envs (ListItem(Map))

  // ----- locals -----------------------------------------------------------
  rule <k> X:Id => V ... </k> <env> ... X |-> V ... </env>
  rule <k> ret V:Val => V ... </k>
  rule <k> if true  then E else _ => E ... </k>
  rule <k> if false then _ else E => E ... </k>

  // ----- THE CRUX --------------------------------------------------------
  // Basic.__new__(cls(C), A) constructs an object whose class is exactly the
  // first argument C.  No class name is hard-wired here; whatever class is
  // passed is the class produced.  (CPython: object.__new__(C) is an instance
  // of C.)  This single rule is what the whole fix turns on.
  rule <k> Basic_new(cls(C:Id), A:List) => obj(C, A) ... </k>

  // ----- reflection -------------------------------------------------------
  rule <k> classOf(obj(C:Id, _)) => cls(C) ... </k>
  rule <k> isinstance(obj(C:Id, _), cls(D:Id)) => isSubclass(C, D) ... </k>
  rule <k> arrayForm(obj(_, A:List)) => A ... </k>

  // subclass relation: reflexive + walk the single-parent chain to the root.
  syntax Bool ::= isSubclass(Id, Id) [function]
  rule isSubclass(C, C) => true
  rule isSubclass(C, D) => isSubclass(P, D)
       <classes> ... C |-> classDef(P:Id, _) ... </classes>
       requires C =/=Int{Id} D
  // (root has no entry; an unrelated pair bottoms out to false -- omitted owise)

  // ----- method resolution along the inheritance chain (MRO) --------------
  // mlookup walks parents until the method name is defined.
  syntax Method ::= mlookup(Map, Id, Id) [function]
  rule mlookup(CS, C, M) => methodsOf(CS, C) [[ M ]]
       requires M in_keys(methodsOf(CS, C))
  rule mlookup(CS, C, M) => mlookup(CS, parentOf(CS, C), M)
       requires notBool (M in_keys(methodsOf(CS, C)))
  syntax Map ::= methodsOf(Map, Id) [function]
  rule methodsOf(CS, C) => Ms requires CS [ C ] ==K classDef(?_, Ms)   // (sketch accessor)
  syntax Id  ::= parentOf(Map, Id) [function]
  rule parentOf(CS, C) => P requires CS [ C ] ==K classDef(P, ?_)      // (sketch accessor)

  // ----- the receiver's class as a class object --------------------------
  syntax Val ::= classObjOf(Val) [function]
  rule classObjOf(cls(C))   => cls(C)    // called ON a class  -> that class
  rule classObjOf(obj(C,_)) => cls(C)    // called on instance -> type(instance)

  // ----- DISPATCH: classmethod -------------------------------------------
  // recv.M(V) with M a @classmethod: bind the implicit name `cls` to the
  // receiver's class object, bind the explicit param, run the body.
  rule <k> call(R:Val, M:Id, V:Val) => BODY ~> #restore(RHO) ... </k>
       <env> RHO => ( cls |-> classObjOf(R) ) P |-> V </env>
       <stack> .List => ListItem(RHO) ... </stack>
       <classes> CS </classes>
    requires mlookup(CS, classNameOf(R), M) ==K method(cm, ?P:Id, ?BODY:Exp)
     andBool P  ==K ?P andBool BODY ==K ?BODY            // bind P, BODY (sketch)

  // ----- DISPATCH: staticmethod ------------------------------------------
  // recv.M(V) with M a @staticmethod: NO implicit binding; the body uses
  // whatever class name it hard-codes.
  rule <k> call(R:Val, M:Id, V:Val) => BODY ~> #restore(RHO) ... </k>
       <env> RHO => P |-> V </env>
       <stack> .List => ListItem(RHO) ... </stack>
       <classes> CS </classes>
    requires mlookup(CS, classNameOf(R), M) ==K method(sm, P, BODY)

  // ----- DISPATCH: instance method ---------------------------------------
  // inst.M(V): bind `self` to the instance, bind the explicit param, run body.
  rule <k> call(obj(C:Id,B:List), M:Id, V:Val) => BODY ~> #restore(RHO) ... </k>
       <env> RHO => ( self |-> obj(C,B) ) P |-> V </env>
       <stack> .List => ListItem(RHO) ... </stack>
       <classes> CS </classes>
    requires mlookup(CS, C, M) ==K method(im, P, BODY)

  // ----- DISPATCH: C(arg) == type.__call__ -> __new__(C, arg) -------------
  // The class being constructed (C) is passed as __new__'s first explicit
  // parameter -- even when __new__ is inherited from a base class.  (CPython
  // type.__call__.)  This is why `Sub(x)` reaches Permutation.__new__ with
  // cls bound to Sub.
  rule <k> construct(cls(C:Id), A:Val) => BODY ~> #restore(RHO) ... </k>
       <env> RHO => ( CP |-> cls(C) ) AP |-> A </env>
       <stack> .List => ListItem(RHO) ... </stack>
       <classes> CS </classes>
    requires mlookup(CS, C, #newName) ==K methodNew(CP, AP, BODY)

  // ----- return: pop frame, deliver value --------------------------------
  rule <k> V:Val ~> #restore(RHO:Map) => V ... </k>
       <env> _ => RHO </env>
       <stack> ListItem(RHO) => .List ... </stack>

  syntax Id     ::= "#newName" [macro]   // the identifier  __new__
  syntax KItem  ::= "#restore" "(" Map ")"
  syntax Id     ::= classNameOf(Val) [function]
  rule classNameOf(cls(C))   => C
  rule classNameOf(obj(C,_)) => C
endmodule
