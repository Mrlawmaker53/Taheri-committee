import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class ActivityLogService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> log({
    required String action,
    required String targetId,
    required String targetType,
    required String targetName,
    String? note,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final auth = Get.find<AuthController>();
      final payload = <String, dynamic>{
        'actorId': auth.uid,
        'actorName': auth.displayName,
        'actorRole': auth.role,
        'action': action,
        'targetId': targetId,
        'targetType': targetType,
        'targetName': targetName,
        'note': note ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      };
      if (metadata != null && metadata.isNotEmpty) {
        payload['metadata'] = metadata;
      }
      await _db.collection('activity_logs').add(payload);
    } catch (_) {}
  }
}
