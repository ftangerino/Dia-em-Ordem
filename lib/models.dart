import 'dart:convert';
import 'dart:math';

String newId() => '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 30)}';
String dayKey(DateTime date) => '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
String brDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
String money(int cents) {
  final digits = (cents.abs() ~/ 100).toString();
  final groups = digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  return '${cents < 0 ? '-' : ''}R\$ $groups,${(cents.abs() % 100).toString().padLeft(2, '0')}';
}
int? parseCents(String input) {
  // Brazilian notation: 1234,56 or 1.234,56. No binary floating-point arithmetic.
  final raw = input.trim().replaceAll('R\$', '').replaceAll(' ', '');
  if (!RegExp(r'^(\d+|\d{1,3}(\.\d{3})+)(,\d{1,2})?$').hasMatch(raw)) return null;
  final parts = raw.replaceAll('.', '').split(',');
  final value = int.tryParse(parts[0]);
  if (value == null || value > 999999999) return null;
  final cents = value * 100 + (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0);
  return cents > 0 ? cents : null;
}
DateTime parseDay(dynamic value) {
  if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    throw const FormatException('Data inválida.');
  }
  final date = DateTime.tryParse(value);
  if (date == null || dayKey(date) != value || date.year < 2000 || date.year > 2100) {
    throw const FormatException('Data fora do intervalo 2000–2100.');
  }
  return date;
}
String checkedText(dynamic value, int max) {
  if (value is! String || value.trim().isEmpty || value.length > max) {
    throw const FormatException('Texto ausente ou muito longo.');
  }
  return value.trim();
}
String checkedArea(dynamic value) {
  if (value != 'Empresa' && value != 'Pessoal') throw const FormatException('Área inválida.');
  return value as String;
}

class Task {
  final String id;
  final String title;
  final String area;
  final DateTime? due;
  final bool done;
  final int priority;
  const Task({required this.id, required this.title, required this.area, this.due, this.done = false, this.priority = 1});
  Task toggle() => Task(id: id, title: title, area: area, due: due, done: !done, priority: priority);
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'area': area, 'due': due == null ? null : dayKey(due!), 'done': done, 'priority': priority};
  factory Task.fromJson(Map<String, dynamic> j) {
    final priority = j['priority'];
    if (priority is! int || priority < 0 || priority > 2 || j['done'] is! bool) throw const FormatException('Tarefa inválida.');
    return Task(id: checkedText(j['id'], 100), title: checkedText(j['title'], 160), area: checkedArea(j['area']), due: j['due'] == null ? null : parseDay(j['due']), done: j['done'] as bool, priority: priority);
  }
}
class Entry {
  final String id;
  final String title;
  final String area;
  final int cents;
  final bool income;
  final DateTime date;
  const Entry({required this.id, required this.title, required this.area, required this.cents, required this.income, required this.date});
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'area': area, 'cents': cents, 'income': income, 'date': dayKey(date)};
  factory Entry.fromJson(Map<String, dynamic> j) {
    if (j['cents'] is! int || j['cents'] <= 0 || j['cents'] > 99999999999 || j['income'] is! bool) throw const FormatException('Valor financeiro inválido.');
    return Entry(id: checkedText(j['id'], 100), title: checkedText(j['title'], 160), area: checkedArea(j['area']), cents: j['cents'] as int, income: j['income'] as bool, date: parseDay(j['date']));
  }
}
class FocusSession {
  final String id;
  final DateTime date;
  final int minutes;
  const FocusSession({required this.id, required this.date, required this.minutes});
  Map<String, dynamic> toJson() => {'id': id, 'date': dayKey(date), 'minutes': minutes};
  factory FocusSession.fromJson(Map<String, dynamic> j) {
    if (j['minutes'] is! int || j['minutes'] < 1 || j['minutes'] > 120) throw const FormatException('Sessão inválida.');
    return FocusSession(id: checkedText(j['id'], 100), date: parseDay(j['date']), minutes: j['minutes'] as int);
  }
}
class AppData {
  final List<Task> tasks;
  final List<Entry> entries;
  final List<FocusSession> sessions;
  AppData({List<Task>? tasks, List<Entry>? entries, List<FocusSession>? sessions}) : tasks = tasks ?? [], entries = entries ?? [], sessions = sessions ?? [];
  int get points => tasks.where((t) => t.done).length * 10 + sessions.length * 25;
  String encode() => jsonEncode({'version': 1, 'tasks': tasks.map((t) => t.toJson()).toList(), 'entries': entries.map((e) => e.toJson()).toList(), 'sessions': sessions.map((s) => s.toJson()).toList()});
  factory AppData.decode(String text) {
    if (text.length > 5000000) throw const FormatException('Backup muito grande.');
    final j = jsonDecode(text);
    if (j is! Map<String, dynamic> || j['version'] != 1) throw const FormatException('Versão de backup incompatível.');
    for (final key in ['tasks', 'entries', 'sessions']) {
      if (j[key] is! List || (j[key] as List).length > 10000) throw const FormatException('Lista de registros inválida.');
    }
    final data = AppData(tasks: (j['tasks'] as List).map((v) => Task.fromJson(Map<String, dynamic>.from(v as Map))).toList(), entries: (j['entries'] as List).map((v) => Entry.fromJson(Map<String, dynamic>.from(v as Map))).toList(), sessions: (j['sessions'] as List).map((v) => FocusSession.fromJson(Map<String, dynamic>.from(v as Map))).toList());
    final ids = [...data.tasks.map((t) => t.id), ...data.entries.map((e) => e.id), ...data.sessions.map((s) => s.id)];
    if (ids.toSet().length != ids.length) throw const FormatException('Identificadores duplicados.');
    return data;
  }
}
