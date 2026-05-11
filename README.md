# Dbench

Dbench is a Dart and Flutter local database benchmark suite. It tracks popular Flutter database packages, documents their tradeoffs, and runs the same write/read/update/delete workload on Android, Web, and Windows targets where an adapter is available.

The repository is intentionally benchmark-first: package claims are not treated as results until the benchmark harness can run them and commit JSON output.

The current executable adapter set is a first measured slice, not a finished ranking of every major database package. Packages marked `Tracked; adapter pending` are included so gaps are visible instead of silently ignored.

## Current Scope

- Flutter stable: 3.41.9 locally, `stable` channel in CI.
- Runtime targets: Android physical device, Flutter Web in Chrome, and Flutter Windows.
- Workload: deterministic record insert, point read, update, and delete loops, followed by update/delete verification reads.
- Result source of truth: JSON files under `results/`, rendered into this README by `dart run tool/update_readme.dart`.
- CI refreshes hosted Web and Windows results automatically. Android physical-device results are committed from local ADB runs because GitHub-hosted runners do not provide this device.
- `memory_baseline`, `shared_preferences`, `get_storage`, and `hive_ce` are baselines, not durable relational or rich-query document/object databases; compare them against database engines with that limitation in mind.

Ops/sec is `write + read + update + delete` operation count divided by the full timed window for that adapter, including `open()`, `clear()`, and verification reads. This intentionally reflects benchmark-harness cost, not a vendor microbenchmark of only raw CRUD calls.

## Package Matrix

<!-- DBENCH:PACKAGE_MATRIX:start -->
| Package | Latest | Family | Type | Platforms | Transactions | Benchmark status |
| --- | ---: | --- | --- | --- | --- | --- |
| [isar_community](https://pub.dev/packages/isar_community) | 3.3.2 | NoSQL | NoSQL object database | Android, iOS, macOS, Windows, Linux | Read/write transactions | Tracked; adapter pending generated model wiring |
| [isar_db](https://pub.dev/packages/isar_db) | 1.0.1+1 | NoSQL | NoSQL object database | Flutter targets declared by package | Read/write transactions | Tracked; compatibility adapter pending |
| [isar](https://pub.dev/packages/isar) | 3.1.0+1 | NoSQL | NoSQL object database | Android, iOS, macOS, Windows, Linux, Web | Read/write transactions | Tracked for historical comparison |
| [objectbox](https://pub.dev/packages/objectbox) | 5.3.1 | NoSQL | NoSQL object database | Android, iOS, macOS, Windows, Linux | ACID transactions | Tracked; adapter pending generated model wiring |
| [realm](https://pub.dev/packages/realm) | 20.2.0 | NoSQL | Object database | Android, iOS, macOS, Windows, Linux | Write transactions | Tracked; adapter pending generated model wiring |
| [drift](https://pub.dev/packages/drift) | 2.33.0 | SQL | SQLite ORM/query builder | Android, iOS, macOS, Windows, Linux, Web | SQLite transactions | Tracked; adapter pending |
| [floor](https://pub.dev/packages/floor) | 1.5.0 | SQL | SQLite persistence abstraction | Android, iOS, macOS | SQLite transactions | Tracked; adapter pending |
| [sqflite](https://pub.dev/packages/sqflite) | 2.4.2+1 | SQL | SQLite plugin | Android, iOS, macOS | SQLite transactions | Runnable on Android in this repo |
| [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi) | 2.4.0+3 | SQL | SQLite FFI implementation | Windows, Linux, macOS, tests | SQLite transactions | Runnable on Windows in this repo |
| [sqlite3](https://pub.dev/packages/sqlite3) | 3.3.1 | SQL | SQLite FFI bindings | Dart VM and Flutter native targets | Manual SQLite transactions | Tracked; direct adapter pending |
| [sqlite_async](https://pub.dev/packages/sqlite_async) | 0.14.1 | SQL | Async SQLite wrapper | Flutter native targets | SQLite transactions | Tracked; adapter pending |
| [hive_ce](https://pub.dev/packages/hive_ce) | 2.19.3 | Key-value baseline | Key-value / typed boxes | Android, iOS, macOS, Windows, Linux, Web | No general transaction model | Runnable in this repo |
| [hive](https://pub.dev/packages/hive) | 2.2.3 | Key-value baseline | Key-value / typed boxes | Android, iOS, macOS, Windows, Linux, Web | No general transaction model | Tracked for historical comparison |
| [sembast](https://pub.dev/packages/sembast) | 3.8.7 | NoSQL | Document database | Dart VM and Flutter native targets | Single database transaction API | Runnable in this repo |
| [sembast_web](https://pub.dev/packages/sembast_web) | 2.4.4+1 | NoSQL | Document database | Web | Sembast transaction API | Runnable on Web in this repo |
| [sembast_sqflite](https://pub.dev/packages/sembast_sqflite) | 2.2.1+1 | SQL | Document database over SQLite | sqflite-supported Flutter targets | Sembast transaction API | Tracked; adapter pending |
| [get_storage](https://pub.dev/packages/get_storage) | 2.1.1 | Key-value baseline | Lightweight key-value storage | Android, iOS, macOS, Windows, Linux, Web | No transaction model | Runnable in this repo |
| [localstore](https://pub.dev/packages/localstore) | 1.4.0 | NoSQL | JSON document storage | Flutter targets declared by package | No general transaction model | Tracked; adapter pending |
| [shared_preferences](https://pub.dev/packages/shared_preferences) | 2.5.5 | Key-value baseline | Platform key-value preferences | Android, iOS, macOS, Windows, Linux, Web | No transaction model | Runnable in this repo |
<!-- DBENCH:PACKAGE_MATRIX:end -->

## Test Device And Toolchain

The Android device name is recorded as hardware metadata only. It is not used as a result column.

<!-- DBENCH:DEVICE_SPECS:start -->
| Area | Value |
| --- | --- |
| Android test device | K15 (rockchip, rk3568_r) |
| Android hardware | Rockchip RK3568 EVB1 DDR4 V10 Board |
| Android OS | Android 11 / API 30 |
| Android CPU | 4 x ARM Cortex-A55 class cores (CPU part 0xd05) |
| Android memory | 3984488 kB total, 1992240 kB swap |
| Android display | 1366x768 at 160 dpi |
| Flutter | 3.41.9 stable |
| Dart | 3.11.5 |
| Windows | Microsoft Windows 10.0.26200.8328 |
| Chrome | 148.0.7778.96 |
| Edge | 147.0.3912.98 |
<!-- DBENCH:DEVICE_SPECS:end -->

## Results

<!-- DBENCH:BENCHMARK_RESULTS:start -->
| Environment | Family | Database | Status | Records | Payload | Total ops | Ops/sec | Notes |
| --- | --- | --- | --- | ---: | ---: | ---: | ---: | --- |
| android | Key-value baseline | memory_baseline | completed | 1000 | 256 | 4000 | 6162 |  |
| android | Key-value baseline | shared_preferences | completed | 1000 | 256 | 4000 | 41 |  |
| android | Key-value baseline | get_storage | completed | 1000 | 256 | 4000 | 2262 |  |
| android | Key-value baseline | hive_ce | completed | 1000 | 256 | 4000 | 288 |  |
| android | NoSQL | sembast | completed | 1000 | 256 | 4000 | 84 |  |
| android | SQL | sqflite | completed | 1000 | 256 | 4000 | 158 |  |
| web | Key-value baseline | memory_baseline | completed | 1000 | 256 | 4000 | 259740 |  |
| web | Key-value baseline | shared_preferences | completed | 1000 | 256 | 4000 | 33755 |  |
| web | Key-value baseline | get_storage | completed | 1000 | 256 | 4000 | 613 |  |
| web | Key-value baseline | hive_ce | completed | 1000 | 256 | 4000 | 1803 |  |
| web | NoSQL | sembast | completed | 1000 | 256 | 4000 | 814 |  |
| web | SQL | sqflite_sqlite | skipped | 1000 | 256 | 0 | 0 | SQLite adapter is not available on this target. |
| windows | Key-value baseline | memory_baseline | completed | 1000 | 256 | 4000 | 67789 |  |
| windows | Key-value baseline | shared_preferences | completed | 1000 | 256 | 4000 | 279 |  |
| windows | Key-value baseline | get_storage | completed | 1000 | 256 | 4000 | 36518 |  |
| windows | Key-value baseline | hive_ce | completed | 1000 | 256 | 4000 | 870 |  |
| windows | NoSQL | sembast | completed | 1000 | 256 | 4000 | 191 |  |
| windows | SQL | sqflite_common_ffi | completed | 1000 | 256 | 4000 | 23 |  |
<!-- DBENCH:BENCHMARK_RESULTS:end -->

## Isolate Behavior

This section checks whether a database can be reopened from a separate Dart isolate after the main isolate writes and closes the store. It does not yet prove concurrent multi-isolate write safety or package-specific worker APIs. It is intentionally separate from throughput because isolate behavior is a capability and architecture signal, not just a speed metric.

<!-- DBENCH:ISOLATE_RESULTS:start -->
| Environment | Database | Status | Shared read across isolates | Notes |
| --- | --- | --- | --- | --- |
| android | memory_baseline | completed | no | Dart isolates have separate heaps; in-memory maps are not shared. |
| android | hive_ce | completed | yes | Separate isolate reopened the same box path and read the main isolate record. |
| android | sembast | completed | yes | Separate isolate reopened the same database file and read the main isolate record. |
| android | shared_preferences | skipped | not tested | Plugin-backed storage is not probed from a background isolate. |
| android | get_storage | skipped | not tested | Flutter/widget-bound package; isolate sharing needs a dedicated adapter. |
| android | sqflite | skipped | not tested | Not yet probed; sqflite method-channel access needs a background-isolate-specific adapter. |
| web | all | skipped | not tested | Flutter Web does not expose Dart VM isolates for this benchmark. |
| windows | memory_baseline | completed | no | Dart isolates have separate heaps; in-memory maps are not shared. |
| windows | hive_ce | completed | yes | Separate isolate reopened the same box path and read the main isolate record. |
| windows | sembast | completed | yes | Separate isolate reopened the same database file and read the main isolate record. |
| windows | sqflite_common_ffi | completed | yes | Separate isolate reopened the same SQLite file through sqflite_common_ffi and read the main isolate record. |
| windows | shared_preferences | skipped | not tested | Plugin-backed storage is not probed from a background isolate. |
| windows | get_storage | skipped | not tested | Flutter/widget-bound package; isolate sharing needs a dedicated adapter. |
<!-- DBENCH:ISOLATE_RESULTS:end -->

## Running Locally

```bash
flutter pub get
flutter test
flutter analyze
flutter test integration_test/benchmark_test.dart -d windows --dart-define=DBENCH_RECORDS=1000
flutter build web --release --dart-define=DBENCH_AUTORUN=true --dart-define=DBENCH_RECORDS=1000
node tool/run_web_benchmark.cjs http://127.0.0.1:18080 results/web.json
flutter test integration_test/benchmark_test.dart -d <android-device-id> --dart-define=DBENCH_RECORDS=1000
dart run tool/update_readme.dart
```

Each benchmark run prints a `DBENCH_RESULT_JSON=` line. Save that JSON into `results/<environment>.json`, then run the README updater.

## Adding A Database Adapter

1. Add the package to `data/package_matrix.json`.
2. Implement `DatabaseAdapter` in `lib/src/adapters/`.
3. Register it in `availableAdapters()`.
4. Keep native or code-generated packages isolated so unsupported targets report `skipped` instead of breaking the whole suite.
5. Run the unit test, analyze, and every target that the package claims to support.
