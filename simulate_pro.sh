#!/bin/bash
### Create by @Jpardo

## Read From File
source "/data/config.txt"

urn=$urnVar
server=$serverVar
port=$portVar
user=$userVar
pass=$passVar
premise1=$premise1Var
premise2=$premise2Var
tenant=$tenantVar

##GENERATE BASE64 CREDENTIALS
base=$(echo -n  $user:$pass | base64)
echo $base

## Get PREMISE CODE from STF1
prem1ID=$(curl -X GET 'http://'$server':'$port'/statemachine-api-configuration/rest/configuration/locations?level=premise' -H 'Authorization: Basic '$base'' | jq '.[] | select(.code=="'$premise1'")'| jq -r '.id')
## Get PREMISE CODE from STF2
prem2ID=$(curl -X GET 'http://'$server':'$port'/statemachine-api-configuration/rest/configuration/locations?level=premise' -H 'Authorization: Basic '$base'' | jq '.[] | select(.code=="'$premise2'")'| jq -r '.id')
echo $prem2ID


## XPOINT1 get Data in order to generate the template
XPOINT_id1=$(curl -X GET 'http://'$server':'$port'/statemachine-api-configuration/rest/locations/'$prem1ID'/infra/device/types/XPOINT/devices?ts=1578669849539' -H 'Authorization: Basic '$base'' | jq -r '.[0].id')

curl -X GET 'http://'$server':'$port'/statemachine-api-configuration/rest/infra/devices/'$XPOINT_id1'/povs' -H 'Authorization: Basic '$base''  > /tmp/jsXPOINT1.json

XPOINT1_povID=$(cat /tmp/jsXPOINT1.json | jq -r '.[0].id ')
echo $XPOINT1_povID
XPOINT1_fixture=$(cat /tmp/jsXPOINT1.json | jq -r '.[0].fixtureId')
echo $XPOINT1_fixture


## XPOINT2 get Data in order to generate the template
XPOINT_id2=$(curl -X GET 'http://'$server':'$port'/statemachine-api-configuration/rest/locations/'$prem2ID'/infra/device/types/XPOINT/devices?ts=1578669849539' -H 'Authorization: Basic '$base'' | jq -r '.[0].id')

curl -X GET 'http://'$server':'$port'/statemachine-api-configuration/rest/infra/devices/'$XPOINT_id2'/povs' -H 'Authorization: Basic '$base''  > /tmp/jsXPOINT2.json

XPOINT2_povID=$(cat /tmp/jsXPOINT2.json | jq -r '.[0].id ')
echo $XPOINT2_povID
XPOINT2_fixture=$(cat /tmp/jsXPOINT2.json | jq -r '.[0].fixtureId')
echo $XPOINT2_fixture


## Create Template File
#echo \''{"headers":{"bizStep":"bizStepValue","disposition":"dispositionValue","readPoint":"urn:cxi:site:loc:QnVjlwQvJIqtxwXlmY.Simulator","eventTime":eventTimeValue,"action":"OBSERVE","Current_Location":"currentLocationValue","bizLocation":"bizLocationValue","eventType":"TransactionEvent","tenant":"tenantValue"},"body":[{"epc":"urnValue","locationTrust":1.0,"readtime":readtimeValue,"coordinates":"-1|-1|-1"}]}'\' > rabbit_template.sh_bk
#echo 'rabbitmqadmin publish exchange=local_jsonEpcis routing_key=\' \' payload=\''{"headers":{"bizStep":"bizStepValue","disposition":"dispositionValue","readPoint":"urn:cxi:site:loc:QnVjlwQvJIqtxwXlmY.Simulator,"eventTime":eventTimeValue,"action":"OBSERVE","Current_Location":"currentLocationValue","bizLocation":"bizLocationValue","eventType":"TransactionEvent","tenant":"tenantValue"},"body":[{"epc":"urnValue","locationTrust":1.0,"readtime":readtimeValue,"coordinates":"-1|-1|-1"}]}'''\ > rabbit_template.sh_bk
echo 'rabbitmqadmin publish exchange=local_jsonEpcis routing_key='"'""'" 'payload='\''{"headers":{"bizStep":"bizStepValue","disposition":"dispositionValue","readPoint":"urn:cxi:site:loc:QnVjlwQvJIqtxwXlmY.Simulator","eventTime":eventTimeValue,"action":"OBSERVE","Current_Location":"currentLocationValue","bizLocation":"bizLocationValue","eventType":"TransactionEvent","tenant":"tenantValue"},"body":[{"epc":"urnValue","locationTrust":1.0,"readtime":readtimeValue,"coordinates":"-1|-1|-1"}]}'\' > rabbit_template.sh_bk

## Simulator Execution.
## --------------------
## Nota: If the fixture mapping is not updated in hub only delete \fixtureToEpcisEventMapping.json\ file and wait 15 seconds.
##       a new file should be regenerated with the last data.
##
## Steps.
##
## 1. Get all data from STF created
## 2. Generate template files
## 3. Send Message using rabbitmq
## 4. Review Transaction Events created in the environment.


showMenu()
{
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        echo "~             ~~~!!@@@ #@$@#%$#^%&^$%# ~~~!!@@@                ~"
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        echo "1. Send Automate Shipping"
        echo "2. Send Automate Receiving"
        echo "3. Delete Template Files"
        echo "4. Delete and Update fixtureMapping from Hub"

}

resetTemplate ()
{
	rm -rf rabbit_template.sh
	cp rabbit_template.sh_bk rabbit_template.sh
}

prepareTemplate ()
{
     timestamp=`date "+%s%N" | cut -b1-13`

     sed -i "s/bizStepValue/"$1"/g" rabbit_template.sh
     sed -i "s/dispositionValue/"$2"/g" rabbit_template.sh
     sed -i "s/eventTimeValue/"$timestamp"/g" rabbit_template.sh
     sed -i "s/currentLocationValue/"$3"/g" rabbit_template.sh
     sed -i "s/bizLocationValue/"$4"/g" rabbit_template.sh
     sed -i "s/tenantValue/"$5"/g" rabbit_template.sh
     sed -i "s/urnValue/"$6"/g" rabbit_template.sh
     sed -i "s/readtimeValue/"$timestamp"/g" rabbit_template.sh
}

correrAutomateShipping ()
{
    resetTemplate

    echo "-------- Update XPOINT Parameter in tag"
    echo "---------- SEND AUTOMATE SHIPPING SIMULATION -----------"

    bizStep='urn:epcglobal:cbv:bizstep:shipping'
    disposition='urn:epcglobal:cbv:disp:in_transit'
    currentLocation="urn:epc:id:sgln:${XPOINT1_fixture}"
    bizLocation="urn:cxi:site:loc:transit"

    #### Prepapre Template with all Information in order to upload to cxi-hub-rabbitmq Container
    prepareTemplate $bizStep $disposition $currentLocation $bizLocation $tenant $urn

    ## Copy File to cxi-hub-rabbitmq Container
    docker cp rabbit_template.sh cxi-hub-rabbitmq:/opt/app/rabbitmq/stfSimulator1.sh

    ## Execute command in order to put the message in the topic
    docker exec -ti cxi-hub-rabbitmq bash -c 'bash /opt/app/rabbitmq/stfSimulator1.sh'
}

correrAutomateReceiving ()
{
    resetTemplate

    echo "-------- Update XPOINT Parameter in tag"
    echo "---------- SEND AUTOMATE RECEIVING SIMULATION -----------"

	bizStep='urn:epcglobal:cbv:bizstep:receiving'
    disposition='urn:epcglobal:cbv:disp:encoded'
    currentLocation="urn:epc:id:sgln:${XPOINT2_fixture}"
    bizLocation="urn:epc:id:sgln:${XPOINT2_fixture}"

    #### Prepapre Template with all Information in order to upload to cxi-hub-rabbitmq Container
    prepareTemplate $bizStep $disposition $currentLocation $bizLocation $tenant $urn
    ## Copy File to cxi-hub-rabbitmq Container
    docker cp rabbit_template.sh cxi-hub-rabbitmq:/opt/app/rabbitmq/stfSimulator2.sh

    ## Execute command in order to put the message in the topic
    docker exec -ti cxi-hub-rabbitmq bash -c 'bash /opt/app/rabbitmq/stfSimulator2.sh'
}

deleteSimulatorFiles ()
{
    rm -rf rabbit_template.sh_bk rabbit_template.sh
    docker exec -ti cxi-hub-rabbitmq rm -f stfSimulator1.sh stfSimulator2.sh
}

#deleteFixtureMap ()
#{
#
#}

menu(){
	read -p "Select Option: " option
	echo $option
	case "$option" in

		1) correrAutomateShipping ;;
		2) correrAutomateReceiving ;;
		3) deleteSimulatorFiles ;;
		4) correrPayment ;;

	esac
	}
while true
do
	showMenu
	menu
done