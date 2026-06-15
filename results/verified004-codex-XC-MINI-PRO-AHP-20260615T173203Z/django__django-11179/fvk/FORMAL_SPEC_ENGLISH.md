# Formal Spec English

Status: constructed, not machine-checked.

K-OPT-FAST-SINGLE-CLEAR-PK:
Starting from a collector state representing one saved instance `obj` of `model` with primary key `pk(P)`, where the optimized single-object fast-delete branch is selected and the SQL delete operation returns normally with count `C`, execution reaches a returned delete result `deleteResult(C, model)` and the object primary key map records `obj -> nonePk`.

K-NORMAL-COLLECTED-CLEAR-PK:
Starting from a normal collected-delete cleanup state containing `obj` with primary key `pk(P)`, execution reaches the returned delete result and the object primary key map records `obj -> nonePk`.

Frame condition:
The constructed claims preserve the delete count/model result shape. They do not alter method signatures, queryset-delete cache clearing, signal behavior, cascade behavior, or field-update behavior.

Partial-correctness boundary:
The claims cover normal return from the delete operation. If the SQL delete raises before returning, the postcondition is not claimed; this matches the source ordering where cleanup occurs after the database delete step.
