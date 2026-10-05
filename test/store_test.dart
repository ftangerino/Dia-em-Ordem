import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dia_em_ordem/models.dart';
import 'package:dia_em_ordem/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('grava, recarrega e preserva dados após importação inválida', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = AppStore(prefs, AppData());
    await store.change((d) => d.tasks.add(const Task(id: '1', title: 'Cliente', area: 'Empresa')));
    final persisted = prefs.getString(AppStore.storageKey)!;
    expect(AppData.decode(persisted).tasks.single.title, 'Cliente');
    await expectLater(store.restore('not json'), throwsFormatException);
    expect(store.data.tasks.single.title, 'Cliente');
    expect(prefs.getString(AppStore.storageKey), persisted);
  });
}
