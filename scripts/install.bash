#!/bin/bash
ipadd=$(hostname -I | awk '{print $1}')
echo "Do you wish to continue installation that include ANALYTICS? [y/n]" 
read choice
if [[ $choice == "y" ]]; then
    ANALYTICS=1
elif [[ $choice == "n" ]]; then
    ANALYTICS=0
fi
#############################################################
######################### main function #####################
#############################################################

function main
{
  cd ../docker-compose/
  cp template.env .env 
  keycloak
  if [[ $ANALYTICS == 1 ]]; then
    forms-flow-analytics
  elif [[ $ANALYTICS == 0 ]]; then
    forms-flow-forms
  fi
  forms-flow-bpm
  installconfig
  forms-flow-api
  forms-flow-web
}

#############################################################
######################## creating config.js #################
#############################################################

function installconfig
{
   mkdir ../configuration	
   cd ../configuration/
   pwd
   if [[ -f config.js ]]; then
     rm config.js
   fi

   cp ../docker-compose/front_config_template.js config.js
}

#############################################################
###################### forms-flow-Analytics #################
#############################################################

function forms-flow-analytics
{
    docker-compose -f analytics-docker-compose.yml run --rm server create_db
    docker-compose -f analytics-docker-compose.yml up --build -d
}

#############################################################
######################## forms-flow-bpm #####################
#############################################################

function forms-flow-bpm
{
    docker-compose -f docker-compose.yml up --build -d forms-flow-bpm
}

#############################################################
######################## forms-flow-webapi ##################
#############################################################

function forms-flow-api
{
    if [[ $ANALYTICS == 1 ]]; then (
        echo What is your Redash API key?
        read INSIGHT_API_KEY

        echo INSIGHT_API_KEY=$INSIGHT_API_KEY >> .env
    )
    fi
    docker-compose -f docker-compose.yml up --build -d forms-flow-webapi
}

#############################################################
######################## forms-flow-forms ###################
#############################################################

function forms-flow-forms
{
    cd ../docker-compose
    docker-compose -f docker-compose.yml up --build -d forms-flow-forms

}
function forms-flow-web
{
cd ../docker-compose/
docker-compose -f docker-compose.yml up --build -d forms-flow-web
echo "********************** formsflow.ai is successfully installed ****************************"
}

#############################################################
########################### Keycloak ########################
#############################################################

function keycloak
{
    cd ../docker-compose/
    if [[ -f .env ]]; then
     rm .env
    fi
    echo "Do you have an exsisting keycloak? [y/n]" 
    read value1
    function defaultinstallation
    {
        echo WE ARE SETING UP OUR DEFAULT KEYCLOCK FOR YOU
        printf "%s " "Press enter to continue"
        read that
        echo Please wait, keycloak is setting up!
        docker-compose -f docker-compose.yml up -d
    }
    
    function INSTALL_WITH_EXISTING_KEYCLOAK
    {
      echo What is your Keycloak url?
      read KEYCLOAK_URL
      echo What is your keycloak url realm name?
      read KEYCLOAK_URL_REALM
	  echo what is your keycloak admin user name?
      read KEYCLOAK_ADMIN_USERNAME
	  echo what is your keycloak admin password?
      read KEYCLOAK_ADMIN_PASSWORD
    }
    
     if [[ "$value1" == "y" ]]; then  
        INSTALL_WITH_EXISTING_KEYCLOAK
     elif [[ "$value1" == "n" ]]; then  
         defaultinstallation
     fi  
}
function orderwithanalytics
{
  echo installation will be completed in the following order:
  echo 1. keycloak
  echo 2. analytics
  echo 3. forms
  echo 4. camunda
  echo 5. webapi
  echo 6. web
  printf "%s " "Press enter to continue"
  read that
  main
}
function withoutanalytics
{
  echo installation will be completed in the following order:
  echo 1. keycloak
  echo 2. forms
  echo 3. camunda
  echo 4. webapi
  echo 5. web 
  printf "%s " "Press enter to continue"
  read that
  main
}
if [[ $ANALYTICS == 1 ]]; then
    orderwithanalytics
elif [[ $ANALYTICS == 0 ]]; then
    withoutanalytics
fi
