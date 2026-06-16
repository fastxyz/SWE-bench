# Public Compatibility Audit

Status: static compatibility audit; no code or tests executed.

## Changed public surface

- Public function affected: `sklearn.show_versions()`.
- Internal helper affected: `sklearn.utils._show_versions._get_deps_info()`.
- Signature changes: none.
- Return-shape changes: `_get_deps_info()` remains a dictionary from dependency
  name to version string or `None`; V1 adds one key, `"joblib"`.
- Printed-output changes: `show_versions()` prints one additional dependency
  row under `Python deps`.

## Callsite and override review

- `repo/sklearn/__init__.py` re-exports `show_versions`; no call signature is
  changed.
- `repo/ISSUE_TEMPLATE.md` calls `import sklearn; sklearn.show_versions()` for
  scikit-learn `>= 0.20`; this becomes more complete after V1.
- No subclass, override, or virtual dispatch surface is involved.

## Verdict

No compatibility blocker was found. The only observable change is the intended
addition of `joblib` to the reported dependency set.
