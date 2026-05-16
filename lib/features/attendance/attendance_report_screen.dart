import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/attendance_export_service.dart';
import '../../core/models/event_model.dart';
import '../../core/models/user_model.dart';
import 'attendance_controller.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  EventModel? _selectedEvent;
  final RxList<EventModel> _events = <EventModel>[].obs;
  final RxList<UserModel> _teamMembers = <UserModel>[].obs;
  final Map<String, UserModel> _userCache = {};
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _loadTeamMembers();
  }

  void _loadEvents() {
    FirestoreService.streamEvents().listen((events) {
      _events.value = events.where((e) => e.attendanceEnabled).toList();
    });
  }

  void _loadTeamMembers() {
    final auth = Get.find<AuthController>();
    if (auth.isLeader) {
      // Leader: all members
      FirestoreService.users.snapshots().listen((snap) {
        _teamMembers.value =
            snap.docs.map((d) => UserModel.fromFirestore(d)).toList();
      });
    } else {
      final teamId = auth.teamId;
      if (teamId.isEmpty) return;
      FirestoreService.streamTeamMembers(teamId).listen((members) {
        _teamMembers.value = members;
      });
    }
  }

  Future<UserModel?> _resolveUser(String uid) async {
    if (_userCache.containsKey(uid)) return _userCache[uid];
    final m = _teamMembers.firstWhereOrNull((u) => u.uid == uid);
    if (m != null) {
      _userCache[uid] = m;
      return m;
    }
    final fetched = await FirestoreService.getUser(uid);
    if (fetched != null) _userCache[uid] = fetched;
    return fetched;
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(AttendanceController(), permanent: true);
    final auth = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.chevronLeft,
              color: Colors.white, size: 16),
          onPressed: () => Get.back(),
        ),
        title: const Text('Attendance Report'),
        actions: [
          IconButton(
            tooltip: _selectedEvent == null
                ? 'Select an event first'
                : 'Download Excel report',
            icon: _isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const FaIcon(FontAwesomeIcons.fileExcel,
                    color: Colors.white, size: 18),
            onPressed: (_selectedEvent == null || _isExporting)
                ? null
                : _downloadReport,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final padding = constraints.maxWidth > 700 ? 32.0 : 16.0;
          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => DropdownButtonFormField<EventModel>(
                      initialValue: _selectedEvent,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Select Event',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.all(12),
                          child:
                              FaIcon(FontAwesomeIcons.calendarDays, size: 16),
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      items: _events
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(
                                  '${e.title} • ${DateFormat('dd MMM yyyy').format(e.eventDate)}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (val) async {
                        setState(() => _selectedEvent = val);
                        if (val != null) {
                          await ctrl.loadTeamAttendance(val.eventId);
                        }
                      },
                    )),
                const SizedBox(height: 20),
                if (_selectedEvent != null)
                  Expanded(
                    child: Obx(() {
                      if (ctrl.isLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      // Filter for supervisor: only their team's members
                      var records = ctrl.teamAttendance.toList();
                      if (!auth.isLeader) {
                        final teamUids = _teamMembers.map((u) => u.uid).toSet();
                        records = records
                            .where((a) => teamUids.contains(a.userId))
                            .toList();
                      }
                      records
                          .sort((a, b) => b.scannedAt.compareTo(a.scannedAt));

                      final presentCount = records.length;
                      final teamTotal = _teamMembers.length;
                      final absent =
                          (teamTotal - presentCount).clamp(0, 1 << 31);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    label: 'Present',
                                    value: '$presentCount',
                                    color: Colors.green,
                                    icon: FontAwesomeIcons.userCheck,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _StatCard(
                                    label: 'Team Total',
                                    value: '$teamTotal',
                                    color: const Color(0xFF047857),
                                    icon: FontAwesomeIcons.users,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _StatCard(
                                    label: 'Absent',
                                    value: '$absent',
                                    color: Colors.red,
                                    icon: FontAwesomeIcons.userXmark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (records.isEmpty)
                            Expanded(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FaIcon(FontAwesomeIcons.userSlash,
                                        size: 48, color: Colors.grey.shade400),
                                    const SizedBox(height: 12),
                                    Text('No attendance records yet',
                                        style: TextStyle(
                                            color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                            )
                          else
                            Expanded(
                              child: ListView.builder(
                                itemCount: records.length,
                                itemBuilder: (ctx, i) {
                                  final att = records[i];
                                  return FutureBuilder<UserModel?>(
                                    future: _resolveUser(att.userId),
                                    builder: (ctx, snap) {
                                      final u = snap.data;
                                      final name = u?.fullName ?? 'Loading…';
                                      final initials = u?.initials ?? '?';
                                      final isQr = att.method == 'qr';
                                      return Card(
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor:
                                                const Color(0xFF059669),
                                            child: Text(
                                              initials,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12),
                                            ),
                                          ),
                                          title: Text(name,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600)),
                                          subtitle: Text(
                                            DateFormat('dd MMM yyyy, hh:mm a')
                                                .format(att.scannedAt),
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600),
                                          ),
                                          trailing: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isQr
                                                  ? Colors.blue.shade50
                                                  : Colors.amber.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isQr ? 'QR' : 'MANUAL',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isQr
                                                    ? Colors.blue.shade700
                                                    : Colors.amber.shade800,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                        ],
                      );
                    }),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _selectedEvent == null
          ? null
          : FloatingActionButton(
              backgroundColor: const Color(0xFF047857),
              onPressed: () => _showManualAddSheet(context, ctrl),
              child: const FaIcon(FontAwesomeIcons.userPlus,
                  color: Colors.white, size: 18),
            ),
    );
  }

  Future<void> _downloadReport() async {
    final event = _selectedEvent;
    if (event == null) return;
    final auth = Get.find<AuthController>();
    // Supervisors export just their team; leaders export everyone.
    final scopeTeamId =
        auth.isLeader ? null : (auth.teamId.isEmpty ? null : auth.teamId);
    setState(() => _isExporting = true);
    try {
      await AttendanceExportService.exportEventReport(
        event: event,
        scopeTeamId: scopeTeamId,
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showManualAddSheet(BuildContext context, AttendanceController ctrl) {
    final event = _selectedEvent;
    if (event == null) return;
    String? selectedUid;
    final searchCtrl = TextEditingController();
    String query = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (ctx, setSheet) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.userPlus,
                        size: 16, color: Color(0xFF047857)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Add Manual Attendance',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(
                            'For: ${event.title}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: searchCtrl,
                  onChanged: (v) => setSheet(() => query = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search team members…',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(12),
                      child: FaIcon(FontAwesomeIcons.magnifyingGlass, size: 14),
                    ),
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 240,
                  child: Obx(() {
                    final list = _teamMembers.where((u) {
                      if (query.isEmpty) return true;
                      return u.fullName.toLowerCase().contains(query) ||
                          u.email.toLowerCase().contains(query);
                    }).toList();
                    if (list.isEmpty) {
                      return Center(
                          child: Text('No matches',
                              style: TextStyle(color: Colors.grey.shade600)));
                    }
                    return ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final u = list[i];
                        final selected = selectedUid == u.uid;
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFF059669),
                            child: Text(
                              u.initials,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(u.fullName,
                              style: const TextStyle(fontSize: 13)),
                          trailing: selected
                              ? const FaIcon(FontAwesomeIcons.circleCheck,
                                  size: 16, color: Color(0xFF047857))
                              : null,
                          onTap: () => setSheet(() => selectedUid = u.uid),
                        );
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF047857),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const FaIcon(FontAwesomeIcons.check, size: 14),
                    label: const Text('Mark as Present (Manual)'),
                    onPressed: selectedUid == null
                        ? null
                        : () async {
                            Navigator.pop(sheetCtx);
                            await ctrl.manualMarkAttendance(
                              event.eventId,
                              selectedUid!,
                              event.title,
                            );
                          },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FaIcon(icon, color: color, size: 16),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
