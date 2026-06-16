# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "QuerySet.only() after select_related() crash on proxy models." | The crash is the symptom to remove, not behavior to preserve. | Encoded in SPEC.md and FINDINGS.md. |
| E2 | `benchmark/PROBLEM.md` | `list(AnotherModel.objects.select_related("custom").only("custom__name").all())` raises `ValueError: 'id' is not in list`. | For this query shape, the selected related columns must include the related primary key attname. | Encoded by PO2, PO3, and PO4. |
| E3 | `benchmark/PROBLEM.md` | `custom = models.ForeignKey(ProxyCustomModel, ...)` where `ProxyCustomModel` is `proxy = True`. | A relation target can be a proxy model while its database fields belong to the concrete model. | Encoded by the `concrete(proxyCustomModel) = customModel` rule in `mini-python.k`. |
| E4 | Public hint in `benchmark/PROBLEM.md` | "I would fix cur_model instead: cur_model = cur_model._meta.concrete_model opts = cur_model._meta" | The intended repair is to normalize traversal state to the concrete model, not only to special-case a later consumer. | Encoded by PO2 and the V1 source change. |
| E5 | `repo/django/db/models/sql/query.py` | `must_include = {orig_opts.concrete_model: {orig_opts.pk}}` and later `target[model] = {f.attname for f in fields}`. | Deferred-loading masks are keyed by model and contain field attnames. | Used as implementation evidence for the K model state. |
| E6 | `repo/django/db/models/sql/compiler.py` | `if field.model in only_load and field.attname not in only_load[field.model]: continue`. | Column selection checks the concrete field owner's model key, so mask construction must put required fields under that key. | Encoded by PO4. |
| E7 | `repo/django/db/models/query.py` | `self.pk_idx = self.init_list.index(self.model_cls._meta.pk.attname)`. | The related select list must contain the related model primary key attname. | Encoded by PO4 and F1. |
| E8 | `repo/tests/proxy_models/models.py` | `Issue.assignee = models.ForeignKey(ProxyTrackerUser, ...)` and `ProxyTrackerUser` is a proxy. | Existing public test models include the same proxy-FK shape as the issue. | Supporting evidence only; tests were not modified. |

