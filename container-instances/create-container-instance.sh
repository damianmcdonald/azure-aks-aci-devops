#!/bin/bash

# ##################################################
# Script que crea un Azure Container instance.
#
# https://docs.microsoft.com/es-es/azure/container-instances/container-instances-overview
# https://azure.microsoft.com/es-es/pricing/details/container-instances/
#
# El Azure Container Instance contiene los siguentes servidores:
# * Nexus
# * Sonarqube
# * Subversion
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
CONTAINER_INSTANCE=poc-container
CONTAINER_INSTANCE_DNS_LABEL=pocentornodevops
AZURE_CONTAINER_DNS_LABEL=azurecontainer.io
STORAGE_ACCOUNT_NAME=pocstorage$RANDOM
SUBVERSION_SHARE=subversion
NEXUS_SHARE=nexus
SONARQUBE_DATA_SHARE=sonarqube-data
SONARQUBE_LOGS_SHARE=sonarqube-logs
DEPLOYMENT_FILE=$ROOT_WORKING_DIR/container-instances/deployment.yml
START_SCRIPT=$ROOT_WORKING_DIR/container-instances/start-container-instance.sh
STOP_SCRIPT=$ROOT_WORKING_DIR/container-instances/stop-container-instance.sh
DESTROY_SCRIPT=$ROOT_WORKING_DIR/container-instances/destroy-container-instance.sh

###########################################################
#                                                         #
# Creacion de Azure File Storage                          #
#                                                         #
###########################################################
echo -e "[${LIGHT_BLUE}INFO${NC}] Creando el Azure Storage Account en Resource Group ${YELLOW}$RESOURCE_GROUP${NC} en ${YELLOW}$AZURE_LOCATION${NC} ....";
az storage account create \
    --resource-group $RESOURCE_GROUP \
    --name $STORAGE_ACCOUNT_NAME \
    --location $AZURE_LOCATION \
    --sku Standard_LRS \
    --kind StorageV2

###########################################################
#                                                         #
# Creacion de los Azure File Shares                       #
#                                                         #
###########################################################
## create the subverson share
echo ""
echo -e "[${LIGHT_BLUE}INFO${NC}] Creando los Azure File shares de Subversion ....";
az storage share create --name $SUBVERSION_SHARE --account-name $STORAGE_ACCOUNT_NAME

## create the nexus share
echo ""
echo -e "[${LIGHT_BLUE}INFO${NC}] Creando los Azure File shares de Nexus ....";
az storage share create --name $NEXUS_SHARE --account-name $STORAGE_ACCOUNT_NAME

## create the sonarqube shares
echo ""
echo -e "[${LIGHT_BLUE}INFO${NC}] Creando los Azure File shares de Sonarqube ....";
az storage share create --name $SONARQUBE_DATA_SHARE --account-name $STORAGE_ACCOUNT_NAME
az storage share create --name $SONARQUBE_LOGS_SHARE --account-name $STORAGE_ACCOUNT_NAME

# Get the Storage Account Key
STORAGE_ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP --account-name $STORAGE_ACCOUNT_NAME --query "[0].value" --output tsv)

###########################################################
#                                                         #
# Creacion del archivo de despliegue de los contendores   #
#                                                         #
###########################################################
## create the deployment yaml file
echo ""
echo -e "[${LIGHT_BLUE}INFO${NC}] Creando el deployment.yml ....";

# delete any previous instance of $DEPLOYMENT_FILE
if [ -f "$DEPLOYMENT_FILE" ]; then
    rm $DEPLOYMENT_FILE
fi

cat > $DEPLOYMENT_FILE <<EOF
apiVersion: '2018-10-01'
location: westeurope
name: $CONTAINER_INSTANCE
properties:
  containers:
  - name: subversion
    properties:
      environmentVariables: []
      image: damianmcdonald/subversion-cloud:1.0.0
      ports:
      - port: 7243
      resources:
        requests:
          cpu: 1
          memoryInGB: 1
      volumeMounts:
      - mountPath: /home/svn
        name: fs-subversion
  - name: nexus
    properties:
      environmentVariables: []
      image: sonatype/nexus3:3.19.1
      ports:
      - port: 8081
      resources:
        requests:
          cpu: 1.5
          memoryInGB: 3
      volumeMounts:
      - mountPath: /nexus-data
        name: fs-nexus
  - name: sonarqube
    properties:
      environmentVariables: []
      image: sonarqube:lts
      ports:
      - port: 9000
      resources:
        requests:
          cpu: 1.5
          memoryInGB: 3
      volumeMounts: [
      {
        name: fs-sonarqube-data,
        mountPath: /opt/sonarqube/data
      },
      {
        name: fs-sonarqube-logs,
        mountPath: /opt/sonarqube/logs
      }]
  osType: Linux
  restartPolicy: Always
  ipAddress:
    type: Public
    ports:
      - protocol: tcp
        port: 7243
      - protocol: tcp
        port: 8081
      - protocol: tcp
        port: 9000
    dnsNameLabel: $CONTAINER_INSTANCE_DNS_LABEL
  volumes:
  - name: fs-subversion
    azureFile:
      sharename: subversion
      storageAccountName: $STORAGE_ACCOUNT_NAME
      storageAccountKey: $STORAGE_ACCOUNT_KEY
  - name: fs-nexus
    azureFile:
      sharename: nexus
      storageAccountName: $STORAGE_ACCOUNT_NAME
      storageAccountKey: $STORAGE_ACCOUNT_KEY
  - name: fs-sonarqube-data
    azureFile:
      sharename: sonarqube-data
      storageAccountName: $STORAGE_ACCOUNT_NAME
      storageAccountKey: $STORAGE_ACCOUNT_KEY
  - name: fs-sonarqube-logs
    azureFile:
      sharename: sonarqube-logs
      storageAccountName: $STORAGE_ACCOUNT_NAME
      storageAccountKey: $STORAGE_ACCOUNT_KEY
tags: {}
type: Microsoft.ContainerInstance/containerGroups
EOF

###########################################################
#                                                         #
# Creacion del Azure Container Instance                   #
#                                                         #
###########################################################
echo ""
echo -e "[${LIGHT_BLUE}INFO${NC}] Creando el Container Instance ${YELLOW}$CONTAINER_INSTANCE${NC} en ${YELLOW}$AZURE_LOCATION${NC} ....";
echo -e "[${LIGHT_BLUE}INFO${NC}] Container Instance ${YELLOW}$CONTAINER_INSTANCE${NC} es compuesto de:";
echo ""

echo -e "# ${YELLOW}$CONTAINER_INSTANCE${NC}"
echo -e "#     ${GREEN}Nexus${NC}"
echo -e "#     ${GREEN}Sonarqube${NC}"
echo -e "#     ${GREEN}Subversion${NC}"

az container create --resource-group $RESOURCE_GROUP --file $DEPLOYMENT_FILE

###########################################################
#                                                         #
# Creacion de los scripts de automatizacion               #
#                                                         #
###########################################################
createContainerDestroyScript $DESTROY_SCRIPT $RESOURCE_GROUP $CONTAINER_INSTANCE
createContainerStartScript $START_SCRIPT $RESOURCE_GROUP $CONTAINER_INSTANCE
createContainerStopScript $STOP_SCRIPT $RESOURCE_GROUP $CONTAINER_INSTANCE

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
echo -e "Container Instance:   $CONTAINER_INSTANCE"
echo -e "Azure location:       $AZURE_LOCATION"
echo -e "Resource Group:       $RESOURCE_GROUP"
echo -e "Container DNS label:  $CONTAINER_INSTANCE_DNS_LABEL"
echo -e "Mas informacion:      https://docs.microsoft.com/es-es/azure/container-instances/container-instances-overview"
echo -e "                      https://azure.microsoft.com/es-es/pricing/details/container-instances/"
echo ""
echo -e "Nexus URL:            http://$CONTAINER_INSTANCE_DNS_LABEL.$AZURE_LOCATION.$AZURE_CONTAINER_DNS_LABEL:8081"
echo -e "Sonarqube URL:        http://$CONTAINER_INSTANCE_DNS_LABEL.$AZURE_LOCATION.$AZURE_CONTAINER_DNS_LABEL:9000"
echo -e "Subversion URL:       http://$CONTAINER_INSTANCE_DNS_LABEL.$AZURE_LOCATION.$AZURE_CONTAINER_DNS_LABEL:7243"
echo ""
echo -e "## NEXUS ##"
echo ""
echo -e "Nexus URL:            http://$CONTAINER_INSTANCE_DNS_LABEL.$AZURE_LOCATION.$AZURE_CONTAINER_DNS_LABEL:8081"
echo -e "Nexus Username:       admin"
echo -e "Nexus Password:       hay que conectar al contenedor y ejecutar los mandos:"
echo ""
echo -e "                      az container exec -g $RESOURCE_GROUP --name $CONTAINER_INSTANCE --container-name nexus --exec-command \"/bin/sh\""
echo -e "                      cat /nexus-data/admin.password"
echo ""
echo -e "Mas informacion:      https://hub.docker.com/r/sonatype/nexus3"
echo ""
echo -e "## SONARQUBE ##"
echo ""
echo -e "Sonarqube URL:        http://$CONTAINER_INSTANCE_DNS_LABEL.$AZURE_LOCATION.$AZURE_CONTAINER_DNS_LABEL:9000"
echo -e "Sonarqube Username:   admin"
echo -e "Sonarqube Password:   admin"
echo -e "Mas informacion:      https://hub.docker.com/_/sonarqube"
echo ""
echo -e "## SUBVERSION ##"
echo ""
echo -e "Subversion users:     root/unisys2020"
echo -e "Subversion URL:       http://$CONTAINER_INSTANCE_DNS_LABEL.$AZURE_LOCATION.$AZURE_CONTAINER_DNS_LABEL:7243"
echo -e "                      svnuser1/unisys2020"
echo -e "                      svnuser2/unisys2020"
echo -e "                      svnuser3/unisys2020"
echo ""
echo -e "                      hay que crear un nuevo proyecto en subversion utilizando los siguentes mandos:"
echo ""
echo -e "                      az container exec -g $RESOURCE_GROUP --name $CONTAINER_INSTANCE --container-name subversion --exec-command /bin/sh"
echo -e "                      apt update && apt install nano"
echo -e "                      cd /home/svn"
echo -e "                      svnadmin create sample-app-svn-git"
echo ""
echo -e "                      # edit the svnserve.conf file"
echo -e "                      # uncomment the line password-db = passwd and save the file"
echo -e "                      nano /home/svn/sample-app-svn-git/conf/svnserve.conf"
echo ""
echo -e "                      # edit the passwd file as shown below and save the file"
echo -e "                      # in the  [users] section add new users as"
echo -e "                      # svnuser1=unisys2020"
echo -e "                      # svnuser2=unisys2020"
echo -e "                      # svnuser3=unisys2020"
echo -e "                      nano /home/svn/sample-app-svn-git/conf/svnserve.conf"
echo ""
echo -e "                      # set permissions on the svn dir"
echo -e "                      chmod -R 777 /home/svn"
echo ""
echo -e "Mas informacion:      https://hub.docker.com/r/krisdavison/svn-server"

###########################################################
#                                                         #
# Anadir los detalles del Azure Container Instance        #
# al fichero ENV-INFO.txt                                 #
#                                                         #
###########################################################
cat <<EOT >> $ENV_INFO_FILE

#########################################################
#                                                       #
#        Azure Container Instance Informacion           #
#                                                       #
#########################################################

Container Instance:   $CONTAINER_INSTANCE
Azure location:       $AZURE_LOCATION
Resource Group:       $RESOURCE_GROUP
Container DNS label:  $CONTAINER_INSTANCE_DNS_LABEL
Mas informacion:      https://docs.microsoft.com/es-es/azure/container-instances/container-instances-overview
                      https://azure.microsoft.com/es-es/pricing/details/container-instances/

Nexus URL:            http://$CONTAINER_INSTANCE_DNS_LABEL.$AZURE_LOCATION.$AZURE_CONTAINER_DNS_LABEL:8081
Sonarqube URL:        http://$CONTAINER_INSTANCE_DNS_LABEL.$AZURE_LOCATION.$AZURE_CONTAINER_DNS_LABEL:9000
Subversion URL:       http://$CONTAINER_INSTANCE_DNS_LABEL.$AZURE_LOCATION.$AZURE_CONTAINER_DNS_LABEL:7243

## NEXUS ##

Nexus URL:            http://$CONTAINER_INSTANCE_DNS_LABEL.$AZURE_LOCATION.$AZURE_CONTAINER_DNS_LABEL:8081
Nexus Username:       admin
Nexus Password:       hay que conectar al contenedor y ejecutar los mandos:

                      az container exec -g $RESOURCE_GROUP --name $CONTAINER_INSTANCE --container-name nexus --exec-command "/bin/sh"
                      cat /nexus-data/admin.password

Mas informacion:      https://hub.docker.com/r/sonatype/nexus3

## SONARQUBE ##

Sonarqube URL:        http://$CONTAINER_INSTANCE_DNS_LABEL.$AZURE_LOCATION.$AZURE_CONTAINER_DNS_LABEL:9000
Sonarqube Username:   admin
Sonarqube Password:   admin
Mas informacion:      https://hub.docker.com/_/sonarqube

## SUBVERSION ##

Subversion URL:       http://$CONTAINER_INSTANCE_DNS_LABEL.$AZURE_LOCATION.$AZURE_CONTAINER_DNS_LABEL:7243
Subversion users:     root/unisys2020
                      svnuser1/unisys2020
                      svnuser2/unisys2020
                      svnuser3/unisys2020

                      hay que crear un nuevo proyecto en subversion utilizando los siguentes mandos:

                      az container exec -g $RESOURCE_GROUP --name $CONTAINER_INSTANCE --container-name subversion --exec-command "/bin/sh"
                      apt update && apt install nano
                      cd /home/svn
                      svnadmin create sample-app-svn-git

                      # edit the svnserve.conf file
                      # uncomment the line password-db = passwd and save the file
                      nano /home/svn/sample-app-svn-git/conf/svnserve.conf

                      # edit the passwd file as shown below and save the file
                      # in the  [users] section add new users as
                      # svnuser1=unisys2020
                      # svnuser2=unisys2020
                      # svnuser3=unisys2020
                      nano /home/svn/sample-app-svn-git/conf/svnserve.conf

                      # set permissions on the svn dir
                      chmod -R 777 /home/svn

Mas informacion:      https://hub.docker.com/r/krisdavison/svn-server

## OPERACIONES ##

https://docs.microsoft.com/en-us/cli/azure/container?view=azure-cli-latest

# Arancar los contenedores
az container start --name $CONTAINER_INSTANCE --resource-group $RESOURCE_GROUP

# Apagar los contenedores
az container stop --name $CONTAINER_INSTANCE --resource-group $RESOURCE_GROUP

# Reiniciar los contenedores
az container restart --name $CONTAINER_INSTANCE --resource-group $RESOURCE_GROUP

# Destruir los contenedores - ATTENCION, se pierde los datos!!
az container delete --name $CONTAINER_INSTANCE --resource-group $RESOURCE_GROUP

# Mostrar los contenedores
az container list --name $CONTAINER_INSTANCE --resource-group $RESOURCE_GROUP

# Obtener detalles de los contenedores
az container show --name $CONTAINER_INSTANCE --resource-group $RESOURCE_GROUP

# Mostrar los logs de los contenedores
az container logs --name $CONTAINER_INSTANCE --resource-group $RESOURCE_GROUP

## SCRIPTS ##

Hay scripts para facilitar la administracion de los contenedores.

# Arancar los contenedores
$START_SCRIPT

# Apagar los contenedores
$STOP_SCRIPT

# Destruir los contenedores - ATTENCION, se pierde los datos!!
$DESTROY_SCRIPT
EOT
