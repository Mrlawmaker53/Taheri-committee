import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/models/transfer_request_model.dart';
import '../../core/services/firestore_service.dart';
import 'transfers_controller.dart';

class SupervisorApproveScreen extends StatelessWidget {
  const SupervisorApproveScreen({super.key});

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
        title: const Text('Transfer Requests'),
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final padding = constraints.maxWidth > 700 ? 32.0 : 16.0;
          return RefreshIndicator(
            onRefresh: () async {},
            child: Obx(() {
              if (ctrl.pendingSupervisor.isEmpty) {
                return ListView(
                  padding: EdgeInsets.all(padding),
                  children: [
                    const SizedBox(height: 80),
                    Center(
                      child: Column(
                        children: [
                          FaIcon(FontAwesomeIcons.arrowRightArrowLeft,
                              size: 56, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('No pending transfer requests',
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return ListView.builder(
                padding: EdgeInsets.all(padding),
                itemCount: ctrl.pendingSupervisor.length,
                itemBuilder: (ctx, i) => _TransferCard(
                  req: ctrl.pendingSupervisor[i],
                  ctrl: ctrl,
                  isSupervisor: true,
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _TransferCard extends StatelessWidget {
  final TransferRequestModel req;
  final TransfersController ctrl;
  final bool isSupervisor;

  const _TransferCard({
    required this.req,
    required this.ctrl,
    required this.isSupervisor,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        FirestoreService.getUser(req.memberId),
        if (req.toTeamId.isNotEmpty)
          FirestoreService.teams.doc(req.toTeamId).get()
        else
          Future.value(null),
      ]),
      builder: (ctx, snap) {
        final memberName = snap.hasData && snap.data![0] != null
            ? (snap.data![0] as dynamic).fullName as String
            : req.memberId;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.arrowRightArrowLeft,
                        color: Color(0xFF047857), size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        memberName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.rightLong,
                        size: 12, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text('To Team: ${req.toTeamId}',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12)),
                    const Spacer(),
                    Text(
                      DateFormat('dd MMM').format(req.createdAt),
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('"${req.reason}"',
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontStyle: FontStyle.italic)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _showActionDialog(context, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                        icon: const FaIcon(FontAwesomeIcons.check,
                            size: 12),
                        label: const Text('Approve'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _showActionDialog(context, false),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        icon: const FaIcon(FontAwesomeIcons.xmark,
                            size: 12),
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
            labelText: isApprove ? 'Note (optional)' : 'Reason',
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
              if (isSupervisor) {
                if (isApprove) {
                  ctrl.supervisorApprove(req, noteCtrl.text.trim());
                } else {
                  ctrl.supervisorDecline(req, noteCtrl.text.trim());
                }
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
