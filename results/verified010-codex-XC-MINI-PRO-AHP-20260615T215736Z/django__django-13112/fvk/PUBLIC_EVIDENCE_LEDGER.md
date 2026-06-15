# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Public evidence | Obligation |
| --- | --- | --- |
| E1 | Problem title: "makemigrations crashes for ForeignKey with mixed-case app name." | Fix migration serialization for mixed-case app labels. |
| E2 | Error references `dj_reglogin.category`, but installed app is `DJ_RegLogin`. | Preserve `DJ_RegLogin` exactly. |
| E3 | Public hint: app labels are case-sensitive in migrations. | Do not lowercase app labels. |
| E4 | `make_model_tuple()` returns `(app_label, model_name.lower())`. | Lowercase only model names for normalized string references. |
| E5 | `Options.label_lower` preserves `app_label` and uses `model_name`. | Concrete branch already has the right shape. |
| E6 | `Apps.get_model()` documents model names as case-insensitive and app lookup through exact labels. | App label and model name have different case rules. |

