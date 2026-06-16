module MINI-PYTHON-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports LIST-SYNTAX

  syntax Class ::= "Perm" | "Sub"
  syntax Obj ::= "obj" "(" Class "," List ")"
               | "noObj"

  syntax CtorCase ::= "empty" | "cycleArgs" | "cycleObj"
                    | "singleton" | "arrayForm"

  syntax Cmd ::= "afNew" "(" Class "," List ")"
               | "constructorFast" "(" Class "," CtorCase "," List ")"
               | "constructorArray" "(" Class "," List ")"
               | "constructExisting" "(" Class "," Obj ")"
               | "operationFresh" "(" Obj "," List ")"
               | "classmethodFresh" "(" Class "," List ")"
               | "moduleAliasAfNew" "(" List ")"
endmodule

module MINI-PYTHON
  imports MINI-PYTHON-SYNTAX
  imports BOOL
  imports LIST

  configuration
    <k> $PGM:Cmd </k>
    <result> noObj </result>

  syntax Bool ::= isInstance(Obj, Class) [function]
  rule isInstance(obj(C:Class, A:List), C) => true
  rule isInstance(obj(Sub, A:List), Perm) => true
  rule isInstance(obj(Perm, A:List), Sub) => false
  rule isInstance(noObj, C:Class) => false

  syntax Obj ::= existingResult(Class, Obj) [function]
  rule existingResult(C:Class, O:Obj) => O
    requires isInstance(O, C)
  rule existingResult(C:Class, obj(OC:Class, A:List)) => obj(C, A)
    requires notBool isInstance(obj(OC, A), C)

  rule <k> afNew(C:Class, A:List) => .K </k>
       <result> _ => obj(C, A) </result>

  rule <k> constructorFast(C:Class, CASE:CtorCase, A:List)
            => afNew(C, A) ... </k>

  rule <k> constructorArray(C:Class, A:List) => .K </k>
       <result> _ => obj(C, A) </result>

  rule <k> constructExisting(C:Class, O:Obj) => .K </k>
       <result> _ => existingResult(C, O) </result>

  rule <k> operationFresh(obj(C:Class, OLD:List), A:List)
            => afNew(C, A) ... </k>

  rule <k> classmethodFresh(C:Class, A:List)
            => afNew(C, A) ... </k>

  rule <k> moduleAliasAfNew(A:List)
            => afNew(Perm, A) ... </k>
endmodule

