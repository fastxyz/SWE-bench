# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt issue | "Fixture dirs duplicates undetected if dir is Path instance" | Duplicate detection must not depend on whether a configured directory is represented as a string or `Path`. | Encoded in SPEC and K claims. |
| E2 | prompt issue | "When FIXTURE_DIRS contains Path instances, the duplicate check in loaddata does not detect duplicates." | `FIXTURE_DIRS` validation must normalize path-like entries before checking equality. | Encoded in PO-001 and PO-002. |
| E3 | docs `ref/django-admin.txt` | "Django will search ... In any directory named in the FIXTURE_DIRS setting" | `FIXTURE_DIRS` entries are search directories; validation protects fixture search behavior. | Encoded as target scope. |
| E4 | docs `ref/settings.txt` | "List of directories searched for fixture files" | The setting is a directory list, not a list of arbitrary non-path objects. | Encoded as domain. |
| E5 | release note `docs/releases/1.8.txt` | "`loaddata` command now prevents repeated fixture loading. If FIXTURE_DIRS contains duplicates or a default fixture directory path ..., an exception is raised." | Duplicate configured directories and configured app default fixture directories are error cases. | Encoded in PO-002 and PO-003. |
| E6 | public test `test_fixture_dirs_with_duplicates` | "settings.FIXTURE_DIRS cannot contain duplicates in order to avoid repeated fixture loading." | Equal configured entries must raise the duplicate error. | Supporting evidence for PO-002. |
| E7 | public test `test_fixture_dirs_with_default_fixture_path` | "FIXTURE_DIRS cannot contain a default fixtures directory ... to avoid repeated fixture loading." | A configured app default fixture directory must raise the default-directory error. | Supporting evidence for PO-003. |
| E8 | public test `test_fixtures_dir_pathlib` | `FIXTURE_DIRS=[Path(_cur_dir) / "fixtures_1"]` is accepted. | Path-like entries are valid when they are not duplicates. | Encoded in PO-004. |
| E9 | implementation | V1 uses `[os.fspath(fixture_dir) for fixture_dir in settings.FIXTURE_DIRS]` before duplicate/default checks. | Candidate mechanism for satisfying E1-E8; not independent intent. | Audited in proof. |
| E10 | implementation | The property later returns `[os.path.realpath(d) for d in dirs]`. | Raises a possible broader canonical-alias question. | Finding F-002, ambiguous. |
