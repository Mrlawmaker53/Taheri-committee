import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/controllers/theme_controller.dart';
import '../../core/widgets/glass_card.dart';
import '../transport/transport_controller.dart';
import '../../core/models/transport_model.dart';
import '../../core/models/seat_booking_model.dart';

class SeatAssignmentForm extends StatefulWidget {
  const SeatAssignmentForm({super.key});

  @override
  State<SeatAssignmentForm> createState() => _SeatAssignmentFormState();
}

class _SeatAssignmentFormState extends State<SeatAssignmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _memberNameController = TextEditingController();
  final _memberIdController = TextEditingController();

  TransportModel? _selectedTransport;
  String? _selectedSeatId;

  @override
  void dispose() {
    _memberNameController.dispose();
    _memberIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(TransportController());
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seat Assignment'),
        actions: [
          TextButton(
            onPressed: _submitForm,
            child: const Text('Assign'),
          ),
        ],
      ),
      body: Obx(() {
        if (!ctrl.hasLoaded.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Member Information
                _buildSectionHeader(
                    'Member Information', FontAwesomeIcons.user, isDark),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _memberNameController,
                  label: 'Member Name',
                  hint: 'Enter member name',
                  icon: FontAwesomeIcons.user,
                  isDark: isDark,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter member name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _memberIdController,
                  label: 'Member ID',
                  hint: 'Enter member ID',
                  icon: FontAwesomeIcons.idCard,
                  isDark: isDark,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter member ID';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Transport Selection
                _buildSectionHeader(
                    'Transport Selection', FontAwesomeIcons.bus, isDark),
                const SizedBox(height: 16),

                _buildTransportSelector(ctrl, isDark),
                const SizedBox(height: 32),

                // Seat Selection
                if (_selectedTransport != null) ...[
                  _buildSectionHeader(
                      'Seat Selection', FontAwesomeIcons.chair, isDark),
                  const SizedBox(height: 16),
                  _buildSeatSelector(isDark),
                  const SizedBox(height: 32),
                ],

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Assign Seat',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        FaIcon(icon, color: const Color(0xFF059669), size: 20),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
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
              validator: validator,
            ),
          );
  }

  Widget _buildTransportSelector(TransportController ctrl, bool isDark) {
    final activeTransports =
        ctrl.transports.where((t) => t.status == 'active').toList();

    if (activeTransports.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const FaIcon(FontAwesomeIcons.exclamationTriangle,
                color: Colors.orange, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No active transports available',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return isDark
        ? GlassCard(
            padding: const EdgeInsets.all(16),
            opacity: 0.08,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Transport',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButton<TransportModel>(
                  value: _selectedTransport,
                  hint: Text(
                    'Select transport vehicle',
                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                  ),
                  isExpanded: true,
                  dropdownColor: const Color(0xFF0C0A09),
                  items: activeTransports.map((transport) {
                    return DropdownMenuItem<TransportModel>(
                      value: transport,
                      child: Text(
                        '${transport.vehicleLabel} - ${transport.driverName}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTransport = value;
                      _selectedSeatId = null; // Reset seat selection
                    });
                  },
                ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Transport',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButton<TransportModel>(
                  value: _selectedTransport,
                  hint: Text(
                    'Select transport vehicle',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  isExpanded: true,
                  items: activeTransports.map((transport) {
                    return DropdownMenuItem<TransportModel>(
                      value: transport,
                      child: Text(
                        '${transport.vehicleLabel} - ${transport.driverName}',
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTransport = value;
                      _selectedSeatId = null; // Reset seat selection
                    });
                  },
                ),
              ],
            ),
          );
  }

  Widget _buildSeatSelector(bool isDark) {
    if (_selectedTransport == null) return const SizedBox.shrink();

    final seats = _selectedTransport!.vehicleType.layout;
    final availableSeats = seats.where((seat) => !seat.isDriver);

    return isDark
        ? GlassCard(
            padding: const EdgeInsets.all(16),
            opacity: 0.08,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Seat',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableSeats.map((seat) {
                    final isSelected = _selectedSeatId == seat.id;
                    return ChoiceChip(
                      label: Text(seat.label),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedSeatId = isSelected ? seat.id : null;
                        });
                      },
                      backgroundColor: Colors.white.withOpacity(0.1),
                      selectedColor: const Color(0xFF059669).withOpacity(0.3),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                      ),
                    );
                  }).toList(),
                ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Seat',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableSeats.map((seat) {
                    final isSelected = _selectedSeatId == seat.id;
                    return ChoiceChip(
                      label: Text(seat.label),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedSeatId = isSelected ? seat.id : null;
                        });
                      },
                      backgroundColor: Colors.grey.shade100,
                      selectedColor: const Color(0xFF059669).withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? const Color(0xFF059669)
                            : Colors.black87,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTransport == null) {
      Get.snackbar('Error', 'Please select a transport vehicle');
      return;
    }

    if (_selectedSeatId == null) {
      Get.snackbar('Error', 'Please select a seat');
      return;
    }

    // TODO: Implement seat assignment logic
    Get.snackbar('Success', 'Seat assigned successfully');
    Get.back();
  }
}
