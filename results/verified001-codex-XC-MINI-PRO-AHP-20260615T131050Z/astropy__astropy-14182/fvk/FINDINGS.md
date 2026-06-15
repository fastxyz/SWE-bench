# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent
and static source inspection only.

## F-001: RST rejected `header_rows`

- Classification: code bug, fixed by V1.
- Evidence: issue traceback shows `TypeError: RST.__init__() got an unexpected
  keyword argument 'header_rows'`.
- Input: `tbl.write(sys.stdout, format="ascii.rst", header_rows=["name", "unit"])`.
- Observed pre-fix behavior: writer construction fails before output begins.
- Expected behavior: RST output is produced with both requested header rows.
- Related proof obligations: O1, O2.
- V1 status: discharged. `RST.__init__` now accepts `header_rows` and forwards it
  to `FixedWidth.__init__`.

## F-002: Separator placement must depend on the header-row count

- Classification: code bug avoided by V1; required companion to F-001.
- Evidence: existing `RST.write` used `lines[1]` as the separator. In the
  inherited fixed-width output, `lines[1]` is the separator only when exactly one
  header row is configured.
- Input: any write with `len(header_rows) > 1`, including the issue's
  `["name", "unit"]`.
- Observed risk if only the constructor were changed: the second header row
  would be used as the RST separator source.
- Expected behavior: the separator is the line generated after all configured
  header rows.
- Related proof obligations: O3, O4.
- V1 status: discharged. `RST.write` uses
  `lines[len(self.header.header_rows)]`.

## F-003: Matching readback needs a shifted data start

- Classification: compatibility improvement, fixed by V1.
- Evidence: fixed-width docs state that a table with non-standard header rows
  can be read back with the same `header_rows` list. RST's default body starts
  after top separator, one header row, and middle separator.
- Input: an RST table written with two header rows and then read with the same
  `header_rows`.
- Observed risk if `data.start_line` stayed at `3`: the middle separator would
  be treated as the first data line.
- Expected behavior: for `K` configured header rows, the first data line is at
  `K + 2`.
- Related proof obligation: O5.
- V1 status: discharged. `RST.__init__` sets `self.data.start_line` to
  `len(self.header.header_rows) + 2`.

## F-004: No public obligation for no-header RST output

- Classification: underspecified intent, not a required code change.
- Evidence: the issue asks for "header rows" and provides the nonempty
  `["name", "unit"]` case. Existing no-header fixed-width support is represented
  by a separate `fixed_width_no_header` class, and RST parsing still requires a
  named header row for column discovery unless names are supplied through other
  paths.
- Input: `format="ascii.rst", header_rows=[]`.
- Observed V1 behavior: not included in the verified domain.
- Expected behavior: ambiguous from public evidence.
- Related proof obligation: O7.
- V1 status: unchanged. No source edit is justified by the public issue.

## F-005: Empty table behavior is inherited and out of scope

- Classification: out-of-scope residual risk.
- Evidence: `FixedWidthData.write` computes widths from data rows before
  incorporating headers. The public issue example has data rows and reports a
  constructor error, not empty-table behavior.
- Input: RST writing for a table with no data rows.
- Observed V1 behavior: not audited by this FVK pass.
- Expected behavior: outside the stated issue and proof domain.
- Related proof obligation: O7.
- V1 status: unchanged.

## Summary

No open finding requires changing `repo/astropy/io/ascii/rst.py` beyond V1 for
the verified public contract.

