#!/bin/bash

TENANT='RED'
PREMISE='CHE041'

ZOOKEEPER=zookeeper
PORT=2181

BASE='___v1___data0___'
MIDDLE='___'
END="___RAWEPCISEVENT"
PREMISE_TOPIC="$BASE$TENANT$MIDDLE$PREMISE$END"

##echo "xxx $PREMISE_TOPIC."

/kafka/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER:$PORT --replication-factor 1 --partitions 1 --topic ___v1___cache___configThings --config cleanup.policy=compact
/kafka/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER:$PORT --replication-factor 1 --partitions 1 --topic ___v1___cache___connection --config cleanup.policy=compact
/kafka/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER:$PORT --replication-factor 1 --partitions 1 --topic ___v1___cache___edgebox --config cleanup.policy=compact
/kafka/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER:$PORT --replication-factor 1 --partitions 1 --topic ___v1___cache___edgeboxconfiguration --config cleanup.policy=compact
/kafka/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER:$PORT --replication-factor 1 --partitions 1 --topic ___v1___cache___edgeboxrule --config cleanup.policy=compact
/kafka/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER:$PORT --replication-factor 1 --partitions 1 --topic ___v1___cache___eventType --config cleanup.policy=compact
/kafka/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER:$PORT --replication-factor 1 --partitions 1 --topic ___v1___cache___group --config cleanup.policy=compact
/kafka/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER:$PORT --replication-factor 1 --partitions 1 --topic ___v1___cache___groupconfiguration --config cleanup.policy=compact
/kafka/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER:$PORT --replication-factor 1 --partitions 1 --topic ___v1___cache___grouptype --config cleanup.policy=compact
/kafka/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER:$PORT --replication-factor 1 --partitions 1 --topic ___v1___cache___logicalreader --config cleanup.policy=compact
/kafka/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER:$PORT --replication-factor 1 --partitions 1 --topic ___v1___cache___rulesetfilter --config cleanup.policy=compact
/kafka/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER:$PORT --replication-factor 1 --partitions 1 --topic ___v1___cache___shift --config cleanup.policy=compact
/kafka/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER:$PORT --replication-factor 1 --partitions 1 --topic ___v1___cache___shiftzone --config cleanup.policy=compact
/kafka/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER:$PORT --replication-factor 1 --partitions 1 --topic ___v1___cache___siteconfig --config cleanup.policy=compact
/kafka/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER:$PORT --replication-factor 1 --partitions 1 --topic ___v1___cache___things___tickles --config cleanup.policy=compact
/kafka/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER:$PORT --replication-factor 1 --partitions 1 --topic ___v1___cache___thingtype --config cleanup.policy=compact
/kafka/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER:$PORT --replication-factor 1 --partitions 1 --topic ___v1___cache___thingtypepath --config cleanup.policy=compact
/kafka/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER:$PORT --replication-factor 1 --partitions 1 --topic ___v1___cache___transform --config cleanup.policy=compact
/kafka/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER:$PORT --replication-factor 1 --partitions 1 --topic ___v1___cache___zone --config cleanup.policy=compact
/kafka/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER:$PORT --replication-factor 1 --partitions 1 --topic ___v1___cache___zonetype --config cleanup.policy=compact

#data0 topics needed by the transformer
/kafka/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER:$PORT --replication-factor 1 --partitions 1 --topic ___v1___data0___csv
/kafka/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER:$PORT --replication-factor 1 --partitions 1 --topic ___v1___data0___ale
/kafka/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER:$PORT --replication-factor 1 --partitions 1 --topic ___v1___data0___sf___data
/kafka/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER:$PORT --replication-factor 1 --partitions 1 --topic ___v1___data0___json
/kafka/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER:$PORT --replication-factor 1 --partitions 1 --topic ___v1___data0___sf___response
/kafka/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER:$PORT --replication-factor 1 --partitions 1 --topic ___v1___data0___sf___ie
/kafka/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER:$PORT --replication-factor 1 --partitions 1 --topic ___v2___data0___json

#POE/POS topics
/kafka/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER:$PORT --replication-factor 1 --partitions 1 --topic ___v1___ss___epcisMap --config cleanup.policy=compact
/kafka/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER:$PORT --replication-factor 1 --partitions 1 --topic ___v1___ss___itemStatus --config cleanup.policy=compact
/kafka/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER:$PORT --replication-factor 1 --partitions 1 --topic ___v1___ss___inventory --config cleanup.policy=compact

## transform should do this
/kafka/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER:$PORT --replication-factor 1 --partitions 1 --topic "$PREMISE_TOPIC"
/kafka/bin/kafka-topics.sh --create --zookeeper $ZOOKEEPER:$PORT --replication-factor 1 --partitions 1 --topic ___v1___data1



