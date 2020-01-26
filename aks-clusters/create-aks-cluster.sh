#!/bin/bash

# ##################################################
# Script que crea un AKS (Azure Kubrntes Service) Cluster.
#
# https://docs.microsoft.com/es-es/azure/aks/
# https://azure.microsoft.com/es-es/pricing/details/kubernetes-service/
#
# El Azure Kubernetes Service contiene los siguentes servidores:
# * Gitlab-CE
# * Jenkins
# * Tomcat
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
# Parametros del script                                   #
#                                                         #
###########################################################
# El working directory del master script (create-devops-poc.sh)
ROOT_WORKING_DIR=$1

###########################################################
#                                                         #
# Load external scripts                                   #
#                                                         #
###########################################################
source $ROOT_WORKING_DIR/common/global-constants.sh
source $ROOT_WORKING_DIR/common/global-functions.sh

###########################################################
#                                                         #
# Variable declarations                                   #
#                                                         #
###########################################################
AKS_CLUSTER_NAME=poc-cluster
AKS_NODE_COUNT=2
GITLAB_NAME=gitlab
JENKINS_NAME=jenkins
TOMCAT_NAME=tomcat
DEPLOYMENT_TIMEOUT=600s
START_SCRIPT=$ROOT_WORKING_DIR/aks-clusters/start-aks-cluster.sh
STOP_SCRIPT=$ROOT_WORKING_DIR/aks-clusters/stop-aks-cluster.sh
DESTROY_SCRIPT=$ROOT_WORKING_DIR/aks-clusters/destroy-aks-cluster.sh

###########################################################
#                                                         #
# Creacion del AKS Cluster                                #
#                                                         #
###########################################################
echo ""
echo -e "[${LIGHT_BLUE}INFO${NC}] Creando el AKS cluster ${YELLOW}$AKS_CLUSTER_NAME${NC} en ${YELLOW}$AZURE_LOCATION${NC} ....";
echo -e "[${LIGHT_BLUE}INFO${NC}] La creacion del AKS cluster puede tardar hasta 40 minutos. Toma un cafe!!!";
az aks create --resource-group $RESOURCE_GROUP \
  --name $AKS_CLUSTER_NAME \
  --node-count $AKS_NODE_COUNT \
  --enable-addons monitoring,http_application_routing \
  --generate-ssh-keys

# Grab credentials to be able to access the AKS cluster
echo ""
echo -e "[${LIGHT_BLUE}INFO${NC}] Obteniendo los credentiales para acceder el AKS cluster ${YELLOW}$AKS_CLUSTER_NAME${NC} en ${YELLOW}$AZURE_LOCATION${NC} ....";
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --overwrite-existing

###########################################################
#                                                         #
# Inicializacion de HELM                                  #
#                                                         #
###########################################################
echo ""
echo -e "[${LIGHT_BLUE}INFO${NC}] Añadiendo charts en helm ....";
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm repo update

###########################################################
#                                                         #
# Despliegue de Gitlab-CE                                 #
#                                                         #
###########################################################
# Install Gitlab-CE Chart
echo ""
echo -e "[${LIGHT_BLUE}INFO${NC}] Instalando Gitlab-CE en AKS con helm ....";
helm upgrade --install $GITLAB_NAME stable/gitlab-ce --wait --timeout $DEPLOYMENT_TIMEOUT --set externalUrl=http://$GITLAB_NAME.$DNS_ZONE

# Create a DNS record for Gitlab
echo ""
GITLAB_EXTERNAL_IP=$(kubectl get svc --namespace default gitlab-gitlab-ce -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [[ -z "$GITLAB_EXTERNAL_IP" ]]
then
  echo -e "[${RED}ERROR${NC}] No puse obtener un External IP por Gitlab :(";
else
  echo -e "[${LIGHT_BLUE}INFO${NC}] Creando un DNS record por Gitlab con External IP ${YELLOW}$GITLAB_EXTERNAL_IP${NC} ....";
  az network dns record-set a add-record \
    -g $RESOURCE_GROUP \
    -z $DNS_ZONE \
    -n $GITLAB_NAME \
    -a $GITLAB_EXTERNAL_IP
fi

###########################################################
#                                                         #
# Despliegue de Jenkins                                   #
#                                                         #
###########################################################
# Install Jenkins
echo ""
echo -e "[${LIGHT_BLUE}INFO${NC}] Creando Jenkins en AKS ....";
kubectl create -f "${ROOT_WORKING_DIR}/kubernetes/${JENKINS_NAME}"

echo -e "[${LIGHT_BLUE}INFO${NC}] Esperando la creacion del Persistent Volume Claim de Jenkins ....";
# wait for the PVC to be created
waitPvcCreate "$JENKINS_NAME"

echo -e "[${LIGHT_BLUE}INFO${NC}] Esperando el despliegue de Jenkins en Kubernetes ....";
# wait for the deployment to be created
waitDeploymentCreate "$JENKINS_NAME"

echo -e "[${LIGHT_BLUE}INFO${NC}] Esperando la creacion de un Exteral IP por Jenkins ....";
# wait for an external IP to be assigned
JENKINS_EXTERNAL_IP=$(waitExternalIpCreate "$JENKINS_NAME")

# Create a DNS record for Jenkins
echo ""
if [[ -z "$JENKINS_EXTERNAL_IP" ]]
then
  echo -e "[${RED}ERROR${NC}] No puse obtener un External IP por Jenkins :(";
else
  echo -e "[${LIGHT_BLUE}INFO${NC}] Creando un DNS record por Jenkins con External IP ${YELLOW}$JENKINS_EXTERNAL_IP${NC} ....";
  az network dns record-set a add-record \
    -g $RESOURCE_GROUP \
    -z $DNS_ZONE \
    -n $JENKINS_NAME \
    -a $JENKINS_EXTERNAL_IP
fi

###########################################################
#                                                         #
# Despliegue de Tomcat                                    #
#                                                         #
###########################################################
# Install Tomcat Chart
echo ""
echo -e "[${LIGHT_BLUE}INFO${NC}] Creando Jenkins en AKS ....";

echo -e "[${LIGHT_BLUE}INFO${NC}] Instalando Tomcat deployment ....";
kubectl create -f "${ROOT_WORKING_DIR}/kubernetes/${TOMCAT_NAME}"

echo -e "[${LIGHT_BLUE}INFO${NC}] Esperando el despliegue de Tomcat en Kubernetes ....";
# wait for the deployment to be created
waitDeploymentCreate "$TOMCAT_NAME"

echo -e "[${LIGHT_BLUE}INFO${NC}] Esperando la creacion de un Exteral IP por Tomcat ....";
# wait for an external IP to be assigned
TOMCAT_EXTERNAL_IP=$(waitExternalIpCreate "$TOMCAT_NAME")

# Create a DNS record for Tomcat
echo ""
if [[ -z "$TOMCAT_EXTERNAL_IP" ]]
then
  echo -e "[${RED}ERROR${NC}] No puse obtener un External IP por Tomcat :(";
else
  echo -e "[${LIGHT_BLUE}INFO${NC}] Creando un DNS record por Tomcat con External IP ${YELLOW}$TOMCAT_EXTERNAL_IP${NC} ....";
  az network dns record-set a add-record \
    -g $RESOURCE_GROUP \
    -z $DNS_ZONE \
    -n $TOMCAT_NAME \
    -a $TOMCAT_EXTERNAL_IP
fi

###########################################################
#                                                         #
# Creacion de los scripts de automatizacion               #
#                                                         #
###########################################################
createClusterDestroyScript $DESTROY_SCRIPT $RESOURCE_GROUP $AKS_CLUSTER_NAME
createClusterStartScript $START_SCRIPT $AKS_CLUSTER_NAME
createClusterStopScript $STOP_SCRIPT $AKS_CLUSTER_NAME

###########################################################
#                                                         #
# Mostrar los detalles del entorno en la consola          #
#                                                         #
###########################################################
echo -e "#########################################################"
echo -e "#                                                       #"
echo -e "#        Azure Container Instance Informacion           #"
echo -e "#                                                       #"
echo -e "#########################################################"
echo  ""
echo -e "Cluster Name:         $AKS_CLUSTER_NAME"
echo -e "Cluster Node Count:   $AKS_NODE_COUNT"
echo -e "Azure location:       $AZURE_LOCATION"
echo -e "Resource Group:       $RESOURCE_GROUP"
echo -e "Mas informacion:      https://docs.microsoft.com/es-es/azure/aks/"
echo -e "                      https://azure.microsoft.com/es-es/pricing/details/kubernetes-service/"
echo ""
echo -e "Gitlab URL:           http://$GITLAB_EXTERNAL_IP"
echo -e "Jenkins URL:          http://$JENKINS_EXTERNAL_IP:7575"
echo -e "Tomcat URL:           http://$TOMCAT_EXTERNAL_IP:7895"
echo ""
echo -e "## GITLAB ##"
echo ""
echo -e "Gitlab URL:           http://$GITLAB_EXTERNAL_IP"
echo -e "Gitlab Username:      root"
echo -e "Gitlab Password:      hay que elegir un password al primer aceso"
echo -e "Mas informacion:      https://github.com/helm/charts/tree/master/stable/gitlab-ce"
echo ""
echo -e "## JENKINS ##"
echo ""
echo -e "Jenkins URL:          http://$JENKINS_EXTERNAL_IP:7575"
echo -e "Jenkins Username:     hay que elegir"
echo -e "Jenkins Password:     el password para primer aceso es generado automaticamente"
echo -e "                      Para obtener el password, hay que utilizar lo siguentes mandos"
echo ""
echo -e "                      kubectl get pods"
echo -e "                      kubectl exec -it jenkins-deployment-XXXXXX -- cat /var/jenkins_home/secrets/initialAdminPassword"
echo ""
echo -e "Mas informacion:      https://bitbucket.org/damianmcdonald/entorno-ci-cd-azure-k8s/src/master/docker/jenkins"
echo ""
echo -e "## TOMCAT ##"
echo ""
echo -e "Tomcat URL:           http://$TOMCAT_EXTERNAL_IP:7895"
echo -e "Tomcat Username:      admin"
echo -e "Tomcat Password:      unisys2020"
echo -e "Mas informacion:      https://bitbucket.org/damianmcdonald/entorno-ci-cd-azure-k8s/src/master/docker/tomcat"
echo ""
echo -e "## OPERACIONES ##"
echo ""
echo -e "Para administrar un AKS cluster tienes que utilizar el mando: kubectl"
echo ""
echo -e "kubectl es una herremienta muy potente con mil opciones."
echo ""
echo -e "Aqui abajo es una chuleta de mandos de kubectl, es una referencia muy util!"
echo ""
echo -e "https://kubernetes.io/docs/reference/kubectl/cheatsheet/"
echo ""
echo -e "## SCRIPTS ##"
echo ""
echo -e "Hay scripts para facilitar la automatizacion del AKS Cluster."
echo ""
echo -e "# Arancar el cluster"
echo -e "$START_SCRIPT"
echo ""
echo -e "# Apagar el cluster"
echo -e "$STOP_SCRIPT"
echo ""
echo -e "# Destruir el cluster - ATTENCION, se pierde los datos!!"
echo -e "$DESTROY_SCRIPT"

###########################################################
#                                                         #
# Anadir los detalles del AKS Cluster                     #
# al fichero ENV-INFO.txt                                 #
#                                                         #
###########################################################

cat <<EOT >> $ENV_INFO_FILE

#########################################################
#                                                       #
#            Azure AKS Cluster Informacion              #
#                                                       #
#########################################################

Cluster Name:         $AKS_CLUSTER_NAME
Cluster Node Count:   $AKS_NODE_COUNT
Azure location:       $AZURE_LOCATION
Resource Group:       $RESOURCE_GROUP
Mas informacion:      https://docs.microsoft.com/es-es/azure/aks/
                      https://azure.microsoft.com/es-es/pricing/details/kubernetes-service/

Gitlab URL:           http://$GITLAB_EXTERNAL_IP
Jenkins URL:          http://$JENKINS_EXTERNAL_IP:7575
Tomcat URL:           http://$TOMCAT_EXTERNAL_IP:7895

## GITLAB ##

Gitlab URL:           http://$GITLAB_EXTERNAL_IP
Gitlab Username:      root
Gitlab Password:      hay que elegir un password al primer aceso
Mas informacion:      https://github.com/helm/charts/tree/master/stable/gitlab-ce

## JENKINS ##

Jenkins URL:          http://$JENKINS_EXTERNAL_IP:7575
Jenkins Username:     hay que elegir al primer aceso
Jenkins Password:     el password para primer aceso es generado automaticamente
                      Para obtener el password, hay que utilizar lo siguentes mandos

                      kubectl get pods
                      kubectl exec -it jenkins-deployment-XXXXXX -- cat /var/jenkins_home/secrets/initialAdminPassword

Mas informacion:      https://bitbucket.org/damianmcdonald/entorno-ci-cd-azure-k8s/src/master/docker/jenkins

## TOMCAT ##

Tomcat URL:           http://$TOMCAT_EXTERNAL_IP:7895
Tomcat Username:      admin
Tomcat Password:      unisys2020
Mas informacion:      https://bitbucket.org/damianmcdonald/entorno-ci-cd-azure-k8s/src/master/docker/tomcat

## OPERACIONES ##

Para administrar un AKS cluster tienes que utilizar el mando: kubectl

kubectl es una herremienta muy potente con mil opciones.

Aqui abajo es una chuleta de mandos de kubectl, es una referencia muy util!

https://kubernetes.io/docs/reference/kubectl/cheatsheet/

## SCRIPTS ##

Hay scripts para facilitar la automatizacion del AKS Cluster.

# Arancar el cluster
$START_SCRIPT

# Apagar el cluster
$STOP_SCRIPT

# Destruir el cluster - ATTENCION, se pierde los datos!!
$DESTROY_SCRIPT
EOT
