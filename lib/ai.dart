import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class CaptureSuggestion {
  final String kind;
  final String title;
  final String area;
  final DateTime? date;
  final int priority;
  final int? cents;
  const CaptureSuggestion({required this.kind, required this.title, required this.area, this.date, this.priority = 1, this.cents});
  factory CaptureSuggestion.fromJson(Map<String, dynamic> j) {
    final kind = j['kind'];
    if (!['task', 'income', 'expense'].contains(kind)) throw const FormatException('Tipo inválido.');
    final cents = j['amountCents'];
    if (kind != 'task' && (cents is! int || cents <= 0 || cents > 99999999999)) throw const FormatException('A IA não informou um valor válido.');
    final priority = j['priority'];
    if (priority is! int || priority < 0 || priority > 2) throw const FormatException('Prioridade inválida.');
    return CaptureSuggestion(kind: kind as String, title: checkedText(j['title'], 160), area: checkedArea(j['area']), date: j['date'] == null ? null : parseDay(j['date']), cents: cents as int?, priority: priority);
  }
  CaptureSuggestion copyWith({String? title, String? area, DateTime? date, int? cents}) => CaptureSuggestion(kind: kind, title: title ?? this.title, area: area ?? this.area, date: date ?? this.date, cents: cents ?? this.cents, priority: priority);
}
Future<List<CaptureSuggestion>> captureText({required String baseUrl, required String token, required String text}) async {
  final base = Uri.tryParse(baseUrl.trim());
  if (base == null || !['http', 'https'].contains(base.scheme) || base.host.isEmpty || base.userInfo.isNotEmpty) throw const FormatException('Informe uma URL válida do servidor.');
  final response = await http.post(base.resolve('/api/capture'), headers: {'Content-Type': 'application/json', if (token.isNotEmpty) 'Authorization': 'Bearer $token'}, body: jsonEncode({'text': text, 'today': dayKey(DateTime.now())})).timeout(const Duration(seconds: 50));
  if (response.statusCode != 200) {
    String message = 'Falha ao consultar o servidor (${response.statusCode}).';
    try { final error = jsonDecode(response.body); if (error['error'] is String) message = error['error'] as String; } catch (_) {}
    throw StateError(message);
  }
  final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  final items = data['items'];
  if (items is! List || items.length > 15) throw const FormatException('Resposta inesperada da IA.');
  return items.map((item) => CaptureSuggestion.fromJson(Map<String, dynamic>.from(item as Map))).toList();
}
