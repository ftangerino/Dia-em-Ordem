import 'package:flutter/material.dart';
import 'models.dart';
import 'store.dart';
import 'ai.dart';
import 'dialogs.dart';

class CapturePage extends StatefulWidget {
  final AppStore store;
  final String baseUrl;
  final String token;
  const CapturePage({super.key, required this.store, required this.baseUrl, required this.token});
  @override
  State<CapturePage> createState() => _CapturePageState();
}
class _CapturePageState extends State<CapturePage> {
  final text = TextEditingController();
  List<CaptureSuggestion> items = [];
  Set<int> selected = {};
  bool busy = false;
  bool demonstration = false;
  String? error;
  @override
  void dispose() { text.dispose(); super.dispose(); }
  Future<void> analyze() async {
    if (text.text.trim().isEmpty) { setState(() => error = 'Escreva uma anotação primeiro.'); return; }
    setState(() { busy = true; error = null; items = []; selected = {}; demonstration = false; });
    try {
      final result = await captureText(baseUrl: widget.baseUrl, token: widget.token, text: text.text.trim());
      if (!mounted) return;
      setState(() { items = result; selected = Set<int>.from(List.generate(items.length, (i) => i)); if (items.isEmpty) error = 'Nenhum registro identificado. Informe uma tarefa ou um lançamento com valor.'; });
    } catch (e) {
      if (mounted) setState(() => error = 'Não foi possível organizar a anotação. Confira o servidor, o token e a conexão.\n$e');
    } finally { if (mounted) setState(() => busy = false); }
  }
  void demo() {
    final today = DateTime.now();
    setState(() {
      demonstration = true; error = null;
      text.text = 'Enviar proposta ao cliente amanhã e registrar R\$ 89 de hospedagem pagos hoje pela empresa.';
      items = [CaptureSuggestion(kind: 'task', title: '[Exemplo] Enviar proposta ao cliente', area: 'Empresa', date: today.add(const Duration(days: 1))), CaptureSuggestion(kind: 'expense', title: '[Exemplo] Hospedagem', area: 'Empresa', date: today, cents: 8900)];
      selected = {0, 1};
    });
  }
  Future<void> edit(int index) async {
    final item = items[index];
    if (item.kind == 'task') {
      final task = await editTask(context, task: Task(id: 'preview', title: item.title, area: item.area, due: item.date, priority: item.priority));
      if (task != null && mounted) setState(() => items[index] = CaptureSuggestion(kind: 'task', title: task.title, area: task.area, date: task.due, priority: task.priority));
    } else {
      final entry = await editEntry(context, entry: Entry(id: 'preview', title: item.title, area: item.area, cents: item.cents!, income: item.kind == 'income', date: item.date ?? DateTime.now()));
      if (entry != null && mounted) setState(() => items[index] = CaptureSuggestion(kind: entry.income ? 'income' : 'expense', title: entry.title, area: entry.area, date: entry.date, cents: entry.cents));
    }
  }
  Future<void> commit() async {
    setState(() { busy = true; error = null; });
    try {
      await widget.store.change((data) {
        for (final index in selected) {
          final item = items[index];
          if (item.kind == 'task') {
            data.tasks.add(Task(id: newId(), title: item.title, area: item.area, due: item.date, priority: item.priority));
          } else {
            data.entries.add(Entry(id: newId(), title: item.title, area: item.area, cents: item.cents!, income: item.kind == 'income', date: item.date ?? DateTime.now()));
          }
        }
      });
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${selected.length} registros salvos.'))); Navigator.pop(context); }
    } catch (_) { if (mounted) setState(() { error = 'Falha ao salvar. Tente novamente. Nenhum registro desta captura foi adicionado.'; busy = false; }); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Captura inteligente')), body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: ListView(padding: const EdgeInsets.all(20), children: [
    const Text('O que está na sua cabeça?', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800)), const SizedBox(height: 8), const Text('Escreva tarefas, prazos ou gastos. Revise as sugestões antes de salvar.'), const SizedBox(height: 20),
    TextField(controller: text, enabled: !busy, minLines: 4, maxLines: 7, maxLength: 3000, decoration: const InputDecoration(hintText: 'Enviar proposta amanhã. Paguei R\$ 89 de hospedagem hoje pela empresa.')),
    const SizedBox(height: 10), FilledButton.icon(onPressed: busy ? null : analyze, icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome), label: Text(busy ? 'Aguarde…' : 'Organizar com IA')),
    TextButton(onPressed: busy ? null : demo, child: const Text('Ver exemplo demonstrativo sem IA')),
    const Text('Ao usar a IA, somente esta anotação e a data atual serão enviadas ao servidor e à OpenAI. O restante dos registros permanece no dispositivo.', style: TextStyle(fontSize: 12, color: Colors.black54)),
    if (error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(error!, style: TextStyle(color: Colors.red.shade700))),
    if (items.isNotEmpty) ...[
      const Divider(height: 36), Text(demonstration ? 'Exemplo demonstrativo — não usa IA' : 'Revise as sugestões', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 6), const Text('Toque no lápis para corrigir informações. Desmarque o que não quiser salvar. Lançamentos sem data usam hoje.'), const SizedBox(height: 14),
      ...List.generate(items.length, (i) { final item = items[i]; return Card(elevation: 0, color: Colors.white, child: ListTile(leading: Checkbox(value: selected.contains(i), onChanged: busy ? null : (value) => setState(() { if (value == true) { selected.add(i); } else { selected.remove(i); } })), title: Text(item.title), subtitle: Text('${item.kind == 'task' ? 'Tarefa' : item.kind == 'income' ? 'Entrada' : 'Saída'} · ${item.area}\n${item.kind == 'task' ? '' : '${money(item.cents!)} · '}${item.date == null ? item.kind == 'task' ? 'Sem prazo' : 'Hoje' : brDate(item.date!)}'), isThreeLine: true, trailing: IconButton(tooltip: 'Editar sugestão', onPressed: busy ? null : () => edit(i), icon: const Icon(Icons.edit_outlined)))); }),
      const SizedBox(height: 16), FilledButton(onPressed: busy || selected.isEmpty ? null : commit, child: Text('Confirmar ${selected.length} registros')),
    ],
  ])))));
}
