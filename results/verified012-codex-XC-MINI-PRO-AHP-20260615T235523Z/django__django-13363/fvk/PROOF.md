# Constructed Proof

Status: constructed, not machine-checked.

## Claims

The proof targets the nine claims in `fvk/trunc-tzinfo-spec.k`:

- three `getTzName` claims for disabled, current fallback, and explicit
  timezone branches;
- three `TruncDate.as_sql()` claims for disabled, current fallback, and
  explicit timezone branches;
- three `TruncTime.as_sql()` claims for disabled, current fallback, and
  explicit timezone branches.

No loop or recursion exists in this audited slice, so the proof has no
circularity obligation.

## Symbolic proof sketch

1. For `GET-TZ-DISABLED`, symbolic execution matches the rule
   `getTzName(false, TZ, CURRENT) => selectedTz(noSqlTz())`. This discharges
   PO3.
2. For `GET-TZ-CURRENT`, symbolic execution matches the rule
   `getTzName(true, noTzInfo(), CURRENT) => selectedTz(sqlTz(CURRENT))`. This
   discharges PO2.
3. For `GET-TZ-EXPLICIT`, symbolic execution matches the rule
   `getTzName(true, someTz(EXPLICIT), CURRENT) =>
   selectedTz(sqlTz(EXPLICIT))`. This discharges PO1 and rejects the legacy
   current-timezone behavior.
4. For each `TruncDate` claim, symbolic execution matches the corresponding
   `truncDateAsSql(...)` rule and reaches
   `sqlResult(castDate(LHS, selected_timezone), PARAMS)`. This discharges PO4
   and the params-preservation part of PO6.
5. For each `TruncTime` claim, symbolic execution matches the corresponding
   `truncTimeAsSql(...)` rule and reaches
   `sqlResult(castTime(LHS, selected_timezone), PARAMS)`. This discharges PO5
   and the params-preservation part of PO6.

The V1 source code implements these transitions because both subclass
overrides now compute `tzname = self.get_tzname()` before calling the existing
backend cast method.

## Adequacy gate

The formal claim paraphrases in `fvk/FORMAL_SPEC_ENGLISH.md` match the
intent-only obligations in `fvk/INTENT_SPEC.md`. `fvk/SPEC_AUDIT.md` marks all
formal obligations PASS. `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` finds no unhandled
public callsite, override, signature change, or backend operation mismatch.

## Test recommendation

No test files were modified. Existing public tests should be kept because this
constructed proof only covers timezone selection and forwarding for the audited
methods, not full database execution, backend-specific SQL rendering, query
evaluation, null conversion, or validation integration.

Recommended future tests, not applied here:

- `TruncDate("start_datetime", tzinfo=melb)` should produce date grouping in
  the explicit timezone even when the active timezone differs.
- `TruncTime("start_datetime", tzinfo=melb)` should produce time grouping in
  the explicit timezone even when the active timezone differs.

## Reproduce the machine check later

These commands are recorded for a later environment with K installed. They were
not executed in this session.

```sh
cd fvk
kompile mini-django-trunc.k --backend haskell
kast --backend haskell trunc-tzinfo-spec.k
kprove trunc-tzinfo-spec.k
```

Expected machine-check result after the constructed proof is validated:
`#Top`.

