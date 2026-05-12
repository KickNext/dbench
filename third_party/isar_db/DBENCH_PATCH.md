This vendored copy is based on the published `isar_db` 1.0.1+1 package.

The pub.dev package hardcodes `Isar.version` as `0.0.0-placeholder`, while the
desktop-compatible Isar native core available to this benchmark reports
`1.2.6`. The benchmark patches that constant so the runtime version guard
accepts the same core used by `isar_plus_flutter_libs`.

No benchmark adapter behavior is implemented here; the adapter lives in
`lib/src/adapters/extended_adapters_io.dart` and uses the public `isar_db` API.
