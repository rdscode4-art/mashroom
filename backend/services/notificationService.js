const admin = require('firebase-admin');
const serviceAccount = require('../config/rifresh-firebase-adminsdk.json');

// Initialize Firebase Admin SDK
try {
  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    console.log('Firebase Admin SDK initialized successfully.');
  }
} catch (error) {
  console.error('Firebase Admin initialization error:', error.message);
}

/**
 * Sends a push notification to one or multiple device tokens.
 * @param {Array<string>|string} tokens - A single FCM token or an array of tokens.
 * @param {string} title - The notification title.
 * @param {string} body - The notification body.
 * @param {object} data - Optional data payload.
 * @param {object} androidConfig - Optional Android-specific config (e.g. channel_id, priority).
 */
const sendPushNotification = async (tokens, title, body, data = {}, androidConfig = {}) => {
  try {
    const tokenList = Array.isArray(tokens) ? tokens : [tokens];
    const validTokens = tokenList.filter(t => t && typeof t === 'string' && t.trim() !== '');

    if (validTokens.length === 0) {
      console.log('No valid FCM tokens provided. Skipping notification.');
      return null;
    }

    const message = {
      notification: {
        title,
        body
      },
      data: {
        ...data,
        click_action: 'FLUTTER_NOTIFICATION_CLICK'
      },
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          ...androidConfig
        }
      },
      apns: {
        payload: {
          aps: {
            sound: androidConfig.sound === 'order_sound' ? 'order_sound.aiff' : 'default',
            contentAvailable: true,
          }
        }
      },
      tokens: validTokens,
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    
    console.log(`Successfully sent ${response.successCount} messages. Failed: ${response.failureCount}`);
    if (response.failureCount > 0) {
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          console.error(`Error sending to token ${validTokens[idx]}:`, resp.error);
        }
      });
    }
    
    return response;
  } catch (error) {
    console.error('Error sending push notification:', error);
    throw error;
  }
};

module.exports = {
  sendPushNotification
};
