# Formal Spec in English

Status: constructed from `session-encode-spec.k`, not machine-checked.

## Claim 1: SHA1 Encodes Legacy

For any store class and serializable session dictionary, evaluating `encode(C, D, SHA1)` reaches the legacy payload shape containing the legacy hash over the serialized data and the serialized data itself.

## Claim 2: SHA1 Legacy Round Trip

For any store class and serializable session dictionary, if a SHA1 transition-mode write is passed to the legacy decoder, evaluation reaches the original session dictionary.

## Claim 3: Current Decode Accepts Legacy

For any store class and serializable session dictionary, Django 3.1's decode operation accepts a legacy payload with the matching legacy hash and returns the original session dictionary.

## Claim 4: SHA256 Default Preserved

For any store class and serializable session dictionary, evaluating `encode(C, D, SHA256)` reaches the signed Django 3.1 payload shape.

## Claim 5: Current Decode Accepts Signed

For any store class and serializable session dictionary, Django 3.1's decode operation accepts the signed Django 3.1 payload and returns the original session dictionary.

## Side Conditions

The model assumes deterministic serializer round trip, a consistent store class/key salt, and a consistent secret key across participating instances. These are intent-domain assumptions, not implementation-derived escape hatches.

