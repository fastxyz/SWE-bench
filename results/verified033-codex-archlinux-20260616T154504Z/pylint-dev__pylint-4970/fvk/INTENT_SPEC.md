# Intent Spec

Constructed from public/user-provided evidence only.

## Required behavior

1. When `min-similarity-lines` is configured as `0`, pylint's duplicate-code
   detection is disabled.
2. Disabled duplicate-code detection must not emit `R0801` / `duplicate-code`
   messages, even when checked files contain duplicate code.
3. Disabled duplicate-code detection should not perform duplicate-code matching
   work. The issue wording says "stop pylint from checking duplicate code" and
   "disable the duplicate code check", not merely "hide reports".
4. Positive `min-similarity-lines` values keep their existing meaning as the
   minimum duplicate-code threshold.
5. The public issue does not require solving partial, per-code-block disables
   for `R0801`; the hint identifies that as a separate issue.

## Boundary assumptions

- `0` is the only value explicitly named by public intent as a disable sentinel.
- A negative minimum line count is not meaningful for a minimum-lines option.
  Treating non-positive values as disabled is a conservative default-domain
  assumption, not an independent public requirement.
- The proof is partial correctness over the checked path. It does not prove
  process termination or performance bounds.
