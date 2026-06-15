# Proof Obligations

Status: constructed, not machine-checked. No proof command was executed.

## PO-1: Plain column with non-empty suffix

Statement: For any quoted column token `Q` and bare non-empty suffix token `S`, `Columns.__str__()` must render the per-column item as `Q + " " + S`.

Public evidence: INT-1 and INT-4.

V1 discharge: line `return ' '.join(part for part in (col, suffix) if part)` includes `col` and non-empty `suffix` as two adjacent tokens. Python's string join inserts exactly one separator between included parts.

K claim: `PLAIN-NONEMPTY-SUFFIX`.

Finding links: F-1.

## PO-2: Plain column with empty suffix

Statement: For any quoted column token `Q` and suffix `''`, `Columns.__str__()` must render the per-column item as `Q` with no trailing whitespace.

Public evidence: INT-2 by analogy to empty order suffixes and INT-4's `''` producer contract.

V1 discharge: the generator filters falsey parts, so `''` is omitted and only `col` remains.

K claim: `PLAIN-EMPTY-SUFFIX`.

Finding links: F-1.

## PO-3: Opclass column with empty suffix

Statement: For any quoted column token `Q` and opclass token `O`, with suffix `''`, `IndexColumns.__str__()` must render the per-column item as `Q + " " + O` with no trailing whitespace.

Public evidence: INT-2, INT-4, and INT-5.

V1 discharge: the generator includes `col` and `self.opclasses[idx]`, filters the empty suffix, and joins the two remaining tokens with exactly one separator.

K claim: `INDEX-EMPTY-SUFFIX`.

Finding links: F-2.

## PO-4: Opclass column with non-empty suffix

Statement: For any quoted column token `Q`, opclass token `O`, and bare non-empty suffix token `S`, `IndexColumns.__str__()` must render the per-column item as `Q + " " + O + " " + S`.

Public evidence: INT-3, INT-4, and INT-5.

V1 discharge: all three tuple entries are true and therefore retained by the generator; join inserts one separator between each adjacent pair.

K claim: `INDEX-NONEMPTY-SUFFIX`.

Finding links: F-3.

## PO-5: Multi-column delimiter and caller compatibility

Statement: Rendering multiple columns must continue using `', '` between per-column strings, and the public call path must not require signature or dispatch changes.

Public evidence: INT-6 and existing source shape in `ddl_references.py`.

V1 discharge: both `__str__()` methods retain `return ', '.join(...)`; constructors and call signatures are unchanged; `_index_columns()` still selects `Columns` or `IndexColumns` exactly as before.

K claim: represented as a composition obligation in `index-columns-spec.k` comments and discharged by source preservation.

Finding links: F-6.

## PO-6: Honesty and non-execution

Statement: Because the environment forbids execution, no test result or machine-check result may be claimed.

Public evidence: task instructions and FVK honesty gate.

V1 discharge: `PROOF.md` labels the proof constructed, not machine-checked, and includes commands only for later reproduction.

Finding links: F-5.
