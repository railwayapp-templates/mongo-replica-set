#!/bin/bash

# Function to check if MongoDB is up
check_mongo() {
  local host=$1
  local port=$2
  echo "Checking MongoDB at $host:$port..."
  mongo_output=$(mongosh --host "$host" --port "$port" --eval "db.adminCommand('ping')" 2>&1)
  mongo_exit_code=$?
  echo "MongoDB check exit code: $mongo_exit_code"
  echo "MongoDB check output: $mongo_output"
  return $mongo_exit_code
}

# Function to check if all nodes are up
check_all_nodes() {
  local nodes=("$@")
  for node in "${nodes[@]}"; do
    local host=$(echo $node | cut -d: -f1)
    local port=$(echo $node | cut -d: -f2)
    until check_mongo "$host" "$port"; do
      echo "Waiting for MongoDB to be up at $host:$port..."
      sleep 2
    done
  done
}

# Function to initiate replica set
initiate_replica_set() {
  echo "Initiating replica set with the following configuration:"
  echo "_id: $REPLICA_SET_NAME"
  echo "Primary member: $MONGO_PRIMARY_HOST:$MONGO_PORT"
  echo "Replica member 1: $MONGO_REPLICA_HOST:$MONGO_PORT"
  echo "Replica member 2: $MONGO_REPLICA2_HOST:$MONGO_PORT"

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
  echo "Replica set initiation exit code: $init_exit_code"
  return $init_exit_code
}

# List of all nodes
nodes=("$MONGO_PRIMARY_HOST:$MONGO_PORT" "$MONGO_REPLICA_HOST:$MONGO_PORT" "$MONGO_REPLICA2_HOST:$MONGO_PORT")

# Check if all nodes are up
check_all_nodes "${nodes[@]}"

echo "All MongoDB nodes are up. Initiating replica set..."

# Initiate replica set, fail if it doesn't complete successfully
if initiate_replica_set; then
  echo "Replica set initiated successfully. Exiting script..."
  exit 0
else
  echo "Failed to initiate replica set. Please check the logs for more information."
  exit 1
fi