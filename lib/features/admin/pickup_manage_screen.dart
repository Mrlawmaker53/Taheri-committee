import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_input.dart';

class PickupManageScreen extends StatefulWidget {
  const PickupManageScreen({super.key});

  @override
  State<PickupManageScreen> createState() => _PickupManageScreenState();
}

class _PickupManageScreenState extends State<PickupManageScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final RxList<DocumentSnapshot> _pickups = <DocumentSnapshot>[].obs;
  final RxBool _isLoading = false.obs;
  final RxBool _hasLoaded = false.obs;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.toLowerCase());
    });
    _listenToPickups();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _listenToPickups() {
    _db.collection('pickups').orderBy('name').snapshots().listen((snap) {
      _pickups.value = snap.docs;
      _hasLoaded.value = true;
    }, onError: (_) => _hasLoaded.value = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.chevronLeft,
              color: Colors.white, size: 16),
          onPressed: () => Get.back(),
        ),
        title: const Text('Manage Pickup Locations'),
        backgroundColor: AppTokens.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.plus,
                color: Colors.white, size: 16),
            onPressed: () => _showAddPickupDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AppInput(
              hint: 'Search pickup locations...',
              controller: _searchCtrl,
              prefixIcon: const Icon(Icons.search, color: AppTokens.textMuted),
              isDark: false,
            ),
          ),
          Expanded(
            child: Obx(() {
              if (!_hasLoaded.value) {
                return const Center(child: CircularProgressIndicator());
              }

              var filteredPickups = _pickups.where((doc) {
                final name = (doc['name'] as String? ?? '').toLowerCase();
                final address = (doc['address'] as String? ?? '').toLowerCase();
                return name.contains(_query) || address.contains(_query);
              }).toList();

              if (filteredPickups.isEmpty) {
                return const Center(child: Text('No pickup locations found'));
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: filteredPickups.length,
                itemBuilder: (ctx, i) => _PickupTile(
                  doc: filteredPickups[i],
                  onTap: () => _showEditPickupDialog(filteredPickups[i]),
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPickupDialog(),
        backgroundColor: AppTokens.primary,
        child:
            const FaIcon(FontAwesomeIcons.plus, color: Colors.white, size: 18),
      ),
    );
  }

  void _showAddPickupDialog() {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    InputDecoration deco(String label, IconData icon) => InputDecoration(
          labelText: label,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: FaIcon(icon, size: 14),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          isDense: true,
        );

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF047857).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const FaIcon(FontAwesomeIcons.mapLocationDot,
                              color: Color(0xFF047857), size: 18),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Add Pickup Location',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 2),
                              Text('Create a new pickup location',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const FaIcon(FontAwesomeIcons.xmark, size: 16),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: deco('Location Name', FontAwesomeIcons.tag),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressCtrl,
                      decoration: deco('Address', FontAwesomeIcons.locationDot),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF047857),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const FaIcon(FontAwesomeIcons.check, size: 14),
                          label: const Text('Add Location'),
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              Navigator.pop(ctx);
                              await _addPickup(
                                name: nameCtrl.text.trim(),
                                address: addressCtrl.text.trim(),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditPickupDialog(DocumentSnapshot doc) {
    final nameCtrl = TextEditingController(text: doc['name'] as String? ?? '');
    final addressCtrl =
        TextEditingController(text: doc['address'] as String? ?? '');
    final formKey = GlobalKey<FormState>();

    InputDecoration deco(String label, IconData icon) => InputDecoration(
          labelText: label,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: FaIcon(icon, size: 14),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          isDense: true,
        );

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF047857).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const FaIcon(FontAwesomeIcons.mapLocationDot,
                              color: Color(0xFF047857), size: 18),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Edit Pickup Location',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 2),
                              Text('Update pickup location details',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const FaIcon(FontAwesomeIcons.xmark, size: 16),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: deco('Location Name', FontAwesomeIcons.tag),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressCtrl,
                      decoration: deco('Address', FontAwesomeIcons.locationDot),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF047857),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const FaIcon(FontAwesomeIcons.check, size: 14),
                          label: const Text('Update Location'),
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              Navigator.pop(ctx);
                              await _updatePickup(
                                docId: doc.id,
                                name: nameCtrl.text.trim(),
                                address: addressCtrl.text.trim(),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addPickup({
    required String name,
    required String address,
  }) async {
    try {
      await _db.collection('pickups').add({
        'name': name,
        'address': address,
        'isActive': true,
        'createdAt': Timestamp.now(),
      });
      Get.snackbar('Success', 'Pickup location added successfully',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900);
    } catch (e) {
      Get.snackbar('Error', 'Failed to add pickup location: $e',
          backgroundColor: Colors.red.shade100, colorText: Colors.red.shade900);
    }
  }

  Future<void> _updatePickup({
    required String docId,
    required String name,
    required String address,
  }) async {
    try {
      await _db.collection('pickups').doc(docId).update({
        'name': name,
        'address': address,
        'updatedAt': Timestamp.now(),
      });
      Get.snackbar('Success', 'Pickup location updated successfully',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update pickup location: $e',
          backgroundColor: Colors.red.shade100, colorText: Colors.red.shade900);
    }
  }

  Future<void> _deletePickup(String docId) async {
    try {
      await _db.collection('pickups').doc(docId).delete();
      Get.snackbar('Success', 'Pickup location deleted successfully',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete pickup location: $e',
          backgroundColor: Colors.red.shade100, colorText: Colors.red.shade900);
    }
  }
}

class _PickupTile extends StatelessWidget {
  final DocumentSnapshot doc;
  final VoidCallback onTap;

  const _PickupTile({required this.doc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = doc['name'] as String? ?? 'Unknown';
    final address = doc['address'] as String? ?? 'No address';
    final isActive = doc['isActive'] as bool? ?? true;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive
                ? AppTokens.primary.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FaIcon(
            FontAwesomeIcons.mapLocationDot,
            color: isActive ? AppTokens.primary : Colors.grey,
            size: 16,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(address, style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (val) {
            if (val == 'edit') {
              onTap();
            } else if (val == 'delete') {
              _showDeleteConfirmation(context);
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          child: const FaIcon(FontAwesomeIcons.ellipsisVertical,
              size: 16, color: Colors.grey),
        ),
        onTap: onTap,
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Pickup Location'),
        content:
            const Text('Are you sure you want to delete this pickup location?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              // Get the parent widget's delete method
              final parentState =
                  context.findAncestorStateOfType<_PickupManageScreenState>();
              parentState?._deletePickup(doc.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
