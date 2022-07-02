#!/bin/bash
### Create by @Jpardo
source "simulate_FitPosPoe.txt"

EPC=$EPC
server=$server
user=$user
pass=$pass
premise=$premise
tenant=$tenant

##GENERATE BASE64 CREDENTIALS
base=$(echo -n  $user:$pass | base64)
echo $base

## Get PREMISE CODE from NAME
premID=$(curl -X GET 'https://red-at.vizix.io:443/statemachine-api-configuration/rest/configuration/locations?level=premise' -H 'Authorization: Basic 'UkVEcm9vdDptMGoxeEluYyExYg=='' | jq '.[] | select(.code=="QATEST")'| jq -r '.id')
echo $premID

## POS GET DATA
POS_id=$(curl -X GET 'https://'$server'/statemachine-api-configuration/rest/locations/'$premID'/infra/devices?model=KEONN__ADPY__1&ts=1576156454337' -H 'Authorization: Basic '$base''| jq -r '.[0].id ' )
echo $POS_id

curl -X GET 'https://'$server'/statemachine-api-configuration/rest/infra/devices/'$POS_id'/povs' -H 'Authorization: Basic '$base''  > /tmp/jsPOS.json

POS_povID=$(cat /tmp/jsPOS.json | jq -r '.[0].id ')
echo $POS_povID
POS_fixture=$(cat /tmp/jsPOS.json | jq -r '.[0].fixtureId')
echo $POS_fixture


## POE GET DATA
POE_id=$(curl -X GET 'https://'$server'/statemachine-api-configuration/rest/locations/'$premID'/infra/device/types/POE/devices?ts=1576167798640' -H 'Authorization: Basic '$base''| jq -r '.[0].id ' )
echo $POE_id

curl -X GET 'https://'$server'/statemachine-api-configuration/rest/infra/devices/'$POE_id'/povs' -H 'Authorization: Basic '$base''  > /tmp/jsPOE.json

POE_povID=$(cat /tmp/jsPOE.json | jq -r '.[0].id ')
echo $POE_povID
POE_fixture=$(cat /tmp/jsPOE.json | jq -r '.[0].fixtureId')
echo $POE_fixture

## Ftiiting-room GET DATA
FIT_id=$(curl -X GET 'https://'$server'/statemachine-api-configuration/rest/locations/'$premID'/infra/device/types/FITTING_ROOM/devices?ts=1585863394019' -H 'Authorization: Basic '$base''| jq -r '.[0].id ' )
echo $FIT_id

curl -X GET 'https://'$server'/statemachine-api-configuration/rest/infra/devices/'$FIT_id'/povs' -H 'Authorization: Basic '$base''  > /tmp/jsPOE.json

FIT_povID=$(cat /tmp/jsPOE.json | jq -r '.[0].id')
echo $FIT_povID
FIT_fixture=$(cat /tmp/jsPOE.json | jq -r '.[0].fixtureId')
echo $FIT_fixture

## Create Template File 
echo '{"epc":"epcValue","readerId":"readerIdValue","povId":"povIdValue","fixtureId":"fixtureIdValue","mode":"modeValue","timestamp":timestampValue}' > template.txt_bk

showMenu()
{
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        echo "~             ~~~!!@@@ #@$@#%$#^%&^$%# ~~~!!@@@                ~"
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        echo "1. Send POE"
        echo "2. Send POS READ_ONLY"
        echo "3. Send POS RETURN"
        echo "4. Send POS PAYMENT"
        echo "5. Send FITTING"
        echo "6. Delete Template Files"
}

resetTemplate ()
{
	rm -rf template.txt
	cp template.txt_bk template.txt
}

prepareTemplate ()
{
     timestamp=`date "+%s%N" | cut -b1-13`

     sed -i "s/epcValue/"$1"/g" template.txt
     sed -i "s/readerIdValue/"$2"/g" template.txt
     sed -i "s/povIdValue/"$3"/g" template.txt
     sed -i "s/fixtureIdValue/"$4"/g" template.txt
     sed -i "s/modeValue/"$5"/g" template.tx
     sed -i "s/timestampValue/"$timestamp"/g" template.txt
}

correrPOE () {

    resetTemplate

    echo "-- Update POE Parameter in tag"
    echo "---------- SEND GUARD SIMULATION ---------------"

    #### Prepapre Template with all Information in order to upload to Kedge Container
    prepareTemplate $EPC $POE_id $POE_povID $POE_fixture GUARD

    ## Copy File to Kedge Container
    docker cp template.txt kedge:/kafka/poe_guard.txt

    ## Execute command in order to put the message in the topic 
    docker exec -ti kedge  bash -c 'cat poe_guard.txt | ./bin/kafka-console-producer.sh --broker-list kedge:9092 --topic ___v1___data0___'$tenant'___'$premise'___RAWEPCISEVENT'
}

correrFitting () {

    resetTemplate

    echo "-- Update Fitting Parameter in tag"
    echo "---------- SEND FITTING SIMULATION ---------------"

    #### Prepapre Template with all Information in order to upload to Kedge Container
    prepareTemplate $EPC $FIT_id $FIT_povID $FIT_fixture FITTING_ROOM-IN

    ## Copy File to Kedge Container
    docker cp template.txt kedge:/kafka/fitting_room-in.txt

    ## Execute command in order to put the message in the topic
    docker exec -ti kedge  bash -c 'cat fitting_room-in.txt | ./bin/kafka-console-producer.sh --broker-list kedge:9092 --topic ___v1___data0___'$tenant'___'$premise'___RAWEPCISEVENT'
}

correrReadOnly () {

    resetTemplate

    echo "-------- Update POS Parameter in tag"
    echo "---------- SEND READ_ONLY SIMULATION -----------"

    #### Prepapre Template with all Information in order to upload to Kedge Container
    prepareTemplate $EPC $POS_id $POS_povID $POS_fixture POS_READ_ONLY

    ## Copy File to Kedge Container
    docker cp template.txt kedge:/kafka/pos_read_only.txt

     ## Execute command in order to put the message in the topic 
    docker exec -ti kedge  bash -c 'cat pos_read_only.txt | ./bin/kafka-console-producer.sh --broker-list kedge:9092 --topic ___v1___data0___'$tenant'___'$premise'___RAWEPCISEVENT'
}

correrReturn () {

    resetTemplate

    echo "-------- Update POS Parameter in tag"
    echo "---------- SEND RETURN SIMULATION -----------"

    #### Prepapre Template with all Information in order to upload to Kedge Container
    prepareTemplate $EPC $POS_id $POS_povID $POS_fixture POS_RETURN 

    ## Copy File to Kedge Container
    docker cp template.txt kedge:/kafka/pos_return.txt

     ## Execute command in order to put the message in the topic 
    docker exec -ti kedge  bash -c 'cat pos_return.txt | ./bin/kafka-console-producer.sh --broker-list kedge:9092 --topic ___v1___data0___'$tenant'___'$premise'___RAWEPCISEVENT'

}

correrPayment () {

    resetTemplate

    echo "-------- Update POS Parameter in tag"
    echo "---------- SEND PAYMENT SIMULATION -----------"

    #### Prepapre Template with all Information in order to upload to Kedge Container
    prepareTemplate $EPC $POS_id $POS_povID $POS_fixture POS_PAYMENT

    ## Copy File to Kedge Container
    docker cp template.txt kedge:/kafka/pos_payment.txt

    ## Execute command in order to put the message in the topic 
    docker exec -ti kedge  bash -c 'cat pos_payment.txt | ./bin/kafka-console-producer.sh --broker-list kedge:9092 --topic ___v1___data0___'$tenant'___'$premise'___RAWEPCISEVENT'
}

deleteSimulatorFiles ()
{
    rm -rf template.txt template.txt_bk
    docker exec -ti kedge rm -f pos_read_only.txt pos_return.txt pos_payment.txt poe_guard.txt fitting_room-in.txt
}

menu(){
	read -p "Select Option: " option
	echo $option
	case "$option" in

		1) correrPOE ;;
		2) correrReadOnly ;;
		3) correrReturn ;;
		4) correrPayment ;;
		5) correrFitting ;;
                6) deleteSimulatorFiles ;;

	esac
	}
while true
do
	showMenu
	menu
done

