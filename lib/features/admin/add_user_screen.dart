import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_input.dart';
import '../../core/widgets/app_primary_button.dart';
import '../../core/models/user_model.dart';
import '../../core/services/firestore_service.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _itsNoCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _teamIdCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _professionalCtrl = TextEditingController();
  final _profileUrlCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  String? _selectedGender;
  String? _selectedSkill;
  String? _selectedPickupPoint;
  String? _selectedRole;
  bool _isActive = true;
  bool _isLoading = false;

  // Dynamic pickup points list (can be extended from Firebase)
  final List<String> _pickupPoints = [
    "hussaini masjid",
    "burhani school",
    "hotal rama",
    "saifee nagar",
    "sujai bag",
    "memun nagar",
    "navarang society",
    "landmark build",
    "hakim tower",
    "ratlami sevi bhandar",
    "jhalod",
    "saifee mohalla",
    "burhani mohalla",
    "thakkar faliya",
    "yaadgar chowk",
  ];

  final List<String> _skills = [
    "handle kitchen rice",
    "rice plate",
    "serve dal and water server",
    "all rounder",
  ];

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _roles = ['member', 'supervisor', 'leader'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _itsNoCtrl.dispose();
    _contactCtrl.dispose();
    _teamIdCtrl.dispose();
    _dobCtrl.dispose();
    _addressCtrl.dispose();
    _professionalCtrl.dispose();
    _profileUrlCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now()
          .subtract(const Duration(days: 365 * 20)), // Default 20 years ago
      firstDate: DateTime.now()
          .subtract(const Duration(days: 365 * 100)), // 100 years ago
      lastDate: DateTime.now()
          .subtract(const Duration(days: 365 * 10)), // Minimum 10 years old
    );
    if (picked != null) {
      setState(() {
        _dobCtrl.text =
            "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      });
    }
  }

  String _generateUid() {
    // UID will be same as ITS No (8 digits)
    return _itsNoCtrl.text;
  }

  Future<void> _addUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = _generateUid();

      final newUser = UserModel(
        uid: uid,
        itsNo: _itsNoCtrl.text,
        fullName: _nameCtrl.text.trim(),
        mobile:
            _contactCtrl.text.trim(), // Changed from contactNumber to mobile
        teamId: _teamIdCtrl.text.trim(),
        dateOfBirth: _dobCtrl.text.trim(),
        gender: _selectedGender ?? '',
        address: _addressCtrl.text.trim(),
        professional: _professionalCtrl.text.trim(),
        skill: _selectedSkill ?? '',
        pickupPoint: _selectedPickupPoint ?? '',
        profileUrl: _profileUrlCtrl.text.trim(),
        avatarUrl: _profileUrlCtrl.text.trim(), // avatarUrl is required
        email: _emailCtrl.text.trim(),
        role: _selectedRole ?? 'member',
        isActive: _isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await FirestoreService.createUser(newUser);

      Get.snackbar(
        'Success!',
        'User added successfully',
        backgroundColor: AppTokens.success,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      _clearForm();
      Get.back();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add user: $e',
        backgroundColor: AppTokens.danger,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _nameCtrl.clear();
    _itsNoCtrl.clear();
    _contactCtrl.clear();
    _teamIdCtrl.clear();
    _dobCtrl.clear();
    _addressCtrl.clear();
    _professionalCtrl.clear();
    _profileUrlCtrl.clear();
    _emailCtrl.clear();
    setState(() {
      _selectedGender = null;
      _selectedSkill = null;
      _selectedPickupPoint = null;
      _selectedRole = null;
      _isActive = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New User'),
        backgroundColor: AppTokens.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information Section
              _buildSectionHeader('Basic Information'),
              const SizedBox(height: 16),

              // Name
              AppInput(
                label: 'Full Name',
                hint: 'Enter full name',
                controller: _nameCtrl,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Please enter name' : null,
              ),
              const SizedBox(height: 16),

              // ITS No (8 digits)
              AppInput(
                label: 'ITS No',
                hint: 'Enter 8-digit ITS number',
                controller: _itsNoCtrl,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter ITS number';
                  if (v.length != 8) {
                    return 'ITS number must be exactly 8 digits';
                  }
                  if (!RegExp(r'^\d{8}$').hasMatch(v)) {
                    return 'ITS number must contain only digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Contact Number
              AppInput(
                label: 'Contact Number',
                hint: 'Enter contact number',
                controller: _contactCtrl,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Please enter contact number';
                  }
                  if (!RegExp(r'^\d{10}$').hasMatch(v)) {
                    return 'Contact number must be 10 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Team ID
              AppInput(
                label: 'Team ID',
                hint: 'Enter team ID',
                controller: _teamIdCtrl,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Please enter team ID' : null,
              ),
              const SizedBox(height: 16),

              // Date of Birth
              GestureDetector(
                onTap: _selectDate,
                child: AbsorbPointer(
                  child: AppInput(
                    label: 'Date of Birth',
                    hint: 'DD-MM-YYYY',
                    controller: _dobCtrl,
                    validator: (v) => v == null || v.isEmpty
                        ? 'Please select date of birth'
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Gender
              _buildDropdownField(
                'Gender',
                _genders,
                _selectedGender,
                (value) => setState(() => _selectedGender = value),
                validator: (v) => v == null ? 'Please select gender' : null,
              ),
              const SizedBox(height: 24),

              // Additional Information Section
              _buildSectionHeader('Additional Information'),
              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'Enter full address',
                  filled: true,
                  fillColor: AppTokens.surfaceInput,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                        Radius.circular(AppTokens.radiusInput)),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                        Radius.circular(AppTokens.radiusInput)),
                    borderSide: BorderSide(color: AppTokens.border, width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                        Radius.circular(AppTokens.radiusInput)),
                    borderSide:
                        BorderSide(color: AppTokens.primary, width: 1.5),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppTokens.sp16,
                    vertical: AppTokens.sp16,
                  ),
                ),
                maxLines: 3,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Please enter address' : null,
              ),
              const SizedBox(height: 16),

              // Professional
              AppInput(
                label: 'Professional',
                hint: 'Enter profession',
                controller: _professionalCtrl,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Please enter profession' : null,
              ),
              const SizedBox(height: 16),

              // Skill
              _buildDropdownField(
                'Skill',
                _skills,
                _selectedSkill,
                (value) => setState(() => _selectedSkill = value),
                validator: (v) => v == null ? 'Please select skill' : null,
              ),
              const SizedBox(height: 16),

              // Pickup Point
              _buildDropdownField(
                'Pickup Point',
                _pickupPoints,
                _selectedPickupPoint,
                (value) => setState(() => _selectedPickupPoint = value),
                validator: (v) =>
                    v == null ? 'Please select pickup point' : null,
              ),
              const SizedBox(height: 24),

              // System Information Section
              _buildSectionHeader('System Information'),
              const SizedBox(height: 16),

              // Profile URL
              AppInput(
                label: 'Profile URL',
                hint: 'Enter profile image URL (optional)',
                controller: _profileUrlCtrl,
                validator: (v) {
                  if (v != null && v.isNotEmpty) {
                    final uri = Uri.tryParse(v);
                    if (uri == null || !uri.hasAbsolutePath) {
                      return 'Please enter a valid URL';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email
              AppInput(
                label: 'Email',
                hint: 'Enter email address',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter email';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(v)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Role
              _buildDropdownField(
                'Role',
                _roles,
                _selectedRole,
                (value) => setState(() => _selectedRole = value),
                validator: (v) => v == null ? 'Please select role' : null,
              ),
              const SizedBox(height: 16),

              // Active Status
              Row(
                children: [
                  Checkbox(
                    value: _isActive,
                    onChanged: (value) =>
                        setState(() => _isActive = value ?? true),
                    activeColor: AppTokens.primary,
                  ),
                  const Text('Active User'),
                ],
              ),
              const SizedBox(height: 32),

              // Submit Button
              AppPrimaryButton(
                label: 'Add User',
                isLoading: _isLoading,
                onTap: _isLoading ? null : _addUser,
                isDark: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTokens.primary,
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    List<String> items,
    String? selectedValue,
    Function(String?) onChanged, {
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: selectedValue,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppTokens.surfaceInput,
        labelStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppTokens.primary,
          fontSize: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusInput),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusInput),
          borderSide: const BorderSide(color: AppTokens.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusInput),
          borderSide: const BorderSide(color: AppTokens.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.sp16,
          vertical: AppTokens.sp16,
        ),
      ),
      items: items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (validator != null) {
          return validator(value);
        }
        return null;
      },
    );
  }
}
