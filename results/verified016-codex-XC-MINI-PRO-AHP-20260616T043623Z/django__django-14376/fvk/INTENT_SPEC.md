# Intent Spec

Status: intent-only; written before accepting candidate behavior as correct.

1. Django's MySQL backend must stop generating mysqlclient's deprecated `db`
   kwarg from `settings.DATABASES['NAME']`.
2. Django's MySQL backend must stop generating mysqlclient's deprecated
   `passwd` kwarg from `settings.DATABASES['PASSWORD']`.
3. The replacement names are `database` and `password`.
4. No mysqlclient-version compatibility branch is needed in this checkout,
   because supported mysqlclient versions accept the replacement names.
5. Existing unrelated connection settings behavior should be preserved.
6. `OPTIONS` remains a user-supplied mysqlclient options channel, with canonical
   options taking precedence over standard settings.
