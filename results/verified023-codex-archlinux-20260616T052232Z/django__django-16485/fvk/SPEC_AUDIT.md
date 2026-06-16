# Spec Audit

Status: pass for the reported zero-decimal precision path; constructed, not
machine-checked.

| Formal claim | Intent coverage | Audit result |
| --- | --- | --- |
| C-01 safe precision lower bound | Matches E-01, E-02, and E-06: the reported crash is exactly invalid Decimal context precision on zero decimals. | Pass |
| C-02 zero with precision 0 formats as `"0"` | Matches E-03 and the issue calls in E-02. | Pass |
| C-03 negative precision zero branch unchanged | Matches E-04 and E-07 frame evidence. | Pass |
| Frame: raw precision already valid remains unchanged | Required by E-04, E-05, and E-07 compatibility/frame obligations. | Pass |

## Coverage Limits

The mini semantics deliberately abstracts away full Decimal arithmetic,
localization, grouping, nonzero rounding, infinity, NaN, and invalid argument
parsing. Those behaviors are not used to justify `V1 == correct`; they are
listed as proof capability boundaries in `FINDINGS.md` and must remain covered
by conventional Django tests until a fuller semantics is available.
