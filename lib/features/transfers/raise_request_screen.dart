import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/team_model.dart';
import 'transfers_controller.dart';

class RaiseRequestScreen extends StatefulWidget {
  const RaiseRequestScreen({super.key});

  @override
  State<RaiseRequestScreen> createState() => _RaiseRequestScreenState();
}

class _RaiseRequestScreenState extends State<RaiseRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();
  String? _selectedTeamId;
  List<TeamModel> _teams = [];
  bool _loadingTeams = true;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  void _loadTeams() {
    FirestoreService.streamAllTeams().listen((teams) {
      if (mounted) {
        setState(() {
          _teams = teams;
          _loadingTeams = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

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
        title: const Text('Request Team Transfer'),
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final padding = constraints.maxWidth > 700 ? 32.0 : 16.0;
          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Transfer Details',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                      fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          _loadingTeams
                              ? const LinearProgressIndicator()
                              : DropdownButtonFormField<String>(
                                  initialValue: _selectedTeamId,
                                  decoration: const InputDecoration(
                                    labelText: 'Target Team',
                                    prefixIcon: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: FaIcon(
                                          FontAwesomeIcons.peopleGroup,
                                          size: 16),
                                    ),
                                  ),
                                  items: _teams
                                      .map((t) => DropdownMenuItem(
                                            value: t.teamId,
                                            child: Text(t.teamName),
                                          ))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _selectedTeamId = v),
                                  validator: (v) =>
                                      v == null ? 'Select a team' : null,
                                ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _reasonCtrl,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Reason for Transfer',
                              prefixIcon: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 16),
                                child: FaIcon(
                                    FontAwesomeIcons.commentDots,
                                    size: 16),
                              ),
                              alignLabelWithHint: true,
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
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
                                    ctrl.raiseTransferRequest(
                                      toTeamId: _selectedTeamId!,
                                      reason: _reasonCtrl.text.trim(),
                                    );
                                  }
                                },
                          icon: ctrl.isLoading.value
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : const FaIcon(
                                  FontAwesomeIcons.arrowRightArrowLeft,
                                  size: 14),
                          label: const Text('Submit Transfer Request'),
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
