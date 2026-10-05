import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class AppStore extends ChangeNotifier {
  static const storageKey = 'dia_em_ordem_v1';
  final SharedPreferences preferences;
  AppData data;
  bool busy = false;
  AppStore(this.preferences, this.data);

  Future<void> change(void Function(AppData) edit) async {
    if (busy) throw StateError('Aguarde o salvamento anterior.');
    busy = true;
    try {
      final next = AppData.decode(data.encode());
      edit(next);
      final encoded = next.encode();
      AppData.decode(encoded); // Validate before committing.
      if (!await preferences.setString(storageKey, encoded)) throw StateError('Não foi possível salvar os dados.');
      data = next;
      notifyListeners();
    } finally {
      busy = false;
    }
  }
  Future<void> restore(String json) async {
    final incoming = AppData.decode(json);
    await change((d) {
      d.tasks..clear()..addAll(incoming.tasks);
      d.entries..clear()..addAll(incoming.entries);
      d.sessions..clear()..addAll(incoming.sessions);
    });
  }
}
