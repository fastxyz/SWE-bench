# Formal Spec English

Claim C1: If the combined sequence of ufunc inputs and outputs contains a
non-Quantity, non-ndarray object that has a `unit` attribute, the modeled
`Quantity.__array_ufunc__` dispatch gate returns `NotImplemented`.

Claim C2: If the combined sequence contains only Quantities, ndarrays, `None`,
or objects without `unit`, the modeled dispatch gate proceeds to the existing
Quantity converter path.

Claim C3: In the C1 case, the converter path is not entered.

Claim C4: Astropy table Columns remain accepted because they are represented by
the `ND` class in the model.

