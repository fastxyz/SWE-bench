# SPEC — `pylint._check_regexp_csv` / `_regexp_csv_transfomer`

Formal specification produced by applying the FVK `/formalize` workflow to the
V1 fix for pylint-dev/pylint#8898 ("bad-names-rgxs mangles regular expressions
with commas"). Default mode is **intent-spec**: align the issue's intent ↔ the
code ↔ this formal spec, and report mismatches as Findings.

The constructed K artifacts are `fvk/mini_python.k` (the mini-Python fragment
semantics) and `fvk/mini_python_spec.k` (the claims). They are **constructed,
not machine-checked** — the MVP does not run `kompile`/`kprove`.

---

## 1. Target functions

Two functions in the call chain for any option of type `regexp_csv`
(`bad-names-rgxs`, `good-names-rgxs`, `design_analysis` exclusions, …):

* `pylint/utils/utils.py::_check_regexp_csv(value)` — the new comma splitter (the
  subject of this audit; it contains the only loop).
* `pylint/config/argument.py::_regexp_csv_transfomer(value)` — calls
  `_check_regexp_csv` and compiles each piece with `_regex_transformer`,
  collecting `list[Pattern[str]]`.

`_regex_transformer` is reused unchanged; its contract is: return
`re.compile(s)`, or raise `argparse.ArgumentTypeError` on `re.error`.

## 2. Intended behavior (from intent evidence)

Evidence: the issue title/body ("any valid regular expression … expressible in
this option"), the maintainer thread (keep the CSV-of-regexes feature for 3.0
but "don't split on a comma if it's inside an unclosed `{`"; validate each piece
cleanly; "exit cleanly" on a bad regex), the function/parameter names, the
docstring, and the **pre-existing contract of `_splitstrip`** that this code
replaces (`split on ',' → strip each field → discard empty fields`).

Intended contract of `_check_regexp_csv(value)` for a **string** `value`:

> Partition `value` into fields at every comma **that is not inside an
> unclosed `{ … }`**; strip surrounding whitespace from each field; discard
> fields that are empty after stripping; return the remaining fields in order.

i.e. it **generalizes `_splitstrip`** by exempting commas inside a `{}`
quantifier. For a `list`/`tuple` `value` it passes the elements through
unchanged (exactly as the sibling `_check_csv` does).

Define this precisely as the abstraction `SPLIT(value)` (formalized as `split`
in `mini_python_spec.k`):

* Left-scan `value` keeping a boolean `inBrace`, updated per char: `{` ⟼ `true`;
  `}` ⟼ `false` **iff** currently `true`; any other char ⟼ unchanged. (Commas
  do not touch `inBrace`, so the value before/after the per-char update
  coincides for a comma — no ambiguity in "evaluate the guard before or after".)
* A **separator** is an index `i` with `value[i] == ','` and `inBrace` false there.
* Separators partition `value` into segments `S₀ … S_k`.
* `SPLIT(value) = [ strip(Sⱼ) for j if strip(Sⱼ) != "" ]`.

Intended contract of `_regexp_csv_transfomer(value)`:

> `[ re.compile(p) for p in SPLIT(value) ]`, except that a `p` that is not a
> valid regex raises `argparse.ArgumentTypeError` (never a bare `re.error`/
> traceback, and never silently mangled).

## 3. Formal claims (see `mini_python_spec.k`)

* **(C-STR)** function contract, string branch — a reachability rule
  `φ_pre ⇒ φ_post`: from the initial state (`regexps=[None]`, `open_curly=False`,
  symbolic input char-list `VALUE`), executing the scan loop **and** the result
  loop terminates with `<out> = split(VALUE)`. Precondition: `VALUE` is a string
  (no further restriction — the function is **total on all strings**).
* **(C-LIST)** function contract, list/tuple branch — pass-through:
  `<out> = VALUE`. Precondition `isList(VALUE)`.
* **(LOOP)** scan-loop **circularity**, generalized over the partial segment
  list `R`, the brace boolean `B`, and the unscanned suffix `REST` (NOT pinned to
  their entry values). Running the loop from `(R, B)` over `REST` reaches
  `regexps = scanFrom(R, B, REST)`, `open_curly = brace(B, REST)`. `scanFrom` /
  `brace` are the left-folds of the body's case logic; their one-char unfoldings
  are the verification condition **VC-STEP**.

The result loop (`for regexp in regexps`) is a second bounded loop; it is
specified by the `emit` abstraction (drop `None` sentinels, strip, drop empties)
and discharged the same way (a trivial circularity over the suffix of `regexps`).

## 4. Termination / correctness class

Both loops are `for` loops over a **fixed-length** value (the input string, then
the finite `regexps` list). Each iteration consumes one element, so the loops
**always terminate**. The proof is therefore **total**, not merely partial — a
stronger result than the `while`-loop reference examples, and there is no
decreasing-measure obligation to defer.

## 5. Trusted base / residual risk

* Adequacy of the mini-Python fragment in `mini_python.k` w.r.t. real CPython
  semantics for the constructs used (`for` over `str`, list `append`, `[-1]`,
  `is None`, `str.join`/`str.strip`, short-circuit `and`/`not`).
* The Python **aliasing** of `current = regexps[-1]; current.append(char)` —
  `current` and `regexps[-1]` are the same mutable object, so the append is
  observed through `regexps`. The K model encodes this as an update of the last
  segment of `regexps` (value sorts don't alias); the fidelity of that encoding
  is part of the trusted base (see Finding F7).
* The reachability proof-system metatheory and `kprove`; the SMT /
  `[simplification]` oracle.
* **"Constructed, not machine-checked."** Run-commands to upgrade to
  machine-checked:

  ```sh
  kompile fvk/mini_python.k --backend haskell
  kast    --backend haskell fvk/mini_python_spec.k
  kprove  fvk/mini_python_spec.k          # expected: #Top
  ```

The genuinely inductive equalities over symbolic strings/lists (VC-STEP and
VC-EMIT for an unbounded symbolic `VALUE`) sit at the **[ESCALATION BOUNDARY]**
of the bundled tier (list/string structural induction); see
`PROOF_OBLIGATIONS.md` PO8. They are *specified*, discharged for every concrete
/ bounded instance, and routed to the induction sources — never faked as
`[trusted]`.
