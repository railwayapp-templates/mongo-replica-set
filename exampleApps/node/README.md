# Example node app

This Node app is intended to demonstrate how to connect to the Mongo replica set deployed from the template in Railway

## Required environment variables

You should set the following variables in the service configuration in Railway:
```
COLLECTION_NAME=nodeCollection
DATABASE_NAME=railway
MONGO_HOSTS=${{mongo1.RAILWAY_PRIVATE_DOMAIN}}:27017,${{mongo2.RAILWAY_PRIVATE_DOMAIN}}:27017,${{mongo3.RAILWAY_PRIVATE_DOMAIN}}:27017
MONGO_URI=mongodb://${{mongo1.MONGO_INITDB_ROOT_USERNAME}}:${{mongo1.MONGO_INITDB_ROOT_PASSWORD}}@${{MONGO_HOSTS}}/?replicaSet=${{REPLICA_SET_NAME}}
REPLICA_SET_NAME=${{mongo1.REPLICA_SET_NAME}}
```