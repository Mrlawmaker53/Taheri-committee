import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/models/team_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/firestore_service.dart';
import 'transfers_controller.dart';

class TeamManagerScreen extends StatefulWidget {
  const TeamManagerScreen({super.key});

  @override
  State<TeamManagerScreen> createState() => _TeamManagerScreenState();
}

class _TeamManagerScreenState extends State<TeamManagerScreen> {
  final RxList<TeamModel> teams = <TeamModel>[].obs;
  final RxMap<String, List<UserModel>> teamMembers =
      <String, List<UserModel>>{}.obs;
  final RxBool isLoading = false.obs;
  String? _expandedTeamId;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  void _loadTeams() {
    FirestoreService.streamAllTeams().listen((t) async {
      teams.value = t;
      for (final team in t) {
        FirestoreService.streamTeamMembers(team.teamId).listen((members) {
          teamMembers[team.teamId] = members;
        });
      }
    });
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
        title: const Text('Team Management'),
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final padding = constraints.maxWidth > 700 ? 32.0 : 16.0;
          return RefreshIndicator(
            onRefresh: () async => _loadTeams(),
            child: Obx(() {
              if (teams.isEmpty) {
                return const Center(
                    child: CircularProgressIndicator());
              }
              return ListView(
                padding: EdgeInsets.all(padding),
                children: [
                  ...teams.map((team) => _TeamExpansionCard(
                        team: team,
                        members: teamMembers[team.teamId] ?? [],
                        ctrl: ctrl,
                        isExpanded: _expandedTeamId == team.teamId,
                        onToggle: () => setState(() {
                          _expandedTeamId =
                              _expandedTeamId == team.teamId
                                  ? null
                                  : team.teamId;
                        }),
                      )),
                  const SizedBox(height: 20),
                  Text('Transfer Requests',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Obx(() {
                    if (ctrl.pendingLeader.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text('No pending transfer requests',
                              style: TextStyle(
                                  color: Colors.grey.shade500)),
                        ),
                      );
                    }
                    return Column(
                      children: ctrl.pendingLeader
                          .map((req) => _TransferRequestTile(
                              req: req, ctrl: ctrl))
                          .toList(),
                    );
                  }),
                ],
              );
            }),
          );
        },
      ),
    );
  }
}

class _TeamExpansionCard extends StatelessWidget {
  final TeamModel team;
  final List<UserModel> members;
  final TransfersController ctrl;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _TeamExpansionCard({
    required this.team,
    required this.members,
    required this.ctrl,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Column(
          children: [
            InkWell(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12)),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(8),
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
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          Text('${members.length} members',
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    FaIcon(
                      isExpanded
                          ? FontAwesomeIcons.chevronUp
                          : FontAwesomeIcons.chevronDown,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded) ...[
              const Divider(height: 1),
              ...members.map((m) => _MemberTile(member: m, ctrl: ctrl)),
            ],
          ],
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final UserModel member;
  final TransfersController ctrl;

  const _MemberTile({required this.member, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final roleLabel = member.isSupervisor
        ? 'Supervisor'
        : member.isLeader
            ? 'Leader'
            : 'Member';
    final roleColor = member.isSupervisor
        ? Colors.blue
        : member.isLeader
            ? Colors.red
            : Colors.green;

    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: const Color(0xFF059669),
        child: Text(member.initials,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
      ),
      title: Text(member.fullName,
          style: const TextStyle(fontSize: 13)),
      subtitle: Container(
        margin: const EdgeInsets.only(top: 2),
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
      trailing: OutlinedButton(
        onPressed: () => _showMoveDialog(context, member),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF047857),
          side: const BorderSide(color: Color(0xFF047857)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: const Text('Move'),
      ),
    );
  }

  void _showMoveDialog(BuildContext context, UserModel member) {
    String? targetTeamId;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Move ${member.fullName}'),
          content: StreamBuilder(
            stream: FirestoreService.streamAllTeams(),
            builder: (ctx, snap) {
              final teams =
                  (snap.data ?? <TeamModel>[]);
              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                    labelText: 'Select Target Team'),
                items: teams
                    .where((t) => t.teamId != member.teamId)
                    .map((t) => DropdownMenuItem(
                          value: t.teamId,
                          child: Text(t.teamName),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => targetTeamId = v),
              );
            },
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: targetTeamId == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      await FirestoreService.updateUserTeam(
                          member.uid, targetTeamId!);
                      Get.snackbar(
                          'Moved',
                          '${member.fullName} moved successfully.',
                          snackPosition: SnackPosition.BOTTOM);
                    },
              child: const Text('Move'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferRequestTile extends StatelessWidget {
  final dynamic req;
  final TransfersController ctrl;

  const _TransferRequestTile({required this.req, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FutureBuilder(
                  future: FirestoreService.getUser(req.memberId),
                  builder: (ctx, snap) => Text(
                    snap.data?.fullName ?? req.memberId,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Text(' → '),
                Text(req.toTeamId,
                    style:
                        const TextStyle(color: Color(0xFF047857))),
                const Spacer(),
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
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(req.reason,
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        ctrl.leaderApprove(req, ''),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding:
                            const EdgeInsets.symmetric(vertical: 8)),
                    child: const Text('Approve Move',
                        style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        ctrl.leaderDecline(req, ''),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding:
                            const EdgeInsets.symmetric(vertical: 8)),
                    child: const Text('Decline',
                        style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
