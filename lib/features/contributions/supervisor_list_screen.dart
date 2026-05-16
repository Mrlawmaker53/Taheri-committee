import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/models/contribution_model.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/user_model.dart';
import '../../core/widgets/shimmer_widgets.dart';
import 'contributions_controller.dart';

class SupervisorListScreen extends StatelessWidget {
  const SupervisorListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(ContributionsController());

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.chevronLeft,
              color: Colors.white, size: 16),
          onPressed: () => Get.back(),
        ),
        title: const Text('Member Contributions'),
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final padding = constraints.maxWidth > 700 ? 32.0 : 16.0;
          return Obx(() {
            if (!ctrl.hasLoadedPending.value) {
              return const CardListShimmer(itemCount: 4, cardHeight: 110);
            }
            final pending = ctrl.pendingContributions;
            if (pending.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(FontAwesomeIcons.checkDouble,
                        size: 56, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('No pending contributions',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('All caught up!',
                        style: TextStyle(color: Colors.grey.shade400)),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: EdgeInsets.all(padding),
              itemCount: pending.length,
              itemBuilder: (ctx, i) => _PendingContribCard(
                contrib: pending[i],
                ctrl: ctrl,
              ),
            );
          });
        },
      ),
      floatingActionButton: Obx(() {
        if (ctrl.pendingContributions.isEmpty) return const SizedBox();
        return FloatingActionButton.extended(
          onPressed: () => Get.toNamed('/contributions/group-request'),
          icon: const FaIcon(FontAwesomeIcons.layerGroup, size: 14),
          label: const Text('Raise Group Request'),
          backgroundColor: const Color(0xFF047857),
        );
      }),
    );
  }
}

class _PendingContribCard extends StatelessWidget {
  final ContributionModel contrib;
  final ContributionsController ctrl;

  const _PendingContribCard({required this.contrib, required this.ctrl});

  Future<UserModel?> _getMember() => FirestoreService.getUser(contrib.memberId);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _getMember(),
      builder: (ctx, snap) {
        final name = snap.data?.fullName ?? contrib.memberId;
        final initials = snap.data?.initials ?? '?';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF059669),
                      child: Text(initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Pending',
                                style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'INR ${contrib.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF047857)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '"${contrib.note}"',
                  style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showNoteDialog(context, true, name),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                        icon: const FaIcon(FontAwesomeIcons.check, size: 12),
                        label: const Text('Approve'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showNoteDialog(context, false, name),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        icon: const FaIcon(FontAwesomeIcons.xmark, size: 12),
                        label: const Text('Decline'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNoteDialog(
      BuildContext context, bool isApprove, String memberName) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text(isApprove ? 'Approve Contribution' : 'Decline Contribution'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Member: $memberName',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Amount: INR ${contrib.amount.toStringAsFixed(0)}'),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: isApprove
                    ? 'Receipt Note (optional)'
                    : 'Reason for decline',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (isApprove) {
                ctrl.approveContribution(contrib, noteCtrl.text.trim());
              } else {
                ctrl.declineContribution(contrib, noteCtrl.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: isApprove ? Colors.green : Colors.red),
            child: Text(isApprove ? 'Approve' : 'Decline'),
          ),
        ],
      ),
    );
  }
}
