import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/models/user_model.dart';
import '../../core/widgets/shimmer_widgets.dart';
import 'members_controller.dart';
import 'member_detail_screen.dart';

Color _roleColor(UserModel m) => m.isLeader
    ? AppTokens.roleLeader
    : m.isSupervisor
        ? AppTokens.roleSupervisor
        : AppTokens.roleMember;

IconData _roleIcon(UserModel m) => m.isLeader
    ? FontAwesomeIcons.crown
    : m.isSupervisor
        ? FontAwesomeIcons.userShield
        : FontAwesomeIcons.user;

String _roleLabel(UserModel m) => m.isLeader
    ? 'Leader'
    : m.isSupervisor
        ? 'Supervisor'
        : 'Member';

ImageProvider? _avatarImage(UserModel m) =>
    m.avatarUrl.isNotEmpty ? NetworkImage(m.avatarUrl) : null;

class DirectoryScreen extends StatelessWidget {
  const DirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(MembersController());

    return Scaffold(
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final w = constraints.maxWidth;
          final padding = w > 700 ? 28.0 : 16.0;
          final crossCount = w > 1100
              ? 4
              : w > 700
                  ? 3
                  : 2;
          final isGrid = w > 500;

          return Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(padding, padding, padding, 0),
                child: Column(
                  children: [
                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.1), width: 1),
                      ),
                      child: TextField(
                        onChanged: ctrl.setSearch,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search members...',
                          hintStyle:
                              TextStyle(color: Colors.white.withOpacity(0.35)),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12),
                            child: FaIcon(FontAwesomeIcons.magnifyingGlass,
                                size: 15,
                                color: Colors.white.withOpacity(0.4)),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Filters + count row
                    Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Obx(() => Row(
                                  children: [
                                    _FilterChip(
                                        label: 'All',
                                        icon: FontAwesomeIcons.users,
                                        isSelected:
                                            ctrl.roleFilter.value == 'all',
                                        onTap: () =>
                                            ctrl.setRoleFilter('all')),
                                    const SizedBox(width: 8),
                                    _FilterChip(
                                        label: 'Members',
                                        icon: FontAwesomeIcons.user,
                                        color: AppTokens.roleMember,
                                        isSelected:
                                            ctrl.roleFilter.value == 'member',
                                        onTap: () =>
                                            ctrl.setRoleFilter('member')),
                                    const SizedBox(width: 8),
                                    _FilterChip(
                                        label: 'Supervisors',
                                        icon: FontAwesomeIcons.userShield,
                                        color: AppTokens.roleSupervisor,
                                        isSelected: ctrl.roleFilter.value ==
                                            'supervisor',
                                        onTap: () =>
                                            ctrl.setRoleFilter('supervisor')),
                                    const SizedBox(width: 8),
                                    _FilterChip(
                                        label: 'Leaders',
                                        icon: FontAwesomeIcons.crown,
                                        color: AppTokens.roleLeader,
                                        isSelected:
                                            ctrl.roleFilter.value == 'leader',
                                        onTap: () =>
                                            ctrl.setRoleFilter('leader')),
                                  ],
                                )),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Obx(() => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  const Color(0xFF059669).withOpacity(0.2),
                                  const Color(0xFF059669).withOpacity(0.08),
                                ]),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: const Color(0xFF059669)
                                        .withOpacity(0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const FaIcon(FontAwesomeIcons.userGroup,
                                      size: 10, color: Color(0xFF059669)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${ctrl.filtered.length}',
                                    style: const TextStyle(
                                        color: Color(0xFF059669),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),

              // ── List / Grid ──────────────────────────────────────────────
              Expanded(
                child: Obx(() {
                  if (ctrl.isLoading.value) {
                    return GridView.count(
                      crossAxisCount: crossCount,
                      padding: EdgeInsets.all(padding),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.82,
                      children:
                          List.generate(6, (_) => const MemberCardShimmer()),
                    );
                  }
                  if (ctrl.filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.1)),
                            ),
                            child: const Center(
                              child: FaIcon(FontAwesomeIcons.usersSlash,
                                  size: 28, color: Colors.white24),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('No members found',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          const Text('Try a different search or filter',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 13)),
                        ],
                      ),
                    );
                  }
                  if (isGrid) {
                    return GridView.builder(
                      padding:
                          EdgeInsets.fromLTRB(padding, 4, padding, padding),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: ctrl.filtered.length,
                      itemBuilder: (ctx, i) =>
                          _MemberGridCard(member: ctrl.filtered[i]),
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(padding, 4, padding, padding),
                    itemCount: ctrl.filtered.length,
                    itemBuilder: (ctx, i) =>
                        _MemberListCard(member: ctrl.filtered[i]),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Filter Chip ────────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF059669);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? c.withOpacity(0.15)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? c.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              icon,
              size: 11,
              color: isSelected ? c : Colors.white38,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? c : Colors.white54,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Grid Card (web / tablet) ───────────────────────────────────────────────────
class _MemberGridCard extends StatelessWidget {
  final UserModel member;
  const _MemberGridCard({required this.member});

  @override
  Widget build(BuildContext context) {
    final rc = _roleColor(member);
    final rl = _roleLabel(member);
    final ri = _roleIcon(member);
    final img = _avatarImage(member);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Get.to(() => MemberDetailScreen(member: member)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.04),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          child: Column(
            children: [
              // Top gradient accent
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [rc, rc.withOpacity(0.2)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Avatar with glow ring
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  rc.withOpacity(0.6),
                                  rc.withOpacity(0.2),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: rc.withOpacity(0.2),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: const Color(0xFF1C1917),
                              backgroundImage: img,
                              onBackgroundImageError:
                                  img != null ? (_, __) {} : null,
                              child: img == null
                                  ? Text(
                                      member.initials,
                                      style: TextStyle(
                                        color: rc,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          if (member.isActive)
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF0C0A09), width: 2),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Name
                      Text(
                        member.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Team or email
                      Text(
                        member.email,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4), fontSize: 10),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      // Role badge with icon
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: rc.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: rc.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(ri, size: 9, color: rc),
                            const SizedBox(width: 5),
                            Text(
                              rl,
                              style: TextStyle(
                                color: rc,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── List Card (mobile) ─────────────────────────────────────────────────────────
class _MemberListCard extends StatelessWidget {
  final UserModel member;
  const _MemberListCard({required this.member});

  @override
  Widget build(BuildContext context) {
    final rc = _roleColor(member);
    final rl = _roleLabel(member);
    final ri = _roleIcon(member);
    final img = _avatarImage(member);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Get.to(() => MemberDetailScreen(member: member)),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withOpacity(0.04),
              border:
                  Border.all(color: Colors.white.withOpacity(0.08), width: 1),
            ),
            child: Row(
              children: [
                // Avatar with ring
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            rc.withOpacity(0.6),
                            rc.withOpacity(0.2),
                          ],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF1C1917),
                        backgroundImage: img,
                        onBackgroundImageError:
                            img != null ? (_, __) {} : null,
                        child: img == null
                            ? Text(
                                member.initials,
                                style: TextStyle(
                                  color: rc,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              )
                            : null,
                      ),
                    ),
                    if (member.isActive)
                      Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFF0C0A09), width: 2),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          FaIcon(FontAwesomeIcons.envelope,
                              size: 10,
                              color: Colors.white.withOpacity(0.3)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              member.email,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.45),
                                  fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Role badge + arrow
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: rc.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: rc.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(ri, size: 9, color: rc),
                          const SizedBox(width: 5),
                          Text(
                            rl,
                            style: TextStyle(
                              color: rc,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    FaIcon(FontAwesomeIcons.chevronRight,
                        size: 10, color: Colors.white.withOpacity(0.2)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
