#!/bin/bash

# ##################################################
# Global constants definidos por el proyecto Prueba de Concepto.
# Los constants son utilizado por los otros scripts.
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
# Definicion de colores en Bash para llama la atencion    #
# a los mensajes en la consola                            #
#                                                         #
###########################################################
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

###########################################################
#                                                         #
# Global variable definitions                             #
#                                                         #
###########################################################
RESOURCE_GROUP=poc-devops-rg
# si quieres ver todos los regiones disponible en Azure, utiliza el mando abajo
# az account list-locations --output table
AZURE_LOCATION=westeurope
DNS_ZONE=pocdevops.info
ENV_INFO_FILE=ENV-INFO.txt
