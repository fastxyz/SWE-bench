# Public Evidence Ledger

Status: constructed, not machine-checked.

## E1: Reported intent

- Source: `benchmark/PROBLEM.md`
- Quoted evidence: "OuterRef in exclude() or ~Q() uses wrong model."
- Semantic obligation: `OuterRef()` in the negated many-valued relation path must resolve to the same outer model it would have resolved to without the internal `split_exclude()` rewrite.
- Status: encoded by PO1 and claim `OUTERREF-SHIFT`.

## E2: Public reproduction

- Source: `benchmark/PROBLEM.md`
- Quoted evidence: `Item.objects.exclude(tags__category_id=OuterRef('pk'))` inside `Exists()` "crashes"; `Item.objects.filter(~Q(tags__category_id=OuterRef('pk')))` also "crashes".
- Semantic obligation: both `exclude()` and negated `Q()` paths must be covered because both reach `split_exclude()` for a negated many-valued relation.
- Status: encoded by I2 and FINDING F1.

## E3: Public alias diagnosis

- Source: `benchmark/PROBLEM.md`
- Quoted evidence: `OuterRef resolves to "V0"."id" instead of "queries_number"."id"`.
- Semantic obligation: the reference must not bind to the immediate `Item` query alias created by the `Exists()` subquery; it must survive one more resolution level and bind to the enclosing `Number` query.
- Status: encoded by PO1 and PO2.

## E4: Existing nested `OuterRef` mechanism

- Source: `repo/django/db/models/expressions.py`
- Quoted evidence: `if isinstance(self.name, self.__class__): return self.name`
- Semantic obligation: wrapping an existing `OuterRef` in another `OuterRef` is the existing mechanism for delaying resolution by one query level.
- Status: encoded by the mini semantics rule `resolveStep(OuterRef(OuterRef(R)), Q) => OuterRef(R)`.

## E5: Existing `F()` compensation in `split_exclude()`

- Source: `repo/django/db/models/sql/query.py`
- Quoted evidence: `elif isinstance(filter_rhs, F): filter_expr = (filter_lhs, OuterRef(filter_rhs.name))`
- Semantic obligation: plain local `F()` values must continue to be shifted outward one level when `split_exclude()` introduces a generated nested query.
- Status: encoded by PO3 and claim `PLAIN-F-PRESERVED`.

## E6: Candidate V1 behavior

- Source: `repo/django/db/models/sql/query.py`
- Quoted evidence: `if isinstance(filter_rhs, OuterRef): filter_expr = (filter_lhs, OuterRef(filter_rhs))`
- Semantic obligation: an existing `OuterRef` is shifted by one additional level before the generated query resolves it.
- Status: checked by PO1.

## E7: Compatibility surface

- Source: source inspection under `repo/django/db/models/sql/query.py`
- Quoted evidence: the changed method is still `def split_exclude(self, filter_expr, can_reuse, names_with_path):`
- Semantic obligation: no public call signature or return shape changes.
- Status: encoded by PO5 and `PUBLIC_COMPATIBILITY_AUDIT.md`.

