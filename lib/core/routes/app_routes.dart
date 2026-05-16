import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/controllers/auth_controller.dart';
import '../../features/dashboard/standard_dashboard_screen.dart';
import '../../features/events/events_screen.dart';
import '../../features/events/event_detail_screen.dart';
import '../../features/events/rsvp_screen.dart';
import '../../features/attendance/attendance_screen.dart';
import '../../features/attendance/qr_scanner_screen.dart';
import '../../features/attendance/attendance_report_screen.dart';
import '../../features/contributions/member_raise_screen.dart';
import '../../features/contributions/my_contributions_screen.dart';
import '../../features/contributions/supervisor_list_screen.dart';
import '../../features/contributions/group_request_screen.dart';
import '../../features/contributions/leader_chart_screen.dart';
import '../../features/transfers/raise_request_screen.dart';
import '../../features/transfers/supervisor_approve_screen.dart';
import '../../features/transfers/leader_approve_screen.dart';
import '../../features/transfers/team_manager_screen.dart';
import '../../features/transport/transport_screen.dart';
import '../../features/transport/manage_transport_screen.dart';
import '../../features/members/directory_screen.dart';
import '../../features/members/member_detail_screen.dart';
import '../../features/announcements/announcements_screen.dart';
import '../../features/announcements/create_announcement_screen.dart';
import '../../features/admin/admin_panel_screen.dart';
import '../../features/admin/user_manage_screen.dart';
import '../../features/admin/role_assign_screen.dart';
import '../../features/activity_log/activity_log_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/transport/seat_map_screen.dart';
import '../../features/seat_booking/presentation/transport_booking_screen.dart';
import '../../features/seat_booking/presentation/admin_vehicle_screen.dart';
import '../../features/seat_booking/presentation/my_bookings_screen.dart';
import '../../features/seat_booking/presentation/booking_scanner_screen.dart';

class AppRoutes {
  static const String dashboard = '/dashboard';
  static const String events = '/events';
  static const String eventDetail = '/events/detail';
  static const String rsvp = '/events/rsvp';
  static const String attendance = '/attendance';
  static const String qrScanner = '/attendance/qr';
  static const String attendanceReport = '/attendance/report';
  static const String memberRaise = '/contributions/raise';
  static const String myContributions = '/contributions/mine';
  static const String supervisorContributions = '/contributions/supervisor';
  static const String groupRequest = '/contributions/group-request';
  static const String leaderChart = '/contributions/chart';
  static const String raiseTransfer = '/transfers/raise';
  static const String supervisorTransfers = '/transfers/supervisor';
  static const String leaderTransfers = '/transfers/leader';
  static const String teamManager = '/transfers/team-manager';
  static const String transport = '/transport';
  static const String manageTransport = '/transport/manage';
  static const String directory = '/members';
  static const String memberDetail = '/members/detail';
  static const String announcements = '/announcements';
  static const String createAnnouncement = '/announcements/create';
  static const String adminPanel = '/admin';
  static const String userManage = '/admin/users';
  static const String roleAssign = '/admin/roles';
  static const String activityLog = '/activity-log';
  static const String notifications = '/notifications';
  static const String seatMap = '/transport/seats';
  static const String transportBooking = '/transport/booking';
  static const String adminVehicles = '/transport/admin-vehicles';
  static const String myBookings = '/transport/my-bookings';
  static const String bookingScanner = '/transport/scanner';

  static List<GetPage> get pages => [
        GetPage(
          name: dashboard,
          page: () => const StandardDashboardScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: events,
          page: () => const EventsScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: eventDetail,
          page: () => EventDetailScreen(event: Get.arguments),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: rsvp,
          page: () => const RsvpScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: attendance,
          page: () => const AttendanceScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: qrScanner,
          page: () => const QrScannerScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: attendanceReport,
          page: () => const AttendanceReportScreen(),
          middlewares: [AuthMiddleware(), SupervisorMiddleware()],
        ),
        GetPage(
          name: memberRaise,
          page: () => const MemberRaiseScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: myContributions,
          page: () => const MyContributionsScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: supervisorContributions,
          page: () => const SupervisorListScreen(),
          middlewares: [AuthMiddleware(), SupervisorMiddleware()],
        ),
        GetPage(
          name: groupRequest,
          page: () => const GroupRequestScreen(),
          middlewares: [AuthMiddleware(), SupervisorMiddleware()],
        ),
        GetPage(
          name: leaderChart,
          page: () => const LeaderChartScreen(),
          middlewares: [AuthMiddleware(), LeaderMiddleware()],
        ),
        GetPage(
          name: raiseTransfer,
          page: () => const RaiseRequestScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: supervisorTransfers,
          page: () => const SupervisorApproveScreen(),
          middlewares: [AuthMiddleware(), SupervisorMiddleware()],
        ),
        GetPage(
          name: leaderTransfers,
          page: () => const LeaderApproveScreen(),
          middlewares: [AuthMiddleware(), LeaderMiddleware()],
        ),
        GetPage(
          name: teamManager,
          page: () => const TeamManagerScreen(),
          middlewares: [AuthMiddleware(), LeaderMiddleware()],
        ),
        GetPage(
          name: transport,
          page: () => const TransportScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: manageTransport,
          page: () => const ManageTransportScreen(),
          middlewares: [AuthMiddleware(), SupervisorMiddleware()],
        ),
        GetPage(
          name: directory,
          page: () => const DirectoryScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: memberDetail,
          page: () => MemberDetailScreen(member: Get.arguments),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: announcements,
          page: () => const AnnouncementsScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: createAnnouncement,
          page: () => const CreateAnnouncementScreen(),
          middlewares: [AuthMiddleware(), SupervisorMiddleware()],
        ),
        GetPage(
          name: adminPanel,
          page: () => const AdminPanelScreen(),
          middlewares: [AuthMiddleware(), LeaderMiddleware()],
        ),
        GetPage(
          name: userManage,
          page: () => const UserManageScreen(),
          middlewares: [AuthMiddleware(), LeaderMiddleware()],
        ),
        GetPage(
          name: roleAssign,
          page: () => const RoleAssignScreen(),
          middlewares: [AuthMiddleware(), LeaderMiddleware()],
        ),
        GetPage(
          name: activityLog,
          page: () => const ActivityLogScreen(),
          middlewares: [AuthMiddleware(), LeaderMiddleware()],
        ),
        GetPage(
          name: notifications,
          page: () => const NotificationsScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: seatMap,
          page: () => SeatMapScreen(transport: Get.arguments),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: transportBooking,
          page: () => TransportBookingScreen(event: Get.arguments),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: adminVehicles,
          page: () => AdminVehicleScreen(event: Get.arguments),
          middlewares: [AuthMiddleware(), SupervisorMiddleware()],
        ),
        GetPage(
          name: myBookings,
          page: () => const MyBookingsScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: bookingScanner,
          page: () => BookingScannerScreen(
            eventId: (Get.arguments as Map)['eventId'],
            eventTitle: (Get.arguments as Map)['eventTitle'],
          ),
          middlewares: [AuthMiddleware(), SupervisorMiddleware()],
        ),
      ];
}

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // Disabled since login route was removed
    return null;
  }
}

class SupervisorMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthController>();
    if (!auth.isSupervisorOrLeader) {
      return const RouteSettings(name: AppRoutes.dashboard);
    }
    return null;
  }
}

class LeaderMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthController>();
    if (!auth.isLeader) {
      return const RouteSettings(name: AppRoutes.dashboard);
    }
    return null;
  }
}
