## PLANILHAS CONSOLIDADAS

### ABA 1: CLUSTERS E ADD-ONS ATUAIS

| Conta       | Account ID | Cluster    | Região    | K8s Atual | Status | Node Group                  | Desired | Current | Max | Add-ons (qtd) |
| ----------- | ---------- | ---------- | --------- | --------- | ------ | --------------------------- | ------- | ------- | --- | ------------- |
| Development | XXXXXX     | XXXXXXXXXX | us-east-1 | 1.35      | ACTIVE | XXXXXXXXXXXXXXXXXXXXXXXXXXX | —       | —       | —   | 4             |
| Sandbox     | XXXXXX     | XXXXXXXXXX | us-east-1 | 1.35      | ACTIVE | XXXXXXXXXXXXXXXXXXXXXXXXXXX | —       | —       | —   | 3             |
| Staging     | XXXXXX     | —          | —         | —         | —      | —                           | —       | —       | —   | —             |
| Production  | XXXXXX     | XXXXXXXXXX | sa-east-1 | 1.35      | ACTIVE | XXXXXXXXXXXXXXXXXXXXXXXXXXX | —       | —       | —   | 4             |

---

### ABA 2: ADD-ONS - ANTES E DEPOIS

| Cluster    | Conta   | Região    | Add-on             | Versão Atual (1.35) | Versão Alvo (1.36)  | Upgrade Necessário | Risks                       | Status |
| ---------- | ------- | --------- | ------------------ | ------------------- | ------------------- | ------------------ | --------------------------- | ------ |
| XXXXXXXXXX | Dev     | us-east-1 | vpc-cni            | v1.21.1-eksbuild.3  | v1.23.1-eksbuild.1  | ✓ SIM              | Pod network pode flutuar    | [ ]    |
| XXXXXXXXXX | Dev     | us-east-1 | kube-proxy         | v1.35.0-eksbuild.2  | v1.36.0-eksbuild.25 | ✓ SIM              | Network rules atualizam     | [ ]    |
| XXXXXXXXXX | Dev     | us-east-1 | coredns            | v1.13.2-eksbuild.1  | v1.14.3-eksbuild.23 | ✓ SIM              | DNS pode ter downtime breve | [ ]    |
| XXXXXXXXXX | Dev     | us-east-1 | aws-ebs-csi-driver | v1.55.0-eksbuild.2  | v1.66.0-eksbuild.1  | ✓ SIM              | Storage pode ter falha      | [ ]    |
| XXXXXXXXXX | Sandbox | us-east-1 | vpc-cni            | v1.21.1-eksbuild.3  | v1.23.1-eksbuild.1  | ✓ SIM              | Pod network pode flutuar    | [ ]    |
| XXXXXXXXXX | Sandbox | us-east-1 | kube-proxy         | v1.35.0-eksbuild.2  | v1.36.0-eksbuild.25 | ✓ SIM              | Network rules atualizam     | [ ]    |
| XXXXXXXXXX | Sandbox | us-east-1 | aws-ebs-csi-driver | v1.55.0-eksbuild.2  | v1.66.0-eksbuild.1  | ✓ SIM              | Storage pode ter falha      | [ ]    |
| XXXXXXXXXX | Prod    | sa-east-1 | vpc-cni            | v1.21.1-eksbuild.3  | v1.23.1-eksbuild.1  | ✓ SIM              | Pod network pode flutuar    | [ ]    |
| XXXXXXXXXX | Prod    | sa-east-1 | kube-proxy         | v1.35.3-eksbuild.2  | v1.36.0-eksbuild.25 | ✓ SIM              | Network rules atualizam     | [ ]    |
| XXXXXXXXXX | Prod    | sa-east-1 | coredns            | v1.13.2-eksbuild.4  | v1.14.3-eksbuild.23 | ✓ SIM              | DNS pode ter downtime breve | [ ]    |
| XXXXXXXXXX | Prod    | sa-east-1 | aws-ebs-csi-driver | v1.61.1-eksbuild.1  | v1.66.0-eksbuild.1  | ✓ SIM              | Storage pode ter falha      | [ ]    |

---

### ABA 3: CRONOGRAMA DE EXECUÇÃO

| Fase                | Ambiente | Cluster    | Ação Principal                                      | Data Proposta | Hora Início | Hora Fim | Duração Est. | Responsável | Escalação |
| ------------------- | -------- | ---------- | --------------------------------------------------- | ------------- | ----------- | -------- | ------------ | ----------- | --------- |
| **Fase 1A**         | Dev      | XXXXXXXXXX | Backup etcd → Control Plane → Add-ons → Node Groups | [ ]           | [ ]         | [ ]      | 2-3h         | [ ]         | [ ]       |
| **Fase 1B**         | Sandbox  | XXXXXXXXXX | Backup etcd → Control Plane → Add-ons → Node Groups | [ ]           | [ ]         | [ ]      | 2-3h         | [ ]         | [ ]       |
| **Decision Gate**   | —        | —          | Revisar Phase 1, confirmar go/no-go                 | [ ]           | —           | —        | 30min        | [ ]         | [ ]       |
| **Fase 2**          | Staging  | —          | N/A — Nenhum cluster EKS                            | —             | —           | —        | —            | —           | —         |
| **Fase 3**          | Prod     | XXXXXXXXXX | Backup etcd → Control Plane → Add-ons → Node Groups | [ ]           | 18h00+      | [ ]      | 2-3h         | [ ]         | [ ]       |
| **Validação Final** | —        | —          | Smoke test, confirmar todos em 1.36                 | [ ]           | +2h         | —        | 1h           | [ ]         | [ ]       |

---

### ABA 4: RISCOS E MITIGAÇÕES

| Risco                              | Probabilidade | Impacto     | Cluster(s)       | Mitigação                                   | Tempo Rollback | Status |
| ---------------------------------- | ------------- | ----------- | ---------------- | ------------------------------------------- | -------------- | ------ |
| Control Plane falha durante update | Baixa (2%)    | Alto        | Dev/Sandbox/Prod | AWS restaura etcd automaticamente           | 20-30min       | [ ]    |
| Pod de add-on faz CrashLoop        | Média (10%)   | Médio       | Dev/Sandbox/Prod | Downgrade imediato da versão                | 5-10min        | [ ]    |
| Node não consegue fazer upgrade    | Baixa (5%)    | Médio       | Dev/Sandbox/Prod | Cordon → drain → terminate e ASG relança    | 10-15min       | [ ]    |
| Aplicação falha com nova versão    | Média (15%)   | Alto (Prod) | Prod             | Investigar logs, rollback add-on específico | 30min-1h       | [ ]    |
| DNS falha (CoreDNS)                | Baixa (3%)    | Alto        | Dev/Sandbox/Prod | Rollback CoreDNS, validar resolução         | 5-10min        | [ ]    |
| Network I/O interrupção (vpc-cni)  | Média (8%)    | Alto        | Dev/Sandbox/Prod | Rollback vpc-cni, restabelecer CNI          | 10-15min       | [ ]    |

---

### ABA 5: CHECKLIST PÓS-ATUALIZAÇÃO

| Item                            | Dev | Sandbox | Prod | Evidence                              |
| ------------------------------- | --- | ------- | ---- | ------------------------------------- |
| Versão do cluster é 1.36        | [ ] | [ ]     | [ ]  | `kubectl version`                     |
| Todos os nós em Ready           | [ ] | [ ]     | [ ]  | `kubectl get nodes`                   |
| Todos os pods em Running        | [ ] | [ ]     | [ ]  | `kubectl get pods --all-namespaces`   |
| Sem eventos de erro no cluster  | [ ] | [ ]     | [ ]  | `kubectl get events --all-namespaces` |
| Métricas de CPU/Memória normais | [ ] | [ ]     | [ ]  | CloudWatch Metrics                    |
| Logs não têm erros críticos     | [ ] | [ ]     | [ ]  | CloudWatch Logs Insights              |

---


### Comando para obter os detalhes dos Node Groups

```bash
for cluster in XXXXXXXXXX XXXXXXXXXX; do
  echo "=== $cluster ==="
  aws eks describe-nodegroup \
    --cluster-name $cluster \
    --nodegroup-name $(aws eks list-nodegroups \
      --cluster-name $cluster \
      --region us-east-1 \
      --query 'nodegroups[0]' \
      --output text) \
    --region us-east-1 \
    --query 'nodegroup.[desiredSize,currentSize,maxSize]' \
    --output text
done

echo "=== Production ==="
aws eks describe-nodegroup \
  --cluster-name XXXXXXXXXX \
  --nodegroup-name $(aws eks list-nodegroups \
    --cluster-name XXXXXXXXXX \
    --region sa-east-1 \
    --query 'nodegroups[0]' \
    --output text) \
  --region sa-east-1 \
  --query 'nodegroup.[desiredSize,currentSize,maxSize]' \
  --output text
```
