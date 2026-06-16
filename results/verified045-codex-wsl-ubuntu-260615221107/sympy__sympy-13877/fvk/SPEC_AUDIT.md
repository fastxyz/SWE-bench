# Spec Audit

| Formal claim | Intent match | Result |
| --- | --- | --- |
| Input `S.NaN` returns `S.NaN` before dispatch | Matches intent item 4 and evidence E4. | Pass |
| Expression expanding to exact zero is skipped as pivot | Matches intent item 3 and evidence E5. | Pass |
| Later truthy expanded candidate can be returned | Required to preserve determinant computation while fixing pivot-zero detection. | Pass |
| Non-expression truthy candidate behavior is preserved | Required compatibility frame; no public intent requires changing it. | Pass |
| Public method API preserved | Matches intent item 5 and evidence E6. | Pass |

No formal claim depends solely on V1/V2 behavior as its evidence.

