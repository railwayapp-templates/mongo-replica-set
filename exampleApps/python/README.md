# Example python app

This Python app is intended to demonstrate how to connect to the Mongo replica set deployed from the template in Railway

## Required environment variables

You should set the following variables in the service configuration in Railway
```
DATABASE_NAME=railway
REPLICA_SET_NAME=${{mongo1.REPLICA_SET_NAME}}
COLLECTION_NAME=mycollection
MONGO_HOSTS=${{mongo1.RAILWAY_PRIVATE_DOMAIN}}:27017,${{mongo2.RAILWAY_PRIVATE_DOMAIN}}:27017,${{mongo3.RAILWAY_PRIVATE_DOMAIN}}:27017
MONGO_URI=mongodb://${{mongo1.MONGO_INITDB_ROOT_USERNAME}}:${{mongo1.MONGO_INITDB_ROOT_PASSWORD}}@${{MONGO_HOSTS}}/?replicaSet=${{REPLICA_SET_NAME}}
```
