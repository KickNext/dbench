import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String?> benchmarkStoragePath() async {
  final directory = await getApplicationSupportDirectory();
  return p.join(directory.path, 'dbench');
}
