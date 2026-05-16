import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/models/user_model.dart';
import 'admin_controller.dart';

class RoleAssignScreen extends StatelessWidget {
  const RoleAssignScreen({super.key});

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
        title: const Text('Assign Roles'),
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final padding = constraints.maxWidth > 700 ? 32.0 : 16.0;
          return Obx(() {
            if (ctrl.allUsers.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              padding: EdgeInsets.all(padding),
              children: [
                _RoleSection(
                  title: 'Leaders',
                  icon: FontAwesomeIcons.crown,
                  color: Colors.red,
                  users: ctrl.leaders,
                  ctrl: ctrl,
                ),
                const SizedBox(height: 16),
                _RoleSection(
                  title: 'Supervisors',
                  icon: FontAwesomeIcons.userTie,
                  color: Colors.blue,
                  users: ctrl.supervisors,
                  ctrl: ctrl,
                ),
                const SizedBox(height: 16),
                _RoleSection(
                  title: 'Members',
                  icon: FontAwesomeIcons.user,
                  color: Colors.green,
                  users: ctrl.members,
                  ctrl: ctrl,
                ),
              ],
            );
          });
        },
      ),
    );
  }
}

class _RoleSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<UserModel> users;
  final AdminController ctrl;

  const _RoleSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.users,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FaIcon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Text(
              '$title (${users.length})',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (users.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text('None', style: TextStyle(color: Colors.grey.shade500)),
          )
        else
          ...users.map((u) => _RoleUserTile(user: u, ctrl: ctrl)),
      ],
    );
  }
}

class _RoleUserTile extends StatelessWidget {
  final UserModel user;
  final AdminController ctrl;

  const _RoleUserTile({required this.user, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFF059669),
          child: Text(user.initials,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ),
        title: Text(user.fullName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(user.email,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            overflow: TextOverflow.ellipsis),
        trailing: PopupMenuButton<String>(
          onSelected: (newRole) => ctrl.updateRole(user, newRole),
          itemBuilder: (ctx) => [
            if (user.role != 'member')
              const PopupMenuItem(
                  value: 'member', child: Text('Set as Member')),
            if (user.role != 'supervisor')
              const PopupMenuItem(
                  value: 'supervisor', child: Text('Set as Supervisor')),
            if (user.role != 'leader' && user.role != 'admin')
              const PopupMenuItem(
                  value: 'leader', child: Text('Set as Leader')),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Change', style: TextStyle(fontSize: 12)),
                SizedBox(width: 4),
                FaIcon(FontAwesomeIcons.chevronDown,
                    size: 10, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
