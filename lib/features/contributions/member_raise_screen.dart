import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/user_model.dart';
import 'contributions_controller.dart';

class MemberRaiseScreen extends StatefulWidget {
  const MemberRaiseScreen({super.key});

  @override
  State<MemberRaiseScreen> createState() => _MemberRaiseScreenState();
}

class _MemberRaiseScreenState extends State<MemberRaiseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String? _selectedSupervisorId;
  List<UserModel> _supervisors = [];
  bool _loadingSupervisors = true;

  @override
  void initState() {
    super.initState();
    _loadSupervisors();
  }

  Future<void> _loadSupervisors() async {
    final snap = await FirestoreService.users
        .where('role', whereIn: ['supervisor', 'leader', 'admin']).get();
    setState(() {
      _supervisors = snap.docs.map((d) => UserModel.fromFirestore(d)).toList();
      _loadingSupervisors = false;
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
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
        title: const Text('Raise Contribution'),
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final padding = constraints.maxWidth > 700 ? 32.0 : 16.0;
          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Contribution Details',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _amountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Amount (₹)',
                              prefixIcon: Padding(
                                padding: EdgeInsets.all(12),
                                child: FaIcon(FontAwesomeIcons.moneyBill,
                                    size: 16),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final n = double.tryParse(v);
                              if (n == null || n <= 0) {
                                return 'Enter valid amount';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _noteCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Note / Description',
                              prefixIcon: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 16),
                                child: FaIcon(FontAwesomeIcons.noteSticky,
                                    size: 16),
                              ),
                              alignLabelWithHint: true,
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          _loadingSupervisors
                              ? const LinearProgressIndicator()
                              : DropdownButtonFormField<String>(
                                  initialValue: _selectedSupervisorId,
                                  decoration: const InputDecoration(
                                    labelText: 'Assign to Supervisor',
                                    prefixIcon: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: FaIcon(FontAwesomeIcons.userTie,
                                          size: 16),
                                    ),
                                  ),
                                  items: _supervisors
                                      .map((s) => DropdownMenuItem(
                                            value: s.uid,
                                            child: Text(s.fullName),
                                          ))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _selectedSupervisorId = v),
                                  validator: (v) =>
                                      v == null ? 'Select a supervisor' : null,
                                ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Obx(() => SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: ctrl.isLoading.value
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    ctrl.raiseContribution(
                                      amount: double.parse(_amountCtrl.text),
                                      note: _noteCtrl.text.trim(),
                                      supervisorId: _selectedSupervisorId!,
                                    );
                                  }
                                },
                          icon: ctrl.isLoading.value
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const FaIcon(FontAwesomeIcons.paperPlane,
                                  size: 14),
                          label: const Text('Submit Request'),
                        ),
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
