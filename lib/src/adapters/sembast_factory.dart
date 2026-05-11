import 'package:sembast/sembast.dart';

export 'sembast_factory_stub.dart'
    if (dart.library.io) 'sembast_factory_io.dart'
    if (dart.library.js_interop) 'sembast_factory_web.dart';

abstract final class SembastFactoryTypes {
  static DatabaseFactory? keepAnalyzerHappy;
}
