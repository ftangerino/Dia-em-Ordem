import 'package:flutter/material.dart';
import 'models.dart';

Future<Task?> editTask(BuildContext context, {Task? task}) => showDialog<Task>(context: context, builder: (_) => TaskDialog(task: task));
class TaskDialog extends StatefulWidget {
  final Task? task;
  const TaskDialog({super.key, this.task});
  @override
  State<TaskDialog> createState() => _TaskDialogState();
}
class _TaskDialogState extends State<TaskDialog> {
  final form = GlobalKey<FormState>();
  late final TextEditingController title;
  late String area;
  late int priority;
  DateTime? due;
  @override
  void initState() { super.initState(); title = TextEditingController(text: widget.task?.title); area = widget.task?.area ?? 'Empresa'; priority = widget.task?.priority ?? 1; due = widget.task?.due; }
  @override
  void dispose() { title.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.task == null ? 'Nova tarefa' : 'Editar tarefa'),
    content: SizedBox(width: 420, child: SingleChildScrollView(child: Form(key: form, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextFormField(controller: title, autofocus: true, maxLength: 160, decoration: const InputDecoration(labelText: 'O que precisa ser feito?'), validator: (v) => v == null || v.trim().isEmpty ? 'Escreva uma tarefa.' : null),
      DropdownButtonFormField<String>(value: area, decoration: const InputDecoration(labelText: 'Área'), items: ['Empresa', 'Pessoal'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => area = v!)),
      const SizedBox(height: 12),
      DropdownButtonFormField<int>(value: priority, decoration: const InputDecoration(labelText: 'Prioridade'), items: const [DropdownMenuItem(value: 0, child: Text('Baixa')), DropdownMenuItem(value: 1, child: Text('Normal')), DropdownMenuItem(value: 2, child: Text('Alta'))], onChanged: (v) => setState(() => priority = v!)),
      const SizedBox(height: 12),
      OutlinedButton.icon(icon: const Icon(Icons.calendar_month_outlined), label: Text(due == null ? 'Definir prazo' : brDate(due!)), onPressed: () async { final value = await showDatePicker(context: context, initialDate: due ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100, 12, 31)); if (value != null && mounted) setState(() => due = value); }),
      if (due != null) TextButton(onPressed: () => setState(() => due = null), child: const Text('Remover prazo')),
    ])))),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), FilledButton(onPressed: () { if (form.currentState!.validate()) Navigator.pop(context, Task(id: widget.task?.id ?? newId(), title: title.text.trim(), area: area, due: due, priority: priority, done: widget.task?.done ?? false)); }, child: const Text('Salvar'))],
  );
}

Future<Entry?> editEntry(BuildContext context, {Entry? entry}) => showDialog<Entry>(context: context, builder: (_) => EntryDialog(entry: entry));
class EntryDialog extends StatefulWidget {
  final Entry? entry;
  const EntryDialog({super.key, this.entry});
  @override
  State<EntryDialog> createState() => _EntryDialogState();
}
class _EntryDialogState extends State<EntryDialog> {
  final form = GlobalKey<FormState>();
  late final TextEditingController title;
  late final TextEditingController amount;
  late String area;
  late bool income;
  late DateTime date;
  @override
  void initState() { super.initState(); final e = widget.entry; title = TextEditingController(text: e?.title); amount = TextEditingController(text: e == null ? '' : '${e.cents ~/ 100},${(e.cents % 100).toString().padLeft(2, '0')}'); area = e?.area ?? 'Empresa'; income = e?.income ?? false; date = e?.date ?? DateTime.now(); }
  @override
  void dispose() { title.dispose(); amount.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(title: Text(widget.entry == null ? 'Novo lançamento' : 'Editar lançamento'), content: SizedBox(width: 420, child: SingleChildScrollView(child: Form(key: form, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    SegmentedButton<bool>(segments: const [ButtonSegment(value: false, label: Text('Saída')), ButtonSegment(value: true, label: Text('Entrada'))], selected: {income}, onSelectionChanged: (v) => setState(() => income = v.first)), const SizedBox(height: 16),
    TextFormField(controller: title, maxLength: 160, decoration: const InputDecoration(labelText: 'Descrição'), validator: (v) => v == null || v.trim().isEmpty ? 'Informe a descrição.' : null),
    TextFormField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Valor em reais', hintText: '89,90', prefixText: 'R\$ '), validator: (v) => parseCents(v ?? '') == null ? 'Use um valor positivo, como 89,90.' : null), const SizedBox(height: 12),
    DropdownButtonFormField<String>(value: area, decoration: const InputDecoration(labelText: 'Área'), items: ['Empresa', 'Pessoal'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => area = v!)), const SizedBox(height: 12),
    OutlinedButton.icon(icon: const Icon(Icons.calendar_month), label: Text(brDate(date)), onPressed: () async { final value = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2000), lastDate: DateTime(2100, 12, 31)); if (value != null && mounted) setState(() => date = value); }),
  ])))), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), FilledButton(onPressed: () { if (form.currentState!.validate()) Navigator.pop(context, Entry(id: widget.entry?.id ?? newId(), title: title.text.trim(), area: area, cents: parseCents(amount.text)!, income: income, date: date)); }, child: const Text('Salvar'))]);
}
Future<bool> confirm(BuildContext context, String title, String message) async => await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: Text(title), content: Text(message), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Confirmar'))])) ?? false;
