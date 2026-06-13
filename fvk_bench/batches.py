"""Owner-specified division of the 45 benchmark instances into five batches.

The division (2026-06-13) is a contract: exactly five batches of nine,
pairwise disjoint, whose union is the 45 submodule-derived instance ids
(invariants are test-enforced). Membership is the contract.
"""

BATCHES: dict[str, tuple[str, ...]] = {
    "batch1": ("astropy__astropy-13398", "django__django-10554", "django__django-11138",
               "django__django-11400", "django__django-11885", "django__django-12325",
               "django__django-12708", "django__django-13128", "django__django-13212"),
    "batch2": ("astropy__astropy-13579", "django__django-13344", "django__django-13449",
               "django__django-13837", "django__django-14007", "django__django-14011",
               "django__django-14631", "django__django-15128", "django__django-15268"),
    "batch3": ("astropy__astropy-14369", "django__django-15503", "django__django-15629",
               "django__django-15957", "django__django-16263", "django__django-16560",
               "django__django-16631", "pylint-dev__pylint-4551", "pylint-dev__pylint-8898"),
    "batch4": ("pydata__xarray-3993", "pytest-dev__pytest-10356", "pytest-dev__pytest-5787",
               "pytest-dev__pytest-6197", "sphinx-doc__sphinx-11510", "sphinx-doc__sphinx-7590",
               "sphinx-doc__sphinx-8548", "sphinx-doc__sphinx-9229", "sphinx-doc__sphinx-9461"),
    "batch5": ("pydata__xarray-6992", "scikit-learn__scikit-learn-25102", "sympy__sympy-12489",
               "sympy__sympy-13852", "sympy__sympy-13878", "sympy__sympy-14248",
               "sympy__sympy-16597", "sympy__sympy-17630", "sympy__sympy-18199"),
}


def batch_instances(name: str) -> tuple[str, ...]:
    """Return the instance ids of batch ``name`` in the owner's listed order.

    Raises:
        KeyError: naming the valid batches, if ``name`` is not one of them.
    """
    try:
        return BATCHES[name]
    except KeyError:
        raise KeyError(
            f"unknown batch {name!r}; valid: {', '.join(sorted(BATCHES))}"
        ) from None
