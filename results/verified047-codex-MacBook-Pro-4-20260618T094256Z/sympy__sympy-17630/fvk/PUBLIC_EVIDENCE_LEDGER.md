# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| E1 | issue (`benchmark/PROBLEM.md`) | "Exception when multiplying BlockMatrix containing ZeroMatrix blocks" | Compatible block multiplication with zero blocks must not raise an exception. | Encoded by claims `BLOCKMUL-COMPATIBLE-ZERO-ENTRY` and `BLOCKMUL-REPEATED-SAFE`. |
| E2 | issue (`benchmark/PROBLEM.md`) | "`b._blockmul(b)._blockmul(b)` ... `AttributeError: 'Zero' object has no attribute 'cols'`" | A product result that will be used as a later `BlockMatrix` operand must not contain scalar zero blocks lacking `.cols`. | Encoded by `BLOCKMUL-REPEATED-SAFE`. |
| E3 | issue (`benchmark/PROBLEM.md`) | "the zeros in `b._blockmul(b)` are not `ZeroMatrix` but `Zero`" | Exact scalar zero produced inside block multiplication is the defect mechanism and must be represented as a shaped `ZeroMatrix`. | Encoded by `NORMALIZE-SCALAR-ZERO` and `BLOCKMUL-COMPATIBLE-ZERO-ENTRY`. |
| E4 | source docstring (`BlockMatrix`) | "A BlockMatrix is a Matrix comprised of other matrices." | Block entries must be matrix-like, not scalar values. | Encoded by result-entry matrix-shape claims. |
| E5 | source code (`rowblocksizes`/`colblocksizes`) | These properties read `.rows` and `.cols` from stored blocks. | Stored block entries are expected to expose shape attributes. | Encoded by `BLOCKMUL-REPEATED-SAFE`. |
| E6 | public in-repo tests | `assert X._blockmul(M).is_MatMul` | `_blockmul` fallback for non-`BlockMatrix` operands is public behavior to preserve. | Encoded by `BLOCKMUL-NONBLOCK-FALLBACK`. |
| E7 | source implementation | The compatible branch checks `self.colblocksizes == other.rowblocksizes`. | Compatibility precondition for block product. | Encoded as `compatible(A, B)` in the mini-semantics. |
| E8 | issue pre-fix display | `b._blockmul(b)` prints zero blocks while internally storing scalar `Zero`. | The printed display is not sufficient; the shape-carrying block type is the required observable for later operations. | Marked SUSPECT as legacy behavior where it hides the defect; not used as a veto. |
