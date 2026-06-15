module MINI-DJANGO-DELETE-SYNTAX
  imports INT-SYNTAX
  imports MAP-SYNTAX

  syntax Obj ::= "obj"
  syntax Model ::= "model"
  syntax Pk ::= pk(Int) | nonePk
  syntax Ret ::= noResult | deleteResult(Int, Model)
  syntax ObjList ::= ".Objs" | Obj ";" ObjList

  syntax KItem ::= singleFastDelete(Obj, Model, Pk, Int)
                 | deleteBatch(Model, Pk, Int)
                 | clearPk(Obj)
                 | finishDelete(Int, Model)
                 | normalCollectedDelete(ObjList, Model, Int)
                 | clearCollected(ObjList)

  syntax KResult ::= Ret
endmodule

module MINI-DJANGO-DELETE
  imports MINI-DJANGO-DELETE-SYNTAX
  imports INT
  imports MAP

  configuration
    <k> $PGM:K </k>
    <objPks> .Map </objPks>
    <ret> noResult </ret>

  // Optimized V1 branch: SQL deletion must return before the in-memory PK is cleared.
  rule <k> singleFastDelete(O, M, P, C) => deleteBatch(M, P, C) ~> clearPk(O) ~> finishDelete(C, M) ... </k>

  // Abstract successful DeleteQuery.delete_batch(); database details are outside this issue.
  rule <k> deleteBatch(M, P, C) => .K ... </k>

  // Model instance cleanup, corresponding to setattr(instance, model._meta.pk.attname, None).
  rule <k> clearPk(O) => .K ... </k>
       <objPks> PKS => PKS [ O <- nonePk ] </objPks>

  rule <k> finishDelete(C, M) => .K ... </k>
       <ret> _ => deleteResult(C, M) </ret>

  // Existing normal cleanup path, included as the reference behavior.
  rule <k> normalCollectedDelete(OS, M, C) => clearCollected(OS) ~> finishDelete(C, M) ... </k>
  rule <k> clearCollected(.Objs) => .K ... </k>
  rule <k> clearCollected(O ; REST) => clearPk(O) ~> clearCollected(REST) ... </k>
endmodule
