import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/models/team_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/firestore_service.dart';
import '../../core/widgets/shimmer_widgets.dart';
import 'announcements_controller.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  State<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  // Target audience config
  String _targetType = 'all'; // all | team | role | individual
  TeamModel? _selectedTeam;
  String? _selectedRole; // member | supervisor | leader
  UserModel? _selectedUser;

  // Response config
  bool _requiresResponse = false;
  final List<TextEditingController> _optionCtrls = [
    TextEditingController(text: 'Yes'),
    TextEditingController(text: 'No'),
  ];

  // Loaded once
  final RxList<TeamModel> _teams = <TeamModel>[].obs;
  final RxList<UserModel> _users = <UserModel>[].obs;

  @override
  void initState() {
    super.initState();
    FirestoreService.streamAllTeams().listen((t) => _teams.value = t);
    FirestoreService.users.snapshots().listen((s) {
      _users.value = s.docs.map((d) => UserModel.fromFirestore(d)).toList();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionCtrls.length >= 4) return;
    setState(() => _optionCtrls.add(TextEditingController()));
  }

  void _removeOption(int i) {
    if (_optionCtrls.length <= 2) return;
    setState(() => _optionCtrls.removeAt(i).dispose());
  }

  void _submit(AnnouncementsController ctrl) {
    if (!_formKey.currentState!.validate()) return;

    // Resolve audience label for backwards compat with older `audience` field.
    String audience;
    String? targetTeamId;
    String? targetRole;
    String? targetUserId;
    switch (_targetType) {
      case 'team':
        if (_selectedTeam == null) {
          Get.snackbar('Pick a team', 'Please choose a team to send to.',
              snackPosition: SnackPosition.BOTTOM);
          return;
        }
        audience = 'team:${_selectedTeam!.teamName}';
        targetTeamId = _selectedTeam!.teamId;
        break;
      case 'role':
        if (_selectedRole == null) {
          Get.snackbar('Pick a role', 'Please choose a role.',
              snackPosition: SnackPosition.BOTTOM);
          return;
        }
        audience = 'role:$_selectedRole';
        targetRole = _selectedRole;
        break;
      case 'individual':
        if (_selectedUser == null) {
          Get.snackbar('Pick a member', 'Please choose a recipient.',
              snackPosition: SnackPosition.BOTTOM);
          return;
        }
        audience = 'user:${_selectedUser!.fullName}';
        targetUserId = _selectedUser!.uid;
        break;
      default:
        audience = 'all';
    }

    final options = _requiresResponse
        ? _optionCtrls
            .map((c) => c.text.trim())
            .where((s) => s.isNotEmpty)
            .toList()
        : <String>[];
    if (_requiresResponse && options.length < 2) {
      Get.snackbar('Need 2 options', 'Provide at least two response options.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    ctrl.createAnnouncement(
      title: _titleCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
      audience: audience,
      targetType: _targetType,
      targetTeamId: targetTeamId,
      targetRole: targetRole,
      targetUserId: targetUserId,
      requiresResponse: _requiresResponse,
      responseOptions: options,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(AnnouncementsController());

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.chevronLeft,
              color: Colors.white, size: 16),
          onPressed: () => Get.back(),
        ),
        title: const Text('New Announcement'),
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
                          Text('Announcement Details',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _titleCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              prefixIcon: Padding(
                                padding: EdgeInsets.all(12),
                                child:
                                    FaIcon(FontAwesomeIcons.heading, size: 16),
                              ),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _bodyCtrl,
                            maxLines: 6,
                            decoration: const InputDecoration(
                              labelText: 'Message Body',
                              prefixIcon: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 16),
                                child: FaIcon(FontAwesomeIcons.alignLeft,
                                    size: 16),
                              ),
                              alignLabelWithHint: true,
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 20),
                          Text('Send To',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            initialValue: _targetType,
                            decoration: InputDecoration(
                              prefixIcon: const Padding(
                                padding: EdgeInsets.all(12),
                                child:
                                    FaIcon(FontAwesomeIcons.bullseye, size: 14),
                              ),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'all', child: Text('All Members')),
                              DropdownMenuItem(
                                  value: 'team', child: Text('Specific Team')),
                              DropdownMenuItem(
                                  value: 'role', child: Text('By Role')),
                              DropdownMenuItem(
                                  value: 'individual',
                                  child: Text('Individual Member')),
                            ],
                            onChanged: (v) =>
                                setState(() => _targetType = v ?? 'all'),
                          ),
                          const SizedBox(height: 12),
                          if (_targetType == 'team')
                            Obx(() {
                              if (_teams.isEmpty) {
                                return const ShimmerBox(
                                    width: double.infinity,
                                    height: 56,
                                    borderRadius: 10);
                              }
                              return DropdownButtonFormField<TeamModel>(
                                initialValue: _selectedTeam,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Team',
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: FaIcon(FontAwesomeIcons.peopleGroup,
                                        size: 14),
                                  ),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                items: _teams
                                    .map((t) => DropdownMenuItem(
                                          value: t,
                                          child: Text(t.teamName,
                                              overflow: TextOverflow.ellipsis),
                                        ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedTeam = v),
                              );
                            }),
                          if (_targetType == 'role')
                            DropdownButtonFormField<String>(
                              initialValue: _selectedRole,
                              decoration: InputDecoration(
                                labelText: 'Role',
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: FaIcon(FontAwesomeIcons.userShield,
                                      size: 14),
                                ),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'member', child: Text('Members')),
                                DropdownMenuItem(
                                    value: 'supervisor',
                                    child: Text('Supervisors')),
                                DropdownMenuItem(
                                    value: 'leader', child: Text('Leaders')),
                              ],
                              onChanged: (v) =>
                                  setState(() => _selectedRole = v),
                            ),
                          if (_targetType == 'individual')
                            Obx(() {
                              if (_users.isEmpty) {
                                return const ShimmerBox(
                                    width: double.infinity,
                                    height: 56,
                                    borderRadius: 10);
                              }
                              return DropdownButtonFormField<UserModel>(
                                initialValue: _selectedUser,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Recipient',
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.all(12),
                                    child:
                                        FaIcon(FontAwesomeIcons.user, size: 14),
                                  ),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                items: _users
                                    .map((u) => DropdownMenuItem(
                                          value: u,
                                          child: Text(u.fullName,
                                              overflow: TextOverflow.ellipsis),
                                        ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedUser = v),
                              );
                            }),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _requiresResponse,
                            onChanged: (v) =>
                                setState(() => _requiresResponse = v),
                            title: const Text(
                              'Request acknowledgement',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              'Recipients will see response buttons',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600),
                            ),
                            activeThumbColor: const Color(0xFF047857),
                          ),
                          if (_requiresResponse) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Response Options (2–4)',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 8),
                            for (int i = 0; i < _optionCtrls.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _optionCtrls[i],
                                        decoration: InputDecoration(
                                          isDense: true,
                                          hintText: 'Option ${i + 1}',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_optionCtrls.length > 2)
                                      IconButton(
                                        tooltip: 'Remove',
                                        onPressed: () => _removeOption(i),
                                        icon: const FaIcon(
                                            FontAwesomeIcons.xmark,
                                            size: 14,
                                            color: Colors.red),
                                      ),
                                  ],
                                ),
                              ),
                            if (_optionCtrls.length < 4)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: _addOption,
                                  icon: const FaIcon(FontAwesomeIcons.plus,
                                      size: 12),
                                  label: const Text('Add option'),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Obx(() => SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF047857),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            disabledBackgroundColor:
                                const Color(0xFF047857).withOpacity(0.4),
                          ),
                          onPressed:
                              ctrl.isLoading.value ? null : () => _submit(ctrl),
                          icon: ctrl.isLoading.value
                              ? const ButtonLoader()
                              : const FaIcon(FontAwesomeIcons.paperPlane,
                                  size: 14),
                          label: Text(
                            ctrl.isLoading.value
                                ? 'Publishing…'
                                : 'Publish Announcement',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
                          ),
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
