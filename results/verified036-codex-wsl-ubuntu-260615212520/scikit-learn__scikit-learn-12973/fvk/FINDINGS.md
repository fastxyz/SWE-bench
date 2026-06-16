# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent, source inspection, and constructed proof obligations only.

## F-001: Constructor copy_X was silently overridden on omitted fit argument

Input: `LassoLarsIC(copy_X=False).fit(X, y)` with no `fit`-level `copy_X`.

Pre-fix observed behavior: `_preprocess_data` used `self.copy_X == False`, but `lars_path` used the method default `copy_X == True`.

Expected behavior: both operations use `False`, because the omitted fit argument must not overwrite the constructor setting.

Status: Closed by V1/V2. Source lines 1504-1515 resolve `None` to `self.copy_X` and pass the resolved local value to both `_preprocess_data` and `lars_path`. This discharges proof obligation PO-1.

## F-002: Explicit fit-level copy_X could still produce mixed internal routing

Input: `LassoLarsIC(copy_X=True).fit(X, y, copy_X=False)`.

Pre-fix observed behavior: `_preprocess_data` used `self.copy_X == True`, but `lars_path` used explicit `copy_X == False`.

Expected behavior: both operations use the explicit value `False`, because keeping the fit argument for compatibility only makes sense if it overrides consistently for the whole fit call.

Status: Closed by V1/V2. Source lines 1507-1515 pass the same resolved local value to both downstream operations. This discharges proof obligation PO-2.

## F-003: Public docstring type needed to mention the None sentinel

Input: a reader or API documentation consumer inspecting `LassoLarsIC.fit(copy_X=None)`.

V1 observed behavior: code accepted and used `None` as the default sentinel, but the docstring said `copy_X : boolean, optional, default None`.

Expected behavior: the public docstring should identify the accepted sentinel as part of the parameter type.

Status: Closed in V2. The docstring now says `copy_X : boolean or None, optional, default None`. This supports proof obligation PO-5.

## F-004: Machine-checking and runtime tests were intentionally not run

Input: any claim that the proof has been checked by `kprove` or validated by tests.

Observed behavior in this session: no Python, tests, `kompile`, `kast`, or `kprove` were run, as required by the task.

Expected behavior: all proof results are labeled constructed, not machine-checked; test removal is not recommended.

Status: Open operational caveat, not a source bug. This is captured by proof obligation PO-6.
