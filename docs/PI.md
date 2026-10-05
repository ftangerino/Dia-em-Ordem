# Planejamento e evidências do Projeto Integrado

## Identificação proposta

- Título: Dia em Ordem — Aplicativo mobile com IA para organização da rotina de um pequeno empreendedor.
- Aluno: Francisco Eduardo Barros Tangerino (conforme relatório anterior; conferir os dados antes da entrega).
- Curso: Análise e Desenvolvimento de Sistemas.
- Módulo: Desenvolvimento Mobile, 3º trimestre letivo de 2026.
- Beneficiário proposto: empresa do aluno, prestadora de serviços de desenvolvimento de software. Preencher nome real e validar elegibilidade da atividade extensionista nas regras do AVA.
- ODS proposta: ODS 8 — Trabalho decente e crescimento econômico.

Este é um planejamento acompanhado de um protótipo. Não declara implantação, aceite do beneficiário, melhoria medida de produtividade nem aprovação acadêmica.

## Problema e objetivo

O empreendedor registra tarefas, prazos e movimentações financeiras em lugares diferentes, o que dificulta acompanhar pendências e separar a vida pessoal da empresa. O projeto propõe centralizar esses registros no celular e reduzir o esforço de cadastro com sugestões de IA revisadas pelo usuário.

Objetivo geral: desenvolver um aplicativo Flutter para organizar tarefas, registros financeiros básicos e sessões de foco, apoiando a autonomia e a gestão da rotina de um pequeno empreendedor.

Objetivos específicos: cadastrar e acompanhar tarefas; registrar entradas e saídas por área; calcular totais mensais; permitir sessões de foco; extrair sugestões de anotações; manter o usuário responsável pela confirmação; oferecer backup dos registros.

## Formação para a Vida e ODS

A proposta se relaciona ao ODS 8 ao apoiar a organização do trabalho e a gestão de uma pequena empresa. Essa relação é indireta e deve ser descrita como contribuição pretendida, sem afirmar impacto econômico comprovado.

Formação para a Vida: planejamento, autonomia, responsabilidade, tomada de decisão e avaliação crítica das sugestões de IA. O desenvolvimento também exercita competências técnicas de interfaces mobile, persistência, APIs, validação e testes. Sessões de foco e pausas são recursos de organização; não se afirma benefício clínico.

## Requisitos e critérios de aceite

| ID | Requisito | Evidência esperada |
|---|---|---|
| RF01 | Criar/editar/excluir tarefas | Capturas antes e depois da operação |
| RF02 | Concluir tarefa e filtrar por estado/área | Tarefa visível no filtro de concluídas |
| RF03 | Registrar entradas e saídas | Valores persistem após reabrir |
| RF04 | Calcular saldo mensal por área | R$ 500 de entrada e R$ 89 de saída = R$ 411 |
| RF05 | Capturar anotação via IA | Resposta real com tarefa e lançamento |
| RF06 | Revisar/editar/confirmar sugestões | Antes de confirmar, listas sem novos registros |
| RF07 | Cronometrar e registrar foco | Sessão real de 15 minutos registrada |
| RF08 | Exportar/restaurar backup | Registros recuperados e JSON inválido rejeitado |
| RNF01 | Flutter mobile | Executar em aparelho/emulador e registrar evidência |
| RNF02 | Funcionar sem API para funções básicas | Cadastro manual com servidor desligado |
| RNF03 | Chave OpenAI somente no servidor | .env local excluído do pacote/repositório |
| RNF04 | Valores em centavos inteiros | Testes de 0,10 e 1.234,56 |

## Arquitetura

Flutter (telas/formulários) → AppStore → armazenamento local.
Flutter (captura) → API Node.js autenticada por token local → OpenAI Responses API.
Sugestões retornam à tela de revisão. Somente a confirmação grava registros locais.

A persistência em shared_preferences mantém o escopo demonstrável; uma versão de produção deve adotar banco transacional, backup automático, autenticação e proteção adicional de dados.

## Método e sequência de entrega

1. Validar a proposta completa e os requisitos de entrega no AVA.
2. Preparar Flutter e executar o aplicativo localmente.
3. Rodar `flutter analyze` e `flutter test`; registrar resultados reais.
4. Criar tarefas e lançamentos; verificar totais e persistência.
5. Configurar uma chave nova no servidor e testar uma captura real.
6. Registrar uma sessão de foco e verificar pontos sem duplicação.
7. Exportar backup antes de testar restauração.
8. Capturar telas em dispositivo mobile, preencher o relatório e gravar demonstração se exigida.

## Roteiro sugerido de demonstração (3 a 5 minutos)

1. Apresente o problema e a empresa beneficiária.
2. Mostre o aplicativo rodando no celular/emulador.
3. Crie tarefa com prazo, edite e conclua.
4. Registre uma entrada de R$ 500 e uma saída de R$ 89 na mesma área/mês; mostre R$ 411.
5. Explique a separação Pessoal/Empresa.
6. Use captura real de IA e mostre a revisão antes da confirmação. Se só usar o exemplo, identifique explicitamente que é demonstrativo e não comprova integração real.
7. Mostre foco, pontos e backup.
8. Apresente limites do protótipo e melhorias futuras.

## Como preencher o modelo de relatório fornecido

1. Identificação: título, aluno e período real de desenvolvimento.
2. Introdução: problema da empresa e motivação.
3. Objetivos: geral e específicos acima, ajustados ao resultado efetivo.
4. Fundamentação: Flutter, organização de estado, persistência, API, IA e uso responsável.
5. Metodologia: trabalho individual, etapas executadas e ferramentas.
6. Desenvolvimento: capturas reais, funcionalidades e testes executados.
7. Resultados: distinguir implementação, execução verificada e benefícios esperados.
8. Dificuldades: configuração, persistência, conectividade e revisão da IA.
9. Considerações finais: alcance observado, limitações e evolução.

## Validação disponível na entrega do código

10 testes do servidor passaram com respostas simuladas da OpenAI. Os testes Flutter estão escritos, mas pendentes de execução local por indisponibilidade do SDK no ambiente de desenvolvimento desta entrega. Nenhum teste em celular, chamada real ao modelo ou aceite da empresa foi declarado.
