# INTENT_SPEC.md

Status: constructed, not machine-checked.

Intent-only obligations from public evidence:

1. `EncodedFile.mode` must not contain `b`.
2. `EncodedFile.mode` should be derived from the wrapped buffer mode by removing
   `b`, preserving other mode flags.
3. `EncodedFile.buffer.mode` should remain the underlying stream mode.
4. `EncodedFile.write` should remain text-oriented; callers should choose text
   writes because `.mode` no longer advertises binary capability.
5. No test files should be modified in this benchmark.
