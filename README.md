# Flutter Database Benchmarks

Flutter Database Benchmarks is a Dart and Flutter local database benchmark suite. It measures popular local persistence packages through real adapters, runs the same realistic scenarios on supported targets, and renders JSON snapshots into charts.

Open [docs/results.html](docs/results.html) to see the benchmark results visually. The README stays as a compact index: what is measured now, how the targets are produced, and where the raw data lives.

## Current Scope

- Flutter stable channel.
- Runtime targets: Flutter Web JS in Chrome, Flutter Web Wasm in Chrome, and one selected native Flutter target.
- Workload: deterministic balanced CRUD, read-heavy, large-payload, write-churn stress, and batched-transaction scenarios with point reads, group queries, updates, deletes, and verification reads.
- Source of truth: JSON files under `results/`, regenerated into this README and `docs/results.html` by `dart run tool/update_readme.dart`.
- The package matrix only lists packages with checked coverage: real adapters where the package can be measured in this repo, or explicit package-level reasons when a direct adapter is blocked by generator, solver, platform, or packaging constraints. Unchecked package ideas do not appear as benchmark coverage.
- `memory_baseline`, `shared_preferences`, `get_storage`, and `hive_ce` are baselines. The HTML report has a separate SQL/document summary so key-value settings stores do not dominate database-engine comparisons.
- Local machine and physical-device measurements belong under gitignored `local_results/`.

Ops/sec is every counted operation divided by the median successful sample window. Counted operations include writes, point reads, group-query calls, updates, deletes, and verification/source reads. `open()`, `clear()`, and successful `close()`/flush work stay inside the timed window but are not added to the operation count.

## Package Matrix

<!-- DBENCH:PACKAGE_MATRIX:start -->
<details>
<summary>Adapter-covered package matrix (52 packages)</summary>

| Package | Latest | Family | Type | Platforms | Transactions | Benchmark status |
| --- | ---: | --- | --- | --- | --- | --- |
| [drift](https://pub.dev/packages/drift) | 2.33.0 | SQL | SQLite ORM/query builder | Android, iOS, macOS, Windows, Linux, Web | SQLite transactions | Runnable on native targets; Web SQLite Wasm assets are outside the current measured adapter set |
| [drift_flutter](https://pub.dev/packages/drift_flutter) | 0.3.0 | NoSQL | Flutter setup helper for Drift | Android, iOS, macOS, Windows, Linux, Web | SQLite transactions through Drift | Adapter coverage maps this package to the Drift adapter because it configures Drift rather than adding a new database engine |
| [drift_sqlite_async](https://pub.dev/packages/drift_sqlite_async) | 0.3.0 | SQL | Drift/sqlite_async bridge | Dart and Flutter native targets | SQLite transactions through sqlite_async | Adapter coverage maps this bridge to the existing Drift and sqlite_async adapters |
| [sqflite](https://pub.dev/packages/sqflite) | 2.4.2+1 | SQL | SQLite plugin | Android, iOS, macOS | SQLite transactions | Runnable on Android and Apple targets; desktop runs use sqflite_common_ffi |
| [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi) | 2.4.0+3 | SQL | SQLite FFI implementation | Windows, Linux, macOS, tests | SQLite transactions | Runnable on Windows and Linux native targets |
| [sqflite_sqlcipher](https://pub.dev/packages/sqflite_sqlcipher) | 3.4.0 | SQL | Encrypted SQLite plugin | Android, iOS, macOS | SQLite transactions | Adapter implemented for mobile/Apple targets; desktop snapshots measure sqflite_common_ffi |
| [sqlite3](https://pub.dev/packages/sqlite3) | 3.3.1 | SQL | SQLite FFI bindings | Dart VM and Flutter native targets | Manual SQLite transactions | Runnable on native Flutter targets |
| [sqlite3_flutter_libs](https://pub.dev/packages/sqlite3_flutter_libs) | 0.6.0+eol | SQL | Deprecated SQLite runtime package | Flutter native targets | No database API | Removed from dependencies; sqlite3 3.x is measured directly |
| [sqlite_async](https://pub.dev/packages/sqlite_async) | 0.14.1 | SQL | Async SQLite wrapper | Flutter native targets | SQLite transactions | Runnable on native targets; Web SQLite Wasm assets are outside the current measured adapter set |
| [floor](https://pub.dev/packages/floor) | 1.5.0 | SQL | SQLite ORM | Flutter targets supported by sqflite | sqflite transactions through generated code | Coverage is explicit: Floor is represented as a generated sqflite ORM; raw storage performance is measured by sqflite |
| [sqlbrite](https://pub.dev/packages/sqlbrite) | 2.8.0 | SQL | Reactive SQLite wrapper | Flutter targets supported by sqflite | sqflite transactions | Adapter implemented with BriteDatabase over sqflite/sqflite_common_ffi |
| [hive](https://pub.dev/packages/hive) | 2.2.3 | Key-value baseline | Key-value / typed boxes | Android, iOS, macOS, Windows, Linux, Web | BoxCollection transactions on Web-oriented collection APIs | Adapter implemented with raw Map boxes |
| [hive_ce](https://pub.dev/packages/hive_ce) | 2.19.3 | Key-value baseline | Key-value / typed boxes | Android, iOS, macOS, Windows, Linux, Web | No general transaction model | Runnable in this repo |
| [isar](https://pub.dev/packages/isar) | 3.1.0+1 | NoSQL | Object database | Android, iOS, macOS, Windows, Linux | Native Isar read/write transactions | Adapter implemented with manual Isar schema and isar_flutter_libs native runtime |
| [isar_community](https://pub.dev/packages/isar_community) | 3.3.2 | NoSQL | Object database | Android, iOS, macOS, Windows, Linux | Native Isar read/write transactions | Adapter implemented with generated Isar Community schema and native transactions |
| [isar_db](https://pub.dev/packages/isar_db) | 1.0.1+1 | NoSQL | Object database fork | Flutter native targets | Native object-store transactions | Adapter implemented with manual Isar DB schema; vendored 1.0.1+1 package patch fixes its placeholder core version guard for the 1.2.6 native runtime |
| [isar_plus](https://pub.dev/packages/isar_plus) | 1.2.6 | NoSQL | Object database fork | Flutter native targets | Native object-store transactions | Adapter implemented with manual Isar Plus schema and isar_plus_flutter_libs native runtime |
| [objectbox](https://pub.dev/packages/objectbox) | 5.3.1 | NoSQL | Object database | Android, iOS, macOS, Windows, Linux | Native ObjectBox transactions | Adapter implemented with generated ObjectBox model bindings |
| [objectbox_flutter_libs](https://pub.dev/packages/objectbox_flutter_libs) | 5.3.1 | NoSQL | ObjectBox Flutter runtime libraries | Android, iOS, macOS, Windows, Linux | Native ObjectBox transactions through objectbox | Adapter coverage maps runtime-library coverage to objectbox |
| [realm](https://pub.dev/packages/realm) | 20.2.0 | NoSQL | Object database | Flutter native targets | Realm write transactions | Solver coverage: realm_generator is incompatible with analyzer 10/build_runner 2.15 in this checkout |
| [cbl_flutter](https://pub.dev/packages/cbl_flutter) | 3.3.5 | NoSQL | Embedded document database | Flutter native targets | Couchbase Lite batch/write semantics | Coverage is explicit: native runtime initialization is represented by adapter coverage, not a synthetic placeholder |
| [couchbase_lite](https://pub.dev/packages/couchbase_lite) | 2.8.5 | NoSQL | Embedded document database | Flutter native targets | Couchbase Lite write semantics | Coverage is explicit: older Couchbase Lite line is mapped to the maintained cbl_flutter runtime |
| [sembast](https://pub.dev/packages/sembast) | 3.8.7 | NoSQL | Document database | Dart VM and Flutter native targets | Single database transaction API | Runnable on native targets |
| [sembast_web](https://pub.dev/packages/sembast_web) | 2.4.4+1 | NoSQL | Document database | Web | Sembast transaction API | Runnable on Web |
| [sembast_sqflite](https://pub.dev/packages/sembast_sqflite) | 2.2.1+1 | NoSQL | Document database on sqflite | Android, iOS, macOS | Sembast transaction API over sqflite | Adapter implemented for mobile/Apple targets; desktop snapshots measure file-backed sembast |
| [objectdb](https://pub.dev/packages/objectdb) | 1.2.1+1 | NoSQL | Document database | Dart IO and Web storage backends | No general transaction model | Adapter implemented with file-system storage |
| [tiny_db](https://pub.dev/packages/tiny_db) | 0.9.2 | NoSQL | JSON document database | Dart IO and Flutter native targets | No general transaction model | Adapter implemented with JsonStorage |
| [store_box](https://pub.dev/packages/store_box) | 2.0.0 | NoSQL | NoSQL key-value boxes | Dart IO and Flutter native targets | No general transaction model | Adapter implemented with Map boxes |
| [work_db](https://pub.dev/packages/work_db) | 1.3.0 | NoSQL | JSON collection database | Dart IO, Flutter native targets, Web | No general transaction model | Adapter implemented with IO WorkDB |
| [flutterdb](https://pub.dev/packages/flutterdb) | 0.0.4 | NoSQL | Mongo-like document API over sqflite | Flutter targets supported by sqflite | sqflite transactions through underlying database | Adapter implemented with FlutterDB collections over sqflite/sqflite_common_ffi |
| [fdatabase](https://pub.dev/packages/fdatabase) | 0.0.7 | NoSQL | Synchronous local file database | Flutter native targets | No documented transaction model | Adapter implemented through FDatabase key/value storage with JSON-encoded records |
| [flutter_local_db](https://pub.dev/packages/flutter_local_db) | 1.5.1 | NoSQL | Rust/LMDB local database | Android, iOS, macOS, Windows, Linux, Web facade | Backend-managed writes | Excluded: package declares Windows plugin support but does not ship a Windows plugin directory, breaking Flutter desktop generation |
| [ffastdb](https://pub.dev/packages/ffastdb) | 0.2.7 | NoSQL | Pure Dart NoSQL database | Dart IO and Web storage strategies | FastDB transaction API | Adapter implemented with WAL storage |
| [reaxdb_dart](https://pub.dev/packages/reaxdb_dart) | 1.4.1 | NoSQL | NoSQL key-value/document database | Dart IO and Flutter native targets | Advanced transaction API | Adapter implemented with SimpleReaxDB |
| [relax_orm](https://pub.dev/packages/relax_orm) | 0.1.4 | NoSQL | Local-first ORM | Flutter native targets | Drift/SQLite transactions | Adapter implemented with manual RelaxORM TableSchema over Drift/SQLite |
| [local_shared](https://pub.dev/packages/local_shared) | 3.0.0 | NoSQL | Secure JSON collections/preferences | Android, iOS, macOS, Windows, Linux, Web | Batch operations, no database transaction model | Adapter implemented with secure JSON documents as a baseline candidate |
| [quanta_db](https://pub.dev/packages/quanta_db) | 0.0.9 | NoSQL | NoSQL database | Dart / Flutter targets declared by package | Package-defined write semantics | Solver coverage: package depends on build ^2.4.x and conflicts with build_runner 2.15 |
| [torex_local_store](https://pub.dev/packages/torex_local_store) | 0.1.6 | NoSQL | Rust embedded key-value database | Flutter native targets | Backend-managed writes | Adapter implemented with Torex boxes |
| [torexstore](https://pub.dev/packages/torexstore) | 0.0.1 | NoSQL | Early Torex storage package | Flutter native targets | Package-defined write semantics | Coverage is explicit: older Torex line is mapped to torex_local_store |
| [entidb_flutter](https://pub.dev/packages/entidb_flutter) | 2.0.0-alpha.3 | NoSQL | Embedded entity database | Android, iOS, macOS, Windows, Linux | ACID transaction API | Adapter implemented with EntiDB collections |
| [rxdb](https://pub.dev/packages/rxdb) | 15.0.0-beta.31 | NoSQL | Reactive database wrapper | Flutter targets declared by package | Package-defined write semantics | Solver coverage: rxdb pins shared_preferences 2.0.17, conflicting with shared_preferences 2.5.5 |
| [instantdb_flutter](https://pub.dev/packages/instantdb_flutter) | 0.2.6 | NoSQL | Offline-first realtime sync client | Flutter native targets and Web | Package-defined sync/write semantics | Adapter coverage explains that a fair run requires configured Instant backend state, not a local-only synthetic adapter |
| [appwrite_offline](https://pub.dev/packages/appwrite_offline) | 0.0.5 | NoSQL | Appwrite offline data adapter | Flutter targets | Package-defined sync/write semantics | Adapter coverage explains that a fair run requires configured Appwrite backend state |
| [offline_db](https://pub.dev/packages/offline_db) | 0.0.1 | NoSQL | Offline data management wrapper | Flutter targets | Hive CE backend semantics | Adapter implemented with OfflineDB standalone node over HiveOfflineDelegate |
| [cloud_firestore](https://pub.dev/packages/cloud_firestore) | 6.4.0 | NoSQL | Hosted NoSQL database SDK | Android, iOS, macOS, Windows, Web | Firestore transactions and batched writes | Adapter coverage explains that local benchmark numbers would be dominated by Firebase project, network, and cache policy |
| [firebase_database](https://pub.dev/packages/firebase_database) | 12.4.0 | NoSQL | Hosted realtime database SDK | Android, iOS, macOS, Windows, Web | Realtime Database transactions | Adapter coverage explains that local benchmark numbers would be dominated by Firebase project, network, and cache policy |
| [serverpod](https://pub.dev/packages/serverpod) | 3.4.8 | NoSQL | Dart app server framework | Flutter client plus Dart server | Server-side database transactions | Adapter coverage excludes it from embedded adapter runs because it requires a running server/database stack |
| [powersync](https://pub.dev/packages/powersync) | 2.1.0 | SQL | Offline-first SQLite sync database | Android, iOS, macOS, Windows, Linux, Web | SQLite write transactions | Adapter implemented with local-only PowerSync table |
| [localstore](https://pub.dev/packages/localstore) | 1.4.0 | NoSQL | JSON document storage | Flutter targets declared by package | No general transaction model | Runnable in this repo |
| [localstorage](https://pub.dev/packages/localstorage) | 6.0.0 | NoSQL | AsyncStorage-style key-value storage | Android, iOS, macOS, Windows, Linux, Web | No transaction model | Adapter implemented as a key-value localStorage baseline with JSON-encoded records |
| [get_storage](https://pub.dev/packages/get_storage) | 2.1.1 | Key-value baseline | Lightweight key-value storage | Android, iOS, macOS, Windows, Linux, Web | No transaction model | Runnable in this repo |
| [shared_preferences](https://pub.dev/packages/shared_preferences) | 2.5.5 | Key-value baseline | Platform key-value preferences | Android, iOS, macOS, Windows, Linux, Web | No transaction model | Runnable in this repo |

</details>
<!-- DBENCH:PACKAGE_MATRIX:end -->

## Result Source

<!-- DBENCH:DEVICE_SPECS:start -->
| Area | Value |
| --- | --- |
| README results | Benchmark JSON files under results/ are rendered into README.md and docs/results.html after the local one-command run. |
| Local results | Scratch and personal reruns can be saved under gitignored local_results/. |
| Flutter | Current local Flutter SDK. |
| Web JS | Flutter Web release build in Chrome through the JavaScript renderer output. |
| Web Wasm | Flutter Web Wasm release build in Chrome through the same browser scraper. |
| Native | Flutter integration_test benchmark on the selected native device, windows by default on this checkout. |
<!-- DBENCH:DEVICE_SPECS:end -->

## Performance Overview

<!-- DBENCH:RUN_VISUALIZATION:start -->
Open [docs/results.html](docs/results.html) for the visual dashboard with overall ranking, scenario winners, and per-target charts.

Committed result snapshots currently present: `native-windows`, `web-js`, `web-wasm`.

Measured packages in committed snapshots: 30 of 52. The public result set only includes completed scenario measurements.

### Measurement Snapshot

| Environment | Measured adapters | Scenario rows | Failed rows |
| --- | --- | ---: | ---: |
| native-windows | `drift`, `fdatabase`, `ffastdb`, `flutterdb`, `get_storage`, `hive`, `hive_ce`, `isar`, `isar_community`, `isar_db`, `isar_plus`, `local_shared`, `localstorage`, `localstore`, `objectbox`, `objectdb`, `offline_db`, `powersync`, `reaxdb_dart`, `relax_orm`, `sembast`, `shared_preferences`, `sqflite_common_ffi`, `sqlbrite`, `sqlite3`, `sqlite_async`, `store_box`, `tiny_db`, `work_db` | 150 | 0 |
| web-js | `get_storage`, `hive_ce`, `localstore`, `sembast_web`, `shared_preferences` | 30 | 0 |
| web-wasm | `hive_ce`, `sembast_web`, `shared_preferences` | 20 | 0 |

### Overall Ranking

| Rank | Adapter | Family | Score | Avg ops/sec | Measurements |
| ---: | --- | --- | ---: | ---: | ---: |
| 1 | `get_storage` | Key-value baseline | 88.7 | 89,519 | 10 |
| 2 | `shared_preferences` | Key-value baseline | 66.4 | 67,358 | 15 |
| 3 | `localstore` | NoSQL | 29.2 | 31,362 | 10 |
| 4 | `hive_ce` | Key-value baseline | 11.5 | 10,866 | 15 |
| 5 | `hive` | Key-value baseline | 11.4 | 10,312 | 5 |
| 6 | `objectbox` | NoSQL | 9.2 | 8,215 | 5 |
| 7 | `offline_db` | NoSQL | 5.2 | 4,529 | 5 |
| 8 | `isar_plus` | NoSQL | 4.5 | 3,977 | 5 |
| 9 | `isar_db` | NoSQL | 4.4 | 3,841 | 5 |
| 10 | `sembast_web` | NoSQL | 4.4 | 3,958 | 10 |
| 11 | `sqlite3` | SQL | 3.5 | 3,196 | 5 |
| 12 | `sqlite_async` | SQL | 3.2 | 2,779 | 5 |

### Scenario Winners

| Environment | Scenario | Fastest SQL/document adapter | Fastest persistent adapter | Completed | Failed |
| --- | --- | --- | --- | ---: | ---: |
| native-windows | batched_transaction | `sqlite3` 10,210 ops/sec | `get_storage` 92,478 ops/sec | 30 | 0 |
| native-windows | crud_balanced | `objectbox` 5,659 ops/sec | `get_storage` 53,060 ops/sec | 30 | 0 |
| native-windows | large_payload | `objectbox` 7,892 ops/sec | `get_storage` 102,471 ops/sec | 30 | 0 |
| native-windows | read_heavy | `objectbox` 10,867 ops/sec | `get_storage` 121,242 ops/sec | 30 | 0 |
| native-windows | write_churn_stress | `objectbox` 9,170 ops/sec | `get_storage` 87,925 ops/sec | 30 | 0 |
| web-js | batched_transaction | `localstore` 77,586 ops/sec | `shared_preferences` 152,542 ops/sec | 6 | 0 |
| web-js | crud_balanced | `localstore` 49,724 ops/sec | `get_storage` 57,692 ops/sec | 6 | 0 |
| web-js | large_payload | `localstore` 39,841 ops/sec | `shared_preferences` 91,743 ops/sec | 6 | 0 |
| web-js | read_heavy | `localstore` 82,126 ops/sec | `get_storage` 139,344 ops/sec | 6 | 0 |
| web-js | write_churn_stress | `localstore` 58,680 ops/sec | `shared_preferences` 127,660 ops/sec | 6 | 0 |
| web-wasm | batched_transaction | `sembast_web` 3,496 ops/sec | `shared_preferences` 132,353 ops/sec | 4 | 0 |
| web-wasm | crud_balanced | `sembast_web` 2,917 ops/sec | `shared_preferences` 46,201 ops/sec | 4 | 0 |
| web-wasm | large_payload | `sembast_web` 2,986 ops/sec | `shared_preferences` 42,955 ops/sec | 4 | 0 |
| web-wasm | read_heavy | `sembast_web` 5,257 ops/sec | `shared_preferences` 113,333 ops/sec | 4 | 0 |
| web-wasm | write_churn_stress | `sembast_web` 3,088 ops/sec | `shared_preferences` 109,091 ops/sec | 4 | 0 |
<!-- DBENCH:RUN_VISUALIZATION:end -->

## Results

<!-- DBENCH:BENCHMARK_RESULTS:start -->
The readable dashboard is [docs/results.html](docs/results.html). Raw machine-readable snapshots stay in `results/*.json` instead of being duplicated into README tables.

Measured packages across committed snapshots: 30 of 52.

| Environment | JSON source | Generated | Scenario rows | Measured packages |
| --- | --- | --- | ---: | ---: |
| native-windows | [`results/native-windows.json`](results/native-windows.json) | `2026-05-12T04:38:35.108364Z` | 150 | 29 |
| web-js | [`results/web-js.json`](results/web-js.json) | `2026-05-12T00:24:29.910Z` | 30 | 5 |
| web-wasm | [`results/web-wasm.json`](results/web-wasm.json) | `2026-05-12T00:26:31.350Z` | 20 | 3 |
<!-- DBENCH:BENCHMARK_RESULTS:end -->

## Isolate Behavior

This section checks whether a database can be reopened from a separate Dart isolate after the main isolate writes and closes the store. It does not yet prove concurrent multi-isolate write safety or package-specific worker APIs. It is intentionally separate from throughput because isolate behavior is a capability and architecture signal, not just a speed metric.

<!-- DBENCH:ISOLATE_RESULTS:start -->
<details>
<summary>Isolate sharing probe rows</summary>

| Environment | Database | Status | Shared read across isolates | Notes |
| --- | --- | --- | --- | --- |
| native-windows | memory_baseline | completed | no | Dart isolates have separate heaps; in-memory maps are not shared. |
| native-windows | hive_ce | completed | yes | Separate isolate reopened the same box path and read the main isolate record. |
| native-windows | sembast | completed | yes | Separate isolate reopened the same database file and read the main isolate record. |
| native-windows | sqflite_common_ffi | completed | yes | Separate isolate reopened the same SQLite file through sqflite_common_ffi and read the main isolate record. |

</details>
<!-- DBENCH:ISOLATE_RESULTS:end -->

## Running Locally

```bash
powershell -ExecutionPolicy Bypass -File tool/run_all_benchmarks.ps1 -Records 1000 -NativeDevice windows
```

The launcher runs unit tests, analysis, Web JS performance, Web Wasm performance, native performance, report regeneration, and result validation. Each benchmark run prints a `DBENCH_RESULT_JSON=` line; scratch runs can be copied into `local_results/`.

## Adding A Database Adapter

1. Add the package to `data/package_matrix.json`.
2. Implement `DatabaseAdapter` in `lib/src/adapters/`.
3. Register it in `availableAdapters()`.
4. Keep native or code-generated packages isolated so only completed measurements enter public result snapshots.
5. Run the unit test, analyze, and every target that the package claims to support.
