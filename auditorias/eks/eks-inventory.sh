#!/bin/bash

# ============================================
# Script de Levantamento de Clusters EKS
# Detecta regiões ativas e coleta dados
# ============================================

PROFILE="${1:-default}"
ACCOUNT_NAME="${2:-Unknown}"

echo "=========================================="
echo "LEVANTAMENTO EKS - Conta: $ACCOUNT_NAME"
echo "Profile: $PROFILE"
echo "=========================================="
echo ""

# Detectar regiões ativas
echo "Detectando regiões ativas..."
REGIOES=$(aws ec2 describe-regions --all-regions --query 'Regions[?OptInStatus!=`not-opted-in`].RegionName' --output text --profile $PROFILE 2>/dev/null)

if [ -z "$REGIOES" ]; then
    echo "Erro ao detectar regiões. Tente novamente ou verifique credenciais."
    exit 1
fi

echo "Regiões ativas: $REGIOES"
echo ""

# Para cada região, listar clusters
for REGIAO in $REGIOES; do
    echo ">>> REGIÃO: $REGIAO"
    
    CLUSTERS=$(aws eks list-clusters --region $REGIAO --profile $PROFILE --query 'clusters[]' --output text 2>/dev/null)
    
    if [ -z "$CLUSTERS" ]; then
        echo "  Nenhum cluster encontrado nesta região."
        echo ""
        continue
    fi
    
    # Para cada cluster
    for CLUSTER in $CLUSTERS; do
        echo ""
        echo "  CLUSTER: $CLUSTER"
        
        # Versão e status do cluster
        aws eks describe-cluster --name $CLUSTER --region $REGIAO --profile $PROFILE \
            --query 'cluster.[version,name,arn,status,createdAt]' \
            --output table 2>/dev/null
        
        echo ""
        echo "  Add-ons instalados:"
        
        # Listar add-ons
        ADDONS=$(aws eks list-addons --cluster-name $CLUSTER --region $REGIAO --profile $PROFILE --query 'addons[]' --output text 2>/dev/null)
        
        if [ -z "$ADDONS" ]; then
            echo "    Nenhum add-on gerenciado encontrado."
        else
            for ADDON in $ADDONS; do
                aws eks describe-addon --cluster-name $CLUSTER --addon-name $ADDON --region $REGIAO --profile $PROFILE \
                    --query "addon.[addonName,addonVersion,status,createdAt]" \
                    --output table 2>/dev/null
            done
        fi
        
        echo ""
        echo "  Node Groups:"
        
        # Listar node groups
        NODEGROUPS=$(aws eks list-nodegroups --cluster-name $CLUSTER --region $REGIAO --profile $PROFILE --query 'nodegroups[]' --output text 2>/dev/null)
        
        if [ -z "$NODEGROUPS" ]; then
            echo "    Nenhum node group encontrado."
        else
            for NG in $NODEGROUPS; do
                echo "    - $NG"
                aws eks describe-nodegroup --cluster-name $CLUSTER --nodegroup-name $NG --region $REGIAO --profile $PROFILE \
                    --query 'nodegroup.[nodegroupName,version,instanceTypes,desiredSize,currentSize,maxSize,status]' \
                    --output table 2>/dev/null
            done
        fi
        
        echo ""
        echo "---"
    done
    
    echo ""
done

echo "=========================================="
echo "FIM DO LEVANTAMENTO"
echo "=========================================="
