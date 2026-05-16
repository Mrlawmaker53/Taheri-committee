// Test notification function for debugging push notification issues
// Add this to your functions/index.js or deploy separately

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Test notification function - callable from Flutter app
 * Usage: await FirebaseFunctions.instance.httpsCallable('testNotification').call({
 *   userId: 'target_user_id',
 *   message: 'Test message from admin'
 * });
 */
exports.testNotification = functions.https.onCall(async (data, context) => {
  // Verify caller is authenticated and has admin/supervisor role
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Authentication required'
    );
  }

  const callerUid = context.auth.uid;
  const callerDoc = await db.collection('users').doc(callerUid).get();
  const callerRole = callerDoc.data()?.role;

  if (!['admin', 'leader', 'supervisor'].includes(callerRole)) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Admin access required'
    );
  }

  const { userId, message, title } = data;

  if (!userId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'userId is required'
    );
  }

  try {
    // Get user's FCM tokens
    const tokensSnapshot = await db
      .collection('fcm_tokens')
      .where('userId', '==', userId)
      .where('isActive', '==', true)
      .get();

    if (tokensSnapshot.empty) {
      return {
        success: false,
        message: 'No active FCM tokens found for user',
        userId: userId,
        debug: {
          hasUser: true,
          tokensCount: 0,
          suggestion: 'User may need to enable notifications in browser'
        }
      };
    }

    const tokens = tokensSnapshot.docs.map(doc => doc.data().token);
    
    // Prepare notification payload
    const payload = {
      notification: {
        title: title || 'Test Notification',
        body: message || 'This is a test notification from admin',
      },
      data: {
        type: 'test',
        requiresResponse: 'false',
        sentBy: callerUid,
        sentAt: new Date().toISOString(),
      },
      tokens: tokens,
    };

    // Send notification
    const response = await messaging.sendMulticast(payload);
    
    // Log results for debugging
    console.log('Test notification results:', {
      userId: userId,
      totalTokens: tokens.length,
      successCount: response.successCount,
      failureCount: response.failureCount,
      responses: response.responses
    });

    // Handle failed tokens
    if (response.failureCount > 0) {
      const failedTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          failedTokens.push({
            token: tokens[idx],
            error: resp.error
          });
        }
      });

      // Deactivate failed tokens
      for (const failed of failedTokens) {
        await db
          .collection('fcm_tokens')
          .where('token', '==', failed.token)
          .limit(1)
          .get()
          .then(snapshot => {
            if (!snapshot.empty) {
              return snapshot.docs[0].ref.update({
                isActive: false,
                lastError: failed.error.message,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
              });
            }
          });
      }
    }

    return {
      success: true,
      message: 'Test notification sent successfully',
      results: {
        userId: userId,
        totalTokens: tokens.length,
        successCount: response.successCount,
        failureCount: response.failureCount,
        failedTokens: response.failureCount > 0 ? failedTokens : null
      }
    };

  } catch (error) {
    console.error('Test notification error:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to send test notification: ' + error.message
    );
  }
});

/**
 * Get notification status for a user
 * Returns FCM tokens and permission status
 */
exports.getNotificationStatus = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Authentication required'
    );
  }

  const { userId } = data;
  const targetUserId = userId || context.auth.uid;

  try {
    // Get user's FCM tokens
    const tokensSnapshot = await db
      .collection('fcm_tokens')
      .where('userId', '==', targetUserId)
      .get();

    const tokens = tokensSnapshot.docs.map(doc => ({
      tokenId: doc.id,
      token: doc.data().token,
      platform: doc.data().platform,
      isActive: doc.data().isActive,
      updatedAt: doc.data().updatedAt?.toDate(),
    }));

    // Get user info
    const userDoc = await db.collection('users').doc(targetUserId).get();
    const userData = userDoc.data();

    return {
      success: true,
      userId: targetUserId,
      user: {
        email: userData?.email,
        role: userData?.role,
        isActive: userData?.isActive,
      },
      tokens: tokens,
      activeTokens: tokens.filter(t => t.isActive).length,
      lastTokenUpdate: tokens.length > 0 
        ? Math.max(...tokens.map(t => t.updatedAt?.getTime() || 0))
        : null,
    };

  } catch (error) {
    console.error('Get notification status error:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to get notification status: ' + error.message
    );
  }
});

/**
 * Force refresh FCM token for current user
 * Useful when troubleshooting token issues
 */
exports.refreshToken = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Authentication required'
    );
  }

  const userId = context.auth.uid;

  try {
    // Deactivate all existing tokens for this user
    const existingTokens = await db
      .collection('fcm_tokens')
      .where('userId', '==', userId)
      .get();

    const batch = db.batch();
    existingTokens.docs.forEach(doc => {
      batch.update(doc.ref, {
        isActive: false,
        deactivatedAt: admin.firestore.FieldValue.serverTimestamp(),
        reason: 'manual_refresh'
      });
    });

    await batch.commit();

    return {
      success: true,
      message: 'All existing tokens deactivated. User should refresh the page to register new token.',
      deactivatedCount: existingTokens.size,
      userId: userId,
    };

  } catch (error) {
    console.error('Refresh token error:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to refresh tokens: ' + error.message
    );
  }
});
