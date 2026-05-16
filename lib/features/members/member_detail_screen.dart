import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/models/user_model.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_tokens.dart';

class MemberDetailScreen extends StatelessWidget {
  final UserModel member;
  const MemberDetailScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final rc = member.isLeader
        ? AppTokens.roleLeader
        : member.isSupervisor
            ? AppTokens.roleSupervisor
            : AppTokens.roleMember;
    final rl = member.isLeader
        ? 'Leader'
        : member.isSupervisor
            ? 'Supervisor'
            : 'Member';
    final ri = member.isLeader
        ? FontAwesomeIcons.crown
        : member.isSupervisor
            ? FontAwesomeIcons.userShield
            : FontAwesomeIcons.user;
    final img =
        member.avatarUrl.isNotEmpty ? NetworkImage(member.avatarUrl) : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0C0A09),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final isWide = constraints.maxWidth > 700;
          final maxWidth = isWide ? 600.0 : double.infinity;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: CustomScrollView(
                slivers: [
                  // ── Compact AppBar ───────────────────────────────────
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: const Color(0xFF0C0A09),
                    elevation: 0,
                    leading: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 16),
                      ),
                      onPressed: () => Get.back(),
                    ),
                    title: Text(
                      member.fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    centerTitle: true,
                  ),

                  // ── Profile Header ───────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                      child: Column(
                        children: [
                          // Avatar with gradient ring
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      rc,
                                      rc.withOpacity(0.3),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: rc.withOpacity(0.3),
                                      blurRadius: 24,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 52,
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
                                            fontSize: 32,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: member.isActive
                                      ? const Color(0xFF10B981)
                                      : Colors.grey,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: const Color(0xFF0C0A09),
                                      width: 3),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Name
                          Text(
                            member.fullName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),

                          // Email
                          if (member.email.isNotEmpty)
                            Text(
                              member.email,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.45),
                                  fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          const SizedBox(height: 16),

                          // Role + Status badges
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: rc.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border:
                                      Border.all(color: rc.withOpacity(0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FaIcon(ri, size: 12, color: rc),
                                    const SizedBox(width: 6),
                                    Text(
                                      rl,
                                      style: TextStyle(
                                        color: rc,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: (member.isActive
                                          ? const Color(0xFF10B981)
                                          : Colors.grey)
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: (member.isActive
                                            ? const Color(0xFF10B981)
                                            : Colors.grey)
                                        .withOpacity(0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: member.isActive
                                            ? const Color(0xFF10B981)
                                            : Colors.grey,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      member.isActive ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        color: member.isActive
                                            ? const Color(0xFF10B981)
                                            : Colors.grey,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // ── Info Cards ─────────────────────────────────────────
                  SliverPadding(
                    padding:
                        EdgeInsets.symmetric(horizontal: isWide ? 0 : 16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Contact Info Card
                        _DetailCard(
                          title: 'Contact & Info',
                          icon: FontAwesomeIcons.addressCard,
                          accentColor: rc,
                          children: [
                            if (member.email.isNotEmpty)
                              _InfoTile(
                                icon: FontAwesomeIcons.envelope,
                                label: 'Email',
                                value: member.email,
                                color: const Color(0xFF0891B2),
                              ),
                            if (member.mobile.isNotEmpty)
                              _InfoTile(
                                icon: FontAwesomeIcons.phone,
                                label: 'Mobile',
                                value: member.mobile,
                                color: const Color(0xFF10B981),
                              ),
                            FutureBuilder<String>(
                              future: _getTeamName(member.teamId),
                              builder: (ctx, snap) {
                                final teamName = snap.data ?? 'Loading...';
                                return _InfoTile(
                                  icon: FontAwesomeIcons.peopleGroup,
                                  label: 'Team',
                                  value: teamName,
                                  color: const Color(0xFFD97706),
                                );
                              },
                            ),
                            _InfoTile(
                              icon: FontAwesomeIcons.calendarCheck,
                              label: 'Member Since',
                              value: DateFormat('dd MMMM yyyy')
                                  .format(member.createdAt),
                              color: const Color(0xFF7C3AED),
                              isLast: true,
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Personal Details Card
                        if (member.itsNo.isNotEmpty ||
                            member.dateOfBirth.isNotEmpty ||
                            member.gender.isNotEmpty ||
                            member.address.isNotEmpty ||
                            member.professional.isNotEmpty ||
                            member.skill.isNotEmpty)
                          _DetailCard(
                            title: 'Personal Details',
                            icon: FontAwesomeIcons.userPen,
                            accentColor: const Color(0xFF0891B2),
                            children: [
                              if (member.itsNo.isNotEmpty)
                                _InfoTile(
                                  icon: FontAwesomeIcons.idBadge,
                                  label: 'ITS No',
                                  value: member.itsNo,
                                  color: const Color(0xFF059669),
                                ),
                              if (member.dateOfBirth.isNotEmpty)
                                _InfoTile(
                                  icon: FontAwesomeIcons.cakeCandles,
                                  label: 'Date of Birth',
                                  value: member.dateOfBirth,
                                  color: const Color(0xFFE11D48),
                                ),
                              if (member.gender.isNotEmpty)
                                _InfoTile(
                                  icon: FontAwesomeIcons.venusMars,
                                  label: 'Gender',
                                  value: member.gender,
                                  color: const Color(0xFF7C3AED),
                                ),
                              if (member.address.isNotEmpty)
                                _InfoTile(
                                  icon: FontAwesomeIcons.locationDot,
                                  label: 'Address',
                                  value: member.address,
                                  color: const Color(0xFFD97706),
                                ),
                              if (member.professional.isNotEmpty)
                                _InfoTile(
                                  icon: FontAwesomeIcons.briefcase,
                                  label: 'Profession',
                                  value: member.professional,
                                  color: const Color(0xFF0891B2),
                                ),
                              if (member.skill.isNotEmpty)
                                _InfoTile(
                                  icon: FontAwesomeIcons.screwdriverWrench,
                                  label: 'Skill',
                                  value: member.skill,
                                  color: const Color(0xFF10B981),
                                  isLast: true,
                                ),
                            ],
                          ),

                        if (member.itsNo.isNotEmpty ||
                            member.dateOfBirth.isNotEmpty ||
                            member.gender.isNotEmpty ||
                            member.address.isNotEmpty ||
                            member.professional.isNotEmpty ||
                            member.skill.isNotEmpty)
                          const SizedBox(height: 14),

                        // Admin Actions Card
                        if (auth.isSupervisorOrLeader)
                          _DetailCard(
                            title: 'Admin Actions',
                            icon: FontAwesomeIcons.gear,
                            accentColor: AppTokens.danger,
                            children: [
                              _ActionTile(
                                icon: FontAwesomeIcons.arrowRightArrowLeft,
                                label: 'Request Transfer',
                                color: AppTokens.primary,
                                onTap: () => Get.toNamed('/transfers/raise'),
                              ),
                            ],
                          ),

                        const SizedBox(height: 32),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<String> _getTeamName(String teamId) async {
    if (teamId.isEmpty) return 'Unassigned';
    final team = await FirestoreService.getTeam(teamId);
    return team?.teamName ?? 'Unknown Team';
  }
}

// ── Detail Card ─────────────────────────────────────────────────────────────────
class _DetailCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<Widget> children;

  const _DetailCard({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: FaIcon(icon, size: 14, color: accentColor),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: Colors.white.withOpacity(0.06)),
          ...children,
        ],
      ),
    );
  }
}

// ── Info Tile ──────────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isLast;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: FaIcon(icon, size: 14, color: color),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Container(
              height: 1,
              margin: const EdgeInsets.only(left: 70),
              color: Colors.white.withOpacity(0.04)),
      ],
    );
  }
}

// ── Action Tile ────────────────────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: FaIcon(icon, size: 14, color: color)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: FaIcon(FontAwesomeIcons.chevronRight,
                  size: 10, color: color.withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }
}
