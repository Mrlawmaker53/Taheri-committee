import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/models/user_model.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/team_model.dart';
import '../../core/widgets/shimmer_widgets.dart';
import '../../core/widgets/app_input.dart';
import 'admin_controller.dart';

class UserManageScreen extends StatefulWidget {
  const UserManageScreen({super.key});

  @override
  State<UserManageScreen> createState() => _UserManageScreenState();
}

class _UserManageScreenState extends State<UserManageScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(AdminController());

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.chevronLeft,
              color: Colors.white, size: 16),
          onPressed: () => Get.back(),
        ),
        title: const Text('Manage Members'),
        backgroundColor: AppTokens.primary,
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final padding = constraints.maxWidth > 700 ? 32.0 : 16.0;
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.all(padding),
                child: AppInput(
                  hint: 'Search members...',
                  controller: _searchCtrl,
                  prefixIcon:
                      const Icon(Icons.search, color: AppTokens.textMuted),
                  isDark: false, // Admin screens use light theme
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (!ctrl.hasLoaded.value) {
                    return Column(
                      children:
                          List.generate(8, (_) => const MemberCardShimmer()),
                    );
                  }
                  var users = ctrl.allUsers.toList();
                  if (_query.isNotEmpty) {
                    users = users
                        .where((u) =>
                            u.fullName.toLowerCase().contains(_query) ||
                            u.email.toLowerCase().contains(_query))
                        .toList();
                  }
                  if (users.isEmpty) {
                    return const Center(child: Text('No members found'));
                  }
                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(padding, 0, padding, padding),
                    itemCount: users.length,
                    itemBuilder: (ctx, i) =>
                        _UserTile(user: users[i], ctrl: ctrl),
                  );
                }),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUserDialog(context, ctrl),
        backgroundColor: AppTokens.primary,
        child: const FaIcon(FontAwesomeIcons.userPlus,
            color: Colors.white, size: 18),
      ),
    );
  }

  void _showAddUserDialog(BuildContext context, AdminController ctrl) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final emergencyContactCtrl = TextEditingController();
    final itsNoCtrl = TextEditingController();
    String role = 'member';
    String? teamId;
    String? pickupId;
    DateTime? joinDate;
    DateTime? dateOfBirth;
    final formKey = GlobalKey<FormState>();

    InputDecoration deco(String label, IconData icon) => InputDecoration(
          labelText: label,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: FaIcon(icon, size: 14),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          isDense: true,
        );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF047857).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const FaIcon(FontAwesomeIcons.userPlus,
                                color: Color(0xFF047857), size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Add User Record',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 2),
                                Text(
                                    'Create a new member profile and assign a team',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon:
                                const FaIcon(FontAwesomeIcons.xmark, size: 16),
                            splashRadius: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: deco('Full Name', FontAwesomeIcons.user),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration:
                            deco('Email Address', FontAwesomeIcons.envelope),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (!v.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: mobileCtrl,
                        keyboardType: TextInputType.phone,
                        decoration:
                            deco('Mobile (optional)', FontAwesomeIcons.phone),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: addressCtrl,
                        decoration:
                            deco('Address', FontAwesomeIcons.locationDot),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emergencyContactCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: deco(
                            'Emergency Contact', FontAwesomeIcons.phoneVolume),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: itsNoCtrl,
                        keyboardType: TextInputType.number,
                        decoration: deco('ITS No', FontAwesomeIcons.hashtag),
                        maxLength: 8,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'ITS No is required';
                          }
                          if (value.length != 8) {
                            return 'ITS No must be exactly 8 digits';
                          }
                          if (!RegExp(r'^\d{8}$').hasMatch(value)) {
                            return 'ITS No must contain only digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1950),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => dateOfBirth = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const FaIcon(FontAwesomeIcons.calendar, size: 14),
                              const SizedBox(width: 12),
                              Text(
                                dateOfBirth != null
                                    ? '${dateOfBirth!.day}/${dateOfBirth!.month}/${dateOfBirth!.year}'
                                    : 'Date of Birth (optional)',
                                style: TextStyle(
                                  color: dateOfBirth != null
                                      ? Colors.black
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate:
                                DateTime.now().add(const Duration(days: 30)),
                          );
                          if (date != null) {
                            setState(() => joinDate = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const FaIcon(FontAwesomeIcons.calendarDays,
                                  size: 14),
                              const SizedBox(width: 12),
                              Text(
                                joinDate != null
                                    ? '${joinDate!.day}/${joinDate!.month}/${joinDate!.year}'
                                    : 'Join Date',
                                style: TextStyle(
                                  color: joinDate != null
                                      ? Colors.black
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: role,
                        isExpanded: true,
                        decoration: deco('Role', FontAwesomeIcons.userShield),
                        items: const [
                          DropdownMenuItem(
                              value: 'member', child: Text('Member')),
                          DropdownMenuItem(
                              value: 'supervisor', child: Text('Supervisor')),
                          DropdownMenuItem(
                              value: 'leader', child: Text('Leader')),
                        ],
                        onChanged: (v) => setState(() => role = v ?? 'member'),
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<List<TeamModel>>(
                        stream: FirestoreService.streamAllTeams(),
                        builder: (ctx, snap) {
                          final teams = snap.data ?? [];
                          return DropdownButtonFormField<String>(
                            initialValue: teamId,
                            isExpanded: true,
                            decoration:
                                deco('Team', FontAwesomeIcons.peopleGroup),
                            items: teams
                                .map((t) => DropdownMenuItem(
                                      value: t.teamId,
                                      child: Text(
                                        t.teamName,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => teamId = v),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Select a team' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('pickups')
                            .snapshots(),
                        builder: (ctx, snap) {
                          final pickups = snap.data?.docs ?? [];
                          return DropdownButtonFormField<String>(
                            initialValue: pickupId,
                            isExpanded: true,
                            decoration: deco('Pickup Location',
                                FontAwesomeIcons.mapLocationDot),
                            items: pickups
                                .map((doc) => DropdownMenuItem(
                                      value: doc.id,
                                      child: Text(
                                        doc['name'] ?? 'Unknown',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => pickupId = v),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Select a pickup location'
                                : null,
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF047857),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            icon:
                                const FaIcon(FontAwesomeIcons.check, size: 14),
                            label: const Text('Add User'),
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                Navigator.pop(ctx);
                                ctrl.createUserAccount(
                                  email: emailCtrl.text.trim(),
                                  mobile: mobileCtrl.text.trim(),
                                  fullName: nameCtrl.text.trim(),
                                  role: role,
                                  teamId: teamId ?? '',
                                  address: addressCtrl.text.trim(),
                                  emergencyContact:
                                      emergencyContactCtrl.text.trim(),
                                  itsNo: itsNoCtrl.text.trim(),
                                  dateOfBirth: dateOfBirth,
                                  joinDate: joinDate ?? DateTime.now(),
                                  pickupId: pickupId ?? '',
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  final AdminController ctrl;

  const _UserTile({required this.user, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final roleLabel = user.isLeader
        ? 'Leader'
        : user.isSupervisor
            ? 'Supervisor'
            : 'Member';
    final roleColor = user.isLeader
        ? AppTokens.roleLeader
        : user.isSupervisor
            ? AppTokens.roleSupervisor
            : AppTokens.roleMember;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        side: const BorderSide(color: AppTokens.borderLight, width: 0.5),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: roleColor.withOpacity(0.15),
          backgroundImage:
              user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
          child: user.avatarUrl.isEmpty
              ? Text(user.initials,
                  style:
                      TextStyle(color: roleColor, fontWeight: FontWeight.w600))
              : null,
        ),
        title: Text(user.fullName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(roleLabel,
                  style: TextStyle(
                      color: roleColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 6),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: user.isActive ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(user.isActive ? 'Active' : 'Inactive',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (val) {
            if (val == 'toggle_active') {
              ctrl.setActive(user, !user.isActive);
            }
          },
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: 'toggle_active',
              child: Row(
                children: [
                  FaIcon(
                    user.isActive
                        ? FontAwesomeIcons.ban
                        : FontAwesomeIcons.circleCheck,
                    size: 14,
                    color: user.isActive ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(user.isActive ? 'Deactivate' : 'Activate'),
                ],
              ),
            ),
          ],
          child: const FaIcon(FontAwesomeIcons.ellipsisVertical,
              size: 16, color: Colors.grey),
        ),
      ),
    );
  }
}
