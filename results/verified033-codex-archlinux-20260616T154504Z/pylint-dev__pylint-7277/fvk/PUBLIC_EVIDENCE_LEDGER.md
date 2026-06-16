# Public Evidence Ledger

## E1 - Reported Bug

- Source: `benchmark/PROBLEM.md`
- Evidence: "`pylint` removes first item from `sys.path` when running from
  `runpy`."
- Obligation: do not blindly remove `sys.path[0]`.
- Status: encoded by PO-1 and K claims `FIRST-NONCWD-*`.

## E2 - Reported Reproducer

- Source: `benchmark/PROBLEM.md`
- Evidence: `sys.path.insert(0, "something")` followed by
  `runpy.run_module('pylint', run_name="__main__", alter_sys=True)`.
- Obligation: a non-CWD first entry such as `"something"` is caller-owned and
  must remain after `modify_sys_path()`.
- Status: encoded by PO-1 and finding F1.

## E3 - Expected Behavior

- Source: `benchmark/PROBLEM.md`
- Evidence: "Check if `\"\"`, `\".\"` or `os.getcwd()` before removing the first
  item from sys.path."
- Obligation: exact removable first-entry set is `{"", ".", cwd}`.
- Status: encoded by PO-1, PO-2, and `isCwdPath` in `mini-python-syspath.k`.

## E4 - Docstring Safety Purpose

- Source: `repo/pylint/__init__.py`
- Evidence: "Strip out the current working directory from sys.path" to avoid
  accidental imports from user code.
- Obligation: CWD-like startup path entries should still be removed.
- Status: encoded by PO-2, PO-3, and PO-4.

## E5 - PYTHONPATH Colon Behavior

- Source: `repo/pylint/__init__.py`
- Evidence: "Remove the working directory from the second and third entries if
  PYTHONPATH includes a ':' at the beginning or the end."
- Obligation: keep the leading and trailing implicit-CWD cleanup cases.
- Status: encoded by PO-3 and PO-4.

## E6 - Explicit PYTHONPATH Exception

- Source: `repo/pylint/__init__.py`
- Evidence: "Don't remove it if PYTHONPATH contains the cwd or '.' as the entry
  will only be added once."
- Obligation: explicit `cwd` or `.` entries in `PYTHONPATH` do not trigger an
  extra pop.
- Status: encoded by PO-5.

## E7 - Later Entry Preservation

- Source: `repo/pylint/__init__.py`
- Evidence: "Don't remove the working directory from the rest. It will be
  included if pylint is installed in an editable configuration."
- Obligation: do not remove every CWD-like path globally.
- Status: encoded by PO-6.

## E8 - Public Regression Evidence

- Source: `repo/tests/test_self.py`
- Evidence: `test_modify_sys_path()` covers first-entry removal and
  leading/trailing `PYTHONPATH` edge cases.
- Obligation: preserve the documented public behavior in those cases.
- Status: treated as compatibility evidence and encoded by PO-2 through PO-5.
