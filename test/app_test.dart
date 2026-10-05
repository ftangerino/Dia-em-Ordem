import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dia_em_ordem/main.dart';
import 'package:dia_em_ordem/models.dart';
import 'package:dia_em_ordem/store.dart';

void main() {
  testWidgets('cria e conclui tarefa pela interface', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = AppStore(prefs, AppData());
    await tester.pumpWidget(DiaApp(store: store));
    await tester.tap(find.text('Tarefas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nova tarefa'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Enviar proposta');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(store.data.tasks.single.title, 'Enviar proposta');
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(store.data.tasks.single.done, isTrue);
    expect(store.data.points, 10);
  });
  testWidgets('exemplo de captura só grava após confirmar', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = AppStore(await SharedPreferences.getInstance(), AppData());
    await tester.pumpWidget(DiaApp(store: store));
    await tester.tap(find.text('Organizar uma anotação'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver exemplo demonstrativo sem IA'));
    await tester.pumpAndSettle();
    expect(store.data.tasks, isEmpty);
    expect(store.data.entries, isEmpty);
    await tester.scrollUntilVisible(find.text('Confirmar 2 registros'), 250);
    await tester.tap(find.text('Confirmar 2 registros'));
    await tester.pumpAndSettle();
    expect(store.data.tasks.length, 1);
    expect(store.data.entries.single.cents, 8900);
  });
}
