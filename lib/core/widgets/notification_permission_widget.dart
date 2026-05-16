import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import '../services/fcm_service.dart';

/// Widget to handle notification permission for web users
/// Shows current status and allows manual permission request
class NotificationPermissionWidget extends StatefulWidget {
  const NotificationPermissionWidget({super.key});

  @override
  State<NotificationPermissionWidget> createState() => _NotificationPermissionWidgetState();
}

class _NotificationPermissionWidgetState extends State<NotificationPermissionWidget> {
  AuthorizationStatus? _permissionStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      setState(() {
        _permissionStatus = settings.authorizationStatus;
      });
    } catch (e) {
      debugPrint('Error checking notification permission: $e');
    }
  }

  Future<void> _requestPermission() async {
    if (!kIsWeb) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // This is called from a user gesture (button press)
      await FCMService.initForUser();
      
      // Re-check status after permission request
      await _checkPermissionStatus();
      
      if (_permissionStatus == AuthorizationStatus.authorized) {
        Get.snackbar(
          'Success!',
          'Notifications enabled successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          'Permission Required',
          'Please allow notifications in your browser settings',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to enable notifications: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor() {
    switch (_permissionStatus) {
      case AuthorizationStatus.authorized:
        return Colors.green;
      case AuthorizationStatus.provisional:
        return Colors.blue;
      case AuthorizationStatus.denied:
        return Colors.red;
      case AuthorizationStatus.notDetermined:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (_permissionStatus) {
      case AuthorizationStatus.authorized:
        return '✅ Notifications Enabled';
      case AuthorizationStatus.provisional:
        return '⚠️ Notifications Partially Enabled';
      case AuthorizationStatus.denied:
        return '❌ Notifications Blocked';
      case AuthorizationStatus.notDetermined:
        return '⚠️ Notifications Not Set Up';
      default:
        return '❓ Checking Status...';
    }
  }

  String _getActionText() {
    switch (_permissionStatus) {
      case AuthorizationStatus.authorized:
        return 'Manage Settings';
      case AuthorizationStatus.denied:
        return 'Enable in Browser';
      case AuthorizationStatus.notDetermined:
        return 'Enable Notifications';
      default:
        return 'Retry Setup';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        border: Border.all(color: _getStatusColor(), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications,
                color: _getStatusColor(),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Notification Status',
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getStatusText(),
            style: TextStyle(
              color: _getStatusColor(),
              fontSize: 14,
            ),
          ),
          if (_permissionStatus != AuthorizationStatus.authorized) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _requestPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getStatusColor(),
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(_getActionText()),
              ),
            ),
            if (_permissionStatus == AuthorizationStatus.denied)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'To enable notifications:\n1. Click the lock icon in your browser\'s address bar\n2. Set notifications to "Allow"\n3. Refresh this page',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
