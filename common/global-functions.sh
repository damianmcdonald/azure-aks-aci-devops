#!/bin/bash

# ##################################################
# Global functions definidos por el proyecto Prueba de Concepto.
# Los functions son utilizado por los otros scripts.
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

###########################################################
#                                                         #
# Function declarations                                   #
#                                                         #
###########################################################

###########################################################
#                                                         #
# Function para dellocate macquinas virtuales            #
#                                                         #
###########################################################
deallocateVmss()
{
  local AKS_CLUSTER_NAME=$1
  local AKS_RESOURCE_GROUP=MC_${RESOURCE_GROUP}_${AKS_CLUSTER_NAME}_${AZURE_LOCATION}
  echo "AKS_RESOURCE_GROUP == $AKS_RESOURCE_GROUP"
  local VMSS_NAME=$(az vmss list --resource-group $AKS_RESOURCE_GROUP --query "[].name" -o tsv)
  az vmss deallocate --resource-group $AKS_RESOURCE_GROUP --name $VMSS_NAME
}

###########################################################
#                                                         #
# Function para arancar las macquinas virtuales del VMSS  #
#                                                         #
###########################################################
allocateVmss()
{
  local AKS_CLUSTER_NAME=$1
  local AKS_RESOURCE_GROUP=MC_${RESOURCE_GROUP}_${AKS_CLUSTER_NAME}_${AZURE_LOCATION}
  echo "AKS_RESOURCE_GROUP == $AKS_RESOURCE_GROUP"
  local VMSS_NAME=$(az vmss list --resource-group $AKS_RESOURCE_GROUP --query "[].name" -o tsv)
  az vmss start --resource-group $AKS_RESOURCE_GROUP --name $VMSS_NAME
}

###########################################################
#                                                         #
# Function para obtener el External IP de un servicio en  #
# kubernetes                                              #
#                                                         #
###########################################################
waitExternalIpCreate()
{
  local SERVICE_NAME=$1
  local SERVICE_IP=""
  local ATTEMPTS=1
  local MAX_ATTEMPTS=10
  local SLEEP_TIME=30s
  until [[ $SERVICE_IP != "" ]]
  do
    if [[ $ATTEMPTS == $MAX_ATTEMPTS ]]
    then
      echo -e "[${RED}FATAL${NC}] Lo siento, no se puso obtener un External IP por $SERVICE_NAME :(";
      break
    fi
    SERVICE_IP=$(kubectl get svc --namespace default $SERVICE_NAME -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    sleep $SLEEP_TIME
    ((ATTEMPTS++))
  done
  echo $SERVICE_IP
}

###########################################################
#                                                         #
# Function para confirmar que un despliegue en kubernetes #
# ha cumplido con exito                                   #
#                                                         #
###########################################################
waitDeploymentCreate()
{
  local SERVICE_NAME=$1
  local IS_CREATED=""
  local ATTEMPTS=1
  local MAX_ATTEMPTS=10
  local SLEEP_TIME=30s
  local RESULT=""
  until [[ $IS_CREATED != "" ]]
  do
    if [[ $ATTEMPTS == $MAX_ATTEMPTS ]]
    then
      echo -e "[${RED}FATAL${NC}] Lo siento, no se puso obtener un External IP por $SERVICE_NAME :(";
      break
    fi
    $(kubectl get pods --namespace default | grep -q $SERVICE_NAME)
    GREP_RESULT=$?
    if [[ $GREP_RESULT == 0 ]]
    then
      RESULT="$SERVICE_NAME ha sido desplegado correctamente.";
      IS_CREATED="true"
      break
    else
      RESULT="Lo siento, $SERVICE_NAME no ha diso desplegado correctamente :(";
    fi
    sleep $SLEEP_TIME
    ((ATTEMPTS++))
  done
  echo "$RESULT"
}

###########################################################
#                                                         #
# Function para confirmar que un PVC en kubernetes        #
# ha cumplido con exito                                   #
#                                                         #
###########################################################
waitPvcCreate()
{
  local SERVICE_NAME=$1
  local IS_CREATED=""
  local ATTEMPTS=1
  local MAX_ATTEMPTS=10
  local SLEEP_TIME=30s
  local RESULT=""
  until [[ $IS_CREATED != "" ]]
  do
    if [[ $ATTEMPTS == $MAX_ATTEMPTS ]]
    then
      echo -e "[${RED}FATAL${NC}] Lo siento, no se puso obtener un External IP por $SERVICE_NAME :(";
      break
    fi
    $(kubectl get pvc --namespace default | grep -q $SERVICE_NAME)
    GREP_RESULT=$?
    if [[ $GREP_RESULT == 0 ]]
    then
      RESULT="$SERVICE_NAME ha sido desplegado correctamente.";
      IS_CREATED="true"
      break
    else
      RESULT="Lo siento, $SERVICE_NAME no ha diso desplegado correctamente :(";
    fi
    sleep $SLEEP_TIME
    ((ATTEMPTS++))
  done
  echo "$RESULT"
}

###########################################################
#                                                         #
# Creacion de un script para destruir el Resource Group   #
#                                                         #
###########################################################
createResourceGroupDestroyScript()
{
local SCRIPT_FILE=$1
local l_RESOURCE_GROUP=$2

# delete any previous instance of $SCRIPT_FILE
if [ -f "$SCRIPT_FILE" ]; then
    rm $SCRIPT_FILE
fi

cat > $SCRIPT_FILE <<EOF
#!/bin/bash

# Colors
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT_GRAY='\033[0;37m'
DARK_GRAY='\033[1;30m'
LIGHT_RED='\033[1;31m'
LIGHT_GREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHT_BLUE='\033[1;34m'
LIGHT_PURPLE='\033[1;35m'
LIGHT_CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

echo -e "[${LIGHT_BLUE}INFO${NC}] Terminando el Resource Group ${YELLOW}$l_RESOURCE_GROUP${NC} ....";
az group delete --resource-group $l_RESOURCE_GROUP
EOF

chmod +x $SCRIPT_FILE
}

###########################################################
#                                                         #
# Creacion de un script para destruir el AKS Cluster      #
#                                                         #
###########################################################
createClusterDestroyScript()
{
local SCRIPT_FILE=$1
local l_RESOURCE_GROUP=$2
local AKS_CLUSTER_NAME=$3

# delete any previous instance of $SCRIPT_FILE
if [ -f "$SCRIPT_FILE" ]; then
    rm $SCRIPT_FILE
fi

cat > $SCRIPT_FILE <<EOF
#!/bin/bash

# Colors
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT_GRAY='\033[0;37m'
DARK_GRAY='\033[1;30m'
LIGHT_RED='\033[1;31m'
LIGHT_GREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHT_BLUE='\033[1;34m'
LIGHT_PURPLE='\033[1;35m'
LIGHT_CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

echo -e "[${LIGHT_BLUE}INFO${NC}] Terminando el AKS Cluster ${YELLOW}$AKS_CLUSTER_NAME${NC} ....";
az aks delete --name $AKS_CLUSTER_NAME--resource-group $l_RESOURCE_GROUP
EOF

chmod +x $SCRIPT_FILE
}

###########################################################
#                                                         #
# Creacion de un script para arancar el AKS Cluster       #
#                                                         #
###########################################################
createClusterStartScript()
{
local SCRIPT_FILE=$1
local AKS_CLUSTER_NAME=$2

# delete any previous instance of $SCRIPT_FILE
if [ -f "$SCRIPT_FILE" ]; then
    rm $SCRIPT_FILE
fi

cat > $SCRIPT_FILE <<EOF
#!/bin/bash

# load external scripts
source $PWD/common/global-functions.sh

# Colors
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT_GRAY='\033[0;37m'
DARK_GRAY='\033[1;30m'
LIGHT_RED='\033[1;31m'
LIGHT_GREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHT_BLUE='\033[1;34m'
LIGHT_PURPLE='\033[1;35m'
LIGHT_CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

echo -e "[${LIGHT_BLUE}INFO${NC}] Dellocating the virtual machines of the AKS Cluster ${YELLOW}$AKS_CLUSTER_NAME${NC} ....";
# Due to an issue with bash substiution, we can't include the allocate command in this file.
# We use this file as a facade/entrypoint to call the allocateVmss function in file
# $PWD/common/global-functions.sh
allocateVmss $AKS_CLUSTER_NAME
EOF

chmod +x $SCRIPT_FILE
}

###########################################################
#                                                         #
# Creacion de un script para apagar el AKS Cluster        #
#                                                         #
###########################################################
createClusterStopScript()
{
local SCRIPT_FILE=$1
local AKS_CLUSTER_NAME=$2

# delete any previous instance of $SCRIPT_FILE
if [ -f "$SCRIPT_FILE" ]; then
    rm $SCRIPT_FILE
fi

cat > $SCRIPT_FILE <<EOF
#!/bin/bash

# load external scripts
source $PWD/common/global-functions.sh

# Colors
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT_GRAY='\033[0;37m'
DARK_GRAY='\033[1;30m'
LIGHT_RED='\033[1;31m'
LIGHT_GREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHT_BLUE='\033[1;34m'
LIGHT_PURPLE='\033[1;35m'
LIGHT_CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

echo -e "[${LIGHT_BLUE}INFO${NC}] Obtaining virtual machines for the AKS Cluster ${YELLOW}$AKS_CLUSTER_NAME${NC} ....";
# Due to an issue with bash substiution, we can't include the deallocate command in this file.
# We use this file as a facade/entrypoint to call the deallocateVmss function in file
# $PWD/common/global-functions.sh
deallocateVmss $AKS_CLUSTER_NAME
EOF

chmod +x $SCRIPT_FILE
}

###########################################################
#                                                         #
# Creacion de un script para destruir el                  #
# Azure Container Instance                                #
#                                                         #
###########################################################
createContainerDestroyScript()
{
local SCRIPT_FILE=$1
local l_RESOURCE_GROUP=$2
local CONTAINER_GROUP=$3

# delete any previous instance of $SCRIPT_FILE
if [ -f "$SCRIPT_FILE" ]; then
    rm $SCRIPT_FILE
fi

cat > $SCRIPT_FILE <<EOF
#!/bin/bash

# Colors
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT_GRAY='\033[0;37m'
DARK_GRAY='\033[1;30m'
LIGHT_RED='\033[1;31m'
LIGHT_GREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHT_BLUE='\033[1;34m'
LIGHT_PURPLE='\033[1;35m'
LIGHT_CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

echo -e "[${LIGHT_BLUE}INFO${NC}] Apagando el Container Instance ${YELLOW}$CONTAINER_GROUP${NC} ....";
az container delete --name $CONTAINER_GROUP --resource-group $l_RESOURCE_GROUP
EOF

chmod +x $SCRIPT_FILE
}

###########################################################
#                                                         #
# Creacion de un script para arancar el                   #
# Azure Container Instance                                #
#                                                         #
###########################################################
createContainerStartScript()
{
local SCRIPT_FILE=$1
local l_RESOURCE_GROUP=$2
local CONTAINER_GROUP=$3

# delete any previous instance of $SCRIPT_FILE
if [ -f "$SCRIPT_FILE" ]; then
    rm $SCRIPT_FILE
fi

cat > $SCRIPT_FILE <<EOF
#!/bin/bash

# Colors
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT_GRAY='\033[0;37m'
DARK_GRAY='\033[1;30m'
LIGHT_RED='\033[1;31m'
LIGHT_GREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHT_BLUE='\033[1;34m'
LIGHT_PURPLE='\033[1;35m'
LIGHT_CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

echo -e "[${LIGHT_BLUE}INFO${NC}] Arancando el Container Instance ${YELLOW}$CONTAINER_GROUP${NC} ....";
az container start --name $CONTAINER_GROUP --resource-group $l_RESOURCE_GROUP
EOF

chmod +x $SCRIPT_FILE
}

###########################################################
#                                                         #
# Creacion de un script para apagar el                    #
# Azure Container Instance                                #
#                                                         #
###########################################################
createContainerStopScript()
{
local SCRIPT_FILE=$1
local l_RESOURCE_GROUP=$2
local CONTAINER_GROUP=$3

# delete any previous instance of $SCRIPT_FILE
if [ -f "$SCRIPT_FILE" ]; then
    rm $SCRIPT_FILE
fi

cat > $SCRIPT_FILE <<EOF
#!/bin/bash

# Colors
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT_GRAY='\033[0;37m'
DARK_GRAY='\033[1;30m'
LIGHT_RED='\033[1;31m'
LIGHT_GREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHT_BLUE='\033[1;34m'
LIGHT_PURPLE='\033[1;35m'
LIGHT_CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

echo -e "[${LIGHT_BLUE}INFO${NC}] Apagando el Container Instance ${YELLOW}$CONTAINER_GROUP${NC} ....";
az container stop --name $CONTAINER_GROUP --resource-group $l_RESOURCE_GROUP
EOF

chmod +x $SCRIPT_FILE
}
