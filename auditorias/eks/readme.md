## SCRIPT PARA CLOUDSHELL

Crie um arquivo chamado `eks-inventory.sh` no CloudShell e cole isso:

## COMO USAR

**0. (Opcional) Validar permissões antes de rodar:**

Se quiser confirmar que tem acesso necessário para listar clusters EKS:

```bash
aws iam simulate-principal-policy \
  --policy-source-arn $(aws sts get-caller-identity --query 'Arn' --output text) \
  --action-names eks:DescribeClusters eks:ListClusters eks:ListNodegroups eks:ListAddons eks:DescribeAddon \
  --resource-arns "*" \
  --query 'EvaluationResults[*].[EvalActionName,EvalDecision]' \
  --output table
```

Se todos retornarem `allowed`, você está pronto. Se algum retornar `implicitDeny`, avise que precisa de permissões adicionais.

Se der erro (tipo "role not found"), significa que o nome da role é diferente. Nesse caso, rode:

```bash
aws iam get-role --role-name beatriz-cevaio-darede --query 'Role.Arn' --output text
```

E use o ARN que retornar no comando acima.

---

**1. No CloudShell, copie e cole o script acima em um arquivo:**
```bash
nano eks-inventory.sh
```

**2. Dê permissão de execução:**
```bash
chmod +x eks-inventory.sh
```

**3. Execute para cada conta (substitua PERFIL e NOME):**

```bash
./eks-inventory.sh default Development
./eks-inventory.sh default Sandbox
./eks-inventory.sh default Staging
./eks-inventory.sh default Production
```

Se você estiver usando profiles do AWS CLI diferentes, substitua `default` pelo seu profile.

---

## O QUE O SCRIPT FAZ

1. Detecta todas as regiões ativas na conta automaticamente
2. Para cada região, lista todos os clusters EKS
3. Para cada cluster, coleta:
   - Versão do control plane
   - Status
   - ARN
   - Add-ons instalados (com versões)
   - Node groups (com versões dos nós)
4. Formata tudo em tabelas legíveis
