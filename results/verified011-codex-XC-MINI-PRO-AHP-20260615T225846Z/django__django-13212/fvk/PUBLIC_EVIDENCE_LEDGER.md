# Public Evidence Ledger

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "Make validators include the provided value in ValidationError" | Invalid reusable validators must pass the provided input in error params. |
| E2 | `benchmark/PROBLEM.md` | "use a %(value)s placeholder" | The required params key is `value`. |
| E3 | `benchmark/PROBLEM.md` | Invalid email examples such as "blah" | `EmailValidator` must expose the full invalid email. |
| E4 | `repo/docs/ref/validators.txt` | `django.core.validators` contains callable validators for model/form fields | Core validators are in scope. |
| E5 | `repo/docs/ref/validators.txt` | Validator example uses `params={'value': value}` | The mechanism is `ValidationError.params`, not message rewriting. |
| E6 | `repo/docs/ref/contrib/postgres/validators.txt` | `KeysValidator` is documented in a validators module | `KeysValidator` is a public reusable validator in scope. |
| E7 | Source inspection | `BaseValidator` already includes `value` | Base-derived validators already satisfy the obligation. |
| E8 | Source inspection | URL, email, file, decimal, and key validators inspect derived values | The spec must require the original submitted value, not the helper value. |
