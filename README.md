# Flutter Database Benchmarks

Flutter Database Benchmarks is a Dart and Flutter local database benchmark suite. It measures popular local persistence packages through real adapters, runs the same realistic scenarios on supported targets, and renders committed JSON snapshots into charts.

Open [docs/results.html](docs/results.html) to see the benchmark results visually. The README stays as a compact index: what is measured now, which targets are skipped for platform reasons, and where the raw data lives.

## Current Scope

- Flutter stable channel.
- Runtime targets: Flutter Web in Chrome, Flutter Linux desktop, and Flutter Windows in CI; Android physical-device runs are supported as local/private measurements.
- CI workload: deterministic balanced CRUD, read-heavy, large-payload, write-churn stress, and batched-transaction scenarios with point reads, group queries, updates, deletes, and verification reads. Pull-request and push runs are smoke-sized to keep every change reproducible; scheduled runs use a larger record count without changing scenario semantics, and manual workflow dispatch defaults to a heavier run.
- Public source of truth: committed JSON files under `results/`, regenerated into this README and `docs/results.html` by `dart run tool/update_readme.dart`.
- The package matrix only lists packages with checked coverage: real adapters where the package can be measured in this repo, or explicit package-level reasons when a direct adapter is blocked by generator, solver, platform, or packaging constraints. Unchecked package ideas do not appear as benchmark coverage.
- `memory_baseline`, `shared_preferences`, `get_storage`, and `hive_ce` are baselines. The HTML report has a separate SQL/document summary so key-value settings stores do not dominate database-engine comparisons.
- Local machine and physical-device measurements belong under gitignored `local_results/`.

Ops/sec is every counted operation divided by the median successful sample window. Counted operations include writes, point reads, group-query calls, updates, deletes, and verification/source reads. `open()`, `clear()`, and successful `close()`/flush work stay inside the timed window but are not added to the operation count.

## Package Matrix

<!-- DBENCH:PACKAGE_MATRIX:start -->
<details>
<summary>Adapter-covered package matrix (36 packages)</summary>

| Package | Latest | Family | Type | Platforms | Transactions | Benchmark status |
| --- | ---: | --- | --- | --- | --- | --- |
| [drift](https://pub.dev/packages/drift) | 2.33.0 | SQL | SQLite ORM/query builder | Android, iOS, macOS, Windows, Linux, Web | SQLite transactions | Runnable on native CI; Web is skipped until sqlite3 WASM assets are configured |
| [sqflite](https://pub.dev/packages/sqflite) | 2.4.2+1 | SQL | SQLite plugin | Android, iOS, macOS | SQLite transactions | Runnable on Android and Apple targets; desktop CI uses sqflite_common_ffi |
| [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi) | 2.4.0+3 | SQL | SQLite FFI implementation | Windows, Linux, macOS, tests | SQLite transactions | Runnable on Windows and Linux CI |
| [sqflite_sqlcipher](https://pub.dev/packages/sqflite_sqlcipher) | 3.4.0 | SQL | Encrypted SQLite plugin | Android, iOS, macOS | SQLite transactions | Adapter implemented; skipped on desktop CI because the plugin backend is mobile/Apple oriented |
| [sqlite3](https://pub.dev/packages/sqlite3) | 3.3.1 | SQL | SQLite FFI bindings | Dart VM and Flutter native targets | Manual SQLite transactions | Runnable on native Flutter targets |
| [sqlite_async](https://pub.dev/packages/sqlite_async) | 0.14.1 | SQL | Async SQLite wrapper | Flutter native targets | SQLite transactions | Runnable on native CI; Web is skipped until sqlite3 WASM assets are configured |
| [floor](https://pub.dev/packages/floor) | 1.5.0 | SQL | SQLite ORM | Flutter targets supported by sqflite | sqflite transactions through generated code | Coverage is explicit: Floor is represented as a generated sqflite ORM; raw storage performance is measured by sqflite |
| [hive](https://pub.dev/packages/hive) | 2.2.3 | Key-value baseline | Key-value / typed boxes | Android, iOS, macOS, Windows, Linux, Web | BoxCollection transactions on Web-oriented collection APIs | Adapter implemented with raw Map boxes |
| [hive_ce](https://pub.dev/packages/hive_ce) | 2.19.3 | Key-value baseline | Key-value / typed boxes | Android, iOS, macOS, Windows, Linux, Web | No general transaction model | Runnable in this repo |
| [isar](https://pub.dev/packages/isar) | 3.1.0+1 | NoSQL | Object database | Android, iOS, macOS, Windows, Linux | Native Isar read/write transactions | Coverage is explicit: generator-required adapter surface is documented, not replaced with a placeholder |
| [isar_community](https://pub.dev/packages/isar_community) | 3.3.2 | NoSQL | Object database | Android, iOS, macOS, Windows, Linux | Native Isar read/write transactions | Coverage is explicit: generator-required adapter surface is documented, not replaced with a placeholder |
| [isar_db](https://pub.dev/packages/isar_db) | 1.0.1+1 | NoSQL | Object database fork | Flutter native targets | Native object-store transactions | Solver coverage: package depends on build ^2.4.x and conflicts with build_runner 2.15 |
| [isar_plus](https://pub.dev/packages/isar_plus) | 1.2.6 | NoSQL | Object database fork | Flutter native targets | Native object-store transactions | Coverage is explicit: generator-required adapter surface is documented, not replaced with a placeholder |
| [objectbox](https://pub.dev/packages/objectbox) | 5.3.1 | NoSQL | Object database | Android, iOS, macOS, Windows, Linux | Native ObjectBox transactions | Coverage is explicit: generator-required adapter surface is documented, not replaced with a placeholder |
| [realm](https://pub.dev/packages/realm) | 20.2.0 | NoSQL | Object database | Flutter native targets | Realm write transactions | Solver coverage: realm_generator is incompatible with analyzer 10/build_runner 2.15 in this checkout |
| [cbl_flutter](https://pub.dev/packages/cbl_flutter) | 3.3.5 | NoSQL | Embedded document database | Flutter native targets | Couchbase Lite batch/write semantics | Coverage is explicit: native runtime initialization is represented by adapter coverage, not a synthetic placeholder |
| [couchbase_lite](https://pub.dev/packages/couchbase_lite) | 2.8.5 | NoSQL | Embedded document database | Flutter native targets | Couchbase Lite write semantics | Coverage is explicit: older Couchbase Lite line is mapped to the maintained cbl_flutter runtime |
| [sembast](https://pub.dev/packages/sembast) | 3.8.7 | NoSQL | Document database | Dart VM and Flutter native targets | Single database transaction API | Runnable on native targets |
| [sembast_web](https://pub.dev/packages/sembast_web) | 2.4.4+1 | NoSQL | Document database | Web | Sembast transaction API | Runnable on Web CI |
| [sembast_sqflite](https://pub.dev/packages/sembast_sqflite) | 2.2.1+1 | NoSQL | Document database on sqflite | Android, iOS, macOS | Sembast transaction API over sqflite | Adapter implemented; skipped on desktop CI because sqflite backend is mobile/Apple oriented |
| [objectdb](https://pub.dev/packages/objectdb) | 1.2.1+1 | NoSQL | Document database | Dart IO and Web storage backends | No general transaction model | Adapter implemented with file-system storage |
| [tiny_db](https://pub.dev/packages/tiny_db) | 0.9.2 | NoSQL | JSON document database | Dart IO and Flutter native targets | No general transaction model | Adapter implemented with JsonStorage |
| [store_box](https://pub.dev/packages/store_box) | 2.0.0 | NoSQL | NoSQL key-value boxes | Dart IO and Flutter native targets | No general transaction model | Adapter implemented with Map boxes |
| [work_db](https://pub.dev/packages/work_db) | 1.3.0 | NoSQL | JSON collection database | Dart IO, Flutter native targets, Web | No general transaction model | Adapter implemented with IO WorkDB |
| [flutter_local_db](https://pub.dev/packages/flutter_local_db) | 1.5.1 | NoSQL | Rust/LMDB local database | Android, iOS, macOS, Windows, Linux, Web facade | Backend-managed writes | Excluded: package declares Windows plugin support but does not ship a Windows plugin directory, breaking Flutter desktop generation |
| [ffastdb](https://pub.dev/packages/ffastdb) | 0.2.7 | NoSQL | Pure Dart NoSQL database | Dart IO and Web storage strategies | FastDB transaction API | Adapter implemented with WAL storage |
| [reaxdb_dart](https://pub.dev/packages/reaxdb_dart) | 1.4.1 | NoSQL | NoSQL key-value/document database | Dart IO and Flutter native targets | Advanced transaction API | Adapter implemented with SimpleReaxDB |
| [quanta_db](https://pub.dev/packages/quanta_db) | 0.0.9 | NoSQL | NoSQL database | Dart / Flutter targets declared by package | Package-defined write semantics | Solver coverage: package depends on build ^2.4.x and conflicts with build_runner 2.15 |
| [torex_local_store](https://pub.dev/packages/torex_local_store) | 0.1.6 | NoSQL | Rust embedded key-value database | Flutter native targets | Backend-managed writes | Adapter implemented with Torex boxes |
| [torexstore](https://pub.dev/packages/torexstore) | 0.0.1 | NoSQL | Early Torex storage package | Flutter native targets | Package-defined write semantics | Coverage is explicit: older Torex line is mapped to torex_local_store |
| [entidb_flutter](https://pub.dev/packages/entidb_flutter) | 2.0.0-alpha.3 | NoSQL | Embedded entity database | Android, iOS, macOS, Windows, Linux | ACID transaction API | Adapter implemented with EntiDB collections |
| [rxdb](https://pub.dev/packages/rxdb) | 15.0.0-beta.31 | NoSQL | Reactive database wrapper | Flutter targets declared by package | Package-defined write semantics | Solver coverage: rxdb pins shared_preferences 2.0.17, conflicting with shared_preferences 2.5.5 |
| [powersync](https://pub.dev/packages/powersync) | 2.1.0 | SQL | Offline-first SQLite sync database | Android, iOS, macOS, Windows, Linux, Web | SQLite write transactions | Adapter implemented with local-only PowerSync table |
| [localstore](https://pub.dev/packages/localstore) | 1.4.0 | NoSQL | JSON document storage | Flutter targets declared by package | No general transaction model | Runnable in this repo |
| [get_storage](https://pub.dev/packages/get_storage) | 2.1.1 | Key-value baseline | Lightweight key-value storage | Android, iOS, macOS, Windows, Linux, Web | No transaction model | Runnable in this repo |
| [shared_preferences](https://pub.dev/packages/shared_preferences) | 2.5.5 | Key-value baseline | Platform key-value preferences | Android, iOS, macOS, Windows, Linux, Web | No transaction model | Runnable in this repo |

</details>
<!-- DBENCH:PACKAGE_MATRIX:end -->

## CI Result Source

<!-- DBENCH:DEVICE_SPECS:start -->
| Area | Value |
| --- | --- |
| README results | Committed benchmark JSON files under results/ are rendered into README.md and docs/results.html; GitHub Actions regenerates Web, Linux, and Windows snapshots on CI runs. |
| Local results | Personal machine and physical-device runs should be saved under gitignored local_results/. |
| Flutter | stable channel in GitHub Actions |
| Web CI | ubuntu-latest runner, Flutter Web release build, Chrome; push/pull_request smoke runs use DBENCH_RECORDS=100, scheduled stress runs use DBENCH_RECORDS=2000, manual dispatch defaults to 10000 |
| Linux CI | ubuntu-latest runner, Flutter Linux desktop integration test target; push/pull_request smoke runs use DBENCH_RECORDS=100, scheduled stress runs use DBENCH_RECORDS=2000, manual dispatch defaults to 10000 |
| Windows CI | windows-latest runner, Flutter Windows desktop test target; push/pull_request smoke runs use DBENCH_RECORDS=100, scheduled stress runs use DBENCH_RECORDS=2000, manual dispatch defaults to 10000 |
| Android | Not published in README because GitHub-hosted runners do not provide the physical device used for local measurements |
<!-- DBENCH:DEVICE_SPECS:end -->

## CI Performance Overview

<!-- DBENCH:CI_VISUALIZATION:start -->
Open [docs/results.html](docs/results.html) for the visual dashboard with SVG charts and cross-target tables.

Committed result snapshots currently present: `linux`, `web`, `windows`.

Measured packages in committed snapshots: 10 of 36. Skipped rows are target-specific platform or scenario limits, not hidden benchmark numbers.

### Coverage Snapshot

| Environment | Completed adapters | Skipped rows | Failed rows |
| --- | --- | ---: | ---: |
| linux | `drift`, `get_storage`, `hive_ce`, `localstore`, `sembast`, `shared_preferences`, `sqflite_common_ffi`, `sqlite3`, `sqlite_async` | 16 | 0 |
| web | `get_storage`, `hive_ce`, `localstore`, `sembast_web`, `shared_preferences` | 36 | 0 |
| windows | `drift`, `get_storage`, `hive_ce`, `localstore`, `sembast`, `shared_preferences`, `sqflite_common_ffi`, `sqlite3`, `sqlite_async` | 16 | 0 |

### Adapter-Covered But Not Present In CI Numbers

`cbl_flutter`, `couchbase_lite`, `entidb_flutter`, `ffastdb`, `floor`, `flutter_local_db`, `hive`, `isar`, `isar_community`, `isar_db`, `isar_plus`, `objectbox`, `objectdb`, `powersync`, `quanta_db`, `realm`, `reaxdb_dart`, `rxdb`, `sembast_sqflite`, `sqflite`, `sqflite_sqlcipher`, `store_box`, `tiny_db`, `torex_local_store`, `torexstore`, `work_db`

Reasons are kept in raw JSON skipped rows, typically platform-only adapters such as `sqflite` on Android/iOS/macOS or Web SQLite WASM/worker setup that is intentionally not counted as a completed CI number.

### Fastest Rows

| Environment | Scenario | Fastest SQL/document adapter | Fastest persistent adapter | Completed | Skipped | Failed |
| --- | --- | --- | --- | ---: | ---: | ---: |
| linux | batched_transaction | `sqlite3` 34,687 ops/sec | `sqlite3` 34,687 ops/sec | 4 | 8 | 0 |
| linux | crud_balanced | `drift` 1,649 ops/sec | `get_storage` 42,645 ops/sec | 10 | 2 | 0 |
| linux | large_payload | `sqlite3` 1,925 ops/sec | `get_storage` 77,548 ops/sec | 10 | 2 | 0 |
| linux | read_heavy | `sqlite3` 2,697 ops/sec | `get_storage` 92,192 ops/sec | 10 | 2 | 0 |
| linux | write_churn_stress | `drift` 1,777 ops/sec | `get_storage` 72,378 ops/sec | 10 | 2 | 0 |
| web | batched_transaction | - | - | 0 | 12 | 0 |
| web | crud_balanced | `localstore` 6,526 ops/sec | `shared_preferences` 40,805 ops/sec | 6 | 6 | 0 |
| web | large_payload | `localstore` 4,070 ops/sec | `shared_preferences` 28,000 ops/sec | 6 | 6 | 0 |
| web | read_heavy | `localstore` 10,681 ops/sec | `shared_preferences` 59,788 ops/sec | 6 | 6 | 0 |
| web | write_churn_stress | `localstore` 3,073 ops/sec | `shared_preferences` 54,839 ops/sec | 6 | 6 | 0 |
| windows | batched_transaction | `sqlite3` 6,008 ops/sec | `sqlite3` 6,008 ops/sec | 4 | 8 | 0 |
| windows | crud_balanced | `sqlite_async` 1,607 ops/sec | `get_storage` 41,349 ops/sec | 10 | 2 | 0 |
| windows | large_payload | `sqlite_async` 1,437 ops/sec | `get_storage` 67,437 ops/sec | 10 | 2 | 0 |
| windows | read_heavy | `sqlite_async` 2,188 ops/sec | `get_storage` 83,673 ops/sec | 10 | 2 | 0 |
| windows | write_churn_stress | `sqlite_async` 2,325 ops/sec | `get_storage` 66,848 ops/sec | 10 | 2 | 0 |
<!-- DBENCH:CI_VISUALIZATION:end -->

## Results

<!-- DBENCH:BENCHMARK_RESULTS:start -->
The readable dashboard is [docs/results.html](docs/results.html). Raw machine-readable snapshots stay in `results/*.json` instead of being duplicated into README tables.

Measured packages across committed snapshots: 10 of 36.

| Environment | JSON source | Generated | Scenario rows | Measured packages |
| --- | --- | --- | ---: | ---: |
| linux | [`results/linux.json`](results/linux.json) | `2026-05-11T21:20:42.451351Z` | 60 | 9 |
| web | [`results/web.json`](results/web.json) | `2026-05-11T21:18:05.162Z` | 60 | 5 |
| windows | [`results/windows.json`](results/windows.json) | `2026-05-11T21:26:42.833289Z` | 60 | 9 |
<!-- DBENCH:BENCHMARK_RESULTS:end -->

## Isolate Behavior

This section checks whether a database can be reopened from a separate Dart isolate after the main isolate writes and closes the store. It does not yet prove concurrent multi-isolate write safety or package-specific worker APIs. It is intentionally separate from throughput because isolate behavior is a capability and architecture signal, not just a speed metric.

<!-- DBENCH:ISOLATE_RESULTS:start -->
<details>
<summary>Isolate sharing probe rows</summary>

| Environment | Database | Status | Shared read across isolates | Notes |
| --- | --- | --- | --- | --- |
| linux | memory_baseline | completed | no | Dart isolates have separate heaps; in-memory maps are not shared. |
| linux | hive_ce | completed | yes | Separate isolate reopened the same box path and read the main isolate record. |
| linux | sembast | completed | yes | Separate isolate reopened the same database file and read the main isolate record. |
| linux | sqflite_common_ffi | completed | yes | Separate isolate reopened the same SQLite file through sqflite_common_ffi and read the main isolate record. |
| linux | sqlite3 | skipped | not tested | Runnable adapter exists, but direct sqlite3 isolate reopening is not probed yet. |
| linux | shared_preferences | skipped | not tested | Plugin-backed storage is not probed from a background isolate. |
| linux | get_storage | skipped | not tested | Flutter/widget-bound package; isolate sharing needs a dedicated adapter. |
| linux | localstore | skipped | not tested | Runnable adapter exists, but file-backed isolate sharing is not probed yet. |
| web | all | skipped | not tested | Flutter Web does not expose Dart VM isolates for this benchmark. |
| windows | memory_baseline | completed | no | Dart isolates have separate heaps; in-memory maps are not shared. |
| windows | hive_ce | completed | yes | Separate isolate reopened the same box path and read the main isolate record. |
| windows | sembast | completed | yes | Separate isolate reopened the same database file and read the main isolate record. |
| windows | sqflite_common_ffi | completed | yes | Separate isolate reopened the same SQLite file through sqflite_common_ffi and read the main isolate record. |
| windows | sqlite3 | skipped | not tested | Runnable adapter exists, but direct sqlite3 isolate reopening is not probed yet. |
| windows | shared_preferences | skipped | not tested | Plugin-backed storage is not probed from a background isolate. |
| windows | get_storage | skipped | not tested | Flutter/widget-bound package; isolate sharing needs a dedicated adapter. |
| windows | localstore | skipped | not tested | Runnable adapter exists, but file-backed isolate sharing is not probed yet. |

</details>
<!-- DBENCH:ISOLATE_RESULTS:end -->

## Running Locally

```bash
flutter pub get
flutter test
flutter analyze
mkdir -p local_results
flutter test integration_test/benchmark_test.dart -d windows --dart-define=DBENCH_RECORDS=1000
flutter build web --release --dart-define=DBENCH_AUTORUN=true --dart-define=DBENCH_RECORDS=1000
node tool/run_web_benchmark.cjs http://127.0.0.1:18080 local_results/web.json
flutter test integration_test/benchmark_test.dart -d <android-device-id> --dart-define=DBENCH_RECORDS=1000
```

Each benchmark run prints a `DBENCH_RESULT_JSON=` line. Save personal runs into `local_results/<environment>.json`; keep `results/` reserved for CI output that is meant to update the public README.

## Adding A Database Adapter

1. Add the package to `data/package_matrix.json`.
2. Implement `DatabaseAdapter` in `lib/src/adapters/`.
3. Register it in `availableAdapters()`.
4. Keep native or code-generated packages isolated so unsupported targets report `skipped` instead of breaking the whole suite.
5. Run the unit test, analyze, and every target that the package claims to support.
