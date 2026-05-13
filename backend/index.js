const express = require('express');
const admin = require('firebase-admin');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

// Initialize Firebase Admin
// Download serviceAccountKey.json from Firebase Console → Project Settings → Service Accounts
const serviceAccount = require("./serviceAccountKey.json");
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});
console.log("Firebase Admin initialized successfully.");

const db = admin.firestore();

// Health Check
app.get('/', (req, res) => {
    res.send('Let\'s Chat Backend is running!');
});

// Get all users (Example of an administrative task)
app.get('/api/users', async (req, res) => {
    try {
        const snapshot = await db.collection('users').get();
        const users = snapshot.docs.map(doc => doc.data());
        res.status(200).json(users);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Send notification (Example of server-side logic)
app.post('/api/send-notification', async (req, res) => {
    const { token, title, body } = req.body;
    const message = {
        notification: { title, body },
        token: token
    };

    try {
        const response = await admin.messaging().send(message);
        res.status(200).json({ success: true, response });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
