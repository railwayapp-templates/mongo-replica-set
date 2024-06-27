from fastapi import FastAPI, HTTPException
from motor.motor_asyncio import AsyncIOMotorClient
import os
from typing import List, Dict
import random
import string

app = FastAPI()

print(os.getenv("MONGO_URI"))

# MongoDB client (motor)
client = AsyncIOMotorClient(os.getenv("MONGO_URI"))
db = client[os.getenv("DATABASE_NAME")]
collection = db[os.getenv("COLLECTION_NAME")]

def generate_random_string(length=8):
    letters = string.ascii_lowercase
    print("generated random string")
    return ''.join(random.choice(letters) for i in range(length))

@app.get("/")
async def set_item():
    random_key = generate_random_string()
    random_value = generate_random_string()
    print("sending to Mongo")
    result = await collection.update_one(
        {"key": random_key}, {"$set": {"value": random_value}}, upsert=True
    )
    print(result)
    if result.upserted_id or result.modified_count:
        return {"status": "success", "key": random_key, "value": random_value}
    raise HTTPException(status_code=500, detail="Failed to set item")

@app.get("/get", response_model=List[Dict[str, str]])
async def get_all_items():
    cursor = collection.find({})
    print("retrieving from Mongo")
    items = await cursor.to_list(length=None)
    for item in items:
        item['_id'] = str(item['_id'])
    return items

@app.get("/health")
async def healthcheck():
    print("starting healthcheck, pulling from mongo")
    cursor = collection.aggregate([{'$sample': {'size': 1}}])
    random_doc = await cursor.to_list(length=1)
    
    if random_doc:
        print("healthcheck successful")
        return {"status": "success", "document": random_doc[0]}
    else:
        print("No documents found")
        raise HTTPException(status_code=500, detail="No documents found in the collection")
