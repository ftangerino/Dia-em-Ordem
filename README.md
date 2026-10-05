# Dia em Ordem — Flutter

Aplicativo mobile em português para organizar tarefas, registros financeiros e sessões de foco de um pequeno empreendedor. Projeto Integrado de Desenvolvimento Mobile, com proposta de vínculo ao ODS 8 — Trabalho decente e crescimento econômico.

## Comece aqui

Este pacote contém o código Flutter e um servidor opcional Node.js. As pastas nativas são geradas pelo Flutter instalado em sua máquina, evitando incompatibilidade entre versões de Gradle e do SDK. Não é um APK pronto.

Pré-requisitos:
- Flutter estável instalado e disponível no PATH, com Dart >= 3.5 (recomendado: versão estável atual).
- Chrome para uma primeira execução rápida, ou Android Studio/emulador/celular Android com depuração USB.
- Node.js 22+ somente para usar a IA. As demais funções não precisam do servidor nem de chave.
- Internet para a instalação das dependências e para a IA.

Extraia o ZIP e abra um terminal na pasta `dia_em_ordem` (aquela que contém `pubspec.yaml`).

```bash
flutter doctor
# Primeira vez: gera Android, iOS e Web e instala as dependências.
dart tool/setup.dart

# Confira os dispositivos disponíveis.
flutter devices

# Primeira demonstração no navegador:
flutter run -d chrome --web-port=5173

# Ou execute em um celular/emulador Android:
flutter run -d ID_DO_DISPOSITIVO
```

Substitua `ID_DO_DISPOSITIVO` pelo identificador mostrado em `flutter devices`. Se houver apenas um dispositivo, `flutter run` é suficiente. O aplicativo é Flutter: a execução no Chrome é uma opção de demonstração; a evidência mobile deve ser obtida no celular ou emulador.

Windows: use PowerShell ou o terminal do VS Code. Se `flutter` não for reconhecido, inclua a pasta `flutter/bin` no PATH e reabra o terminal. Para preparar o Android SDK e aceitar suas licenças, siga o diagnóstico de `flutter doctor`; quando solicitado, execute `flutter doctor --android-licenses`.

macOS: o mesmo fluxo serve para Android/Web. Para iPhone ou simulador iOS é necessário macOS, Xcode, suas ferramentas e, no aparelho físico, configuração de assinatura. Essa configuração não foi testada neste ambiente.

## O que já está implementado

- Tela Hoje com tarefas vencidas/para hoje, minutos de foco e pontos.
- Criar, editar, concluir e excluir tarefas; prazo opcional, prioridade, área e busca.
- Registrar, editar e excluir entradas/saídas; filtros por mês e área; saldo em centavos inteiros.
- Temporizador de 15, 25 ou 50 minutos, pausa, retomada e histórico de sessões.
- 10 pontos por tarefa concluída e 25 por sessão; níveis a cada 100 pontos.
- Persistência local; backup JSON pelo menu e restauração com confirmação.
- Captura com IA: texto livre → sugestões → edição/seleção → confirmação.
- Exemplo demonstrativo offline claramente identificado, que não chama a IA.

O app inicia vazio. Para ver o fluxo sem configurar a API: Hoje → Organizar uma anotação → Ver exemplo demonstrativo sem IA. Os registros só são adicionados após confirmar. Eles têm `[Exemplo]` no título e podem ser excluídos depois.

## IA com gpt-6-luna

A chave OpenAI fica apenas no computador que executa o servidor. A chave exposta anteriormente na conversa deve ser revogada e substituída; nenhuma chave real está incluída neste projeto.

Abra outro terminal:

```bash
cd server
```

Copie `.env.example` para `.env`:

```powershell
# Windows / PowerShell
Copy-Item .env.example .env
```

```bash
# macOS / Linux
cp .env.example .env
```

Gere um token local com:

```bash
node -e "console.log(require('node:crypto').randomBytes(24).toString('hex'))"
```

Edite `.env` no seu editor:

```dotenv
OPENAI_API_KEY=COLE_SUA_NOVA_CHAVE_AQUI
OPENAI_MODEL=gpt-6-luna
LOCAL_API_TOKEN=COLE_O_TOKEN_LOCAL_GERADO_AQUI
PORT=8787
HOST=127.0.0.1
ALLOWED_ORIGINS=http://localhost:5173,http://127.0.0.1:5173
```

Inicie o servidor (não há dependências npm para instalar):

```bash
npm start
```

Abra `http://localhost:8787/health` no navegador do computador. Deve aparecer `{"ok":true}`. Isso confirma apenas o servidor; a chave/modelo são verificados ao executar uma captura real.

No app, menu superior → **Configurar IA**:

| Execução do app | URL do servidor |
|---|---|
| Chrome no computador | `http://localhost:8787` |
| Emulador Android padrão | `http://10.0.2.2:8787` |
| Simulador iOS no mesmo Mac | `http://localhost:8787` |
| Celular físico na mesma rede | `http://IP_DO_COMPUTADOR:8787` |

No campo de token do app, informe o **LOCAL_API_TOKEN**, nunca a chave OpenAI. A configuração vale apenas para a sessão atual.

Para celular físico, altere `HOST=0.0.0.0` no `.env`, reinicie o servidor e permita a porta 8787 no firewall somente na rede privada. Descubra o IP do computador com `ipconfig` (Windows) ou nas configurações de rede (macOS/Linux). No Android físico via USB, uma alternativa é `adb reverse tcp:8787 tcp:8787` e usar `http://127.0.0.1:8787` no app.

O script de preparação libera HTTP local somente no Android debug. Para APK release, use servidor HTTPS e configure sua URL no app. iOS pode exigir permissão para rede local; se HTTP por IP for bloqueado, use HTTPS. Não exponha esse servidor local diretamente na internet.

A IA recebe apenas o texto digitado e a data local atual, com `store:false` na API Responses. Não recebe todo o histórico do aplicativo. Há autenticação por token local, limite de 12 chamadas/minuto e até 2 chamadas simultâneas. Não há logs de chaves ou anotações. O token local é apropriado para uma demonstração privada; publicação multiusuário precisa de autenticação individual.

## Backup e limites do protótipo

Menu → Copiar backup JSON. Cole o conteúdo em um arquivo `.json` e guarde fora do aplicativo. Restaurar backup valida os registros e substitui os dados atuais somente após confirmação.

Os dados ficam no armazenamento local (`shared_preferences`) do dispositivo/navegador. Desinstalar o app ou limpar dados do navegador pode apagá-los. Esse armazenamento é adequado ao protótipo, mas não oferece banco transacional, criptografia de aplicação ou sincronização; não o use como única cópia de informações financeiras importantes. Uma evolução de produção deve migrar para banco local transacional, backup automático e proteção de dados.

O saldo considera somente registros do mês e área escolhidos, sem saldo inicial, integração bancária ou contas a pagar. Não são feitas recomendações de investimento.

O cronômetro usa uma hora de término para corrigir atrasos ao retornar ao app. Não envia notificação/alarme quando fechado e não restaura uma sessão em andamento após reiniciar. Alterações manuais do relógio podem afetá-lo. Pontos de tarefas são recalculados: desmarcar ou excluir uma tarefa remove seus 10 pontos.

## Testar

Após `dart tool/setup.dart`:

```bash
flutter analyze
flutter test
```

Servidor:

```bash
cd server
npm test
```

Estado da validação neste pacote:
- 10 testes automatizados do servidor passaram com Node.js 24.19.0.
- A sintaxe dos 11 arquivos Dart foi verificada com uma gramática Tree-sitter; isso não verifica tipos/APIs Flutter nem substitui o compilador.
- Testes da API usam respostas simuladas; nenhuma chamada paga à OpenAI foi executada.
- Os testes Flutter foram incluídos, mas não executados neste ambiente porque o SDK Flutter não está instalado. A compilação e a inspeção visual em celular precisam ser feitas localmente.
- O acesso ao modelo `gpt-6-luna` depende de sua conta e deve ser verificado com uma captura real.

## Estrutura

```text
lib/
  main.dart              Inicialização, tema e recuperação de erro
  models.dart            Modelos, datas, moeda e backup
  store.dart             Persistência local e mutações
  screens.dart           Hoje, tarefas, finanças, foco e configurações
  dialogs.dart           Formulários e confirmações
  ai.dart                Cliente HTTP e validação das sugestões
  capture_screen.dart    Revisão antes de salvar
server/
  server.mjs             API Node.js e integração OpenAI
  server.test.mjs        Testes de validação, autorização e falhas
  .env.example           Configuração sem credenciais reais
test/                    Testes Flutter a executar localmente
tool/setup.dart          Geração das pastas de plataforma
docs/PI.md               Planejamento e roteiro de evidências
```

## Referências técnicas

- Flutter CLI: https://docs.flutter.dev/reference/flutter-cli
- Preparação de ambiente: https://docs.flutter.dev/install
- Persistência do protótipo: https://pub.dev/packages/shared_preferences
- Saídas estruturadas: https://developers.openai.com/api/docs/guides/structured-outputs
- Modelo: https://developers.openai.com/api/docs/models/gpt-6-luna

A relação com a ODS 8 é uma proposta para o PI. As páginas de orientações fornecidas confirmam Desenvolvimento Mobile, mas não trazem a rubrica completa nem uma ODS obrigatória. Confirme regras específicas no AVA.
