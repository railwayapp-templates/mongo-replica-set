#!/bin/bash

debug_log() {
  if [[ "$DEBUG" == "1" ]]; then
    echo "DEBUG: $1"
  fi
}

print_on_start() {
  echo "**********************************************************"
  echo "*                                                        *"
  echo -e "*  Deploying a Mongo Replica Set to Railway...           *"
  echo -e "*  \033]8;;https://railway.app\033\\(Click here to open Railway)\033]8;;\033\\         *"
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

check_all_nodes() {
  local nodes=("$@")
  for node in "${nodes[@]}"; do
    local host=$(echo $node | cut -d: -f1)
    local port=$(echo $node | cut -d: -f2)
    echo "Waiting for MongoDB to be available at $host:$port"
    until check_mongo "$host" "$port"; do
      echo "Waiting..."
      sleep 2
    done
  echo "All MongoDB nodes are up."
  done
}

initiate_replica_set() {
  echo "Initiating replica set."
  debug_log "_id: $REPLICA_SET_NAME"
  debug_log "Primary member: $MONGO_PRIMARY_HOST:$MONGO_PORT"
  debug_log "Replica member 1: $MONGO_REPLICA_HOST:$MONGO_PORT"
  debug_log "Replica member 2: $MONGO_REPLICA2_HOST:$MONGO_PORT"

  mongosh --host "$MONGO_PRIMARY_HOST" --port "$MONGO_PORT" --username "$MONGOUSERNAME" --password "$MONGOPASSWORD" --authenticationDatabase "admin" <<EOF
rs.initiate({
  _id: "$REPLICA_SET_NAME",
  members: [
    { _id: 0, host: "$MONGO_PRIMARY_HOST:$MONGO_PORT" },
    { _id: 1, host: "$MONGO_REPLICA_HOST:$MONGO_PORT" },
    { _id: 2, host: "$MONGO_REPLICA2_HOST:$MONGO_PORT" }
  ]
})
EOF
  init_exit_code=$?
  debug_log "Replica set initiation exit code: $init_exit_code"
  return $init_exit_code
}

nodes=("$MONGO_PRIMARY_HOST:$MONGO_PORT" "$MONGO_REPLICA_HOST:$MONGO_PORT" "$MONGO_REPLICA2_HOST:$MONGO_PORT")

print_on_start

check_all_nodes "${nodes[@]}"

if initiate_replica_set; then
  echo "**********************************************************"
  echo "**********************************************************"
  echo "*                                                        *"
  echo "*           Replica set initiated successfully.          *"
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
