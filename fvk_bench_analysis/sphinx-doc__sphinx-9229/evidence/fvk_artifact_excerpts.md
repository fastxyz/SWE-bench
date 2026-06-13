# Key FVK-artifact excerpts — `sphinx-doc__sphinx-9229`

All paths under `results/batch4-XC-MINI-PRO-AHP-260613182909/sphinx-doc__sphinx-9229/`.

The real root cause = `ClassDocumenter.add_content` unconditionally appends an
`alias of <target>` line for `doc_as_attr`, and the V1 fix does NOT suppress it
when the alias has its own doc-comment. The oracle fixes this with
`if self.doc_as_attr and not self.get_variable_comment():`.

Below: every artifact excerpt that touches this region. Note that none flags it as
a bug; the load-bearing ones assert that rendering BOTH is the *intended* behavior.

---

## A. The inverted intent premise — the spec enshrines the bug (THE keystone excerpt)

`fvk/SPEC.md:53-56` (Intent ledger, item I1):
```
- **I1.** If the alias variable has its **own** documentation comment, that
  comment is rendered **in addition to** `alias of <target>` (mirrors the
  already-correct behaviour of `DataDocumenter`, asserted by
  `test_autodata_GenericAlias`).
```
This is the exact behavior the gold test forbids. The fvk arm took the wrong
sibling (`DataDocumenter`, which legitimately shows both) as the intent for
`ClassDocumenter` aliases (which must suppress `alias of` once documented).

`fvk/SPEC.md:48-49`:
```
shows only the auto-generated `alias of ...` text and drops the user's comment.
The intended, *consistent* behaviour is:
```
Intent is framed solely as "add the comment," never as "drop `alias of`."

---

## B. The proof asserts the failing behavior is correct

`fvk/PROOF.md:116-117` (§ End-to-end):
```
- **End-to-end**, an alias with a comment renders **comment + `alias of …`
  exactly once**; a comment-less alias renders **only `alias of …`**.
```
"comment + alias of" is precisely the 2-line output the test rejects.

`fvk/PROOF.md:118-120`:
```
For the reporter's example, all three aliases now render their docstrings (the
two previously dropped were routed through `ClassDocumenter` ...
```
Correctness assumed; the `alias of` line count is never checked.

---

## C. The wrong-analogy source in the findings

`fvk/FINDINGS.md:40-41` (F1, "expected" column):
```
- **expected (I1):** the docstring **and** `alias of int` are both rendered (the
  behaviour `DataDocumenter` already has, asserted by `test_autodata_GenericAlias`).
```

`fvk/FINDINGS.md:7-11` (headline) and `:169` (closing):
```
... **none is an unaddressed correctness bug in V1.**
...
Net: **the audit confirms V1; no code change is required.**
```

---

## D. The `add_content` model literally elides the buggy lines

`fvk/SPEC.md` §4 (NO-DOUBLE / `add_content` mini-model) models only the
docstring/analyzer `PATH-1`/`PATH-2` and the `no_docstring` flag. The block
`if self.doc_as_attr: more_content = StringList(['alias of %s' ...])` is omitted
from the model — so the proof's entire "render exactly once" keystone (PO-I1)
governs only comment-blocks and never reasons about the `alias of` injection.

`fvk/PROOF_OBLIGATIONS.md:83-94` (PO-I1 NO-DOUBLE) — the keystone obligation —
covers docstring/comment render-count only; `alias of` `more_content` is outside
its case analysis. Closing `:152-154`:
```
No obligation is blocked by a defect in the V1 code.
```

---

## E. Escalation boundaries point AWAY from the defect

`fvk/PROOF_OBLIGATIONS.md` PO-T1 (`:112`) and PO-T2 (`:120`) are the only
`[ESCALATION BOUNDARY]` items; both route to `sphinx.pycode` parser internals,
"upstream and unchanged by this fix." Per kit policy these are capability gaps,
not code bugs — and they sit on the analyzer, not on `add_content`.

---

## F. The transcript: where the inverted premise entered, and the region was skipped

`transcripts/fvk.jsonl.gz` (continued session; baseline phase lines ~4-219,
fvk-audit phase ~220-316):
- Line ~56 (baseline): *"The test `test_autodata_GenericAlias` shows the current
  expected behavior is docstring + 'alias of'."* — adoption of the inverted premise.
- Line ~64 (baseline): *"Let me examine the `restify` function, which is used to
  render the 'alias of' text."* — looked at HOW `alias of` renders, never WHETHER
  it should be emitted (the `add_content` guard).
- Lines ~299-303 (audit): the only audit-phase source re-read confirms the
  `no_docstring` "render once" keystone in `add_content`'s docstring branch, then
  stops — never reaching the `doc_as_attr → more_content = "alias of"` block.
- `reports/fvk_notes.md:109`: *"Source code under `repo/`: none (V1 confirmed)."*

---

## G. Self-defeating detail (deep irony)

The gold test case is SAME-module (`OtherAlias = Bar`, `Bar` in `target.classes`),
so by the artifacts' own case table (`fvk/SPEC.md` §4; `fvk_notes.md` D1) PATH-1
fires and `get_doc` is NOT called — meaning the `[comment]` return value the entire
proof centers on is never even exercised by the failing test. The bug is 100% in
the `alias of` injection the artifacts never modeled.
