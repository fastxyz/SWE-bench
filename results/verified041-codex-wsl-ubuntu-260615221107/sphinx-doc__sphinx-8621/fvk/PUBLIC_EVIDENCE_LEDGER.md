# Public Evidence Ledger

| ID | Source | Quoted evidence | Obligation |
| --- | --- | --- | --- |
| INT-1 | `benchmark/PROBLEM.md` | "For single keystrokes that use `-`, `+` or`^`, just a single `kbd` element should be created." | Standalone punctuation separator characters are keys and must not produce blank nested keys. |
| INT-2 | `benchmark/PROBLEM.md` | "differentiate between `-`, `+` and `^` characters appearing in separator vs keystroke positions" | Tokenization is positional. |
| INT-3 | `benchmark/PROBLEM.md` | examples `:kbd:`-``, `:kbd:`+``, `:kbd:`Shift-+`` | The example family generalizes to all three punctuation separators in the same key positions. |
| INT-4 | `repo/doc/usage/restructuredtext/roles.rst` | "Mark a sequence of keystrokes" and `C-x C-f` / `Control-x Control-f` examples | Compound key sequence behavior remains in scope. |
| INT-5 | public source/tests | `Control+X` and `M-x  M-s` examples | Preserve ordinary compound HTML tokenization. |
| INT-6 | implementation | HTML post-transform matches `nodes.literal` with class `kbd` | Limit the fix to the HTML kbd transform; do not alter unrelated writers or role registration. |

The issue's quoted broken HTML is legacy-bug evidence, not an expected output.
