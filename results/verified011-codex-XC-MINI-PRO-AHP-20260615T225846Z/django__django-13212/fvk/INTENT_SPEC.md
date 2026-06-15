# Intent Spec

The public issue requires reusable built-in validators to include the submitted
value in `ValidationError.params` so custom error messages can interpolate
`%(value)s`.

Required behavior:

1. Invalid reusable validator calls expose `params['value']` as the original
   submitted value.
2. Existing validity decisions, messages, codes, and specialized params are
   preserved.
3. Validators that inspect helper values internally still expose the top-level
   submitted value.
4. The change is scoped to reusable validator callables documented in
   `django.core.validators` and `django.contrib.postgres.validators`.

Observed V1 behavior to audit:

V1 adds `value` params in core validators and postgres `KeysValidator` without
changing validator signatures or validity predicates.
