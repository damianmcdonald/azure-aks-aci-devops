#!/bin/bash

# ##################################################
# Master script que crea un Poc de DevOps que es
# montado en la nube de Microsoft (Azure).
#
# PoC ENTORNO DEVOPS es un entorno Prueba de Concepto
# que es montado en Azure para proporcionar un entorno
# real que puede ser utilizando para practicar tecnicas
# y experimentar.
#
# El entorno consiste en:
#
# * Azure Resource Group
# * AKS Cluster (Azure Kubernetes Service)
# * Container Instance
# * DNS Zone y DNS Records
# * Azure File Storage
#
# AUTHORS:
#
# * Damian McDonald - damian.mcdonald.tcs at gmail.com
#
# HISTORY:
#
# * DATE - v1.0.0  - Creacion Inicial
#
# ##################################################

###########################################################
#                                                         #
# Load external scripts                                   #
#                                                         #
###########################################################
source $PWD/common/global-constants.sh
source $PWD/common/global-functions.sh

###########################################################
#                                                         #
# Variable declarations                                   #
#                                                         #
###########################################################
CREATE_AKS_CLUSTER_SCRIPT=$PWD/aks-clusters/create-aks-cluster.sh
CREATE_CONTAINER_INSTANCE_SCRIPT=$PWD/container-instances/create-container-instance.sh
DESTROY_SCRIPT=$PWD/destroy-devops-poc.sh

###########################################################
#                                                         #
# Azure Resource Group Creation                           #
#                                                         #
###########################################################
echo -e "[${LIGHT_BLUE}INFO${NC}] Creando el Resource Group ${YELLOW}$RESOURCE_GROUP${NC} en ${YELLOW}$AZURE_LOCATION${NC} ....";
az group create --name $RESOURCE_GROUP --location $AZURE_LOCATION

###########################################################
#                                                         #
# Azure DNS Zone Creation                                 #
#                                                         #
###########################################################
echo ""
echo -e "[${LIGHT_BLUE}INFO${NC}] Creando un DNS zone ${YELLOW}$DNS_ZONE${NC} en Resource Group ${YELLOW}$RESOURCE_GROUP${NC} ....";
az network dns zone create -g $RESOURCE_GROUP  -n $DNS_ZONE

###########################################################
#                                                         #
# Environment info file creation                          #
#                                                         #
###########################################################
AZURE_DISPLAY_NAME=$(az ad signed-in-user show --query "displayName" --output tsv)
AZURE_SUBSCRIPTION_DETAILS=$(az account show --output yaml)

# delete any previous instance of $ENV_INFO_FILE
if [ -f "$ENV_INFO_FILE" ]; then
    rm $ENV_INFO_FILE
fi

cat > $ENV_INFO_FILE <<EOF
#########################################################
#                                                       #
#           PoC ENTORNO DEVOPS Informacion              #
#                                                       #
#########################################################

PoC ENTORNO DEVOPS es un entorno Prueba de Concepto que es montado
en Azure para proporcionar un entorno real que puede ser utilizado
para practicar tecnicas y experimentar.

El entorno consiste en:

* Azure Resource Group
* AKS Cluster (Azure Kubernetes Service)
* Container Instance
* DNS Zone y DNS Records
* Azure File Storage

## Detalles ##

Azure location:       $AZURE_LOCATION
Resource Group:       $RESOURCE_GROUP
DNS Zone:             $DNS_ZONE

El entorno ha sido creado por $AZURE_DISPLAY_NAME

Abajo se puede ver los detalles del suscripcion de Azure:

$AZURE_SUBSCRIPTION_DETAILS

Abajo hay un enlace que se puede utilizar para calcular los costes del entorno

https://azure.microsoft.com/en-us/pricing/calculator/

Abajo hay un enlace que se puede utilizar para verificar el estado de los servicios de Azure

https://status.azure.com/en-us/status
EOF

###########################################################
#                                                         #
# Azure AKS Cluster Creation                              #
#                                                         #
###########################################################
$CREATE_AKS_CLUSTER_SCRIPT $PWD

###########################################################
#                                                         #
# Azure AKS Container Instance Creation                   #
#                                                         #
###########################################################
$CREATE_CONTAINER_INSTANCE_SCRIPT $PWD

###########################################################
#                                                         #
# Destroy Resource Group script creation                  #
#                                                         #
###########################################################
createResourceGroupDestroyScript $DESTROY_SCRIPT $RESOURCE_GROUP

###########################################################
#                                                         #
# Anadir los detalles del Resource Group                  #
# al fichero ENV-INFO.txt                                 #
#                                                         #
###########################################################
AZURE_RESOURCES=$(az resource list --resource-group $RESOURCE_GROUP --output table)

cat <<EOT >> $ENV_INFO_FILE

#########################################################
#                                                       #
#           Azure Resource Group Informacion            #
#                                                       #
#########################################################

Abajo se puede ver los detalles de los recursos que han sido creado por el entorno:

$AZURE_RESOURCES
EOT
