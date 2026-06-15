# Proof Obligations

Status: constructed, not machine-checked. These obligations are derived from
`fvk/SPEC.md` and traced to `fvk/FINDINGS.md`.

## O1: Constructor Keyword Acceptance

- Statement: `RST.__init__` accepts `header_rows` as an optional keyword and
  forwards it to the fixed-width base class.
- Evidence: E1, E2, E6.
- Code evidence: `RST.__init__(self, header_rows=None)` calls
  `super().__init__(delimiter_pad=None, bookend=False, header_rows=header_rows)`.
- Proof sketch: `core._get_writer` passes `header_rows` as a writer-specific
  constructor kwarg. Since the RST constructor now accepts that kwarg, the
  pre-fix `TypeError` path is removed for the issue input.
- Related findings: F-001.
- Status: discharged by V1.

## O2: Header-Row Value Source and Order

- Statement: For each `col_attr` in the configured `header_rows`, RST output uses
  the same column `info` value source and row order as the fixed-width writer.
- Evidence: E3, E5.
- Code evidence: `FixedWidth.__init__` stores the same `header_rows` on
  `self.header` and `self.data`; `FixedWidthData.write` iterates through
  `header_rows` in order and reads `getattr(col.info, col_attr)`.
- Proof sketch: RST delegates header and data formatting to `FixedWidth.write`.
  No RST-specific code mutates `header_rows` or header values after delegation.
- Related findings: F-001.
- Status: discharged by inherited fixed-width behavior.

## O3: Multi-Header Separator Placement

- Statement: For `K = len(header_rows) >= 1`, the RST middle separator is the
  inherited fixed-width line at index `K`, and that same separator is used for
  the top and bottom RST separators.
- Evidence: E1, E3, E4.
- Code evidence: `FixedWidthData.write` appends all header rows, then appends
  the position/separator line. `RST.write` now computes
  `separator = lines[len(self.header.header_rows)]`.
- Proof sketch: By construction, inherited `lines` has the form
  `HeaderLines(H) ++ [Sep] ++ DataLines`; indexing by `len(H)` selects `Sep`.
  Prepending and appending `Sep` yields the required RST simple-table shape.
- Related findings: F-002.
- Status: discharged by V1.

## O4: Default RST Output Preservation

- Statement: With no `header_rows` argument, RST output remains the existing
  one-header-row simple table.
- Evidence: E4.
- Code evidence: `FixedWidth.__init__` normalizes `header_rows is None` to
  `["name"]`; `len(["name"]) == 1`, so `RST.write` selects `lines[1]`, matching
  the previous implementation.
- Proof sketch: O3 instantiated with `H = ["name"]` is extensionally identical
  to the pre-V1 `lines = [lines[1]] + lines + [lines[1]]`.
- Related findings: F-002.
- Status: discharged by V1.

## O5: Matching Multi-Header Readback Data Start

- Statement: If RST is configured with `K >= 1` header rows, the default data
  start line is `K + 2`: top separator, `K` header rows, middle separator, then
  data.
- Evidence: E5.
- Code evidence: `RST.__init__` sets
  `self.data.start_line = len(self.header.header_rows) + 2`.
- Proof sketch: The RST row layout contains one top separator before the header
  block and one middle separator after the header block. Therefore, data begins
  after `1 + K + 1` lines.
- Related findings: F-003.
- Status: discharged by V1.

## O6: Public Compatibility

- Statement: The V1 change is backward-compatible for public RST call sites and
  does not break subclasses or overrides in the repository.
- Evidence: E4, E6.
- Static search evidence: in-repo searches found `RST` used directly as a reader
  or writer class, and no subclass overriding `RST.__init__` or `RST.write`.
- Proof sketch: Adding an optional keyword preserves zero-argument construction.
  Existing default `header_rows is None` follows O4. No virtual dispatch site is
  changed to pass a new keyword to an override.
- Related findings: none open.
- Status: discharged by static inspection.

## O7: Domain Boundary

- Statement: This proof does not claim correctness for `header_rows=[]`, empty
  tables, continuation-line RST tables, or RST column spans.
- Evidence: E1, E2, E3 and the RST class docstring's explicit limitations.
- Proof sketch: The public issue only requires nonempty header rows for output,
  and the concrete reproducer uses `["name", "unit"]`. No positive public
  obligation requires no-header RST behavior or empty-table behavior in this
  task.
- Related findings: F-004, F-005.
- Status: recorded boundary, no code change.

