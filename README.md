# Flutter Database Benchmarks

Flutter Database Benchmarks is a Dart and Flutter local database benchmark suite. It measures popular local persistence packages through real adapters, runs the same realistic scenarios on supported targets, and renders JSON snapshots into charts.

Open [docs/results.html](docs/results.html) to see the benchmark results visually. The README stays as a compact index: what is measured now, how the targets are produced, and where the raw data lives.

## Current Scope

- Flutter stable channel.
- Runtime targets: Flutter Web JS in Chrome, Flutter Web Wasm in Chrome, and one selected native Flutter target.
- Workload: deterministic balanced CRUD, read-heavy, large-payload, write-churn stress, and batched-transaction scenarios with point reads, group queries, updates, deletes, and verification reads.
- Source of truth: JSON files under `results/`, regenerated into this README and `docs/results.html` by `dart run tool/update_readme.dart`.
- The package matrix only lists packages with checked coverage: real adapters where the package can be measured in this repo, or explicit package-level reasons when a direct adapter is blocked by generator, solver, platform, or packaging constraints. Unchecked package ideas do not appear as benchmark coverage.
- `memory_baseline` is the only synthetic baseline. Settings stores such as `shared_preferences`, `get_storage`, and AsyncStorage-style packages are intentionally excluded because they are not databases.
- Local machine and physical-device measurements belong under gitignored `local_results/`.

Ops/sec is every counted operation divided by the median successful sample window. Counted operations include writes, point reads, group-query calls, updates, deletes, and verification/source reads. `open()`, `clear()`, and successful `close()`/flush work stay inside the timed window but are not added to the operation count.

## Package Matrix

<!-- DBENCH:PACKAGE_MATRIX:start -->
<details>
<summary>Curated package matrix (34 primary, 3 companion)</summary>

| Package | Scope | Latest | Family | Type | Platforms | Transactions | Benchmark status |
| --- | --- | ---: | --- | --- | --- | --- | --- |
| [drift](https://pub.dev/packages/drift) | primary | 2.33.0 | SQL | SQLite ORM/query builder | Android, iOS, macOS, Windows, Linux, Web | SQLite transactions | Runnable on native targets; Web SQLite Wasm assets are outside the current measured adapter set |
| [sqflite](https://pub.dev/packages/sqflite) | primary | 2.4.2+1 | SQL | SQLite plugin | Android, iOS, macOS | SQLite transactions | Runnable on Android and Apple targets; desktop runs use sqflite_common_ffi |
| [sqflite_sqlcipher](https://pub.dev/packages/sqflite_sqlcipher) | primary | 3.4.0 | SQL | Encrypted SQLite plugin | Android, iOS, macOS | SQLite transactions | Adapter implemented for mobile/Apple targets; desktop snapshots measure sqflite_common_ffi |
| [sqlite3](https://pub.dev/packages/sqlite3) | primary | 3.3.1 | SQL | SQLite FFI bindings | Dart VM and Flutter native targets | Manual SQLite transactions | Runnable on native Flutter targets |
| [sqlite_async](https://pub.dev/packages/sqlite_async) | primary | 0.14.1 | SQL | Async SQLite wrapper | Flutter native targets | SQLite transactions | Runnable on native targets; Web SQLite Wasm assets are outside the current measured adapter set |
| [floor](https://pub.dev/packages/floor) | primary | 1.5.0 | SQL | SQLite ORM | Flutter targets supported by sqflite | sqflite transactions through generated code | Coverage is explicit: Floor is represented as a generated sqflite ORM; raw storage performance is measured by sqflite |
| [sqlbrite](https://pub.dev/packages/sqlbrite) | primary | 2.8.0 | SQL | Reactive SQLite wrapper | Flutter targets supported by sqflite | sqflite transactions | Adapter implemented with BriteDatabase over sqflite/sqflite_common_ffi |
| [hive](https://pub.dev/packages/hive) | primary | 2.2.3 | Key-value | Key-value / typed boxes | Android, iOS, macOS, Windows, Linux, Web | BoxCollection transactions on Web-oriented collection APIs | Adapter implemented with raw Map boxes |
| [hive_ce](https://pub.dev/packages/hive_ce) | primary | 2.19.3 | Key-value | Key-value / typed boxes | Android, iOS, macOS, Windows, Linux, Web | No general transaction model | Runnable in this repo |
| [isar](https://pub.dev/packages/isar) | primary | 3.1.0+1 | NoSQL | Object database | Android, iOS, macOS, Windows, Linux | Native Isar read/write transactions | Adapter implemented with manual Isar schema and isar_flutter_libs native runtime |
| [isar_community](https://pub.dev/packages/isar_community) | primary | 3.3.2 | NoSQL | Object database | Android, iOS, macOS, Windows, Linux | Native Isar read/write transactions | Adapter implemented with generated Isar Community schema and native transactions |
| [isar_db](https://pub.dev/packages/isar_db) | primary | 1.0.1+1 | NoSQL | Object database fork | Flutter native targets | Native object-store transactions | Adapter implemented with manual Isar DB schema; vendored 1.0.1+1 package patch fixes its placeholder core version guard for the 1.2.6 native runtime |
| [isar_plus](https://pub.dev/packages/isar_plus) | primary | 1.2.6 | NoSQL | Object database fork | Flutter native targets | Native object-store transactions | Adapter implemented with manual Isar Plus schema and isar_plus_flutter_libs native runtime |
| [objectbox](https://pub.dev/packages/objectbox) | primary | 5.3.1 | NoSQL | Object database | Android, iOS, macOS, Windows, Linux | Native ObjectBox transactions | Adapter implemented with generated ObjectBox model bindings |
| [realm](https://pub.dev/packages/realm) | primary | 20.2.0 | NoSQL | Object database | Flutter native targets | Realm write transactions | Solver coverage: realm_generator is incompatible with analyzer 10/build_runner 2.15 in this checkout |
| [cbl_flutter](https://pub.dev/packages/cbl_flutter) | primary | 3.3.5 | NoSQL | Embedded document database | Flutter native targets | Couchbase Lite batch/write semantics | Coverage is explicit: native runtime initialization is represented by adapter coverage, not a synthetic placeholder |
| [sembast](https://pub.dev/packages/sembast) | primary | 3.8.7 | NoSQL | Document database | Dart VM and Flutter native targets | Single database transaction API | Runnable on native targets |
| [objectdb](https://pub.dev/packages/objectdb) | primary | 1.2.1+1 | NoSQL | Document database | Dart IO and Web storage backends | No general transaction model | Adapter implemented with file-system storage |
| [tiny_db](https://pub.dev/packages/tiny_db) | primary | 0.9.2 | NoSQL | JSON document database | Dart IO and Flutter native targets | No general transaction model | Adapter implemented with JsonStorage |
| [store_box](https://pub.dev/packages/store_box) | primary | 2.0.0 | Key-value | NoSQL key-value boxes | Dart IO and Flutter native targets | No general transaction model | Adapter implemented with Map boxes |
| [work_db](https://pub.dev/packages/work_db) | primary | 1.3.0 | NoSQL | JSON collection database | Dart IO, Flutter native targets, Web | No general transaction model | Adapter implemented with IO WorkDB |
| [flutterdb](https://pub.dev/packages/flutterdb) | primary | 0.0.4 | NoSQL | Mongo-like document API over sqflite | Flutter targets supported by sqflite | sqflite transactions through underlying database | Adapter implemented with FlutterDB collections over sqflite/sqflite_common_ffi |
| [fdatabase](https://pub.dev/packages/fdatabase) | primary | 0.0.7 | NoSQL | Synchronous local file database | Flutter native targets | No documented transaction model | Adapter implemented through FDatabase key/value storage with JSON-encoded records |
| [flutter_local_db](https://pub.dev/packages/flutter_local_db) | primary | 1.5.1 | NoSQL | Rust/LMDB local database | Android, iOS, macOS, Windows, Linux, Web facade | Backend-managed writes | Excluded: package declares Windows plugin support but does not ship a Windows plugin directory, breaking Flutter desktop generation |
| [ffastdb](https://pub.dev/packages/ffastdb) | primary | 0.2.7 | NoSQL | Pure Dart NoSQL database | Dart IO and Web storage strategies | FastDB transaction API | Adapter implemented with WAL storage |
| [reaxdb_dart](https://pub.dev/packages/reaxdb_dart) | primary | 1.4.1 | NoSQL | NoSQL key-value/document database | Dart IO and Flutter native targets | Advanced transaction API | Adapter implemented with SimpleReaxDB |
| [relax_orm](https://pub.dev/packages/relax_orm) | primary | 0.1.4 | NoSQL | Local-first ORM | Flutter native targets | Drift/SQLite transactions | Adapter implemented with manual RelaxORM TableSchema over Drift/SQLite |
| [quanta_db](https://pub.dev/packages/quanta_db) | primary | 0.0.9 | NoSQL | NoSQL database | Dart / Flutter targets declared by package | Package-defined write semantics | Solver coverage: package depends on build ^2.4.x and conflicts with build_runner 2.15 |
| [torex_local_store](https://pub.dev/packages/torex_local_store) | primary | 0.1.6 | NoSQL | Rust embedded key-value database | Flutter native targets | Backend-managed writes | Adapter implemented with Torex boxes |
| [entidb_flutter](https://pub.dev/packages/entidb_flutter) | primary | 2.0.0-alpha.3 | NoSQL | Embedded entity database | Android, iOS, macOS, Windows, Linux | ACID transaction API | Adapter implemented with EntiDB collections |
| [rxdb](https://pub.dev/packages/rxdb) | primary | 15.0.0-beta.31 | NoSQL | Reactive database wrapper | Flutter targets declared by package | Package-defined write semantics | Solver coverage: package dependency pins conflict with the benchmark app dependency set |
| [offline_db](https://pub.dev/packages/offline_db) | primary | 0.0.1 | NoSQL | Offline data management wrapper | Flutter targets | Hive CE backend semantics | Adapter implemented with OfflineDB standalone node over HiveOfflineDelegate |
| [powersync](https://pub.dev/packages/powersync) | primary | 2.1.0 | SQL | Offline-first SQLite sync database | Android, iOS, macOS, Windows, Linux, Web | SQLite write transactions | Adapter implemented with local-only PowerSync table |
| [localstore](https://pub.dev/packages/localstore) | primary | 1.4.0 | NoSQL | JSON document storage | Flutter targets declared by package | No general transaction model | Runnable in this repo |
| [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi) | companion | 2.4.0+3 | SQL | SQLite FFI implementation | Windows, Linux, macOS, tests | SQLite transactions | Runnable on Windows and Linux native targets |
| [objectbox_flutter_libs](https://pub.dev/packages/objectbox_flutter_libs) | companion | 5.3.1 | NoSQL | ObjectBox Flutter runtime libraries | Android, iOS, macOS, Windows, Linux | Native ObjectBox transactions through objectbox | Adapter coverage maps runtime-library coverage to objectbox |
| [sembast_web](https://pub.dev/packages/sembast_web) | companion | 2.4.4+1 | NoSQL | Document database | Web | Sembast transaction API | Runnable on Web |

</details>
<!-- DBENCH:PACKAGE_MATRIX:end -->

## Result Source

<!-- DBENCH:DEVICE_SPECS:start -->
| Area | Value |
| --- | --- |
| README results | Curated primary and mandatory companion package rows are rendered from data/package_matrix.json; benchmark JSON under results/ is published only when it declares a release measurement mode. |
| Local results | Scratch and personal reruns can be saved under gitignored local_results/. |
| Flutter | Current local Flutter SDK. |
| Web JS | Flutter Web release build in Chrome through the JavaScript renderer output. |
| Web Wasm | Flutter Web Wasm release build in Chrome through the same browser scraper. |
| Native | Windows release AOT Flutter desktop executable, launched by the benchmark script and scraped from DBENCH_RESULT_JSON stdout. |
<!-- DBENCH:DEVICE_SPECS:end -->

## Performance Overview

<!-- DBENCH:RUN_VISUALIZATION:start -->
Open [docs/results.html](docs/results.html) for the visual dashboard with overall ranking, scenario winners, and per-target charts.

Committed result snapshots currently present: `native-windows`, `web-js`, `web-wasm`.

Measured curated packages in committed snapshots: 26 of 37. Primary package targets in scope: 34. The public result set only includes completed scenario measurements.

### Measurement Snapshot

| Environment | Measured adapters | Scenario rows | Failed rows |
| --- | --- | ---: | ---: |
| native-windows | `drift`, `fdatabase`, `ffastdb`, `flutterdb`, `hive`, `hive_ce`, `isar`, `isar_community`, `isar_db`, `isar_plus`, `localstore`, `objectbox`, `objectdb`, `offline_db`, `powersync`, `reaxdb_dart`, `relax_orm`, `sembast`, `sqflite_common_ffi`, `sqlbrite`, `sqlite3`, `sqlite_async`, `store_box`, `tiny_db`, `work_db` | 130 | 0 |
| web-js | `hive_ce`, `localstore`, `sembast_web` | 20 | 0 |
| web-wasm | `hive_ce`, `sembast_web` | 15 | 0 |

### Overall Ranking

| Rank | Adapter | Family | Score | Avg ops/sec | Measurements |
| ---: | --- | --- | ---: | ---: | ---: |
| 1 | `hive` | Key-value | 96.8 | 17,953 | 5 |
| 2 | `localstore` | NoSQL | 57.8 | 30,152 | 10 |
| 3 | `hive_ce` | Key-value | 55.7 | 12,449 | 15 |
| 4 | `offline_db` | NoSQL | 49.2 | 7,160 | 5 |
| 5 | `objectbox` | NoSQL | 42.8 | 5,867 | 5 |
| 6 | `flutterdb` | NoSQL | 32.1 | 4,391 | 5 |
| 7 | `isar_db` | NoSQL | 27.4 | 3,907 | 5 |
| 8 | `isar_plus` | NoSQL | 27.1 | 3,994 | 5 |
| 9 | `sqlite_async` | SQL | 25.4 | 3,433 | 5 |
| 10 | `powersync` | SQL | 23.4 | 3,293 | 5 |
| 11 | `isar_community` | NoSQL | 21.2 | 3,046 | 5 |
| 12 | `isar` | NoSQL | 20.6 | 2,894 | 5 |

### Scenario Winners

| Environment | Scenario | Fastest SQL/document adapter | Fastest persistent adapter | Completed | Failed |
| --- | --- | --- | --- | ---: | ---: |
| native-windows | batched_transaction | `offline_db` 6,053 ops/sec | `hive` 21,206 ops/sec | 26 | 0 |
| native-windows | crud_balanced | `offline_db` 5,984 ops/sec | `hive` 16,810 ops/sec | 26 | 0 |
| native-windows | large_payload | `offline_db` 5,839 ops/sec | `offline_db` 5,839 ops/sec | 26 | 0 |
| native-windows | read_heavy | `offline_db` 10,208 ops/sec | `hive` 31,124 ops/sec | 26 | 0 |
| native-windows | write_churn_stress | `offline_db` 7,715 ops/sec | `hive` 15,734 ops/sec | 26 | 0 |
| web-js | batched_transaction | `localstore` 82,721 ops/sec | `localstore` 82,721 ops/sec | 4 | 0 |
| web-js | crud_balanced | `localstore` 37,037 ops/sec | `localstore` 37,037 ops/sec | 4 | 0 |
| web-js | large_payload | `localstore` 39,651 ops/sec | `localstore` 39,651 ops/sec | 4 | 0 |
| web-js | read_heavy | `localstore` 80,645 ops/sec | `localstore` 80,645 ops/sec | 4 | 0 |
| web-js | write_churn_stress | `localstore` 51,392 ops/sec | `localstore` 51,392 ops/sec | 4 | 0 |
| web-wasm | batched_transaction | `sembast_web` 4,217 ops/sec | `hive_ce` 17,045 ops/sec | 3 | 0 |
| web-wasm | crud_balanced | `sembast_web` 3,190 ops/sec | `hive_ce` 13,294 ops/sec | 3 | 0 |
| web-wasm | large_payload | `sembast_web` 3,499 ops/sec | `hive_ce` 13,423 ops/sec | 3 | 0 |
| web-wasm | read_heavy | `sembast_web` 5,202 ops/sec | `hive_ce` 27,508 ops/sec | 3 | 0 |
| web-wasm | write_churn_stress | `sembast_web` 3,670 ops/sec | `hive_ce` 11,707 ops/sec | 3 | 0 |
<!-- DBENCH:RUN_VISUALIZATION:end -->

## Results

<!-- DBENCH:BENCHMARK_RESULTS:start -->
The readable dashboard is [docs/results.html](docs/results.html). Raw machine-readable snapshots stay in `results/*.json` instead of being duplicated into README tables.

Measured curated packages across committed snapshots: 26 of 37.
Primary package targets in scope: 34.

| Environment | Mode | JSON source | Generated | Scenario rows | Measured packages |
| --- | --- | --- | --- | ---: | ---: |
| native-windows | `release-aot` | [`results/native-windows.json`](results/native-windows.json) | `2026-05-12T14:53:43.683350Z` | 130 | 25 |
| web-js | `release-web-js` | [`results/web-js.json`](results/web-js.json) | `2026-05-12T14:50:52.273Z` | 20 | 3 |
| web-wasm | `release-web-wasm` | [`results/web-wasm.json`](results/web-wasm.json) | `2026-05-12T14:52:43.116Z` | 15 | 2 |
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
