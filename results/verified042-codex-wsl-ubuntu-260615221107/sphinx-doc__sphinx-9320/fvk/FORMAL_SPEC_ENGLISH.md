# Formal Spec English

Status: paraphrase of `fvk/quickstart-spec.k`.

## QS-EXISTING-ROOT

For every interactive quickstart invocation where the selected root path already
contains `conf.py`, execution reaches a terminal state with status `1`, the
existing-project warning has been emitted, generation has not happened, and the
replacement-root prompt has not been reached.

## QS-EXISTING-SOURCE

For every interactive quickstart invocation where the selected root path does
not contain `conf.py` directly but does contain `source/conf.py`, execution
reaches a terminal state with status `1`, the existing-project warning has been
emitted, generation has not happened, and the replacement-root prompt has not
been reached.

## QS-NO-CONF-FRAME

For the reduced non-conflict model where neither `conf.py` nor `source/conf.py`
exists, this patch does not take the existing-project branch; generation remains
reachable and no existing-project warning or replacement-root prompt is emitted
by the audited guard.
