# FORMAL_SPEC_ENGLISH.md

Status: constructed, not machine-checked.

1. `MODE-GETTER`: for every in-domain buffer mode `M`,
   `EncodedFile.mode` returns `stripB(M)`.
2. `MODE-NO-B`: for every in-domain buffer mode `M`, `stripB(M)` contains no
   binary flag.
3. `BUFFER-MODE-PRESERVED`: for every in-domain buffer mode `M`,
   `EncodedFile.buffer.mode` remains `M`.
4. `STRIPB-PRESERVES-NON-B`: for every in-domain buffer mode `M`, every
   non-binary mode flag appears in the wrapper mode in the same order and
   multiplicity as in `M`.
5. `WRITE-FRAME`: V1 does not alter `EncodedFile.write`.
6. `DELEGATION-FRAME`: V1 does not alter non-mode `__getattr__` delegation.
