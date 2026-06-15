"""Owner-specified and generated benchmark batch definitions.

The 45-instance division (2026-06-13) is a contract: exactly five batches of
nine, pairwise disjoint, whose union is the 45 submodule-derived instance ids
(invariants are test-enforced). Membership is the contract.

For the full SWE-bench Verified set, batches are generated from the sorted
500-instance metadata file as ``verified001`` ... ``verified050`` with ten
instances each.
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


VERIFIED_BATCH_SIZE = 10
VERIFIED_BATCH_COUNT = 50


def verified_batch_names() -> tuple[str, ...]:
    """Return generated full-Verified batch names in order."""
    return tuple(f"verified{i:03d}" for i in range(1, VERIFIED_BATCH_COUNT + 1))


def batch_instances(
    name: str, *, instance_ids: tuple[str, ...] | None = None
) -> tuple[str, ...]:
    """Return the instance ids of batch ``name`` in the owner's listed order.

    The fixed ``batch1`` ... ``batch5`` names ignore ``instance_ids``. The
    generated ``verifiedNNN`` names require the caller to pass the ordered full
    Verified 500-id sequence, because their membership is defined by that
    vendored metadata order.

    Raises:
        KeyError: naming the valid batches, if ``name`` is not one of them.
    """
    if name in BATCHES:
        return BATCHES[name]

    verified_names = verified_batch_names()
    if name in verified_names:
        ids = tuple(instance_ids or ())
        required = VERIFIED_BATCH_SIZE * VERIFIED_BATCH_COUNT
        if len(ids) != required:
            raise KeyError(
                f"{name} requires exactly {required} ordered verified500 instance ids; "
                f"got {len(ids)}"
            )
        idx = int(name.removeprefix("verified")) - 1
        start = idx * VERIFIED_BATCH_SIZE
        return ids[start:start + VERIFIED_BATCH_SIZE]

    raise KeyError(
        f"unknown batch {name!r}; valid: {', '.join(sorted(BATCHES))} "
        f"or verified001..verified050"
    )
