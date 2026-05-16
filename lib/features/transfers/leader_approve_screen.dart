import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/models/transfer_request_model.dart';
import '../../core/services/firestore_service.dart';
import 'transfers_controller.dart';

class LeaderApproveScreen extends StatelessWidget {
  const LeaderApproveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(TransfersController());

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.chevronLeft,
              color: Colors.white, size: 16),
          onPressed: () => Get.back(),
        ),
        title: const Text('Pending Transfers'),
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final padding = constraints.maxWidth > 700 ? 32.0 : 16.0;
          return RefreshIndicator(
            onRefresh: () async {},
            child: Obx(() {
              if (ctrl.pendingLeader.isEmpty) {
                return ListView(
                  padding: EdgeInsets.all(padding),
                  children: [
                    const SizedBox(height: 80),
                    Center(
                      child: Column(
                        children: [
                          FaIcon(FontAwesomeIcons.checkDouble,
                              size: 56, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('No transfers awaiting approval',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return ListView.builder(
                padding: EdgeInsets.all(padding),
                itemCount: ctrl.pendingLeader.length,
                itemBuilder: (ctx, i) => _LeaderTransferCard(
                  req: ctrl.pendingLeader[i],
                  ctrl: ctrl,
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _LeaderTransferCard extends StatelessWidget {
  final TransferRequestModel req;
  final TransfersController ctrl;

  const _LeaderTransferCard({required this.req, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: FirestoreService.getUser(req.memberId),
      builder: (ctx, snap) {
        final memberName = snap.data?.fullName ?? req.memberId;
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
                          Text(memberName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              Text(req.fromTeamId,
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12)),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: FaIcon(
                                    FontAwesomeIcons.arrowRight,
                                    size: 10,
                                    color: Colors.grey),
                              ),
                              Text(req.toTeamId,
                                  style: const TextStyle(
                                      color: Color(0xFF047857),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        border: Border.all(color: Colors.orange.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Pending',
                          style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('"${req.reason}"',
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontStyle: FontStyle.italic)),
                if (req.supervisorNote.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.userTie,
                          size: 11, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('Supervisor: ${req.supervisorNote}',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 11)),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Requested ${DateFormat('dd MMM yyyy').format(req.createdAt)}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _showActionDialog(context, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                        icon: const FaIcon(FontAwesomeIcons.check, size: 12),
                        label: const Text('Approve Move'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _showActionDialog(context, false),
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

  void _showActionDialog(BuildContext context, bool isApprove) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isApprove ? 'Approve Transfer' : 'Decline Transfer'),
        content: TextField(
          controller: noteCtrl,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: isApprove ? 'Note (optional)' : 'Reason for decline',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (isApprove) {
                ctrl.leaderApprove(req, noteCtrl.text.trim());
              } else {
                ctrl.leaderDecline(req, noteCtrl.text.trim());
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
