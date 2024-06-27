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

# Function to find the primary node.. (not used)
find_primary() {
  local host=$1
  local port=$2
  echo "Checking replica set status at $host:$port..."
  rs_status=$(mongosh --quiet --host "$host" --port "$port" --username "$MONGOUSERNAME" --password "$MONGOPASSWORD" --authenticationDatabase "$AUTH_DB" --eval "rs.status()")
  echo "Replica set status: $rs_status"
  
  # Step 1: Find the Line Number of the 'PRIMARY' State
  primary_line=$(echo "$rs_status" | awk '/stateStr: .PRIMARY./{print NR}')
  echo "Line number for PRIMARY state: $primary_line"
  
  # Step 2: Look Backwards to Find the Corresponding 'name' Field
  primary_name_line=$(echo "$rs_status" | awk -v primary_line=$primary_line 'NR<=primary_line && /name/ {print $0; exit}')
  echo "Line with primary name: $primary_name_line"
  
  # Step 3: Extract the Actual Name Value
  PRIMARY_HOST=$(echo "$primary_name_line" | sed "s/.*name: '\([^']*\)'.*/\1/")
  echo "Extracted primary node: $PRIMARY_HOST"

  if [ -z "$PRIMARY_HOST" ]; then
    echo "Failed to find the primary node."
    return 1
  else
    echo "Primary node found: $PRIMARY_HOST"
    return 0
  fi
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

# Check if the designated primary node is up
until check_mongo "$MONGO_PRIMARY_HOST" "$MONGO_PORT"; do
  echo "Waiting for MongoDB to be up at $MONGO_PRIMARY_HOST:$MONGO_PORT..."
  sleep 2
done

echo "MongoDB is up. Initiating replica set..."

# Initiate replica set and capture result
if ! initiate_replica_set; then
  echo "Failed to initiate replica set. Please check the logs for more information."
  exit 1
fi

# Execute GraphQL mutation to remove the init service
echo "Executing GraphQL mutation to remove the init service..."
curl --location "$RAILWAY_API_URL" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $RAILWAY_API_TOKEN" \
  --data "{\"query\":\"mutation serviceDelete(\$environmentId: String, \$id: String!) { serviceDelete(environmentId: \$environmentId, id: \$id) }\",\"variables\":{\"environmentId\":\"$ENVIRONMENT_ID\",\"id\":\"$SERVICE_ID\"}}"

if [ $? -eq 0 ]; then
  echo "GraphQL mutation executed successfully."
else
  echo "Failed to delete the service via the API. Please delete it manually."
  exit 1
fi

exit 0
