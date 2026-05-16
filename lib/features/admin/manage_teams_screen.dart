import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/models/team_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/firestore_service.dart';
import '../../core/widgets/shimmer_widgets.dart';
import 'admin_controller.dart';

/// Leader-only screen for creating, renaming, reassigning, and deleting
/// teams. Reachable from the Admin Panel.
class ManageTeamsScreen extends StatelessWidget {
  const ManageTeamsScreen({super.key});

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
        title: const Text('Manage Teams'),
        backgroundColor: AppTokens.primary,
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final padding = constraints.maxWidth > 700 ? 32.0 : 16.0;
          return StreamBuilder<List<TeamModel>>(
            stream: FirestoreService.streamAllTeams(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: CardListShimmer(itemCount: 4, cardHeight: 96),
                );
              }
              final teams = snap.data ?? [];
              return RefreshIndicator(
                onRefresh: () async {},
                child: ListView(
                  padding: EdgeInsets.all(padding),
                  children: [
                    _SummaryHeader(teamCount: teams.length, ctrl: ctrl),
                    const SizedBox(height: 16),
                    if (teams.isEmpty)
                      _EmptyState(
                          onCreate: () => _showTeamDialog(context, ctrl))
                    else
                      ...teams.map((t) => _TeamCard(
                            team: t,
                            ctrl: ctrl,
                            onEdit: () =>
                                _showTeamDialog(context, ctrl, existing: t),
                            onDelete: () => _confirmDelete(context, ctrl, t),
                          )),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTeamDialog(context, Get.find<AdminController>()),
        backgroundColor: AppTokens.primary,
        icon:
            const FaIcon(FontAwesomeIcons.plus, size: 14, color: Colors.white),
        label: const Text('New Team', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  // Create / edit dialog
  // ───────────────────────────────────────────────────────────────────────
  void _showTeamDialog(BuildContext context, AdminController ctrl,
      {TeamModel? existing}) {
    final nameCtrl = TextEditingController(text: existing?.teamName ?? '');
    String? supervisorId =
        existing?.supervisorId.isEmpty == true ? null : existing?.supervisorId;
    String? leaderId =
        existing?.leaderId.isEmpty == true ? null : existing?.leaderId;
    final formKey = GlobalKey<FormState>();
    final isEdit = existing != null;

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
                          const FaIcon(FontAwesomeIcons.peopleGroup,
                              color: Color(0xFF047857), size: 18),
                          const SizedBox(width: 10),
                          Text(isEdit ? 'Edit Team' : 'Create New Team',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: nameCtrl,
                        autofocus: !isEdit,
                        textCapitalization: TextCapitalization.words,
                        decoration: _deco('Team Name', FontAwesomeIcons.tag),
                        validator: (v) => v == null || v.trim().length < 2
                            ? 'At least 2 characters'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _UserDropdown(
                        label: 'Supervisor (optional)',
                        icon: FontAwesomeIcons.userTie,
                        roleFilter: 'supervisor',
                        value: supervisorId,
                        onChanged: (v) => setState(() => supervisorId = v),
                      ),
                      const SizedBox(height: 12),
                      _UserDropdown(
                        label: 'Leader (optional)',
                        icon: FontAwesomeIcons.userShield,
                        roleFilter: 'leader',
                        value: leaderId,
                        onChanged: (v) => setState(() => leaderId = v),
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
                          Obx(() => ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF047857),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: ctrl.isLoading.value
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      )
                                    : const FaIcon(FontAwesomeIcons.check,
                                        size: 14),
                                label: Text(isEdit ? 'Save' : 'Create'),
                                onPressed: ctrl.isLoading.value
                                    ? null
                                    : () async {
                                        if (!formKey.currentState!.validate()) {
                                          return;
                                        }
                                        Navigator.pop(ctx);
                                        if (isEdit) {
                                          await ctrl.updateTeam(
                                            teamId: existing.teamId,
                                            teamName: nameCtrl.text,
                                            supervisorId: supervisorId ?? '',
                                            leaderId: leaderId ?? '',
                                          );
                                        } else {
                                          await ctrl.createTeam(
                                            teamName: nameCtrl.text,
                                            supervisorId: supervisorId ?? '',
                                            leaderId: leaderId ?? '',
                                          );
                                        }
                                      },
                              )),
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

  void _confirmDelete(
      BuildContext context, AdminController ctrl, TeamModel team) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            FaIcon(FontAwesomeIcons.triangleExclamation,
                color: Colors.red, size: 18),
            SizedBox(width: 10),
            Text('Delete Team?'),
          ],
        ),
        content: Text(
          'This will permanently delete "${team.teamName}". '
          'Members assigned to this team must be moved first.',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ctrl.deleteTeam(team.teamId, team.teamName);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  InputDecoration _deco(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: FaIcon(icon, size: 14),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        isDense: true,
      );
}

// ───────────────────────────────────────────────────────────────────────────
// Header card showing total teams + member counts.
// ───────────────────────────────────────────────────────────────────────────
class _SummaryHeader extends StatelessWidget {
  final int teamCount;
  final AdminController ctrl;
  const _SummaryHeader({required this.teamCount, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final totalMembers = ctrl.allUsers.length;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF047857), Color(0xFF1976D2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const FaIcon(FontAwesomeIcons.peopleGroup,
                color: Colors.white, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$teamCount team${teamCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('$totalMembers total members',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.9), fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Empty state.
// ───────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          FaIcon(FontAwesomeIcons.peopleGroup,
              size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No teams yet',
              style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Tap "New Team" to create your first one.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const FaIcon(FontAwesomeIcons.plus, size: 14),
            label: const Text('Create Team'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF047857),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Per-team card with name, member count, supervisor/leader lookups, edit/del.
// ───────────────────────────────────────────────────────────────────────────
class _TeamCard extends StatelessWidget {
  final TeamModel team;
  final AdminController ctrl;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TeamCard({
    required this.team,
    required this.ctrl,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: FirestoreService.streamTeamMembers(team.teamId),
      builder: (ctx, snap) {
        final members = snap.data ?? [];
        final supervisor = _findUser(team.supervisorId);
        final leader = _findUser(team.leaderId);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1.5,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF047857).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const FaIcon(FontAwesomeIcons.peopleGroup,
                          color: Color(0xFF047857), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(team.teamName,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(
                              '${members.length} member${members.length == 1 ? '' : 's'} · created ${DateFormat('d MMM yyyy').format(team.createdAt)}',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: FaIcon(FontAwesomeIcons.ellipsisVertical,
                          size: 16, color: Colors.grey.shade700),
                      onSelected: (v) {
                        if (v == 'edit') onEdit();
                        if (v == 'delete') onDelete();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              FaIcon(FontAwesomeIcons.penToSquare, size: 14),
                              SizedBox(width: 10),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              FaIcon(FontAwesomeIcons.trash,
                                  size: 14, color: Colors.red),
                              SizedBox(width: 10),
                              Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _RoleChip(
                      icon: FontAwesomeIcons.userTie,
                      label: supervisor?.fullName ?? 'No supervisor',
                      color: Colors.orange,
                    ),
                    _RoleChip(
                      icon: FontAwesomeIcons.userShield,
                      label: leader?.fullName ?? 'No leader',
                      color: Colors.purple,
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

  UserModel? _findUser(String uid) {
    if (uid.isEmpty) return null;
    try {
      return ctrl.allUsers.firstWhere((u) => u.uid == uid);
    } catch (_) {
      return null;
    }
  }
}

class _RoleChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _RoleChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 11, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Reusable user dropdown (filters by role).
// ───────────────────────────────────────────────────────────────────────────
class _UserDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final String roleFilter;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _UserDropdown({
    required this.label,
    required this.icon,
    required this.roleFilter,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AdminController>();
    return Obx(() {
      final users = ctrl.allUsers
          .where((u) => u.role == roleFilter && u.isActive)
          .toList();
      // Make sure current value is always present in the items list, even if
      // the user has been deactivated/removed since assignment.
      final items = <DropdownMenuItem<String>>[
        const DropdownMenuItem(value: '', child: Text('— None —')),
        ...users.map((u) => DropdownMenuItem(
              value: u.uid,
              child: Text(u.fullName, overflow: TextOverflow.ellipsis),
            )),
      ];
      final safeValue = items.any((i) => i.value == value) ? value : '';
      return DropdownButtonFormField<String>(
        initialValue: safeValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: FaIcon(icon, size: 14),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          isDense: true,
        ),
        items: items,
        onChanged: (v) => onChanged(v == '' ? null : v),
      );
    });
  }
}
