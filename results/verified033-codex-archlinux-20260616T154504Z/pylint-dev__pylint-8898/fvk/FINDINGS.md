# Findings

Status: FVK audit findings; constructed, not machine-checked.

## F-001: Existing public test encodes the legacy bug

Input:

```text
--bad-names-rgx=(foo{1,3})
```

Observed legacy expectation:

- `repo/tests/config/test_config.py::test_csv_regex_error` expects an argparse error containing the split fragment `(foo{1`.

Expected by public issue intent:

- `(foo{1,3})` is a valid regex and should be passed as one regex fragment.

Classification:

- SUSPECT legacy-test obligation.

Trace:

- Public evidence E1/E2 says splitting this comma is the bug.
- Proof obligation O6 requires this input to remain one fragment.

Decision:

- Do not modify tests per task constraints.
- Do not preserve the legacy expectation in source code.

## F-002: V1 satisfies the reported quantifier bug

Input:

```text
(foo{1,3})
```

Observed in V1 by static inspection:

- `_split_regex_csv` sets `open_brace = True` on `{`, does not split the comma, clears `open_brace` on `}`, and finalizes one fragment.

Expected:

- One fragment, `(foo{1,3})`, then successful regex compilation if the regex is valid.

Classification:

- Confirmed code behavior against O2/O3/O6.

Decision:

- No source edit required.

## F-003: V1 preserves top-level CSV compatibility

Input:

```text
foo,bar
```

Observed in V1 by static inspection:

- The comma is unescaped and outside brace/class context, so the helper emits `foo` and starts `bar`.

Expected:

- Two ordered fragments, preserving existing `regexp_csv` list semantics.

Classification:

- Confirmed code behavior against O3/O4/O5/O7.

Decision:

- No source edit required.

## F-004: V1 provides an escape path for literal commas

Input:

```text
foo\,bar
```

Observed in V1 by static inspection:

- The backslash sets `escaped = True`; the comma is appended by the escaped-character branch and is not considered a separator.

Expected:

- One fragment containing the escaped comma.

Classification:

- Confirmed code behavior against E3 and O2/O3.

Decision:

- No source edit required.

## F-005: Compatibility surface is unchanged

Input:

```text
regexp_csv option parsing in command-line, config-file string, or config-file list form
```

Observed in V1 by static inspection:

- The `"regexp_csv"` type key still points to `_regexp_csv_transfomer`.
- `_regexp_csv_transfomer` still returns a sequence of compiled regex patterns.
- Other CSV transformers are untouched.

Expected:

- Existing public option API and non-regex CSV behavior remain compatible.

Classification:

- Confirmed against O8/O10.

Decision:

- No source edit required.

## F-006: Documentation for escaped commas is not updated

Input:

```text
User wants a literal comma outside braces or character classes.
```

Observed:

- V1 supports `\,`, but option help still only says "separated by a comma."

Expected:

- The code path is correct for the issue; documentation could be clearer in a follow-up.

Classification:

- Non-blocking documentation gap, not a source-code correctness defect for this task.

Decision:

- No code edit required; record as iteration guidance.
