import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/controllers/theme_controller.dart';
import '../../core/widgets/glass_card.dart';
import 'event_announcement_controller.dart';

class CreateEventAnnouncementScreen extends StatefulWidget {
  const CreateEventAnnouncementScreen({super.key});

  @override
  State<CreateEventAnnouncementScreen> createState() =>
      _CreateEventAnnouncementScreenState();
}

class _CreateEventAnnouncementScreenState
    extends State<CreateEventAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _eventTitleController = TextEditingController();
  final _eventDateController = TextEditingController();
  final _deadlineController = TextEditingController();

  DateTime? _selectedEventDate;
  DateTime? _selectedDeadline;
  final List<String> _selectedGroups = [];
  bool _sendToAll = true;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _eventTitleController.dispose();
    _eventDateController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<EventAnnouncementController>();
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event Announcement'),
        actions: [
          Obx(() => TextButton(
                onPressed: ctrl.isLoading.value ? null : _submitForm,
                child: ctrl.isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create'),
              )),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              _buildTextField(
                controller: _titleController,
                label: 'Announcement Title',
                hint: 'Enter a clear title for the announcement',
                icon: FontAwesomeIcons.heading,
                isDark: isDark,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Provide details about the event...',
                icon: FontAwesomeIcons.alignLeft,
                isDark: isDark,
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Event Title
              _buildTextField(
                controller: _eventTitleController,
                label: 'Event Title',
                hint: 'e.g., Sunday Service, Ashara Mubarak',
                icon: FontAwesomeIcons.calendarDays,
                isDark: isDark,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the event title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Event Date
              _buildDateSelector(
                controller: _eventDateController,
                label: 'Event Date & Time',
                hint: 'Select event date and time',
                icon: FontAwesomeIcons.clock,
                isDark: isDark,
                selectedDate: _selectedEventDate,
                onTap: () => _selectDateTime(context, (date) {
                  setState(() {
                    _selectedEventDate = date;
                    _eventDateController.text = _formatDateTime(date);
                  });
                }),
                validator: (value) {
                  if (_selectedEventDate == null) {
                    return 'Please select event date';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Response Deadline
              _buildDateSelector(
                controller: _deadlineController,
                label: 'Response Deadline (Optional)',
                hint: 'Select deadline for attendance responses',
                icon: FontAwesomeIcons.hourglassEnd,
                isDark: isDark,
                selectedDate: _selectedDeadline,
                onTap: () => _selectDateTime(context, (date) {
                  setState(() {
                    _selectedDeadline = date;
                    _deadlineController.text = _formatDateTime(date);
                  });
                }),
              ),
              const SizedBox(height: 24),

              // Target Audience
              Text(
                'Target Audience',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildTargetAudienceSection(isDark),
              const SizedBox(height: 32),

              // Submit Button
              Obx(() => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: ctrl.isLoading.value ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: ctrl.isLoading.value
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Create Announcement',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return isDark
        ? GlassCard(
            padding: const EdgeInsets.all(16),
            opacity: 0.08,
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                prefixIcon:
                    FaIcon(icon, color: const Color(0xFF059669), size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF059669)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
                ),
                labelStyle: const TextStyle(color: Color(0xFF059669)),
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
              style: const TextStyle(color: Colors.white),
              maxLines: maxLines,
              validator: validator,
            ),
          )
        : Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                prefixIcon:
                    FaIcon(icon, color: const Color(0xFF059669), size: 18),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                labelStyle: const TextStyle(color: Color(0xFF059669)),
                hintStyle: TextStyle(color: Colors.grey.shade500),
              ),
              maxLines: maxLines,
              validator: validator,
            ),
          );
  }

  Widget _buildDateSelector({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    DateTime? selectedDate,
    required VoidCallback onTap,
    String? Function(String?)? validator,
  }) {
    return isDark
        ? GlassCard(
            padding: const EdgeInsets.all(16),
            opacity: 0.08,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: label,
                  hintText: hint,
                  prefixIcon:
                      FaIcon(icon, color: const Color(0xFF059669), size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF059669)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
                  ),
                  labelStyle: const TextStyle(color: Color(0xFF059669)),
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  suffixIcon: const FaIcon(
                    FontAwesomeIcons.calendar,
                    color: Color(0xFF059669),
                    size: 18,
                  ),
                ),
                child: Text(
                  controller.text.isEmpty ? hint : controller.text,
                  style: TextStyle(
                    color: controller.text.isEmpty
                        ? Colors.white.withOpacity(0.5)
                        : Colors.white,
                  ),
                ),
              ),
            ),
          )
        : Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: label,
                  hintText: hint,
                  prefixIcon:
                      FaIcon(icon, color: const Color(0xFF059669), size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  labelStyle: const TextStyle(color: Color(0xFF059669)),
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  suffixIcon: const FaIcon(
                    FontAwesomeIcons.calendar,
                    color: Color(0xFF059669),
                    size: 18,
                  ),
                ),
                child: Text(
                  controller.text.isEmpty ? hint : controller.text,
                  style: TextStyle(
                    color: controller.text.isEmpty
                        ? Colors.grey.shade500
                        : Colors.black87,
                  ),
                ),
              ),
            ),
          );
  }

  Widget _buildTargetAudienceSection(bool isDark) {
    return isDark
        ? GlassCard(
            padding: const EdgeInsets.all(16),
            opacity: 0.08,
            child: Column(
              children: [
                Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.users,
                      color: Color(0xFF059669),
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Send to all groups/users',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Switch(
                      value: _sendToAll,
                      onChanged: (value) {
                        setState(() {
                          _sendToAll = value;
                          if (value) {
                            _selectedGroups.clear();
                          }
                        });
                      },
                      activeThumbColor: const Color(0xFF059669),
                    ),
                  ],
                ),
                if (!_sendToAll) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Select specific groups:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // TODO: Add group selection widgets
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Group selection will be implemented based on your team structure',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white60,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          )
        : Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.users,
                      color: Color(0xFF059669),
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Send to all groups/users',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Switch(
                      value: _sendToAll,
                      onChanged: (value) {
                        setState(() {
                          _sendToAll = value;
                          if (value) {
                            _selectedGroups.clear();
                          }
                        });
                      },
                      activeThumbColor: const Color(0xFF059669),
                    ),
                  ],
                ),
                if (!_sendToAll) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Select specific groups:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Group selection will be implemented based on your team structure',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
  }

  Future<void> _selectDateTime(
      BuildContext context, Function(DateTime) onSelected) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(now),
      );

      if (time != null) {
        final selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        onSelected(selectedDateTime);
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final ctrl = Get.find<EventAnnouncementController>();

    // Generate a mock event ID for now
    final eventId = 'event_${DateTime.now().millisecondsSinceEpoch}';

    ctrl.createAnnouncement(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      eventId: eventId,
      eventTitle: _eventTitleController.text.trim(),
      eventDate: _selectedEventDate!,
      deadlineAt: _selectedDeadline,
      targetGroups: _sendToAll ? [] : _selectedGroups,
    );
  }
}
