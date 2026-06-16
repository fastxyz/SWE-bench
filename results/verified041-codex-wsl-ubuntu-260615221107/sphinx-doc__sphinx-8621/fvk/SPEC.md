# FVK Specification

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were executed.

## Target

This audit targets the V1 change in
`repo/sphinx/builders/html/transforms.py`:

- `KeyboardTransform.is_separator(char)`
- `KeyboardTransform.split_keys(text)`
- the `KeyboardTransform.run()` use of `split_keys()` to build nested
  `nodes.literal(..., classes=["kbd"])` children for HTML output

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| INT-1 | `benchmark/PROBLEM.md` | "single keystrokes that use `-`, `+` or `^`, just a single `kbd` element should be created" | A one-character key equal to a punctuation separator is a key token, not a separator. The HTML transform must not create blank nested key nodes for it. | Encoded by PO-2 and claim `STANDALONE-SEP-KEYS`. |
| INT-2 | `benchmark/PROBLEM.md` | "compound-keystrokes ... differentiate between `-`, `+` and `^` characters appearing in separator vs keystroke positions" | Tokenization is positional: after a key, a separator may be read; after a separator, the next punctuation separator character is a key. | Encoded by PO-3, PO-4, and claim `GENERAL-POSITIONAL-TOKENIZATION`. |
| INT-3 | `benchmark/PROBLEM.md` | examples `:kbd:`-``, `:kbd:`+``, and `:kbd:`Shift-+`` | The required family includes all punctuation separators as standalone keys and as key-position characters in compound sequences, not only the listed `-` and `+` examples. | Encoded by PO-2 and PO-4 for `-`, `+`, and `^`. |
| INT-4 | `repo/doc/usage/restructuredtext/roles.rst` | "Mark a sequence of keystrokes" and examples `C-x C-f` / `Control-x Control-f` | Existing compound key syntax remains supported. A separator between ordinary key names still creates nested key nodes separated by the literal separator text. | Encoded by PO-3. |
| INT-5 | public source/tests | Existing public examples include `Control+X` and `M-x  M-s` expected as compound HTML. | V1 must preserve ordinary plus, hyphen, and whitespace compound output. | Encoded by PO-3 and compatibility audit. |
| INT-6 | implementation fact | `:kbd:` is a `nodes.literal` role and this transform runs only for HTML builders on literal nodes with class `kbd`. | The source change should be limited to the tokenizer/HTML transform and must not change role registration, writer classes, LaTeX output, or public command APIs. | Encoded by PO-6 and compatibility audit. |

Issue-provided pre-fix HTML is treated as SUSPECT legacy behavior because it is
quoted as the bug, not as an expected oracle.

## Domain

The intent-derived domain is finite keyboard sequence text following the
documented role purpose: a nonempty sequence of key tokens, optionally separated
by separator tokens.

Definitions used by the proof obligations:

- `PunctSep = {"-", "+", "^"}`
- `SpaceSep = any nonempty run of whitespace`
- `Sep = PunctSep or SpaceSep`
- `NonSepChar = any character not in PunctSep and not whitespace`
- `Key = NonSepChar+` or `PunctSep NonSepChar*`
- `KeyboardSeq = Key (Sep Key)*`

This domain includes standalone separator keys (`"-"`, `"+"`, `"^"`),
ordinary compounds (`"Control+X"`, `"M-x  M-s"`), and separator-key compounds
(`"Shift-+"`, `"Shift--"`, `"Control++"`, `"Control+^"`). It does not define
malformed text with an expected key missing, such as a punctuation separator
immediately followed by whitespace before a key. That ambiguity is recorded in
`fvk/FINDINGS.md` as F-4 and is not used to justify a source change.

## Intended Behavior

For all `text` in `KeyboardSeq`, `split_keys(text)` returns an alternating list
of typed parts:

```text
[("key", key0), ("sep", sep0), ("key", key1), ...]
```

where every `keyi` is nonempty, every `sepi` is a separator token, concatenating
all values reconstructs the original `text`, and separator-looking characters
in key positions are included in key tokens.

`run()` has the following observable HTML-tree behavior for a `nodes.literal`
with class `kbd` and one text child:

- If `split_keys(text)` has zero or one part, leave the node's text child
  unchanged. This preserves a single `<kbd>` element for single keys.
- If `split_keys(text)` has more than one part, replace the text child with
  nested literal children for `key` parts and text nodes for `sep` parts.
- Do not create empty nested key nodes for any `text` in `KeyboardSeq`.

## Adequacy Summary

The formal claims in `fvk/keyboard-transform-spec.k` paraphrase to the same
obligations above:

- standalone punctuation separators are single key tokens;
- ordinary compound sequences still split on separator positions;
- punctuation separator characters following another separator are key tokens;
- the `run()` transformation preserves order, separator text, and key text;
- the changed code has no public API or writer compatibility impact beyond the
  intended HTML tokenizer behavior.

`fvk/FORMAL_SPEC_ENGLISH.md` and `fvk/SPEC_AUDIT.md` record the adequacy
round trip. No adequacy failure blocks V1.
