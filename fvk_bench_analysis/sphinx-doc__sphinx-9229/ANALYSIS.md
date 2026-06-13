# `sphinx-doc__sphinx-9229` — FVK failure analysis

- **Instance:** `sphinx-doc__sphinx-9229`  ·  **Batch:** `batch4-XC-MINI-PRO-AHP-260613182909` (fvk arm)
- **Repo / base_commit:** `sphinx-doc/sphinx` @ `876fa81e0a038cda466925b85ccf6c5452e0f685`
- **Result:** `resolved: false` — FAIL_TO_PASS `tests/test_ext_autodoc_autoclass.py::test_class_alias_having_doccomment` fails (baseline/control fail identically; all 13 PASS_TO_PASS pass). Source: `results/.../sphinx-doc__sphinx-9229/eval/fvk.report.json`.
- **VERDICT: MISSING (inverted) — but REACHABLE from public data. Counts toward headroom: NO.**

---

## 1. Root cause

When autodoc documents a name that is a **class alias** (`OtherAlias = Bar`, `Bar` a class), it sets `self.doc_as_attr = True`. Two methods of `ClassDocumenter` in `sphinx/ext/autodoc/__init__.py` then suppress the user's own documentation:

1. `get_doc()` did `return None` for `doc_as_attr` — discarding any docstring/comment.
2. `add_content()` unconditionally did `more_content = StringList([_('alias of %s') % restify(self.object)])` — overwriting the body with `alias of <target>`.

The faulty assumption: *an alias has no documentation of its own, so always suppress the docstring and emit only "alias of ...".* That ignores the case where the user attaches a `#:` attribute doc-comment (recorded in `ModuleAnalyzer.attr_docs`). The user's comment is silently dropped and only `alias of ...` renders — exactly the reported symptom.

**The oracle fix makes BOTH suppressions conditional** on a new helper `get_variable_comment()` (`evidence/oracle_patch.diff`):
```python
def get_variable_comment(self) -> Optional[List[str]]:
    try:
        key = ('', '.'.join(self.objpath))
        analyzer = ModuleAnalyzer.for_module(self.get_real_modname())
        analyzer.analyze()
        return list(self.analyzer.attr_docs.get(key, []))
    except PycodeError:
        return None
```
```diff
     def get_doc(self, ignore: int = None) -> Optional[List[List[str]]]:
         if self.doc_as_attr:
-            return None
+            comment = self.get_variable_comment()
+            if comment:  return []
+            else:        return None
...
     def add_content(self, more_content, no_docstring=False) -> None:
-        if self.doc_as_attr:
+        if self.doc_as_attr and not self.get_variable_comment():
             ... more_content = StringList([_('alias of %s') % restify(self.object)], ...)
```

**Bug TYPE:** missing-case / wrong-unconditional-default — two unconditional suppressions (`return None`; `if self.doc_as_attr:`) that needed a precondition guard, plus a data-source omission (never consulting `attr_docs`). The fix converts unconditional suppression into a conditional one in **two coordinated places**.

**Which F2P failed & why:** `test_class_alias_having_doccomment` asserts the alias `OtherAlias` (with `#: docstring`) renders as a `py:attribute` whose body is ONLY `docstring`. Under the V1/fvk patch the output additionally contains `alias of :class:`target.classes.Bar``. Exact failure (`evidence/failing_test.md`):
```
E  AssertionError: ... Left contains one more item: '   alias of :class:`target.classes.Bar`'
```

**Public-data reachability: YES.** The issue title/body name the wrong overriding string ("the only thing shown is the `alias of ...` text"; "docs should show the contents in the docstrings ... instead of the `alias of ...` default text"). Grepping public sphinx source for `alias of` / `doc_as_attr` lands on BOTH `get_doc` and `add_content`; `ModuleAnalyzer.attr_docs` is standard documented autodoc machinery. The exact expected output *format* is hidden (gold test not in the dataset; `hints_text` empty), but the cause and fix direction are derivable.

---

## 2. What the fvk arm did (V1 vs final + key artifact contents)

**V1 (`solution_baseline.patch`) edited only `get_doc`** (added `get_variable_comment`; on a comment, returns `[comment]` rather than the oracle's `[]`). **It never touched `add_content`,** so the `alias of` injection survives — this is the entire defect.

**Final fvk output is byte-for-byte identical to V1** (`md5 dfbc1a6c301db04eaec3be354f29c0ef` for both `solution_baseline.patch` and `solution_fvk.patch`; `diff` exit 0). The fvk arm changed **no code**; `reports/fvk_notes.md:109` — *"Source code under `repo/`: none (V1 confirmed)."* (The separate *control* arm only rewrote `get_variable_comment` cosmetically and also fails the same test.)

**Artifacts produced** (`results/.../sphinx-doc__sphinx-9229/fvk/`): `SPEC.md` (282 L), `FINDINGS.md` (169 L), `PROOF_OBLIGATIONS.md` (154 L), `PROOF.md` (181 L), `ITERATION_GUIDANCE.md` (117 L); no `.k` files (inlined). They build an elaborate, internally-consistent argument that **V1 is correct and needs no change**, resting on an **inverted intent premise**:

- `SPEC.md:53-56` (Intent I1): an alias with its own comment renders it *"**in addition to** `alias of <target>`"* — mirroring `DataDocumenter` / `test_autodata_GenericAlias`. **This is exactly the 2-line output the gold test forbids.**
- `PROOF.md:116-117`: *"an alias with a comment renders **comment + `alias of …` exactly once**."*
- `FINDINGS.md:7-11, 169`: *"none is an unaddressed correctness bug in V1 ... the audit confirms V1; no code change is required."*
- The keystone obligation PO-I1 "NO-DOUBLE" (`PROOF_OBLIGATIONS.md:83-94`) governs only *comment*-block render-count; the `add_content` `alias of` `more_content` block is **omitted from the model entirely** (`SPEC.md` §4).
- The only `[ESCALATION BOUNDARY]`s (PO-T1/T2) route to the `sphinx.pycode` parser — away from the defect.

The scope was fenced to `get_doc` + `get_variable_comment` from the outset (`SPEC.md:9-11`: *"The V1 fix touches two methods of `ClassDocumenter`"*); `add_content` was treated as fixed background and never re-audited.

---

## 3. Artifact audit — VERDICT

### VERDICT: **MISSING (inverted) — REACHABLE — does NOT count toward headroom**

This matches primer **tell #9** ("FVK *certifies the buggy behavior as the spec*"): the artifacts do not merely omit the root cause — their postcondition **equals the buggy output**, and findings assert it correct. The defect region (`ClassDocumenter.add_content`'s unconditional `alias of` injection) is:

- **never named** as code-under-audit (verified: no artifact quotes the `more_content = "alias of …"` block; the file's only audited methods are `get_doc` and `get_variable_comment`), and
- **affirmatively contradicted** wherever the `alias of` text appears.

**Pointed-at-the-spot applied to the *cause* (not the symptom string):** pointing a knowledgeable reader at the cited excerpts shows the artifacts encode the *opposite* of the correct-fix direction. So this is not STATED (the fix direction is never named) and not BURIED (no forced precondition, undischargeable obligation, or divergent claim latently encodes the cause — the formal scaffolding PO-I1 is built on the wrong axis, comment render-count, and explicitly excludes the buggy block). Per tell #9 this is **MISSING (inverted)**, not BURIED.

**Most load-bearing excerpt (the certification of the bug):** `fvk/SPEC.md:53-56` (Intent I1) — the comment is rendered *"in addition to `alias of <target>`"*, reinforced by `fvk/PROOF.md:116-117` ("comment + `alias of …` exactly once"). Full excerpt set in `evidence/fvk_artifact_excerpts.md`.

**Documented absence (what was searched):** the strings `add_content`/`alias of` were traced through all five `fvk/*.md`, `reports/fvk_notes.md`, and the 316-line transcript. `add_content` appears only as the base-class `no_docstring` "render-once" mechanism (`fvk_notes.md` D1; transcript ~299-303); `alias of` appears only inside Intent I1 / F1 / PROOF §4 as a thing rendered *correctly alongside* the comment. The word "suppress" never attaches to `alias of`. No excerpt anywhere proposes (or even rejects) suppressing the `alias of` line.

**Honesty check (reachability → headroom):** reachable from public data (§1), so this is a genuine **FVK gap**. Per PLAN §4, MISSING-but-reachable **does not count toward headroom** (a better surfacer of FVK's *own* output would not flip it — the information is absent and, worse, inverted; flipping it requires generating new analysis FVK never did, namely auditing `add_content`).

**Calibration note:** consistent with the prior six — this is again an **intent-fidelity / localization** failure (V1 + FVK formalized half the fix and certified the buggy other half), not a formal-expressiveness limit. The fix sits squarely in modellable straight-line autodoc control flow, so blind-spots (§vi) do not excuse the miss.

---

## 4. How FVK could surface it (prose, general, no-exec)

1. **Audit the whole rendered artifact, not just the patched method.** The fix lives in two methods (`get_doc` + `add_content`) but the audit was scope-fenced to the patched one. A "confirm V1" audit should specify the *observable output* of the unit (here: the full list of lines `do_autodoc` yields) and trace every contributor to it — which would force `add_content`'s `alias of` line into the model.

2. **Resist formalizing intent from a sibling's behavior; pin it to the issue.** The inverted premise (I1) was imported from `DataDocumenter`/`test_autodata_GenericAlias`. The intent ledger should have flagged that the issue asks to *replace* the `alias of` default text, not *augment* it — a divergence FVK is built to catch (its "spec must encode intent, not implementation" rule). A required check "does the postcondition equal what V1 currently emits?" would have caught the self-certification.

3. **Treat an existing in-repo test as evidence, not ground truth, when the issue contradicts it.** The proof leaned on `test_autodata_GenericAlias` to justify "both render." When the reported intent conflicts with a binding test, that conflict is itself the finding — the same failure mode seen in other instances (primer tell #8).
