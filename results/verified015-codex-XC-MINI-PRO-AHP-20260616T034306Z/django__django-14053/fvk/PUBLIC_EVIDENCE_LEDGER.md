# Public Evidence Ledger

Status: constructed from public evidence, not machine-checked.

| ID | Source | Evidence | Semantic Obligation | Spec Status |
| --- | --- | --- | --- | --- |
| E1 | problem | `benchmark/PROBLEM.md:6-7`: multi-pass processing is necessary, but duplicate yields are the issue. | Preserve repeated internal passes while changing only public emission policy. | Encoded by modeling `_post_process()` as repeated event input and proving emission filtering. |
| E2 | problem | `benchmark/PROBLEM.md:14-17`: expected output for `admin/css/base.css` has one final `Post-processed` line. | A successful adjustable original is yielded once with its final hash. | Encoded in PO-003 and PO-004. |
| E3 | problem | `benchmark/PROBLEM.md:19-20`: `collectstatic` counts yielded files and subclasses may do work per yield. | Public successful yields must be unique by original path. | Encoded in PO-007. |
| E4 | problem | `benchmark/PROBLEM.md:21-23`: intermediate files are lower-level implementation details. | Intermediate adjustable pass results must not be yielded. | Encoded in PO-002 through PO-004. |
| E5 | problem | `benchmark/PROBLEM.md:24-28`: stable files also duplicated during repeat passes. | Even if a repeated pass reports the same final hash, the original is yielded once. | Encoded in PO-003 and PO-004. |
| E6 | code docstring | `repo/django/contrib/staticfiles/storage.py:207-215`: either hashing/copying or reference adjustment counts as post-processing. | Non-adjustable first-pass successes remain valid successful yielded results. | Encoded in PO-002. |
| E7 | collectstatic callsite | `repo/django/contrib/staticfiles/management/commands/collectstatic.py:128-138`: collectstatic consumes triples and counts successful processed yields. | Keep yielded tuple shape; uniqueness fixes count inflation. | Encoded in PO-007 and PO-008. |
| E8 | collectstatic callsite | `repo/django/contrib/staticfiles/management/commands/collectstatic.py:129-134`: exceptions are raised immediately when yielded. | Preserve immediate exception yield behavior. | Encoded in PO-006. |
| E9 | implementation | `repo/django/contrib/staticfiles/storage.py:224-260`: V1 stores adjustable results in a dict and yields values after repeat passes. | Candidate mechanism for final-only adjustable emission; must be checked against intent, not used as intent. | Audited in FINDINGS F-001 and PROOF. |
