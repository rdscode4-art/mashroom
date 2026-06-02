import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../core/controllers/auth_controller.dart';
import '../core/theme/app_theme.dart';
import '../core/services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final AuthController _auth;

  bool _isLoading = false;
  File? _selectedPhoto;

  final _nameCtrl = TextEditingController();
  final _vehicleNoCtrl = TextEditingController();
  String _selectedVehicleType = 'bike';

  final List<String> _vehicleTypes = ['bike', 'scooter', 'cycle', 'other'];

  @override
  void initState() {
    super.initState();
    _auth = Get.find<AuthController>();
    _initFields();
  }

  void _initFields() {
    final partner = _auth.partner.value;
    if (partner != null) {
      _nameCtrl.text = partner.name;
      _vehicleNoCtrl.text = partner.vehicleNumber;
      _selectedVehicleType = _vehicleTypes.contains(partner.vehicleType)
          ? partner.vehicleType
          : 'bike';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _vehicleNoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );
      if (picked != null) {
        setState(() {
          _selectedPhoto = File(picked.path);
        });
      }
    } catch (e) {
      Get.snackbar(
        'Photo Selection Failed',
        e.toString(),
        backgroundColor: AppTheme.danger,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final partner = _auth.partner.value;
      final res = await ApiService.updateProfile(
        name: _nameCtrl.text.trim(),
        email:
            partner?.email ?? '', // Preserve email in backend if already exists
        vehicleType: _selectedVehicleType,
        vehicleNumber: _vehicleNoCtrl.text.trim().toUpperCase(),
        profileImagePath: _selectedPhoto?.path,
      );

      if (res['success'] == true) {
        Get.snackbar(
          'Profile Saved ✅',
          'Your details have been updated successfully.',
          backgroundColor: AppTheme.primary,
          colorText: Colors.white,
        );
        await _auth.refreshProfile();
        Get.back(); // Pop page and return to Profile Screen
      }
    } catch (e) {
      Get.snackbar(
        'Update Failed',
        e.toString().replaceFirst('Exception: ', ''),
        backgroundColor: AppTheme.danger,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text(
          'Edit Profile Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Obx(() {
        final partner = _auth.partner.value;
        if (partner == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // 1. Profile Avatar Picker
                Center(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primary, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.15),
                              blurRadius: 16,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 54,
                          backgroundColor: Colors.white,
                          backgroundImage: _selectedPhoto != null
                              ? FileImage(_selectedPhoto!) as ImageProvider
                              : (partner.profileImage.isNotEmpty
                                    ? NetworkImage(
                                        partner.profileImage.startsWith('http')
                                            ? partner.profileImage
                                            : 'https://mushroomback.ridealdigitalseva.com/${partner.profileImage}',
                                      )
                                    : null),
                          child:
                              partner.profileImage.isEmpty &&
                                  _selectedPhoto == null
                              ? Icon(
                                  Icons.person_rounded,
                                  size: 54,
                                  color: AppTheme.textMuted,
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: GestureDetector(
                          onTap: _pickPhoto,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Personal fields
                _buildFormCard(
                  title: 'Personal Information',
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      style: TextStyle(color: AppTheme.textColor),
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        labelStyle: TextStyle(color: AppTheme.textMuted),
                        prefixIcon: const Icon(
                          Icons.person_outline_rounded,
                          color: AppTheme.primary,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Name is required'
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. Vehicle fields
                _buildFormCard(
                  title: 'Vehicle Configuration',
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedVehicleType,
                      style: TextStyle(color: AppTheme.textColor),
                      dropdownColor: AppTheme.card,
                      decoration: InputDecoration(
                        labelText: 'Vehicle Category',
                        labelStyle: TextStyle(color: AppTheme.textMuted),
                        prefixIcon: const Icon(
                          Icons.directions_bike_rounded,
                          color: AppTheme.primary,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      items: _vehicleTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(
                            type.toUpperCase(),
                            style: TextStyle(color: AppTheme.textColor),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null)
                          setState(() => _selectedVehicleType = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _vehicleNoCtrl,
                      style: TextStyle(color: AppTheme.textColor),
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'License Plate / Vehicle Number',
                        labelStyle: TextStyle(color: AppTheme.textMuted),
                        prefixIcon: const Icon(
                          Icons.pin_outlined,
                          color: AppTheme.primary,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 4. Save Button
                _isLoading
                    ? const CircularProgressIndicator(color: AppTheme.primary)
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Save Profile Updates',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
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

  Widget _buildFormCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(height: 24, color: AppTheme.border),
          ...children.expand((w) => [w, const SizedBox(height: 12)]).toList()
            ..removeLast(),
        ],
      ),
    );
  }
}
