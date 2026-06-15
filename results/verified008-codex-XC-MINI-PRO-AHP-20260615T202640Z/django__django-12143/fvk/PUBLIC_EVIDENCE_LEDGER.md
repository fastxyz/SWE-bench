# Public Evidence Ledger

This ledger mirrors the entries in `fvk/SPEC.md`.

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "Generating a regex like this using string formatting can cause problems when the arguments contain special regex characters." | Escape or otherwise literalize dynamic regex fragments. |
| E2 | `benchmark/PROBLEM.md` | "prefix has no such restrictions ... and could contain any number of special regex characters." | Prefix values with regex metacharacters are in domain. |
| E3 | `benchmark/PROBLEM.md` | "The fix is quite straightforward (use re.escape())." | `re.escape()` is public-intent-supported. |
| E4 | `repo/django/forms/models.py` | `pk_key = '%s-%s' % (self.add_prefix(i), self.model._meta.pk.name)` | Generated primary-key field names are prefix, index, and pk name joined by hyphens. |
| E5 | `repo/django/contrib/admin/options.py` | list comprehension over `request.POST.items()` with `pk_pattern.match(key)` | Selection is value filtering over POST item order. |
| E6 | source search | Only one `re.compile(...format(...))` occurrence was found under `repo/django`. | The same source pattern does not remain elsewhere in allowed source. |

