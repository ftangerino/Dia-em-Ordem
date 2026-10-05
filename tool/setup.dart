// Run from the project root: dart tool/setup.dart
// Generates platform folders with the Flutter SDK installed on your machine.
import 'dart:io';

Future<void> main() async {
  if (!File('pubspec.yaml').existsSync() || !File('lib/main.dart').existsSync()) {
    stderr.writeln('Execute na pasta dia_em_ordem.'); exit(1);
  }
  final flutter = Platform.isWindows ? 'flutter.bat' : 'flutter';
  final args = ['create', '--no-pub', '--platforms=android,ios,web', '--project-name', 'dia_em_ordem', '--org', 'br.com.diaemordem', '.'];
  // Preserve app files even if Flutter's generation behavior changes.
  final preserved = <String, List<int>>{};
  for (final path in ['pubspec.yaml', 'analysis_options.yaml', 'README.md', '.gitignore']) {
    final file = File(path); if (file.existsSync()) preserved[path] = file.readAsBytesSync();
  }
  for (final dir in ['lib', 'test']) {
    for (final entity in Directory(dir).listSync(recursive: true).whereType<File>()) {
      preserved[entity.path] = entity.readAsBytesSync();
    }
  }
  int code;
  try {
    final process = await Process.start(flutter, args, runInShell: Platform.isWindows, mode: ProcessStartMode.inheritStdio);
    code = await process.exitCode;
  } finally {
    for (final entry in preserved.entries) { File(entry.key)..createSync(recursive: true)..writeAsBytesSync(entry.value); }
  }
  final defaultTest = File('test/widget_test.dart');
  if (!preserved.containsKey(defaultTest.path) && defaultTest.existsSync()) defaultTest.deleteSync();
  if (code != 0) exit(code);
  final manifest = File('android/app/src/main/AndroidManifest.xml');
  var xml = manifest.readAsStringSync();
  if (!xml.contains('android.permission.INTERNET')) xml = xml.replaceFirst('<application', '<uses-permission android:name="android.permission.INTERNET"/>\n    <application');
  xml = xml.replaceAll('android:label="dia_em_ordem"', 'android:label="Dia em Ordem"');
  manifest.writeAsStringSync(xml);
  // Local plain HTTP is enabled only for Android debug builds.
  final debug = File('android/app/src/debug/AndroidManifest.xml');
  var debugXml = debug.readAsStringSync();
  if (!debugXml.contains('usesCleartextTraffic')) debugXml = debugXml.replaceFirst('</manifest>', '    <application android:usesCleartextTraffic="true"/>\n</manifest>');
  debug.writeAsStringSync(debugXml);
  final plist = File('ios/Runner/Info.plist');
  var ios = plist.readAsStringSync();
  if (!ios.contains('NSLocalNetworkUsageDescription')) ios = ios.replaceFirst('</dict>', '<key>NSLocalNetworkUsageDescription</key><string>Conectar ao servidor de IA na sua rede local.</string>\n<key>NSAppTransportSecurity</key><dict><key>NSAllowsLocalNetworking</key><true/></dict>\n</dict>');
  plist.writeAsStringSync(ios);
  final get = await Process.start(flutter, ['pub', 'get'], runInShell: Platform.isWindows, mode: ProcessStartMode.inheritStdio);
  final result = await get.exitCode;
  if (result != 0) exit(result);
  stdout.writeln('\nPronto. Execute flutter run -d chrome --web-port=5173, ou flutter run em um dispositivo Android.');
}
