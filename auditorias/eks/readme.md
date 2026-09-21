## SCRIPT PARA CLOUDSHELL

Crie um arquivo chamado `eks-inventory.sh` no CloudShell e cole isso:

## COMO USAR

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
