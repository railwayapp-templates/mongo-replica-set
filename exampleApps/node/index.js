const express = require('express');
const { MongoClient } = require('mongodb');
const randomString = require('randomstring');

const app = express();
const port = process.env.PORT || 3000;

// MongoDB client (for replica set)
const client = new MongoClient(process.env.MONGO_URI);

let collection;

async function connectToDatabase() {
    try {
        await client.connect();
        const db = client.db(process.env.DATABASE_NAME);
        collection = db.collection(process.env.COLLECTION_NAME);
        console.log('Connected to MongoDB');
    } catch (err) {
        console.error('Failed to connect to MongoDB', err);
    }
}

connectToDatabase();

function generateRandomString(length = 8) {
    const result = randomString.generate(length);
    console.log('Generated random string:', result);
    return result;
}

app.get('/', async (req, res) => {
    try {
        const randomKey = generateRandomString();
        const randomValue = generateRandomString();
        console.log('Sending to Mongo');
        const result = await collection.updateOne(
            { key: randomKey },
            { $set: { value: randomValue } },
            { upsert: true }
        );
        console.log(result);
        if (result.upsertedId || result.modifiedCount) {
            res.json({ status: 'success', key: randomKey, value: randomValue });
        } else {
            res.status(500).json({ detail: 'Failed to set item' });
        }
    } catch (err) {
        console.error('Error setting item:', err);
        res.status(500).json({ detail: 'Failed to set item' });
    }
});

app.get('/get', async (req, res) => {
    try {
        console.log('Retrieving from Mongo');
        const items = await collection.find({}).toArray();
        items.forEach(item => {
            item._id = item._id.toString();
        });
        res.json(items);
    } catch (err) {
        console.error('Error retrieving items:', err);
        res.status(500).json({ detail: 'Failed to retrieve items' });
    }
});

app.get('/health', async (req, res) => {
    try {
        console.log('Starting health check, pulling from Mongo');
        const cursor = collection.aggregate([{ $sample: { size: 1 } }]);
        const randomDoc = await cursor.toArray();
        if (randomDoc.length > 0) {
            console.log('Health check successful');
            res.json({ status: 'success', document: randomDoc[0] });
        } else {
            console.log('No documents found');
            res.status(500).json({ detail: 'No documents found in the collection' });
        }
    } catch (err) {
        console.error('Health check failed:', err);
        res.status(500).json({ detail: 'Failed to perform health check' });
    }
});

app.listen(port, '::',  () => {
    console.log(`Server is running on port: ${port}`);
});
