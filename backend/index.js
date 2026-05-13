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

// Simple debug helper - enable with DEBUG=true in env
const isDebug = !!(process.env.DEBUG && process.env.DEBUG !== 'false');
const debug = (...args) => {
    if (isDebug) console.debug(...args);
};

// Authentication middleware with optional debug logging
const verifyAuth = async (req, res, next) => {
    const authHeader = req.headers.authorization || req.headers.Authorization;
    debug('[auth] Incoming request:', req.method, req.originalUrl, 'from', req.ip);

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        debug('[auth] No Bearer token found in Authorization header.');
        return res.status(401).json({ error: 'Unauthorized: No token provided' });
    }

    const idToken = authHeader.split(' ')[1];
    try {
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        debug('[auth] Token verified. uid=', decodedToken.uid);
        // attach decoded token to request for downstream handlers
        req.user = decodedToken;
        next();
    } catch (error) {
        debug('[auth] Token verification failed:', error && error.message ? error.message : error);
        return res.status(401).json({ error: 'Unauthorized: Invalid token' });
    }
};

// Health Check
app.get('/', (req, res) => {
    debug('[health] Health check received from', req.ip, '-', req.method, req.originalUrl);
    // include a minimal headers summary to help debug clients
    debug('[health] Headers summary:', JSON.stringify({ host: req.headers.host, ua: req.headers['user-agent'] }));
    res.send('Let\'s Chat Backend is running!');
});

// Get all users (Example of an administrative task)
// Protected: get all users (requires valid Firebase ID token)
app.get('/api/users', verifyAuth, async (req, res) => {
    try {
    debug('[users] Requesting user list - requested by uid=', req.user ? req.user.uid : 'unknown');
        const snapshot = await db.collection('users').get();
        const users = snapshot.docs.map(doc => doc.data());
        res.status(200).json(users);
    } catch (error) {
    debug('[users] Error fetching users:', error && error.message ? error.message : error);
        res.status(500).json({ error: error.message });
    }
});

// Protected: send notification (requires valid Firebase ID token)
app.post('/api/send-notification', verifyAuth, async (req, res) => {
    const { token, title, body } = req.body;
    const message = {
        notification: { title, body },
        token: token
    };

    try {
    debug('[notify] Sending notification - from uid=', req.user ? req.user.uid : 'unknown', 'to token=', token, 'title=', title);
        const response = await admin.messaging().send(message);
    debug('[notify] Notification send response:', response);
        res.status(200).json({ success: true, response });
    } catch (error) {
    debug('[notify] Error sending notification:', error && error.message ? error.message : error);
        res.status(500).json({ error: error.message });
    }
});

// Admin/Utility: Seed initial data
// Note: In a production app, this should be highly restricted or removed.
app.post('/api/seed-data', async (req, res) => {
    try {
        console.log("Seeding initial data...");
        
        // Seed some communities
        const communities = [
            { name: "Travel Buddies", description: "Connect with fellow travelers around the world." },
            { name: "Culinary Arts", description: "Share recipes and cooking tips with foodies." },
            { name: "Wellness & Yoga", description: "A space for mindfulness and physical health." },
            { name: "General", description: "The main community for everyone." }
        ];

        for (const community of communities) {
            await db.collection('communities').doc(community.name).set({
                ...community,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                members: []
            }, { merge: true });
        }

        // Seed a sample system user if doesn't exist
        await db.collection('users').doc('system_user').set({
            uid: 'system_user',
            email: 'system@letschat.com',
            name: 'System Assistant',
            about: 'I am here to help you get started!',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            settings: {
                Privacy: { "Last seen": "Everyone" }
            }
        }, { merge: true });

        console.log("Seeding completed successfully.");
        res.status(200).json({ success: true, message: "Initial data seeded successfully." });
    } catch (error) {
        console.error("Seeding error:", error);
        res.status(500).json({ error: error.message });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
