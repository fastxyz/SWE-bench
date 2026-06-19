"""Regression test for IsolationForest positional-argument compatibility.

When ``warm_start`` was exposed in ``IsolationForest.__init__`` it must be
appended *after* the pre-existing parameters, not inserted in the middle of the
(non-keyword-only) signature.  The original public constructor was::

    __init__(self, n_estimators=100, max_samples="auto", contamination="legacy",
             max_features=1., bootstrap=False, n_jobs=None, behaviour='old',
             random_state=None, verbose=0)

so every parameter is legitimately addressable positionally.  A buggy fix
inserted ``warm_start`` between ``bootstrap`` and ``n_jobs``, silently shifting
the positional slots of ``n_jobs``, ``behaviour``, ``random_state`` and
``verbose`` and thereby breaking every pre-existing positional caller.
"""

import inspect

import pytest

from sklearn.ensemble import IsolationForest


@pytest.mark.filterwarnings('ignore:default contamination')
@pytest.mark.filterwarnings('ignore:behaviour')
def test_isolation_forest_positional_arg_compat():
    # A caller written against the original public API, intending:
    #   n_estimators=100, max_samples="auto", contamination="legacy",
    #   max_features=1., bootstrap=False, n_jobs=3, behaviour="new",
    #   random_state=0, verbose=1
    # (construction only -- we never call .fit(), so no deprecation warnings
    #  are emitted and no invalid n_jobs reaches joblib).
    clf = IsolationForest(100, "auto", "legacy", 1., False, 3, "new", 0, 1)

    # Each positional argument must bind to the parameter the caller intended.
    assert clf.n_jobs == 3
    assert clf.behaviour == "new"
    assert clf.random_state == 0
    assert clf.verbose == 1
    # warm_start was not supplied, so it must keep its default.
    assert clf.warm_start is False

    # Defense in depth: warm_start must come *after* verbose in the signature
    # (i.e. appended, not inserted), which is what guarantees the positional
    # contract above.
    params = list(inspect.signature(IsolationForest.__init__).parameters)
    assert "warm_start" in params
    assert params.index("warm_start") > params.index("verbose")
