# PROOF_OBLIGATIONS.md — VCs for the V1 fix (sphinx-doc__sphinx-9229)

Obligations the proof in `PROOF.md` must discharge for the contracts in
`SPEC.md`. Each lists: statement, how discharged, and status. Classes:
**PO-G** (side condition / guard), **PO-D** (behavioural / data), **PO-I**
(integration invariant), **PO-T** (trusted base / escalation boundary).

> All "discharged" below are **constructed, not machine-checked** (no toolchain
> run). PO-T items are trusted (upstream, unchanged by this fix), not proved.

---

## Side-condition obligations

### PO-G1 — `objpath` is non-empty when `get_variable_comment` runs
- **Statement:** `self.objpath ≠ []` at every call site of
  `get_variable_comment` (so `self.objpath[-1]` is defined and
  `'.'.join(self.objpath[:-1])` is well-formed).
- **Discharge:** by the reachability precondition + a caller-establishes-it
  argument. `get_doc`/`get_variable_comment` are reached only after
  `generate → import_object` succeeded; `ClassDocumenter.import_object` evaluates
  `self.objpath[-1]` for any `type` object, and a `ClassDocumenter` object is
  always a `type` (`can_document_member = isinstance(member, type)`), which
  always has `__name__`. So `import_object` would itself have raised on an empty
  `objpath` before `get_doc` runs. **Pre-existing, shared** with
  `DataDocumenter.get_doc` and `import_object`. → discharged (Z3-trivial:
  `len(objpath) ≥ 1`); see FINDINGS F7. **Status: discharged (precondition,
  upstream-enforced).**

### PO-G2 — `self.modname` is a usable module name or the failure is caught
- **Statement:** `ModuleAnalyzer.for_module(self.modname)` either returns an
  analyzer or raises `PycodeError`; no other exception escapes
  `get_variable_comment`.
- **Discharge:** `for_module` raises only `PycodeError` (it caches/raises
  `PycodeError` on `get_module_source` failure); `analyze()` wraps **all**
  exceptions as `PycodeError` (`except Exception as exc: raise PycodeError(...)`).
  Both are caught by `except PycodeError → return []`. `self.modname` is non-`None`
  on the reachable path (else `generate` returned early before `parse_name`
  resolved a module). → **Status: discharged** (totality; FINDINGS F2).

---

## Behavioural / data obligations

### PO-D1 — (GVC) result correctness
- **Statement:** `get_variable_comment() = list(attr_docs_of(self.modname).get(K0, []))`
  with `K0 = ('.'.join(self.objpath[:-1]), self.objpath[-1])`.
- **Discharge:** straight-line symbolic execution (`PROOF.md` §A): bind
  `key = K0`; `analyzer = for_module(M)`; `analyze()` (idempotent, no observable
  store change modeled — effect folded into the oracle); evaluate
  `attr_docs.get(key, [])`; `list(...)` is a value-preserving copy. → **Status:
  discharged**, modulo PO-T1/PO-T2.

### PO-D2 — `get_doc` returns **`None`** (not `[]`) iff no comment
- **Statement:** alias branch with `C0 = []` reaches `return None`, and `None`
  (≠ `[]`) is essential: `[]` would make `add_content` fire
  `autodoc-process-docstring` on a dummy block.
- **Discharge:** `(GETDOC-NONE)` symbolic run — `truthy([]) = false` selects the
  `else: return None` arm. The `None`/`[]` distinction is checked against
  `add_content`'s `if docstrings is None: pass` vs
  `if not docstrings: docstrings.append([])`. → **Status: discharged** (FINDINGS
  F5; pins `test_class_alias`).

### PO-D3 — `get_doc` returns `[C0]` iff comment present
- **Statement:** alias branch with `C0 ≠ []` reaches `return [C0]`.
- **Discharge:** `(GETDOC-COMMENT)` symbolic run — `truthy(C0) = true` selects
  `return wrap(C0) = [C0]`. → **Status: discharged** (FINDINGS F1).

### PO-D4 — alias branch never reaches the class-`__doc__` path (I2 preserved)
- **Statement:** when `doc_as_attr = true`, `get_doc` returns from the alias
  branch and never falls through to `getattr(self,'_new_docstrings',…)` /
  `self.object.__doc__`.
- **Discharge:** the `if self.doc_as_attr:` block returns on **both** arms
  (`[C0]` or `None`); control cannot reach the code below it. (Also
  `format_signature` returns `''` early for `doc_as_attr`, so `_find_signature`
  never runs and `_new_docstrings` stays `None` — no interaction.) → **Status:
  discharged.**

---

## Integration obligation (the keystone)

### PO-I1 — NO-DOUBLE: the comment renders at most once
- **Statement:** in `Documenter.add_content`, PATH-1 (analyzer) and PATH-2
  (`get_doc`) never both render the comment.
- **Discharge:** Case-Analysis on `key ∈ attr_docs(self.analyzer)`:
  - **true →** PATH-1 renders **and** sets `no_docstring = True`; the guard
    `if not no_docstring:` then **skips** PATH-2 (so `get_doc` is not even
    called). One render.
  - **false →** PATH-1 renders nothing, `no_docstring` stays `False`, PATH-2
    runs; it renders `[C0]` (if `C0≠[]`) or nothing (if `get_doc=None`). ≤1 render.
  Disjoint and exhaustive ⇒ render count ∈ {0,1}. → **Status: discharged**
  (FINDINGS F4). This is the obstacle whose *failure* would have been the bug
  signal; it discharges.

### PO-I2 — module-coverage completeness
- **Statement:** for every alias-with-comment, **some** path renders it: PATH-1
  when `self.analyzer`'s module (`self.real_modname`) contains the key; PATH-2
  (from `self.modname`) otherwise.
- **Discharge:** the comment is recorded under `self.modname` (PO-T2). If
  `self.real_modname = self.modname` (same-module, or `automodule` forcing
  `real_modname` to the documented module), PATH-1 covers it. Else PATH-2 reads
  `self.modname` directly via `get_variable_comment`. The two together cover all
  cases where the alias is defined in `self.modname`. (Re-export across modules is
  the explicit gap — FINDINGS F9, no worse than V0.) → **Status: discharged for
  the in-scope domain.**

---

## Trusted base / escalation boundaries

### PO-T1 — analyzer oracle adequacy `[ESCALATION BOUNDARY]`
- `#oracleAttrDocs(M,K)` equals
  `list(ModuleAnalyzer.for_module(M).analyze().attr_docs.get(K, []))` on
  analyzable `M`, `.List` otherwise. The `sphinx.pycode` parser populating
  `attr_docs` is **upstream and unchanged by this fix**. Trusted, **not** proved
  here (would require formalizing the tokenizer + AST visitor — out of fragment).
  Routed to the parser sources, not faked `[trusted]`-with-confidence.

### PO-T2 — key adequacy `[ESCALATION BOUNDARY]`
- A module/class variable comment is stored under `(parent_qualname, name)`, and
  for the documented object that equals
  `('.'.join(self.objpath[:-1]), self.objpath[-1])`. Established by reading
  `VariableCommentPicker.add_variable_comment` and confirming it is the **same**
  key `add_content`'s PATH-1 already uses (so V1 cannot disagree with the
  established path on the key). Trusted.

### PO-T3 — Python value/exception semantics
- Truthiness of `list`/`None`, `list(L)` shallow copy, `'.'.join`, slice/index,
  and `try/except` flow are assumed standard (mini-Python fragment + the
  guard-modeling convention). The fragment is a stopgap; full Python-in-K is the
  roadmap. Trusted.

---

## Summary table

| PO | Kind | Status |
|----|------|--------|
| PO-G1 objpath non-empty | side cond | discharged (upstream-enforced) |
| PO-G2 modname/total | guard | discharged |
| PO-D1 GVC result | data | discharged (mod PO-T1/T2) |
| PO-D2 None≠[] no-comment | data | discharged |
| PO-D3 [C0] with-comment | data | discharged |
| PO-D4 I2 no class __doc__ | data | discharged |
| PO-I1 NO-DOUBLE | integration | **discharged (keystone)** |
| PO-I2 coverage | integration | discharged (in-scope) |
| PO-T1 analyzer oracle | trusted | escalation boundary (upstream) |
| PO-T2 key adequacy | trusted | escalation boundary (upstream) |
| PO-T3 Python semantics | trusted | fragment stopgap |

**No obligation is blocked by a defect in the V1 code.** The only open items are
trusted-base/escalation boundaries that are upstream of, and unaffected by, this
fix.
