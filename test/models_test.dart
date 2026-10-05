import 'package:flutter_test/flutter_test.dart';
import 'package:dia_em_ordem/models.dart';

void main() {
  test('converte reais brasileiros sem erro de ponto flutuante', () {
    expect(parseCents('1.234,56'), 123456);
    expect(parseCents('0,10'), 10);
    expect(parseCents('89,9'), 8990);
    expect(parseCents('R\$ 89'), 8900);
    for (final invalid in ['-20', '0', '12.34', '1,999', 'abc', 'NaN']) { expect(parseCents(invalid), isNull); }
    expect(money(-123456), '-R\$ 1.234,56');
  });
  test('rejeita datas impossíveis e preserva ano bissexto', () {
    expect(() => parseDay('2026-02-30'), throwsFormatException);
    expect(() => parseDay('2026-13-01'), throwsFormatException);
    expect(dayKey(parseDay('2024-02-29')), '2024-02-29');
  });
  test('backup preserva lançamentos e pontos sem duplicar conclusão', () {
    final d = AppData(tasks: [Task(id: 't1', title: 'Enviar proposta', area: 'Empresa', done: true)], entries: [Entry(id: 'e1', title: 'Hospedagem', area: 'Empresa', cents: 8900, income: false, date: DateTime(2026, 10, 5))], sessions: [FocusSession(id: 's1', date: DateTime(2026, 10, 5), minutes: 25)]);
    final copy = AppData.decode(d.encode());
    expect(copy.entries.single.cents, 8900);
    expect(copy.points, 35);
    copy.tasks[0] = copy.tasks[0].toggle();
    expect(copy.points, 25);
    copy.tasks[0] = copy.tasks[0].toggle();
    expect(copy.points, 35);
  });
  test('backup inválido e IDs duplicados são rejeitados', () {
    expect(() => AppData.decode('{"version":2}'), throwsFormatException);
    final t = Task(id: 'same', title: 'Tarefa', area: 'Empresa');
    expect(() => AppData.decode(AppData(tasks: [t, t]).encode()), throwsFormatException);
  });
}
