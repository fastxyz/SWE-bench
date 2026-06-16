# Formal Spec In English

1. `PREPARE-METHOD-PY2-UNICODE`: For any ASCII HTTP method token `S`, preparing
   a Python 2 unicode method `S` results in a Python 2 native string containing
   `S.upper()`.
2. `PREPARE-METHOD-PY2-NATIVE`: For any ASCII HTTP method token `S`, preparing
   a Python 2 native string method `S` results in a Python 2 native string
   containing `S.upper()`.
3. `SESSION-REQUEST-PY2-UNICODE`: For any ASCII HTTP method token `S`, passing
   Python 2 unicode method `S` through the `requests.request()` /
   `Session.request()` construction path results in a prepared Python 2 native
   string containing `S.upper()`.
4. `PREPARE-METHOD-NONE`: If the method is `None`, `prepare_method()` leaves it
   as `None`.
5. `ASCII-METHOD-SIDE-CONDITION`: The unicode-to-native conversion is specified
   only for ASCII HTTP method tokens.
6. `PUBLIC-COMPATIBILITY`: The proof changes no public signatures and preserves
   existing uppercasing.

