# FVK Findings

Status: constructed for audit, not machine-checked. Findings are derived from
public intent, source inspection, and proof obligations; no tests or code were
executed.

## F1: Reported Single-Field Total UniqueConstraint Is Covered

Input class: `USERNAME_FIELD == "username"`, `username.unique == False`, and
`_meta.total_unique_constraints` contains a constraint with
`fields == ("username",)`.

Observed in V1 by source inspection: the uniqueness branch evaluates
`field.unique or any(constraint.fields == (USERNAME_FIELD,))` to true, so it
does not append `auth.E003` or `auth.W004`.

Expected from intent ledger I1-I3: no `auth.E003` for a total
`UniqueConstraint(fields=["username"])`.

Classification: confirmed fixed behavior.

Related proof obligations: PO1, PO3.

## F2: Non-Unique USERNAME_FIELD Behavior Is Preserved

Input class: `field.unique == False` and no total single-field constraint whose
`fields` tuple equals `(USERNAME_FIELD,)`.

Observed in V1 by source inspection: the existing backend split remains inside
the same branch. Default `ModelBackend` still produces `auth.E003`; other
backends still produce `auth.W004`.

Expected from public test evidence I4 and unchanged auth-check behavior.

Classification: frame behavior preserved.

Related proof obligations: PO2, PO4, PO7.

## F3: Conditional UniqueConstraints Are Not Accidentally Accepted

Input class: the model has a conditional `UniqueConstraint` for
`USERNAME_FIELD`, but that constraint is absent from
`_meta.total_unique_constraints` because its `condition` is not `None`.

Observed in V1 by source inspection: the auth check only consults
`_meta.total_unique_constraints`, so the conditional constraint does not
satisfy `has_username_uniqueness`.

Expected from issue wording "total UniqueConstraints" and metadata evidence I5.

Classification: confirmed correct exclusion.

Related proof obligations: PO1, PO5.

## F4: Composite UniqueConstraints Are Not Over-Accepted

Input class: `_meta.total_unique_constraints` contains
`fields == ("username", "tenant")` and `USERNAME_FIELD == "username"`, with no
single-field uniqueness guarantee.

Observed in V1 by source inspection: tuple equality against `("username",)`
fails, so the check still treats the username field as non-unique.

Expected from uniqueness semantics I6: uniqueness of `(username, tenant)` does
not imply global uniqueness of `username`.

Classification: confirmed correct exclusion.

Related proof obligations: PO1, PO6.

## F5: No Public API or Compatibility Regression Found

Input class: public callsites that import or run `check_user_model()`.

Observed in V1 by source inspection: the function signature, return type, error
classes, message strings, and IDs are unchanged. Only the predicate deciding
whether the existing uniqueness branch runs was broadened.

Expected from the task: source-only targeted fix with no test edits and no
unrelated refactoring.

Classification: compatibility confirmed by inspection.

Related proof obligations: PO7.

## F6: Proof Is Constructed, Not Machine-Checked

Input class: all modeled cases above.

Observed in this benchmark: execution is forbidden, so neither tests nor
`kompile`/`kprove` were run.

Expected from benchmark constraints and FVK honesty gate: keep the source
decision grounded in public intent, but label the proof as constructed rather
than machine-verified.

Classification: residual verification limitation, not a code bug.

Related proof obligations: PO8.
