import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/models/contribution_model.dart';
import '../../core/services/firestore_service.dart';
import '../../core/widgets/shimmer_widgets.dart';
import 'contributions_controller.dart';

class MyContributionsScreen extends StatelessWidget {
  const MyContributionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(ContributionsController());

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {},
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final padding = constraints.maxWidth > 700 ? 32.0 : 16.0;
            return Obx(() {
              if (!ctrl.hasLoadedMine.value) {
                return const CardListShimmer(itemCount: 4, cardHeight: 110);
              }
              if (ctrl.myContributions.isEmpty) {
                return ListView(
                  padding: EdgeInsets.all(padding),
                  children: const [
                    SizedBox(height: 80),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(FontAwesomeIcons.receipt,
                              size: 56, color: Colors.white24),
                          SizedBox(height: 16),
                          Text('No contributions yet',
                              style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500)),
                          SizedBox(height: 8),
                          Text('Your submitted contributions will appear here.',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return ListView.builder(
                padding: EdgeInsets.all(padding),
                itemCount: ctrl.myContributions.length,
                itemBuilder: (ctx, i) =>
                    _ContributionCard(contrib: ctrl.myContributions[i]),
              );
            });
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/contributions/raise'),
        icon: const FaIcon(FontAwesomeIcons.plus, size: 14),
        label: const Text('Raise Request'),
        backgroundColor: const Color(0xFF047857),
      ),
    );
  }
}

class _ContributionCard extends StatefulWidget {
  final ContributionModel contrib;
  const _ContributionCard({required this.contrib});

  @override
  State<_ContributionCard> createState() => _ContributionCardState();
}

class _ContributionCardState extends State<_ContributionCard> {
  bool _expanded = false;
  String _supervisorName = '';

  @override
  void initState() {
    super.initState();
    if (widget.contrib.resolvedBy.isNotEmpty) {
      _loadSupervisorName();
    }
  }

  Future<void> _loadSupervisorName() async {
    final user = await FirestoreService.getUser(widget.contrib.resolvedBy);
    if (mounted && user != null) {
      setState(() => _supervisorName = user.fullName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.contrib;
    Color statusColor;
    String statusLabel;
    switch (c.status) {
      case 'approved':
        statusColor = Colors.green;
        statusLabel = 'Approved';
        break;
      case 'declined':
        statusColor = Colors.red;
        statusLabel = 'Declined';
        break;
      default:
        statusColor = Colors.orange;
        statusLabel = 'Pending';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'INR ${c.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF047857),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        border: Border.all(color: statusColor.withOpacity(0.4)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.calendar,
                        size: 12, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('dd MMM yyyy').format(c.raisedAt),
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    const Spacer(),
                    FaIcon(
                      _expanded
                          ? FontAwesomeIcons.chevronUp
                          : FontAwesomeIcons.chevronDown,
                      size: 12,
                      color: Colors.grey,
                    ),
                  ],
                ),
                if (_expanded) ...[
                  const Divider(height: 20),
                  _InfoRow(
                      label: 'Note submitted',
                      value: c.note.isNotEmpty ? c.note : '—'),
                  if (c.status != 'pending') ...[
                    _InfoRow(
                        label: 'Resolved on',
                        value: c.resolvedAt != null
                            ? DateFormat('dd MMM yyyy, hh:mm a')
                                .format(c.resolvedAt!)
                            : '—'),
                    _InfoRow(
                        label: 'Reviewed by',
                        value: _supervisorName.isNotEmpty
                            ? _supervisorName
                            : c.resolvedBy),
                    _InfoRow(
                        label: 'Supervisor note',
                        value: c.receiptNote.isNotEmpty ? c.receiptNote : '—'),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
