# Etapa 4 — Prompt e Fase 1 (análise e plano)

Registro do prompt que iniciou a implementação da Etapa 4 (varredura
recorrente com relatório via SNS) e da resposta da Fase 1 (análise e plano,
somente leitura — nenhum arquivo de código foi criado/alterado nesta fase).
Guardado aqui para referência futura, já que a Fase 1 não deixa nenhum
artefato de código para consultar depois.

## Prompt original

> # Tarefa: Implementar a Etapa 4 — Varredura recorrente com relatório via SNS
>
> ## Papel
> Você é um engenheiro de cloud/Python trabalhando no projeto de automação de tagging PRM
> (`aws-apn-id`) da Darede. Sua tarefa é implementar a Etapa 4 reaproveitando ao máximo o
> que já existe no repositório, sem alterar decisões de arquitetura já tomadas.
>
> ## Regras obrigatórias
> 1. **Não crie, edite, mova ou apague arquivos** sem minha aprovação explícita. A Fase 1 é
>    somente leitura.
> 2. Trabalhe na branch `hml`. **Pode commitar quando eu aprovar, nunca faça push.**
> 3. **Não altere decisões de arquitetura ou escopo.** Se identificar um problema em uma
>    decisão, aponte como observação e pergunte, não corrija por conta própria.
> 4. **Nunca hardcode** valores de tag, product codes, IDs de conta, e-mails ou nomes de
>    cliente. Tudo entra por parâmetro do CloudFormation / variável de ambiente.
> 5. **Reaproveite os módulos existentes** (Etapas 1, 2 e 3). Não duplique lógica de
>    descoberta, classificação de tag ou detecção de IaC. Se precisar alterar um módulo
>    compartilhado, explique o impacto nas outras etapas antes.
> 6. Não invente comportamento de API AWS. Na dúvida, diga que precisa verificar.
>
> ## Contexto (não alterar)
> - Repositório: `/home/bea/Documentos/darede/tag-proj`
> - Tag key `aws-apn-id` (case-sensitive), value `pc:<product-code>`, uma tag por recurso.
> - Lógica por recurso: sem tag → candidato a taguear; tag igual → ok; tag diferente →
>   conflito (nunca sobrescrever); IaC detectado → sinalizar, nunca taguear via API.
> - Apenas regiões comerciais; serviços limitados ao CSV oficial; tratamento especial para
>   Bedrock (application inference profiles) e EKS (cluster, node groups, LBs, EBS; sem Fargate).
> - **Arquitetura: uma única stack CloudFormation por conta**, implantada via StackSet
>   (service-managed), com **um único Lambda** acionado de três formas:
>   - Custom Resource → Etapas 1+2 na criação da stack
>   - EventBridge (criação de recurso) → Etapa 3
>   - **EventBridge agendado (cron) → Etapa 4 (esta tarefa)**
> - **Execução local por conta**: não existe hub central nem assume-role cross-account.
>   "Varrer todas as contas" significa que cada conta, com sua própria stack, varre
>   **a si mesma em todas as regiões comerciais ativas**. A cobertura de todas as contas vem
>   do deploy do StackSet, não do código.
> - Contas novas que entram em uma OU recebem o parâmetro de contrato padrão da OU via
>   automatic deployment do StackSet; isso deve aparecer no relatório como
>   "valor padrão da OU, pendente de confirmação".
>
> ## Escopo desta tarefa
> **Dentro do escopo:**
> - Recursos no template CloudFormation da stack única:
>   - Regra EventBridge agendada (expressão de agendamento parametrizada)
>   - Permissão para o EventBridge invocar o Lambda
>   - Tópico SNS para o relatório (com criptografia e policy mínima)
>   - Assinatura(s) do tópico parametrizadas (ex: e-mail opcional), sem valores fixos
>   - Permissões IAM mínimas adicionais no role do Lambda (ex: `sns:Publish` só nesse tópico)
>   - Outputs relevantes (ARN do tópico etc.)
> - Roteamento no handler do Lambda para identificar o evento agendado e executar a varredura.
> - Varredura completa da conta: todas as regiões comerciais ativas × serviços do CSV,
>   reaproveitando os módulos da Etapa 1 e a lógica de decisão da Etapa 2a.
> - Geração do relatório consolidado da conta e envio via SNS.
> - Testes e validação.
>
> **Fora do escopo (não implementar, apenas deixar pontos de extensão quando fizer sentido):**
> - Integração com Zabbix/dashboard central
> - Camada de drift em tempo real via CloudTrail + EventBridge
> - Verificação de SCP
> - Qualquer relatório consolidado cross-account
>
> ## Pontos que exigem atenção (analise e proponha, não decida sozinho)
> 1. **Modo da varredura**: a varredura apenas audita/reporta, ou também tagueia recursos sem
>    tag que escaparam da Etapa 3 (reaproveitando a execução da Etapa 2c)? **Pergunte antes de
>    implementar.** Se for configurável, proponha um parâmetro com default seguro (somente relatório).
> 2. **Timeout do Lambda (15 min)**: estime se a varredura de todas as regiões × serviços cabe
>    nesse limite em contas grandes. Se houver risco, proponha alternativas (paralelismo por
>    região, fan-out, etc.) com prós, contras e custo, sem implementar ainda.
> 3. **Limite de tamanho da mensagem SNS (256 KB)**: o relatório completo pode não caber.
>    Proponha a estratégia (ex: resumo com contagens + amostra dos itens mais relevantes com
>    truncamento sinalizado, ou armazenamento do detalhe completo em outro recurso). Se a
>    proposta envolver um recurso novo, justifique e peça aprovação.
> 4. **Legibilidade vs. consumo por máquina**: assinaturas de e-mail recebem texto; integrações
>    futuras (Zabbix) vão precisar de JSON estável. Proponha um formato que atenda aos dois
>    (ex: mensagem com esquema versionado + message attributes para filtro por status/conta).
> 5. **Idempotência e falhas parciais**: erro em uma região ou serviço não pode derrubar a
>    varredura inteira; deve aparecer no relatório como falha parcial. Reaproveite `retry.py`.
>
> ## Conteúdo mínimo do relatório (por execução, por conta)
> - Identificação: account ID, OU (se disponível), timestamp, versão do esquema, valor de tag
>   esperado e se é "padrão da OU pendente de confirmação"
> - Totais: recursos avaliados, ok, sem tag, conflito, pulados por IaC, falhas de leitura
> - Quebra por região e por serviço
> - Lista de conflitos (recurso, valor encontrado, valor esperado)
> - Lista de recursos sem tag e de recursos com IaC (com truncamento sinalizado se necessário)
> - Regiões/serviços que falharam na varredura e o motivo
> - Se o modo de remediação existir: o que foi tagueado e o que falhou
>
> ## Fase 1 — Análise e plano (somente leitura)
> Explore o repositório e responda no chat (sem criar arquivos):
> 1. **Estado atual**: o que já existe das Etapas 1, 2 e 3 que será reaproveitado (módulos,
>    handler, template, testes) e em que estado está cada um.
> 2. **Lacunas**: o que falta no código ou no template para suportar a Etapa 4.
> 3. **Respostas aos 5 pontos de atenção** acima, com recomendação justificada.
> 4. **Desenho proposto**: fluxo do evento agendado até a publicação no SNS, recursos novos
>    no template, parâmetros novos (nome, tipo, default, descrição) e mudanças no IAM.
> 5. **Exemplo do payload** do relatório (JSON) e de como ficaria a versão legível em e-mail.
> 6. **Plano de implementação em lotes pequenos e independentes**, cada um com os arquivos
>    afetados e como será testado.
> 7. **Perguntas** que preciso responder antes de começar.
>
> Depois disso, **pare e aguarde minha aprovação**.
>
> ## Fase 2 — Implementação (somente após aprovação, um lote por vez)
> - Implemente apenas o lote aprovado.
> - Ao final de cada lote: mostre o diff resumido, rode os testes e aguarde aprovação para
>   commitar (na `hml`, sem push).
>
> ## Fase 3 — Validação
> - Testes unitários da lógica de relatório (sem AWS real), incluindo truncamento e falhas
>   parciais.
> - Testes do roteamento do handler (evento agendado vs. Custom Resource vs. criação de recurso),
>   garantindo que as Etapas 1–3 continuam funcionando.
> - Testes de integração com LocalStack/moto para SNS e EventBridge, quando suportado.
> - `cfn-lint` no template.
> - Roteiro de teste manual na **conta sandbox** (deploy da stack, disparo manual da regra,
>   verificação da mensagem recebida), que eu mesma vou executar.

## Resposta — Fase 1: Análise e plano (somente leitura)

### 1. Estado atual — o que existe e será reaproveitado

**Núcleo compartilhado pronto para reuso direto, sem alteração:**
- [regions.py](../regions.py) — `get_active_regions(session)`, já é exatamente "todas as regiões comerciais ativas".
- [services.py](../services.py) — `load_services()` (CSV oficial) + `classify_arn`.
- [resource_discovery.py](../resource_discovery.py) — `discover_generic_resources`, `discover_bedrock_resources`, `discover_eks_resources`, todas `(recursos, falhas)`, 100% leitura, já com try/except granular por região/etapa (mesmo padrão que o ponto 5 da tarefa pede).
- [report.py](../report.py) — `dedupe_by_arn` reaproveitável tal qual; `build_report` monta o formato "Etapa 1", que é insumo de `decision.py` mas **não** é o formato do relatório de compliance que a tarefa pede (ver gap 2 abaixo).
- [decision.py](../decision.py) — `build_decision_report(etapa1_report, expected_tag_value)`, função pura, classifica em `taguear/pular_iac/revisar_tag_similar/ja_ok/conflito`. Reaproveitável sem nenhuma mudança.
- [tag_execution.py](../tag_execution.py) — `run_tagging_execution(decision_report, session, expected_tag_value, dry_run, revalidate)`, já revalida antes de escrever e nunca sobrescreve conflito. Só entra em jogo se o modo remediação (ponto de atenção 1) for aprovado.
- [publish.py](../publish.py) — construído *de propósito* para a Etapa 4 reaproveitar (a própria docstring do módulo já diz isso). Mas o formato atual (`build_outcome_payload`/`publish_outcome`) é "1 mensagem SNS por recurso", o modelo da Etapa 3 — a Etapa 4 precisa de um relatório **consolidado por execução/conta**, formato diferente. `_sns_publish`/`with_backoff` são reaproveitáveis; o payload builder não é, precisa de uma função nova.
- [retry.py](../retry.py) — `with_backoff`, já usado por todas as chamadas de API dentro de `resource_discovery.py`/`tag_reads.py`, nada a fazer aqui.
- `main.py::_run_map` — não é núcleo (é entrypoint de CLI), mas é **o roteiro exato** que o handler agendado da Etapa 4 precisa reproduzir (account_id → regiões → loop por região com try/except por etapa → dedupe → relatório), só trocando "escrever em disco" por "montar em memória + publicar".
- `handler_continuous_tagging.py` — mostra o padrão de entrypoint Lambda já validado em sandbox (env vars nunca hardcoded, `session`/`sns_client` injetáveis para teste, sem lógica de negócio própria). Modelo a seguir para o roteamento do evento agendado.
- `test/unit/conftest.py` — já tem `recurso_factory`, `relatorio_etapa1_factory`, `decisao_factory`, `relatorio_decisao_factory`, `cloudtrail_event_factory`, `fake_session_factory` — cobre quase tudo que os testes da Etapa 4 vão precisar sem duplicar fixture.

### 2. Lacunas

1. **Não existe nenhum "relatório consolidado por conta"** — nem em `report.py` (que é o formato Etapa 1, por recurso) nem em `publish.py` (que é o formato Etapa 3, por recurso/evento). Precisa de uma função nova que agregue o resultado de `decision.build_decision_report` em totais, quebra por região/serviço, listas truncadas, etc. — exatamente o "conteúdo mínimo do relatório" que a tarefa especifica.
2. **`ou_tree.py` não serve como está para identificar a própria OU da conta.** A função `discover_ou_tree` foi desenhada para rodar **a partir da conta de gerenciamento** e constrói a árvore inteira (recusa-se a rodar se `account_id != management_account_id`). Mas a arquitetura da Etapa 4 é "execução local por conta" — cada conta *membro* rodando sobre si mesma, sem cross-account. Uma conta membro chamando `organizations:ListRoots`/`ListOrganizationalUnitsForParent` sobre si mesma **não tem essas permissões por padrão** (são normalmente restritas à conta de gerenciamento ou delegated administrator) — não há certeza de qual API self-service (ex.: `ListParents`) uma conta membro pode chamar sobre si mesma, então não dá para assumir isso sem verificar. **Ver pergunta 3.**
3. **Nenhum mecanismo de truncamento/detalhe-completo existe** — nada no repo grava em S3 ou qualquer outro destino além de SNS/stdout hoje.
4. **Nenhum agendamento (`AWS::Events::Rule` com `ScheduleExpression`, ou o atalho `Events: Type: Schedule` do SAM) existe no template** — só as 5 regras de CloudTrail da Etapa 3.
5. **Timeout/concorrência do `Etapa3Function` são tunados para o perfil reativo** (`Globals.Function.Timeout: 60`, `ReservedConcurrentExecutions: 5`) — incompatíveis com uma varredura de conta inteira sem alteração.
6. **Nenhum dado real de duração de varredura completa existe ainda** — os testes em sandbox até agora validaram a Etapa 3 eventos individuais, não uma varredura full-account cronometrada.

### 3. Respostas aos 5 pontos de atenção

**1. Modo da varredura (auditoria vs. remediação)** — recomendação: **configurável, default seguro = somente relatório**. Parâmetro novo `EnableRemediation` (`String`, `AllowedValues: ["true","false"]`, `Default: "false"`), repassado como env var; quando `"true"`, o handler chama `tag_execution.run_tagging_execution(..., dry_run=False, revalidate=True)` sobre os recursos com decisão `taguear` — reaproveitando `tag_execution.py` sem tocar nele. **Confirmação explícita necessária antes de implementar o branch de remediação.**

**2. Timeout do Lambda (15 min)** — `discover_generic_resources` faz **1 chamada paginada por região** via `tag:GetResources` (cobre todos os serviços genéricos de uma vez, não é 1 chamada por serviço) — bem mais barato do que "serviços × regiões" sugere à primeira vista. Ainda assim, não há dado real de duração contra uma conta de cliente grande (nunca foi cronometrado). Recomendação: **começar simples** — subir o timeout para 900s (teto do Lambda) sem fan-out para o MVP, e documentar como ponto de observação — mesmo padrão de decisão já usado para o buffer SQS da Etapa 3 ("decisão consciente de manter simples, revisitar com dado real de produção"). Escalada natural se necessário: Step Functions `Map` state (fan-out por região, "reducer" final que agrega e publica) — reaproveitando a mesma tecnologia já validada em sandbox pela Etapa 3.

**3. Limite de 256KB do SNS** — a mensagem SNS carrega **só o resumo** (totais, quebra por região/serviço, e amostras truncadas — ex. primeiros 50 conflitos/sem-tag/IaC com `truncado: true` + `total_real`), bem abaixo de 256KB mesmo em conta grande. O **detalhe completo** (lista integral de recursos) precisa de um destino novo — proposta: bucket S3 (versionado, criptografado SSE-S3, bloqueio de acesso público total, lifecycle de expiração ex. 90 dias), um objeto por execução, com a chave/URL referenciada no resumo publicado. **É um recurso novo no template — aprovação pendente** (pergunta 2). Alternativa mais barata (sem recurso novo): CloudWatch Logs estruturado, via Logs Insights — pior para consumo programado futuro.

**4. Legibilidade vs. máquina** — SNS nativamente suporta `MessageStructure: json` com uma chave `default` (JSON estruturado, para futuras integrações como SQS→Zabbix) e uma chave `email` opcional (texto plano legível) na mesma publicação — sem precisar de dois tópicos nem duas publicações. Complementado com **message attributes** (`conta_id`, `etapa`, `tem_conflitos`, `tem_falhas`) para filtragem por assinante sem parsear o body. Função **nova** em `publish.py` (ex. `publish_report`), não uma mudança em `publish_outcome` — a Etapa 3 continua exatamente como está, sem risco de regressão no que já foi validado em sandbox.

**5. Idempotência e falhas parciais** — reaproveita o padrão exato de `main.py::_run_map`: try/except por região × por sub-etapa (genérico/bedrock/eks), cada falha vira uma entrada `{"regiao", "etapa", "erro"}` (mesmo schema de `falhas_descoberta` que já existe) agregada na seção "regiões/serviços que falharam" do relatório final — nenhuma falha isolada aborta a varredura inteira. Idempotência: em modo relatório (default), a varredura é 100% leitura — reexecutar (reentrega do EventBridge, retrigger manual) não tem efeito colateral nenhum, por construção. Em modo remediação, a idempotência já vem de graça de `tag_execution.py` (revalida antes de escrever, nunca sobrescreve conflito) — nada novo a construir aí.

### 4. Desenho proposto

**Fluxo:** `AWS::Events::Rule` (schedule, parametrizado por `ScanScheduleExpression`) → invoca o Lambda diretamente com um payload fixo de marcação (`Input: '{"prm_etapa": "4"}'`) → o handler detecta esse marcador (evento agendado não tem `detail.eventName` como os eventos CloudTrail da Etapa 3) e roteia para o fluxo de varredura → `sts.get_caller_identity` → `regions.get_active_regions` → loop por região com discovery genérico/Bedrock/EKS (try/except por sub-etapa) → `report.dedupe_by_arn` → `decision.build_decision_report` → (se `EnableRemediation=true`) `tag_execution.run_tagging_execution` → monta relatório consolidado novo → se exceder limiar, grava detalhe completo no S3 e referencia → `publish.publish_report` no MESMO `PrmComplianceTopic` da Etapa 3.

Uso do atalho `Events: {Type: Schedule}` do próprio SAM na function (em vez do padrão manual Rule+Role+Targets que a Etapa 3 usa para CloudTrail) — para invocação agendada direta de Lambda, o SAM já cria a `AWS::Events::Rule` e a `AWS::Lambda::Permission` sozinho, sem precisar de role de invocação própria nem Step Functions no meio (não há corrida com IaC para debounce aqui).

**Parâmetros novos:**

| Nome | Tipo | Default | Descrição |
|---|---|---|---|
| `ScanScheduleExpression` | String | `rate(1 day)` | Expressão de agendamento da varredura |
| `EnableRemediation` | String (`true`/`false`) | `"false"` | Liga o modo remediação (Etapa 2c) sobre os recursos `taguear` |
| `OuId` / `OuDefaultPendingConfirmation` | String / String(`true`/`false`) | vazio / `"false"` | Identificação da OU para o relatório — pendente da pergunta 3 abaixo |

**IAM:** política de leitura nova (mesma superfície que `main.py map` já usa hoje — `tag:GetResources`, `ec2:DescribeRegions`, chamadas Bedrock/EKS/ELBv2/EC2/ASG listadas em `resource_discovery.py`, a confirmar 1:1 contra o código antes do deploy, mesmo rigor já aplicado às ~69 ações nativas da Etapa 3). Se o Lambda for compartilhado com a Etapa 3 (pergunta 1), a escrita (`PrmEtapa3TagWrite`/`PrmEtapa3NativeTagWrite`) já existe na mesma role — nenhuma política de escrita nova necessária. Se aprovado o S3, `s3:PutObject` escopado só ao bucket novo.

### 5. Exemplo de payload

```json
{
  "schema_versao": "1.0",
  "etapa": "4",
  "conta_id": "000000000000",
  "ou_id": "ou-abcd-12345678",
  "ou_pendente_confirmacao": false,
  "executado_em": "2026-09-25T03:00:00Z",
  "valor_tag_esperado": "pc:5ugbbrmu7ud3u5hsipfzug61p",
  "modo": "somente_relatorio",
  "resumo": {
    "total_avaliados": 842,
    "por_decisao": {"ja_ok": 610, "taguear": 90, "conflito": 12, "pular_iac": 118, "revisar_tag_similar": 4, "erro": 8},
    "total_falhas_descoberta": 1
  },
  "por_regiao": {"us-east-1": 512, "sa-east-1": 330},
  "por_servico": {"Amazon EC2": 220, "Amazon S3": 95, "...": "..."},
  "conflitos": {"itens": ["..."], "truncado": true, "total_real": 12},
  "sem_tag": {"itens": ["..."], "truncado": true, "total_real": 90},
  "iac_detectado": {"itens": ["..."], "truncado": false, "total_real": 118},
  "falhas_regiao_servico": [{"regiao": "ap-south-2", "etapa": "generico", "erro": "AccessDenied: ..."}],
  "detalhe_completo_url": "s3://prm-etapa4-reports-000000000000/2026-09-25T03-00-00Z.json",
  "remediacao": null
}
```

Versão e-mail (chave `email` do `MessageStructure=json`): texto plano com o mesmo resumo, sem os arrays de itens — só contagens + link do S3 para quem quiser o detalhe.

### 6. Plano de implementação em lotes

1. **Report builder** (módulo novo, função pura, sem AWS) — agrega decision_report + falhas em relatório consolidado, com truncamento. Testes offline com as fixtures já existentes em `conftest.py`.
2. **`publish.py`: `build_report_payload`/`publish_report`** — nova função, `MessageStructure=json` + message attributes. Testes com `fake_session_factory`/sns stub, sem tocar `publish_outcome`.
3. **Handler de orquestração** (roteamento + reprodução do fluxo de `main.py::_run_map` em memória) — testes com sessão/clients falsos, mesmo padrão de `test_handler_continuous_tagging.py`.
4. **`template.yaml`**: regra agendada + parâmetros + (se aprovado) bucket S3 + política IAM de leitura — `cfn-lint`/`sam validate --lint`/`sam build` (sem deploy).
5. **(Só se aprovado) modo remediação** — fiação do `EnableRemediation` até `tag_execution.run_tagging_execution`, testes dos dois branches.
6. **Roteiro de teste manual sandbox** (`test/manual-live-etapa4/README.md`, mesmo formato do da Etapa 3) — execução manual, fora deste plano.

Cada lote: pequeno, independente, testável offline exceto o lote 6 (manual).

### 7. Perguntas antes de começar

1. **Lambda único vs. Lambda dedicado**: o contexto da tarefa descreve o alvo final como "um único Lambda" para as 3 formas de disparo, mas hoje só a Etapa 3 existe como Lambda (Custom Resource das Etapas 1/2 nem foi construído ainda). Estender o `Etapa3Function`/`handler_continuous_tagging.py` existente com um novo branch de roteamento (reaproveita role/timeout/IAM já ali, mas toca o Lambda já validado em sandbox), ou criar um Lambda dedicado à Etapa 4 na mesma stack/tópico (zero risco ao que já está validado, mas duplica um pouco de IAM/config até o dia de unificar tudo)?
2. **Bucket S3 para o detalhe completo do relatório** (>256KB) — aprovar esse recurso novo? Ou preferir CloudWatch Logs estruturado como alternativa (sem recurso novo, pior para consumo futuro por Zabbix)?
3. **Identificação de OU no relatório**: `ou_tree.py` não serve por ser desenhado para a conta de gerenciamento. Passar a OU como **parâmetro do StackSet** (`OuId`, dado externo, igual já é `ExpectedTagValue`) em vez de tentar descobrir via API de dentro da conta membro? Ou verificar primeiro qual API do Organizations uma conta membro pode legitimamente chamar sobre si mesma antes de decidir?
4. **Cadência default do agendamento** — `rate(1 day)` como ponto de partida, ou já existe um valor combinado com o gestor?
5. Confirmar que o modo remediação fica **fora** desta primeira leva de lotes (só relatório) até decisão explícita, ou já incluir o parâmetro `EnableRemediation` desde o lote 5?
6. Sem dado real de duração de scan full-account, seguir com timeout=900s sem fan-out para o MVP, documentando o Step Functions Map como escalada futura (mesmo padrão usado para adiar o SQS da Etapa 3)?

**Status:** aguardando aprovação — nenhuma implementação (Fase 2) começou.
