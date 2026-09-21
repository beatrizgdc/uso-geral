#!/bin/bash

# ============================================
# Script de Levantamento de Clusters EKS
# Detecta regiões ativas e coleta dados
# ============================================

ACCOUNT_NAME="${1:-Sandbox}"

echo "=========================================="
echo "LEVANTAMENTO EKS - Conta: $ACCOUNT_NAME"
echo "=========================================="
echo ""

# Regiões ativas (detectadas automaticamente)
REGIOES=$(aws ec2 describe-regions --query 'Regions[].RegionName' --output text)

echo "Regiões a verificar: $REGIOES"
echo ""

# Para cada região, listar clusters
for REGIAO in $REGIOES; do
    echo ">>> REGIÃO: $REGIAO"
    
    CLUSTERS=$(aws eks list-clusters --region $REGIAO --query 'clusters[]' --output text 2>/dev/null)
    
    if [ -z "$CLUSTERS" ]; then
        echo "  ✗ Nenhum cluster encontrado"
        echo ""
        continue
    fi
    
    echo "  ✓ Clusters encontrados: $CLUSTERS"
    echo ""
    
    # Para cada cluster
    for CLUSTER in $CLUSTERS; do
        echo "  ─── CLUSTER: $CLUSTER ───"
        
        # Versão e status do cluster
        echo "  Detalhes do Cluster:"
        aws eks describe-cluster --name $CLUSTER --region $REGIAO \
            --query 'cluster.[name,version,status,arn]' \
            --output table 2>/dev/null
        
        echo ""
        echo "  Add-ons Instalados:"
        
        # Listar add-ons
        ADDONS=$(aws eks list-addons --cluster-name $CLUSTER --region $REGIAO --query 'addons[]' --output text 2>/dev/null)
        
        if [ -z "$ADDONS" ]; then
            echo "    (nenhum add-on gerenciado)"
        else
            for ADDON in $ADDONS; do
                aws eks describe-addon --cluster-name $CLUSTER --addon-name $ADDON --region $REGIAO \
                    --query "addon.[addonName,addonVersion,status]" \
                    --output table 2>/dev/null
            done
        fi
        
        echo ""
        echo "  Node Groups:"
        
        # Listar node groups
        NODEGROUPS=$(aws eks list-nodegroups --cluster-name $CLUSTER --region $REGIAO --query 'nodegroups[]' --output text 2>/dev/null)
        
        if [ -z "$NODEGROUPS" ]; then
            echo "    (nenhum node group)"
        else
            for NG in $NODEGROUPS; do
                echo "    - $NG"
                aws eks describe-nodegroup --cluster-name $CLUSTER --nodegroup-name $NG --region $REGIAO \
                    --query 'nodegroup.[version,instanceTypes,desiredSize,currentSize,status]' \
                    --output table 2>/dev/null
            done
        fi
        
        echo ""
    done
    
done

echo "=========================================="
echo "FIM DO LEVANTAMENTO - $ACCOUNT_NAME"
echo "=========================================="
