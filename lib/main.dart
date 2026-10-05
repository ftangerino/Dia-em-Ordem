import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'store.dart';
import 'screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppStore.storageKey);
    final data = raw == null ? AppData() : AppData.decode(raw);
    runApp(DiaApp(store: AppStore(prefs, data)));
  } catch (error) {
    runApp(MaterialApp(home: Scaffold(body: SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.warning_amber_rounded, size: 52), const SizedBox(height: 16), const Text('Não foi possível abrir os dados salvos.', style: TextStyle(fontSize: 22)), const SizedBox(height: 12), const Text('Os dados não foram apagados. Tente reiniciar o aplicativo. Se persistir, preserve o armazenamento e use seu último backup para recuperação.'), const SizedBox(height: 12), SelectableText('$error')]))))));
  }
}

class DiaApp extends StatelessWidget {
  final AppStore store;
  const DiaApp({super.key, required this.store});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Dia em Ordem', debugShowCheckedModeBanner: false,
    locale: const Locale('pt', 'BR'),
    supportedLocales: const [Locale('pt', 'BR')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff187668), brightness: Brightness.light), scaffoldBackgroundColor: const Color(0xfff5f6f2), appBarTheme: const AppBarTheme(backgroundColor: Color(0xfff5f6f2), centerTitle: false), inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))), filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)))),
    home: HomeShell(store: store),
  );
}
