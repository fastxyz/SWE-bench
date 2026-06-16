# FVK Findings

Status: constructed by source/formal audit; no tests or K tools were run.

## F-001: Original Case-Folded Registration Collides Distinct Terms

Input:

```rst
.. glossary::

   MySQL
      ...

   mysql
      ...
```

Pre-fix observed behavior from the issue: duplicate warning for `mysql`.

Expected behavior from public intent: no duplicate warning; `MySQL` and `mysql`
are distinct glossary terms.

Classification: code bug in registration key.

Resolution: fixed by registering `termtext` exactly in
`make_glossary_term()`. See PO-001 and PO-002.

## F-002: V1 Changed Public Pending-XRef Target Shape

Input:

```rst
:term:`MySQL`
```

V1 observed by source inspection: removing `lowercase=True` made
`pending_xref['reftarget'] == 'MySQL'`.

Expected compatibility behavior: keep the previous lowercased public
`reftarget == 'mysql'`, because intersphinx inventory lookup uses `reftarget`
directly and existing inventories can contain lowercased term names.

Classification: compatibility regression introduced by V1.

Resolution: fixed in V2 by adding `TermXRefRole`, which stores
`std:term-original == 'MySQL'` while returning lowercased `reftarget ==
'mysql'`. See PO-004 and PO-005.

## F-003: Ambiguous Case-Folded References Must Not Guess

Input state: both `MySQL -> term-MySQL` and `mysql -> term-mysql` exist; a
reference target such as `MYSQL` has no exact term match.

Observed V2 behavior by source inspection: `_resolve_term('MYSQL')` sees two
case-folded matches with different labels and returns no local target.

Expected behavior: do not pick one arbitrarily; exact spelling is required to
distinguish case variants.

Classification: confirmed intentional behavior.

Resolution: encoded in `_resolve_term()` and PO-006.

## F-004: Machine Check and Runtime Tests Not Performed

Input: all proof obligations in this FVK pass.

Observed: the proof is constructed but not machine-checked, and project tests
were not run because the task forbids running tests, Python, or K tooling.

Expected for this environment: emit commands and reason statically.

Classification: proof-process limitation, not a code finding.

Resolution: proof/test removal recommendations remain conditional on running
the emitted K commands and the project tests in a valid environment.
