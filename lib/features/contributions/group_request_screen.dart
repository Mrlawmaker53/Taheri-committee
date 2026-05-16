import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/user_model.dart';
import 'contributions_controller.dart';

class GroupRequestScreen extends StatefulWidget {
  const GroupRequestScreen({super.key});

  @override
  State<GroupRequestScreen> createState() => _GroupRequestScreenState();
}

class _GroupRequestScreenState extends State<GroupRequestScreen> {
  String? _selectedLeaderId;
  List<UserModel> _leaders = [];

  @override
  void initState() {
    super.initState();
    _loadLeaders();
  }

  Future<void> _loadLeaders() async {
    final snap = await FirestoreService.users
        .where('role', whereIn: ['leader', 'admin']).get();
    setState(() {
      _leaders =
          snap.docs.map((d) => UserModel.fromFirestore(d)).toList();
      if (_leaders.isNotEmpty) _selectedLeaderId = _leaders.first.uid;
    });
  }

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
        title: const Text('Raise Group Request'),
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final padding = constraints.maxWidth > 700 ? 32.0 : 16.0;
          return Obx(() {
            final pending = ctrl.pendingContributions;
            final total = ctrl.selectedContribIds.isEmpty
                ? pending.fold<double>(0, (s, c) => s + c.amount)
                : pending
                    .where((c) =>
                        ctrl.selectedContribIds.contains(c.id))
                    .fold<double>(0, (s, c) => s + c.amount);

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.all(padding),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Send to Leader',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              if (_leaders.isEmpty)
                                const LinearProgressIndicator()
                              else
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedLeaderId,
                                  decoration: const InputDecoration(
                                    labelText: 'Select Leader',
                                  ),
                                  items: _leaders
                                      .map((l) => DropdownMenuItem(
                                            value: l.uid,
                                            child: Text(l.fullName),
                                          ))
                                      .toList(),
                                  onChanged: (v) => setState(
                                      () => _selectedLeaderId = v),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Approved Contributions to Include',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (pending.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                                'No pending contributions to bundle.',
                                style: TextStyle(
                                    color: Colors.grey.shade600)),
                          ),
                        )
                      else
                        ...pending.map((c) => CheckboxListTile(
                              value: ctrl.selectedContribIds.isEmpty ||
                                  ctrl.selectedContribIds.contains(c.id),
                              onChanged: (val) {
                                if (ctrl.selectedContribIds.isEmpty) {
                                  ctrl.selectedContribIds.addAll(
                                      pending.map((p) => p.id));
                                }
                                if (val == true) {
                                  ctrl.selectedContribIds.add(c.id);
                                } else {
                                  ctrl.selectedContribIds.remove(c.id);
                                }
                              },
                              title: Text(
                                  'INR ${c.amount.toStringAsFixed(0)}'),
                              subtitle: Text(c.note,
                                  overflow: TextOverflow.ellipsis),
                            )),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, -4))
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('Total Amount:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text(
                            'INR ${total.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Obx(() => SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                                  (ctrl.isLoading.value ||
                                          pending.isEmpty ||
                                          _selectedLeaderId == null)
                                      ? null
                                      : () {
                                          final selected =
                                              ctrl.selectedContribIds.isEmpty
                                                  ? pending
                                                  : pending
                                                      .where((c) => ctrl
                                                          .selectedContribIds
                                                          .contains(c.id))
                                                      .toList();
                                          ctrl.raiseGroupRequest(
                                            contributions: selected,
                                            leaderId: _selectedLeaderId!,
                                          );
                                        },
                              icon: const FaIcon(
                                  FontAwesomeIcons.paperPlane,
                                  size: 14),
                              label: const Text('Send to Leader'),
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            );
          });
        },
      ),
    );
  }
}
