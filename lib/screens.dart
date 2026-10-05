import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models.dart';
import 'store.dart';
import 'dialogs.dart';
import 'capture_screen.dart';

class HomeShell extends StatefulWidget {
  final AppStore store;
  const HomeShell({super.key, required this.store});
  @override
  State<HomeShell> createState() => _HomeShellState();
}
class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int tab = 0;
  String taskArea = 'Todas';
  String taskStatus = 'Pendentes';
  String financeArea = 'Empresa';
  String query = '';
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  late String serverUrl;
  String serverToken = '';
  Timer? ticker;
  DateTime? deadline;
  int focusMinutes = 25;
  int secondsLeft = 25 * 60;
  bool recordingFocus = false;
  @override
  void initState() {
    super.initState();
    serverUrl = !kIsWeb && defaultTargetPlatform == TargetPlatform.android ? 'http://10.0.2.2:8787' : 'http://localhost:8787';
    widget.store.addListener(refresh);
    WidgetsBinding.instance.addObserver(this);
  }
  void refresh() { if (mounted) setState(() {}); }
  @override
  void dispose() { ticker?.cancel(); widget.store.removeListener(refresh); WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { if (state == AppLifecycleState.resumed) tick(); }
  void toast(String message) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message))); }
  Future<bool> save(void Function(AppData) edit) async {
    try { await widget.store.change(edit); return true; } catch (_) { toast('Não foi possível salvar. Tente novamente; seus dados anteriores foram preservados.'); return false; }
  }
  Future<void> taskForm([Task? original]) async {
    final result = await editTask(context, task: original);
    if (result == null || !mounted) return;
    await save((d) { final i = d.tasks.indexWhere((t) => t.id == result.id); if (i < 0) { d.tasks.add(result); } else { d.tasks[i] = result; } });
  }
  Future<void> entryForm([Entry? original]) async {
    final result = await editEntry(context, entry: original);
    if (result == null || !mounted) return;
    await save((d) { final i = d.entries.indexWhere((e) => e.id == result.id); if (i < 0) { d.entries.add(result); } else { d.entries[i] = result; } });
  }
  void tick() {
    if (deadline == null || recordingFocus) return;
    final left = deadline!.difference(DateTime.now()).inMilliseconds;
    setState(() => secondsLeft = left <= 0 ? 0 : (left / 1000).ceil());
    if (secondsLeft == 0) finishFocus();
  }
  Future<void> finishFocus() async {
    if (recordingFocus) return;
    recordingFocus = true;
    ticker?.cancel();
    setState(() => deadline = null);
    final success = await save((d) => d.sessions.add(FocusSession(id: newId(), date: DateTime.now(), minutes: focusMinutes)));
    if (!mounted) return;
    recordingFocus = false;
    setState(() => secondsLeft = success ? focusMinutes * 60 : 0);
    toast(success ? 'Sessão concluída! +25 pontos. Que tal uma pausa?' : 'Sessão concluída, mas não salva. Use “Salvar sessão concluída” para tentar novamente.');
  }
  void startFocus() {
    setState(() => deadline = DateTime.now().add(Duration(seconds: secondsLeft)));
    ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }
  void pauseFocus() { tick(); ticker?.cancel(); setState(() => deadline = null); }
  Widget panel(Widget child, {Color? color}) => Container(width: double.infinity, padding: const EdgeInsets.all(20), margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: color ?? Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xffe4e9e1))), child: child);
  Widget headline(String title, String subtitle) => Padding(padding: const EdgeInsets.only(bottom: 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1)), const SizedBox(height: 6), Text(subtitle, style: TextStyle(color: Colors.grey.shade700, fontSize: 15))]));
  Widget empty(IconData icon, String title, String subtitle) => panel(Column(children: [Icon(icon, size: 44, color: const Color(0xff187668)), const SizedBox(height: 12), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text(subtitle, textAlign: TextAlign.center)]));
  Widget chips(List<String> values, String selected, ValueChanged<String> changed) => Wrap(spacing: 8, runSpacing: 6, children: values.map((v) => ChoiceChip(label: Text(v), selected: v == selected, onSelected: (_) => changed(v))).toList());
  Widget section(String title, Widget action) => Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold))), action]);
  List<Task> sortedTasks(Iterable<Task> values) => values.toList()..sort((a, b) { final done = (a.done ? 1 : 0).compareTo(b.done ? 1 : 0); if (done != 0) return done; final due = (a.due ?? DateTime(2200)).compareTo(b.due ?? DateTime(2200)); return due != 0 ? due : b.priority.compareTo(a.priority); });
  Widget taskTile(Task task) {
    final today = DateTime.now();
    final overdue = !task.done && task.due != null && task.due!.isBefore(DateTime(today.year, today.month, today.day));
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Material(color: Colors.white, borderRadius: BorderRadius.circular(18), child: ListTile(
      leading: Checkbox(value: task.done, onChanged: (_) => save((d) { final i = d.tasks.indexWhere((t) => t.id == task.id); if (i >= 0) d.tasks[i] = d.tasks[i].toggle(); })),
      title: Text(task.title, style: TextStyle(fontWeight: FontWeight.w600, decoration: task.done ? TextDecoration.lineThrough : null)),
      subtitle: Text('${task.area} · ${['Baixa', 'Normal', 'Alta'][task.priority]}${task.due == null ? '' : ' · ${brDate(task.due!)}'}${overdue ? ' · Atrasada' : ''}', style: TextStyle(color: overdue ? Colors.red.shade700 : null)),
      onTap: () => taskForm(task),
      trailing: PopupMenuButton<String>(tooltip: 'Opções da tarefa', onSelected: (value) async { if (value == 'edit') { await taskForm(task); } else if (await confirm(context, 'Excluir tarefa?', task.title)) { await save((d) => d.tasks.removeWhere((t) => t.id == task.id)); } }, itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Editar')), PopupMenuItem(value: 'delete', child: Text('Excluir'))]),
    )));
  }
  Widget todayPage() {
    final d = widget.store.data;
    final today = DateTime.now();
    final todayEnd = DateTime(today.year, today.month, today.day, 23, 59, 59);
    final pending = d.tasks.where((t) => !t.done).length;
    final nowTasks = sortedTasks(d.tasks.where((t) => !t.done && t.due != null && !t.due!.isAfter(todayEnd)));
    final minutes = d.sessions.where((s) => dayKey(s.date) == dayKey(today)).fold<int>(0, (sum, s) => sum + s.minutes);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      headline('Seu dia, com clareza.', '${brDate(today)} · Um passo de cada vez.'),
      Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), gradient: const LinearGradient(colors: [Color(0xff14594e), Color(0xff238575)], begin: Alignment.topLeft, end: Alignment.bottomRight)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Row(children: [Icon(Icons.auto_awesome, color: Color(0xffc9ed92)), SizedBox(width: 8), Text('MENOS RUÍDO. MAIS AÇÃO.', style: TextStyle(color: Color(0xffc9ed92), fontSize: 12, fontWeight: FontWeight.w700))]), const SizedBox(height: 18), const Text('Tire da cabeça.\nColoque em ordem.', style: TextStyle(color: Colors.white, fontSize: 28, height: 1.15, fontWeight: FontWeight.w700)), const SizedBox(height: 12), const Text('Transforme suas anotações em tarefas e lançamentos com ajuda da IA.', style: TextStyle(color: Color(0xffe0eee8))), const SizedBox(height: 20), FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: const Color(0xffd6f6a6), foregroundColor: const Color(0xff173e2f)), onPressed: openCapture, icon: const Icon(Icons.add), label: const Text('Organizar uma anotação'))])),
      const SizedBox(height: 18),
      Wrap(spacing: 12, runSpacing: 12, children: [metric('$pending', 'pendências', Icons.checklist), metric('$minutes min', 'foco hoje', Icons.timelapse), metric('${d.points}', 'pontos', Icons.stars_outlined)]),
      const SizedBox(height: 22), section('Prioridades do dia', TextButton(onPressed: () => setState(() => tab = 1), child: const Text('Ver todas'))), const SizedBox(height: 10),
      if (nowTasks.isEmpty) empty(Icons.wb_sunny_outlined, 'Seu dia pode começar leve', 'Adicione uma tarefa com prazo para hoje. Pendências atrasadas também aparecem aqui.') else ...nowTasks.take(5).map(taskTile),
      panel(const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.eco_outlined, color: Color(0xff8b244b)), SizedBox(width: 12), Expanded(child: Text('ODS 8 · Organização e autonomia para quem empreende. Planeje o trabalho e reserve espaço para suas pausas.'))]), color: const Color(0xffeeeade)),
    ]);
  }
  Widget metric(String value, String label, IconData icon) => Container(width: 145, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: const Color(0xff187668)), const SizedBox(height: 12), Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)), Text(label, style: TextStyle(color: Colors.grey.shade600))]));
  Widget tasksPage() {
    final tasks = sortedTasks(widget.store.data.tasks.where((t) => (taskArea == 'Todas' || t.area == taskArea) && (taskStatus == 'Todas' || (taskStatus == 'Concluídas' ? t.done : !t.done)) && t.title.toLowerCase().contains(query.toLowerCase())));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [headline('Tarefas', 'Planeje o essencial. Conclua no seu ritmo.'), TextField(decoration: const InputDecoration(hintText: 'Buscar tarefa', prefixIcon: Icon(Icons.search)), onChanged: (v) => setState(() => query = v)), const SizedBox(height: 16), chips(['Todas', 'Empresa', 'Pessoal'], taskArea, (v) => setState(() => taskArea = v)), const SizedBox(height: 8), chips(['Pendentes', 'Concluídas', 'Todas'], taskStatus, (v) => setState(() => taskStatus = v)), const SizedBox(height: 16), FilledButton.icon(onPressed: taskForm, icon: const Icon(Icons.add), label: const Text('Nova tarefa')), const SizedBox(height: 20), if (tasks.isEmpty) empty(Icons.checklist, 'Nenhuma tarefa neste filtro', 'Crie uma tarefa ou altere os filtros.') else ...tasks.map(taskTile)]);
  }
  Widget financePage() {
    final entries = widget.store.data.entries.where((e) => e.area == financeArea && e.date.year == month.year && e.date.month == month.month).toList()..sort((a, b) => b.date.compareTo(a.date));
    final income = entries.where((e) => e.income).fold<int>(0, (s, e) => s + e.cents);
    final expense = entries.where((e) => !e.income).fold<int>(0, (s, e) => s + e.cents);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [headline('Finanças', 'Registros simples, separados por área.'), chips(['Empresa', 'Pessoal'], financeArea, (v) => setState(() => financeArea = v)), const SizedBox(height: 12), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [IconButton(tooltip: 'Mês anterior', onPressed: () => setState(() => month = DateTime(month.year, month.month - 1)), icon: const Icon(Icons.chevron_left)), Text('${month.month.toString().padLeft(2, '0')}/${month.year}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), IconButton(tooltip: 'Próximo mês', onPressed: () => setState(() => month = DateTime(month.year, month.month + 1)), icon: const Icon(Icons.chevron_right))]), panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Saldo dos registros · $financeArea'), const SizedBox(height: 8), Text(money(income - expense), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 30)), const Divider(height: 30), Wrap(spacing: 30, runSpacing: 12, children: [Text('Entradas\n${money(income)}', style: const TextStyle(color: Color(0xff187668), height: 1.7)), Text('Saídas\n${money(expense)}', style: TextStyle(color: Colors.red.shade700, height: 1.7))])])), FilledButton.icon(onPressed: entryForm, icon: const Icon(Icons.add), label: const Text('Novo lançamento')), const SizedBox(height: 20), if (entries.isEmpty) empty(Icons.account_balance_wallet_outlined, 'Nenhum registro neste mês', 'Registre entradas e saídas para visualizar seu saldo.') else ...entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Material(color: Colors.white, borderRadius: BorderRadius.circular(18), child: ListTile(leading: CircleAvatar(backgroundColor: e.income ? const Color(0xffe0f2e9) : const Color(0xffffe8e2), child: Icon(e.income ? Icons.south_west : Icons.north_east, color: e.income ? const Color(0xff187668) : Colors.red.shade700)), title: Text(e.title), subtitle: Text('${brDate(e.date)} · ${e.income ? 'Entrada' : 'Saída'}\n${money(e.cents)}'), isThreeLine: true, onTap: () => entryForm(e), trailing: IconButton(tooltip: 'Excluir lançamento', icon: const Icon(Icons.delete_outline), onPressed: () async { if (await confirm(context, 'Excluir lançamento?', '${e.title} — ${money(e.cents)}')) await save((d) => d.entries.removeWhere((v) => v.id == e.id)); }))))), const SizedBox(height: 12), const Text('O saldo representa apenas os registros deste mês. Faça backups; este protótipo não substitui seu controle contábil.', style: TextStyle(fontSize: 12, color: Colors.black54))]);
  }
  Widget focusPage() {
    final label = '${(secondsLeft ~/ 60).toString().padLeft(2, '0')}:${(secondsLeft % 60).toString().padLeft(2, '0')}';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [headline('Uma coisa de cada vez.', 'Uma sessão de foco, seguida de uma pausa.'), panel(Column(children: [const Icon(Icons.spa_outlined, size: 40, color: Color(0xff187668)), const SizedBox(height: 24), Text(label, style: const TextStyle(fontSize: 68, fontWeight: FontWeight.w300, letterSpacing: -2)), const Text('Respire. Escolha uma tarefa. Comece.'), const SizedBox(height: 24), chips(['15 min', '25 min', '50 min'], '$focusMinutes min', (v) { if (deadline != null || recordingFocus || secondsLeft == 0) return; setState(() { focusMinutes = int.parse(v.split(' ').first); secondsLeft = focusMinutes * 60; }); }), const SizedBox(height: 20), Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [FilledButton.icon(onPressed: recordingFocus ? null : (secondsLeft == 0 ? finishFocus : (deadline == null ? startFocus : pauseFocus)), icon: Icon(deadline == null ? Icons.play_arrow : Icons.pause), label: Text(recordingFocus ? 'Salvando…' : secondsLeft == 0 ? 'Salvar sessão concluída' : deadline == null ? 'Começar / continuar' : 'Pausar')), OutlinedButton(onPressed: recordingFocus ? null : () { ticker?.cancel(); setState(() { deadline = null; secondsLeft = focusMinutes * 60; }); }, child: const Text('Reiniciar'))]), const SizedBox(height: 18), const Text('Mantenha o app aberto durante a sessão. Não há alarme em segundo plano.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.black54))])), panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${widget.store.data.points} pontos de organização', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text('Cada tarefa concluída vale 10 pontos; cada sessão registrada vale 25. Desmarcar ou excluir uma tarefa remove seus pontos.'), const SizedBox(height: 14), LinearProgressIndicator(value: (widget.store.data.points % 100) / 100, minHeight: 8), const SizedBox(height: 8), Text('Nível ${widget.store.data.points ~/ 100 + 1} · ${100 - widget.store.data.points % 100} pontos até o próximo nível')])), const Text('Sessões recentes', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), const SizedBox(height: 12), if (widget.store.data.sessions.isEmpty) const Text('Sua primeira sessão começa com um pequeno passo.') else ...widget.store.data.sessions.reversed.take(7).map((s) => ListTile(leading: const Icon(Icons.check_circle_outline), title: Text('${s.minutes} minutos de foco'), subtitle: Text(brDate(s.date)), trailing: const Text('+25 pts')))]);
  }
  Future<void> openCapture() async {
    await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => CapturePage(store: widget.store, baseUrl: serverUrl, token: serverToken)));
  }
  Future<void> settings() async {
    final url = TextEditingController(text: serverUrl);
    final token = TextEditingController(text: serverToken);
    await showDialog<void>(context: context, builder: (c) => AlertDialog(title: const Text('Servidor de IA'), content: SizedBox(width: 430, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Informe o endereço do servidor Node.js e o LOCAL_API_TOKEN definido nele. Não cole sua chave OpenAI aqui.'), const SizedBox(height: 16), TextField(controller: url, decoration: const InputDecoration(labelText: 'URL do servidor', hintText: 'http://localhost:8787')), const SizedBox(height: 12), TextField(controller: token, obscureText: true, autocorrect: false, enableSuggestions: false, decoration: const InputDecoration(labelText: 'Token local do servidor')), const SizedBox(height: 12), const Text('Configuração mantida apenas nesta sessão. No celular físico, use o IP do computador na mesma rede. No emulador Android, use 10.0.2.2.', style: TextStyle(fontSize: 12))]))), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')), FilledButton(onPressed: () { final parsed = Uri.tryParse(url.text.trim()); if (parsed == null || !['http', 'https'].contains(parsed.scheme) || parsed.host.isEmpty || parsed.userInfo.isNotEmpty) { toast('URL inválida.'); return; } setState(() { serverUrl = url.text.trim(); serverToken = token.text.trim(); }); Navigator.pop(c); }, child: const Text('Salvar'))]));
    // Controllers are local to the dialog and disposed after its exit transition.
    await Future<void>.delayed(const Duration(milliseconds: 300)); url.dispose(); token.dispose();
  }
  Future<void> exportBackup() async {
    try { await Clipboard.setData(ClipboardData(text: widget.store.data.encode())); toast('Backup JSON copiado. Cole em um arquivo .json e guarde em local seguro.'); } catch (_) { toast('Não foi possível copiar o backup.'); }
  }
  Future<void> importBackup() async {
    final controller = TextEditingController();
    final raw = await showDialog<String>(context: context, builder: (c) => AlertDialog(title: const Text('Restaurar backup'), content: SizedBox(width: 440, child: TextField(controller: controller, maxLines: 10, decoration: const InputDecoration(hintText: 'Cole o JSON do backup'))), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(c, controller.text), child: const Text('Validar'))]));
    await Future<void>.delayed(const Duration(milliseconds: 300)); controller.dispose();
    if (raw == null || !mounted) return;
    try { final backup = AppData.decode(raw); if (!await confirm(context, 'Substituir dados atuais?', 'Serão restauradas ${backup.tasks.length} tarefas, ${backup.entries.length} lançamentos e ${backup.sessions.length} sessões. Exporte os dados atuais antes de continuar.')) return; await widget.store.restore(raw); toast('Backup restaurado.'); } catch (_) { toast('Não foi possível restaurar. Verifique o formato do backup. Dados atuais preservados.'); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.blur_on, color: Color(0xff187668)), SizedBox(width: 8), Text('dia em ordem', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))]), actions: [PopupMenuButton<String>(tooltip: 'Configurações e backup', onSelected: (value) { switch (value) { case 'server': settings(); break; case 'export': exportBackup(); break; case 'import': importBackup(); break; case 'about': showAboutDialog(context: context, applicationName: 'Dia em Ordem', applicationVersion: '1.0.0 — Projeto Integrado', children: [const Text('Desenvolvimento Mobile · ODS 8\nProtótipo local para organização de um pequeno empreendedor. Os dados ficam neste dispositivo. A captura com IA envia somente a anotação digitada ao servidor e à OpenAI.')]); break; } }, itemBuilder: (_) => const [PopupMenuItem(value: 'server', child: Text('Configurar IA')), PopupMenuItem(value: 'export', child: Text('Copiar backup JSON')), PopupMenuItem(value: 'import', child: Text('Restaurar backup')), PopupMenuItem(value: 'about', child: Text('Sobre o projeto'))])]),
    body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 840), child: SingleChildScrollView(key: ValueKey(tab), padding: const EdgeInsets.fromLTRB(20, 16, 20, 32), child: [todayPage, tasksPage, financePage, focusPage][tab]())))),
    bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i), destinations: const [NavigationDestination(icon: Icon(Icons.wb_sunny_outlined), selectedIcon: Icon(Icons.wb_sunny), label: 'Hoje'), NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: 'Tarefas'), NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Finanças'), NavigationDestination(icon: Icon(Icons.timelapse_outlined), selectedIcon: Icon(Icons.timelapse), label: 'Foco')]),
  );
}
