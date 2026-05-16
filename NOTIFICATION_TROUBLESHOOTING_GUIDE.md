# Push Notification Troubleshooting Guide

## Problem Identified
Members are not receiving push notifications even though they've granted permission in the browser/app.

## Root Cause Analysis

### 1. **Web Permission Issues** (Most Likely)
The FCM service shows specific web permission handling issues:

```dart
// From fcm_service.dart lines 113-119
if (kIsWeb &&
    settings.authorizationStatus != AuthorizationStatus.authorized &&
    settings.authorizationStatus != AuthorizationStatus.provisional) {
  debugPrint('ℹ️ FCM: web permission not granted — will retry from user gesture');
  return;
}
```

**Issue**: Web browsers reject `requestPermission()` calls outside user gesture handlers.

### 2. **Token Registration Problems**
- FCM tokens might not be properly saved to `fcm_tokens` collection
- Tokens might be inactive or expired
- User authentication state issues

### 3. **Cloud Functions Not Triggering**
- Admin actions might not be calling notification functions
- Target user selection issues
- Message payload problems

## Diagnostic Steps

### Step 1: Check Browser Console
1. Open browser DevTools (F12)
2. Go to Console tab
3. Look for these messages:
   - `✅ FCM token saved` (success)
   - `ℹ️ FCM: web permission not granted` (permission issue)
   - `FCM requestPermission error` (permission denied)

### Step 2: Verify FCM Token in Firestore
1. Go to Firebase Console → Firestore Database
2. Check `fcm_tokens` collection
3. Look for the member's user ID
4. Verify:
   - Token exists
   - `isActive: true`
   - `updatedAt` is recent
   - `platform: 'web'`

### Step 3: Test Permission Flow
1. Member must click a button to trigger permission
2. Check browser permission settings:
   - Chrome: Settings → Privacy and security → Site Settings → Notifications
   - Firefox: Options → Privacy & Security → Permissions → Notifications

## Fixes Required

### Fix 1: Improve Web Permission Handling
The current code retries permission from user gesture, but needs better UX:

```dart
// Add to login_screen.dart or dashboard
ElevatedButton(
  onPressed: () async {
    // This is a user gesture - permission will work
    await FCMService.initForUser();
  },
  child: Text('Enable Notifications'),
)
```

### Fix 2: Add Notification Status Indicator
Create a widget to show notification status:

```dart
class NotificationStatusWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final auth = Get.find<AuthController>();
      if (!auth.isLoggedIn.value) return SizedBox.shrink();
      
      return FutureBuilder<bool>(
        future: _checkNotificationPermission(),
        builder: (context, snapshot) {
          final hasPermission = snapshot.data ?? false;
          return Container(
            padding: EdgeInsets.all(8),
            color: hasPermission ? Colors.green : Colors.orange,
            child: Text(
              hasPermission ? '✅ Notifications Enabled' : '⚠️ Enable Notifications',
              style: TextStyle(color: Colors.white),
            ),
          );
        },
      );
    });
  }
  
  Future<bool> _checkNotificationPermission() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }
}
```

### Fix 3: Manual Token Registration
Add a manual trigger for members to register their FCM token:

```dart
// Add to member dashboard or settings
Future<void> manuallyRegisterToken() async {
  try {
    await FCMService.initForUser();
    Get.snackbar(
      'Success',
      'Notifications enabled successfully!',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  } catch (e) {
    Get.snackbar(
      'Error',
      'Failed to enable notifications: $e',
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}
```

### Fix 4: Admin Notification Testing
Create a test function for admins to send notifications:

```javascript
// Add to functions/index.js
exports.testNotification = functions.https.onCall(async (data, context) => {
  const { userId, message } = data;
  
  // Get user's FCM tokens
  const tokens = await getTokensForUsers([userId]);
  
  if (tokens.length === 0) {
    throw new functions.https.HttpsError(
      'not-found',
      'No active FCM tokens found for user'
    );
  }
  
  // Send test notification
  const payload = {
    notification: {
      title: 'Test Notification',
      body: message || 'This is a test notification from admin',
    },
    data: {
      type: 'test',
      requiresResponse: 'false',
    },
    tokens: tokens,
  };
  
  try {
    const response = await messaging.sendMulticast(payload);
    return {
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
    };
  } catch (error) {
    throw new functions.https.HttpsError(
      'internal',
      'Failed to send notification: ' + error.message
    );
  }
});
```

## Immediate Action Plan

### For Members:
1. **Clear Browser Cache**: Members should clear browser cache and cookies
2. **Re-grant Permission**: 
   - Go to browser settings
   - Remove site permission for notifications
   - Refresh the app
   - Click "Enable Notifications" button
3. **Check Console**: Look for FCM success messages

### For Admins:
1. **Test Cloud Functions**: Use the test notification function
2. **Check Target User Selection**: Ensure correct user IDs are being targeted
3. **Verify Message Payload**: Check notification structure matches expected format

### For Developers:
1. **Add Permission Status UI**: Show members if notifications are enabled
2. **Improve Error Handling**: Better error messages for permission issues
3. **Add Manual Registration**: Allow members to manually trigger token registration

## Common Issues & Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| No permission dialog | Called outside user gesture | Add button to trigger permission |
| Token not saved | Web permission denied | Clear site permissions and retry |
| No notifications received | Cloud function not called | Check admin action triggers |
| Wrong user targeted | Incorrect user ID | Verify user selection logic |

## Verification Checklist

- [ ] Member sees permission dialog
- [ ] Console shows "✅ FCM token saved"
- [ ] Token exists in Firestore with `isActive: true`
- [ ] Admin can send test notifications
- [ ] Member receives test notification
- [ ] Real admin actions trigger notifications

## Next Steps

1. **Immediate**: Add manual notification enable button for members
2. **Short-term**: Implement notification status indicator
3. **Long-term**: Improve permission flow and error handling

This should resolve the notification issues for member users! 🎯
