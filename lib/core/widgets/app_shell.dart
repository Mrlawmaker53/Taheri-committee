import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../controllers/auth_controller.dart';
import '../controllers/connectivity_controller.dart';
import 'app_drawer.dart';
import 'top_bar.dart';
import '../../features/dashboard/standard_dashboard_screen.dart';
import '../../features/events/events_screen.dart';
import '../../features/attendance/attendance_screen.dart';
import '../../features/attendance/attendance_report_screen.dart';
import '../../features/transport/transport_screen.dart';
import '../../features/members/directory_screen.dart';
import '../../features/announcements/announcements_screen.dart';
import '../../features/contributions/my_contributions_screen.dart';
import '../../features/admin/admin_panel_screen.dart';
import '../../features/activity_log/activity_log_screen.dart';
import '../../features/notifications/notifications_screen.dart';
// Seat Booking and My Bookings are now unified inside TransportScreen tabs
import '../../screens/home_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<_NavItem> _navItems(AuthController auth) {
    final items = <_NavItem>[
      const _NavItem(
          icon: FontAwesomeIcons.house,
          label: 'Dashboard',
          screen: StandardDashboardScreen()),
      const _NavItem(
          icon: FontAwesomeIcons.calendarDays,
          label: 'RSVP & Events',
          screen: EventsScreen()),
      _NavItem(
          icon: FontAwesomeIcons.qrcode,
          label:
              auth.isSupervisorOrLeader ? 'Attendance Report' : 'Attendance QR',
          screen: auth.isSupervisorOrLeader
              ? const AttendanceReportScreen()
              : const AttendanceScreen()),
      const _NavItem(
          icon: FontAwesomeIcons.bus,
          label: 'Transport',
          screen: TransportScreen()),
      const _NavItem(
          icon: FontAwesomeIcons.users,
          label: 'Members Directory',
          screen: DirectoryScreen()),
      const _NavItem(
          icon: FontAwesomeIcons.bullhorn,
          label: 'Announcements',
          screen: AnnouncementsScreen()),
    ];

    if (auth.isMember || auth.isSupervisorOrLeader) {
      items.add(const _NavItem(
          icon: FontAwesomeIcons.wallet,
          label: 'My Contributions',
          screen: MyContributionsScreen()));
    }

    if (auth.isSupervisorOrLeader) {
      items.add(const _NavItem(
          icon: FontAwesomeIcons.shieldHalved,
          label: 'Admin Panel',
          screen: AdminPanelScreen()));
    }

    if (auth.isLeader) {
      items.add(const _NavItem(
          icon: FontAwesomeIcons.clipboardList,
          label: 'Activity Log',
          screen: ActivityLogScreen()));
    }

    items.add(const _NavItem(
        icon: FontAwesomeIcons.bell,
        label: 'Notifications',
        screen: NotificationsScreen()));

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return GetX<AuthController>(
      builder: (auth) {
        if (!auth.authReady.value) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (!auth.isLoggedIn.value) {
          return const HomeScreen();
        }

        final items = _navItems(auth);
        final safeIndex = _selectedIndex >= items.length ? 0 : _selectedIndex;

        return GetX<ConnectivityController>(
          builder: (conn) => Scaffold(
            body: Column(
              children: [
                if (!conn.isConnected.value)
                  Container(
                    width: double.infinity,
                    color: Colors.orange.shade700,
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    child: const Row(
                      children: [
                        FaIcon(FontAwesomeIcons.triangleExclamation,
                            color: Colors.white, size: 14),
                        SizedBox(width: 8),
                        Text('Offline — showing cached data',
                            style:
                                TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      final isWide = constraints.maxWidth >= 600;
                      if (isWide) {
                        return _WideLayout(
                          items: items,
                          selectedIndex: safeIndex,
                          onSelect: (i) => setState(() => _selectedIndex = i),
                        );
                      } else {
                        return _NarrowLayout(
                          scaffoldKey: _scaffoldKey,
                          items: items,
                          selectedIndex: safeIndex,
                          onSelect: (i) {
                            setState(() => _selectedIndex = i);
                            Navigator.pop(context);
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final Widget screen;
  const _NavItem(
      {required this.icon, required this.label, required this.screen});
}

class _WideLayout extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _WideLayout({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 240,
          child: AppDrawer(
            items: items
                .map((i) => DrawerNavItem(icon: i.icon, label: i.label))
                .toList(),
            selectedIndex: selectedIndex,
            onSelect: onSelect,
            isPermanent: true,
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Scaffold(
            appBar: const TopBar(showHamburger: false),
            body: items[selectedIndex].screen,
          ),
        ),
      ],
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _NarrowLayout({
    required this.scaffoldKey,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: TopBar(
        showHamburger: true,
        onHamburgerTap: () => scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: AppDrawer(
        items: items
            .map((i) => DrawerNavItem(icon: i.icon, label: i.label))
            .toList(),
        selectedIndex: selectedIndex,
        onSelect: onSelect,
        isPermanent: false,
      ),
      body: items[selectedIndex].screen,
    );
  }
}
