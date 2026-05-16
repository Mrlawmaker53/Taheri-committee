import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/models/activity_log_model.dart';
import '../../core/widgets/shimmer_widgets.dart';
import 'activity_log_controller.dart';

class ActivityLogScreen extends StatelessWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(ActivityLogController());

    return Scaffold(
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final padding = constraints.maxWidth > 700 ? 32.0 : 16.0;
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(padding, padding, padding, 8),
                child: Obx(() => DropdownButtonFormField<String>(
                      initialValue: ctrl.actionFilter.value,
                      decoration: const InputDecoration(
                        labelText: 'Filter by Action',
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(12),
                          child: FaIcon(FontAwesomeIcons.filter, size: 15),
                        ),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: ctrl.filterOptions
                          .map((f) => DropdownMenuItem(
                                value: f,
                                child: Text(ctrl.filterLabel(f),
                                    style: const TextStyle(fontSize: 13)),
                              ))
                          .toList(),
                      onChanged: (v) => ctrl.setFilter(v ?? 'all'),
                    )),
              ),
              Expanded(
                child: Obx(() {
                  if (ctrl.isLoading.value) {
                    return const ListShimmer(itemCount: 8);
                  }
                  if (ctrl.logs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(FontAwesomeIcons.clipboardList,
                              size: 56, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('No activity logs found',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 16)),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(padding, 0, padding, padding),
                    itemCount: ctrl.logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (ctx, i) => _LogCard(log: ctrl.logs[i]),
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

class _LogCard extends StatelessWidget {
  final ActivityLogModel log;
  const _LogCard({required this.log});

  Color _actionColor(String action) {
    if (action.contains('approved')) return Colors.green;
    if (action.contains('declined')) return Colors.red;
    if (action.contains('raised') || action.contains('created')) {
      return const Color(0xFF047857);
    }
    if (action.contains('moved') || action.contains('changed')) {
      return Colors.orange;
    }
    return Colors.grey;
  }

  IconData _actionIcon(String action) {
    if (action.contains('contribution')) {
      return FontAwesomeIcons.wallet;
    }
    if (action.contains('group_request')) {
      return FontAwesomeIcons.layerGroup;
    }
    if (action.contains('transfer')) {
      return FontAwesomeIcons.arrowRightArrowLeft;
    }
    if (action.contains('member')) {
      return FontAwesomeIcons.userGear;
    }
    if (action.contains('event')) {
      return FontAwesomeIcons.calendarDays;
    }
    if (action.contains('attendance')) {
      return FontAwesomeIcons.userCheck;
    }
    if (action.contains('announcement')) {
      return FontAwesomeIcons.bullhorn;
    }
    return FontAwesomeIcons.clockRotateLeft;
  }

  @override
  Widget build(BuildContext context) {
    final color = _actionColor(log.action);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: FaIcon(_actionIcon(log.action), color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          log.actionLabel,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM, hh:mm a').format(log.timestamp),
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style:
                          TextStyle(color: Colors.grey.shade700, fontSize: 12),
                      children: [
                        TextSpan(
                          text: log.actorName,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color),
                        ),
                        const TextSpan(text: ' → '),
                        TextSpan(text: log.targetName),
                      ],
                    ),
                  ),
                  if (log.note.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      log.note,
                      style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                          fontStyle: FontStyle.italic),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          log.actorRole.toUpperCase(),
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
