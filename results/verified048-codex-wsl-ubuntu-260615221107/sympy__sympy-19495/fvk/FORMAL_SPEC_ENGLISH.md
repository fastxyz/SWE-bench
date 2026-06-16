# Formal Spec English

Status: English paraphrase of the K claims in `conditionset-subs-spec.k`;
constructed, not machine-checked.

C1. External true guard claim: for any `ConditionSet` state with expression dummy
`SYM`, condition `COND`, base `BASE`, substitution pair `OLD -> NEW`, if
`OLD` is not the dummy, `COND.subs(OLD, NEW)` is true, and `COND` does not depend
on `SYM`, then `_eval_subs` returns `BASE.subs(OLD, NEW)`.

C2. ImageSet preservation corollary: under C1, if the substituted base is an
`ImageSet`, the returned object is that substituted `ImageSet`, not a new
`ConditionSet` with `NEW` as dummy.

C3. Dummy-dependent true guard claim: for any state with `OLD` not the dummy,
`COND.subs(OLD, NEW)` true, and `COND` dependent on the dummy, `_eval_subs`
returns the legacy fallback `ConditionSet(NEW, Contains(NEW, substituted_base),
substituted_base)`.

C4. Non-true guard frame claim: for any state with `OLD` not the dummy and
`COND.subs(OLD, NEW)` not true, `_eval_subs` returns
`ConditionSet(SYM, substituted_condition, substituted_base)` through the existing
constructor path.

C5. Compatibility claim: the proof obligations do not change method signatures,
call protocols, or test files.

