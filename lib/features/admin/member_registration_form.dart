import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/controllers/theme_controller.dart';
import '../../core/widgets/glass_card.dart';
import '../hierarchy/hierarchy_controller.dart';
import '../../core/models/hierarchy_model.dart';

class MemberRegistrationForm extends StatefulWidget {
  const MemberRegistrationForm({super.key});

  @override
  State<MemberRegistrationForm> createState() => _MemberRegistrationFormState();
}

class _MemberRegistrationFormState extends State<MemberRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  HierarchyRole _selectedRole = HierarchyRole.member;
  Gender _selectedGender = Gender.male;
  String? _selectedParentId;
  bool _isActive = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HierarchyController>();
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Registration'),
        actions: [
          TextButton(
            onPressed: _submitForm,
            child: const Text('Register'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personal Information
              _buildSectionHeader(
                  'Personal Information', FontAwesomeIcons.user, isDark),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'Enter member\'s full name',
                icon: FontAwesomeIcons.user,
                isDark: isDark,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                hint: 'Enter email address',
                icon: FontAwesomeIcons.envelope,
                isDark: isDark,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter email address';
                  }
                  if (!GetUtils.isEmail(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: 'Enter phone number',
                icon: FontAwesomeIcons.phone,
                isDark: isDark,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _addressController,
                label: 'Address',
                hint: 'Enter residential address',
                icon: FontAwesomeIcons.home,
                isDark: isDark,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Role Assignment
              _buildSectionHeader(
                  'Role Assignment', FontAwesomeIcons.userShield, isDark),
              const SizedBox(height: 16),

              _buildRoleSelector(isDark),
              const SizedBox(height: 16),

              _buildGenderSelector(isDark),
              const SizedBox(height: 16),

              _buildParentSelector(ctrl, isDark),
              const SizedBox(height: 32),

              // Status
              _buildSectionHeader('Status', FontAwesomeIcons.toggleOn, isDark),
              const SizedBox(height: 16),

              _buildStatusToggle(isDark),
              const SizedBox(height: 32),

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
                    'Register Member',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
    int maxLines = 1,
    TextInputType? keyboardType,
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
              keyboardType: keyboardType,
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
              keyboardType: keyboardType,
              validator: validator,
            ),
          );
  }

  Widget _buildRoleSelector(bool isDark) {
    return isDark
        ? GlassCard(
            padding: const EdgeInsets.all(16),
            opacity: 0.08,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Role',
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
                  children: HierarchyRole.values.map((role) {
                    final isSelected = _selectedRole == role;
                    return ChoiceChip(
                      label: Text(role.displayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedRole = role;
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
                  'Select Role',
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
                  children: HierarchyRole.values.map((role) {
                    final isSelected = _selectedRole == role;
                    return ChoiceChip(
                      label: Text(role.displayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedRole = role;
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

  Widget _buildGenderSelector(bool isDark) {
    return isDark
        ? GlassCard(
            padding: const EdgeInsets.all(16),
            opacity: 0.08,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Gender',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: Gender.values.map((gender) {
                    final isSelected = _selectedGender == gender;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedGender = gender;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF059669).withOpacity(0.3)
                                : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF059669)
                                  : Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            gender.displayName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
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
                  'Select Gender',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: Gender.values.map((gender) {
                    final isSelected = _selectedGender == gender;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedGender = gender;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF059669).withOpacity(0.2)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF059669)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            gender.displayName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF059669)
                                  : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
  }

  Widget _buildParentSelector(HierarchyController ctrl, bool isDark) {
    final potentialParents = ctrl.hierarchyNodes
        .where((node) => node.role.level < _selectedRole.level)
        .toList();

    if (potentialParents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const FaIcon(FontAwesomeIcons.infoCircle, color: Colors.orange, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No parent roles available for the selected role',
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
                  'Select Parent (Optional)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButton<String>(
                  value: _selectedParentId,
                  hint: Text(
                    'Select parent role',
                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                  ),
                  isExpanded: true,
                  dropdownColor: const Color(0xFF0C0A09),
                  items: potentialParents.map((parent) {
                    return DropdownMenuItem<String>(
                      value: parent.id,
                      child: Text(
                        '${parent.name} (${parent.role.displayName})',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedParentId = value;
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
                  'Select Parent (Optional)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButton<String>(
                  value: _selectedParentId,
                  hint: Text(
                    'Select parent role',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  isExpanded: true,
                  items: potentialParents.map((parent) {
                    return DropdownMenuItem<String>(
                      value: parent.id,
                      child: Text(
                        '${parent.name} (${parent.role.displayName})',
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedParentId = value;
                    });
                  },
                ),
              ],
            ),
          );
  }

  Widget _buildStatusToggle(bool isDark) {
    return isDark
        ? GlassCard(
            padding: const EdgeInsets.all(16),
            opacity: 0.08,
            child: Row(
              children: [
                FaIcon(
                  _isActive
                      ? FontAwesomeIcons.checkCircle
                      : FontAwesomeIcons.timesCircle,
                  color: _isActive ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Member Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isActive
                            ? 'Active - Member can access the system'
                            : 'Inactive - Member access revoked',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                  activeThumbColor: const Color(0xFF059669),
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
            child: Row(
              children: [
                FaIcon(
                  _isActive
                      ? FontAwesomeIcons.checkCircle
                      : FontAwesomeIcons.timesCircle,
                  color: _isActive ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Member Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isActive
                            ? 'Active - Member can access the system'
                            : 'Inactive - Member access revoked',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                  activeThumbColor: const Color(0xFF059669),
                ),
              ],
            ),
          );
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final ctrl = Get.find<HierarchyController>();

    ctrl
        .addMember(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      role: _selectedRole,
      gender: _selectedGender,
      parentId: _selectedParentId,
    )
        .then((_) {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
    });
  }
}
