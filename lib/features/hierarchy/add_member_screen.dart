import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/controllers/hierarchy_controller.dart';
import '../../core/models/hierarchy_model.dart';
import '../../core/widgets/glass_card.dart';

class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  HierarchyRole _selectedRole = HierarchyRole.member;
  Gender _selectedGender = Gender.male;
  String? _selectedParentId;
  
  final ctrl = Get.find<HierarchyController>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Add Team Member',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const FaIcon(
            FontAwesomeIcons.arrowLeft,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personal Information
              GlassCard(
                padding: const EdgeInsets.all(16),
                opacity: 0.08,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF059669),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'Enter member\'s full name',
                        prefixIcon: FaIcon(
                          FontAwesomeIcons.user,
                          color: Color(0xFF059669),
                          size: 16,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'Enter email address',
                        prefixIcon: FaIcon(
                          FontAwesomeIcons.envelope,
                          color: Color(0xFF059669),
                          size: 16,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an email';
                        }
                        if (!GetUtils.isEmail(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        hintText: 'Enter phone number',
                        prefixIcon: FaIcon(
                          FontAwesomeIcons.phone,
                          color: Color(0xFF059669),
                          size: 16,
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a phone number';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Role and Gender Selection
              GlassCard(
                padding: const EdgeInsets.all(16),
                opacity: 0.08,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Role & Gender',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF059669),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Gender Selection
                    const Text(
                      'Gender',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: Gender.values.map((gender) {
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: gender == Gender.female ? 0 : 8,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedGender = gender;
                                  _selectedParentId = null; // Reset parent when gender changes
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _selectedGender == gender
                                      ? (gender == Gender.male
                                          ? const Color(0xFF4ECDC4).withOpacity(0.2)
                                          : const Color(0xFFE91E63).withOpacity(0.2))
                                      : Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _selectedGender == gender
                                        ? (gender == Gender.male
                                            ? const Color(0xFF4ECDC4)
                                            : const Color(0xFFE91E63))
                                        : Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FaIcon(
                                      gender == Gender.male
                                          ? FontAwesomeIcons.person
                                          : FontAwesomeIcons.personDress,
                                      size: 16,
                                      color: _selectedGender == gender
                                          ? (gender == Gender.male
                                              ? const Color(0xFF4ECDC4)
                                              : const Color(0xFFE91E63))
                                          : Colors.white54,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      gender.displayName,
                                      style: TextStyle(
                                        color: _selectedGender == gender
                                            ? (gender == Gender.male
                                                ? const Color(0xFF4ECDC4)
                                                : const Color(0xFFE91E63))
                                            : Colors.white54,
                                        fontWeight: _selectedGender == gender
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Role Selection
                    const Text(
                      'Hierarchy Role',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<HierarchyRole>(
                      initialValue: _selectedRole,
                      decoration: const InputDecoration(
                        hintText: 'Select role',
                        prefixIcon: FaIcon(
                          FontAwesomeIcons.userTag,
                          color: Color(0xFF059669),
                          size: 16,
                        ),
                      ),
                      items: HierarchyRole.values.map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Row(
                            children: [
                              FaIcon(
                                _getRoleIcon(role),
                                color: _getRoleColor(role),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                role.displayName,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                          _selectedParentId = null; // Reset parent when role changes
                        });
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Parent Selection
              if (_selectedRole != HierarchyRole.leader) ...[
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  opacity: 0.08,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Parent/Supervisor',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Obx(() {
                        final availableParents = ctrl.getAvailableParents(
                          _selectedRole,
                          _selectedGender,
                        );
                        
                        if (availableParents.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                              ),
                            ),
                            child: const Row(
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.triangleExclamation,
                                  color: Colors.orange,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No available parents for this role and gender',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        return DropdownButtonFormField<String>(
                          initialValue: _selectedParentId,
                          decoration: const InputDecoration(
                            hintText: 'Select parent/supervisor',
                            prefixIcon: FaIcon(
                              FontAwesomeIcons.userShield,
                              color: Color(0xFF059669),
                              size: 16,
                            ),
                          ),
                          items: availableParents.map((parent) {
                            return DropdownMenuItem(
                              value: parent.id,
                              child: Row(
                                children: [
                                  FaIcon(
                                    _getRoleIcon(parent.role),
                                    color: _getRoleColor(parent.role),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${parent.name} (${parent.role.displayName})',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedParentId = value;
                            });
                          },
                          validator: (value) {
                            if (_selectedRole != HierarchyRole.leader && 
                                (value == null || value.isEmpty)) {
                              return 'Please select a parent/supervisor';
                            }
                            return null;
                          },
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Submit Button
              Obx(() => ElevatedButton(
                onPressed: ctrl.isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: ctrl.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(
                            FontAwesomeIcons.userPlus,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Add Member',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              )),
              
              const SizedBox(height: 16),
              
              // Error message
              Obx(() {
                if (ctrl.error.isEmpty) return const SizedBox.shrink();
                
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.triangleExclamation,
                        color: Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ctrl.error,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: ctrl.clearError,
                        icon: const FaIcon(
                          FontAwesomeIcons.xmark,
                          color: Colors.red,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ctrl.addNode(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      role: _selectedRole,
      gender: _selectedGender,
      parentId: _selectedParentId,
    );

    if (success) {
      Get.back();
    }
  }

  IconData _getRoleIcon(HierarchyRole role) {
    switch (role) {
      case HierarchyRole.leader:
        return FontAwesomeIcons.crown;
      case HierarchyRole.coreTeamLeader:
        return FontAwesomeIcons.userTie;
      case HierarchyRole.captain:
        return FontAwesomeIcons.star;
      case HierarchyRole.supervisor:
        return FontAwesomeIcons.userShield;
      case HierarchyRole.monitor:
        return FontAwesomeIcons.eye;
      case HierarchyRole.member:
        return FontAwesomeIcons.user;
    }
  }

  Color _getRoleColor(HierarchyRole role) {
    switch (role) {
      case HierarchyRole.leader:
        return const Color(0xFFFF6B6B);
      case HierarchyRole.coreTeamLeader:
        return const Color(0xFF4ECDC4);
      case HierarchyRole.captain:
        return const Color(0xFF45B7D1);
      case HierarchyRole.supervisor:
        return const Color(0xFF96CEB4);
      case HierarchyRole.monitor:
        return const Color(0xFFFFEAA7);
      case HierarchyRole.member:
        return const Color(0xFFDFE6E9);
    }
  }
}
