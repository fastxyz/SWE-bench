# Formal Spec in English

Status: constructed, not machine-checked.

`LAZY-REF-PRESERVES-APP-LABEL`: For any normalized lazy relation with app label `APP` and model name `MODEL`, serialization returns a relation whose app label is exactly `APP` and whose model component is `lower(MODEL)`.

`REPORTED-CASE`: The reported relation `DJ_RegLogin.Category` serializes to `DJ_RegLogin.category`.

`LEGACY-REPORTED-CASE`: The legacy whole-string lowercasing behavior serializes the reported relation to `dj_reglogin.category`; this is the failing behavior, not an intended result.

`CONCRETE-REF-LABEL-LOWER`: For an already resolved model with app label `APP` and lowercase model key `MODEL_LOWER`, serialization returns `APP.MODEL_LOWER`.

Frame condition: swappable wrapping may wrap the serialized value but does not alter the app-label casing decision.

