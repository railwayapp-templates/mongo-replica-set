#!/bin/bash

set -e

debug_log() {
  if [[ "$DEBUG" == "1" ]]; then
    echo "DEBUG: $1"
  fi
}

print_on_start() {
  echo "**********************************************************"
  echo "*                                                        *"
  echo "*  Initiating a Mongo Single Node Replica Set...         *"
  echo "*                                                        *"
  echo "*  To enable verbose logging, set DEBUG=1                *"
  echo "*  and redeploy the service.                             *"
  echo "*                                                        *"
  echo "**********************************************************"
}

check_mongo() {
  local host=$1
  local port=$2
  mongo_output=$(mongosh --host "$host" --port "$port" --eval "db.adminCommand('ping')" 2>&1)
  mongo_exit_code=$?
  debug_log "MongoDB check exit code: $mongo_exit_code"
  debug_log "MongoDB check output: $mongo_output"
  return $mongo_exit_code
}

initiate_replica_single() {
  echo "Initiating single node replica."
  debug_log "_id: $REPLICA_SET_NAME"
  debug_log "Primary member: $MONGO_PRIMARY_HOST:$MONGO_PORT"

  mongosh --host "$MONGO_PRIMARY_HOST" --port "$MONGO_PORT" --username "$MONGOUSERNAME" --password "$MONGOPASSWORD" --authenticationDatabase "admin" <<EOF
rs.initiate({
  _id: "$REPLICA_SET_NAME",
  members: [
    { _id: 0, host: "$MONGO_PRIMARY_HOST:$MONGO_PORT" }
  ]
})
EOF
  init_exit_code=$?
  debug_log "Single node replica initiation exit code: $init_exit_code"
  return $init_exit_code
}

print_on_start

check_mongo "$MONGO_PRIMARY_HOST" "$MONGO_PORT"

if initiate_replica_single; then
  echo "**********************************************************"
  echo "**********************************************************"
  echo "*                                                        *"
  echo "*           Single node replica initiated successfully.  *"
  echo "*                                                        *"
  echo "*              PLEASE DELETE THIS SERVICE.               *"
  echo "*                                                        *"
  echo "**********************************************************"
  exit 0
else
  echo "**********************************************************"
  echo "**********************************************************"
  echo "*                                                        *"
  echo "*           Failed to initiate replica set.              *"
  echo "*                                                        *"
  echo "*           Please check the MongoDB service logs        *"
  echo "*                 for more information.                  *"
  echo "*                                                        *"
  echo "*          You can also set DEBUG=1 as a variable        *"
  echo "*            on this service for verbose logging.        *"
  echo "*                                                        *"
  echo "**********************************************************"
  exit 1
fi