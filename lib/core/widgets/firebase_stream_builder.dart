import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Generic StreamBuilder wrapper for Firestore collections.
/// Handles loading (shimmer), error and empty states uniformly.
class FirebaseListBuilder<T> extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final T Function(DocumentSnapshot doc) fromDoc;
  final Widget Function(List<T> items) builder;
  final Widget shimmer;
  final Widget emptyState;
  final VoidCallback? onRetry;

  const FirebaseListBuilder({
    super.key,
    required this.stream,
    required this.fromDoc,
    required this.builder,
    required this.shimmer,
    required this.emptyState,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return shimmer;
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off_rounded,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load data',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 14),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(height: 8),
                    TextButton(
                        onPressed: onRetry, child: const Text('Retry')),
                  ],
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return emptyState;
        }
        final items =
            snapshot.data!.docs.map((doc) => fromDoc(doc)).toList();
        return builder(items);
      },
    );
  }
}

/// Generic FutureBuilder wrapper for a single Firestore document.
class FirebaseDocBuilder<T> extends StatelessWidget {
  final Future<DocumentSnapshot> future;
  final T Function(Map<String, dynamic> data) fromMap;
  final Widget Function(T item) builder;
  final Widget shimmer;

  const FirebaseDocBuilder({
    super.key,
    required this.future,
    required this.fromMap,
    required this.builder,
    required this.shimmer,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return shimmer;
        }
        if (snapshot.hasError ||
            !snapshot.hasData ||
            !snapshot.data!.exists) {
          return Center(
            child: Text(
              'Data not found',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          );
        }
        final item =
            fromMap(snapshot.data!.data() as Map<String, dynamic>);
        return builder(item);
      },
    );
  }
}
