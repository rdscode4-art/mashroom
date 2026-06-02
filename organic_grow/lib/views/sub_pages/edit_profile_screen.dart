import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:organic_grow/config/app_color.dart';
import 'package:organic_grow/config/app_typography.dart';
import 'package:organic_grow/core/controllers/profile_controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ProfileController profileController = Get.find<ProfileController>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _pickedImage;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    final user = profileController.user.value;
    nameController.text = (user.name == 'Guest User') ? '' : user.name;
    emailController.text = (user.email == 'no-email@organicgrow.com') ? '' : user.email;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (picked != null) {
        setState(() => _pickedImage = File(picked.path));
        // Auto-upload immediately
        await _uploadPhoto(picked.path);
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not pick image: $e',
          backgroundColor: Colors.red, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _uploadPhoto(String path) async {
    setState(() => _isUploadingPhoto = true);
    try {
      await profileController.uploadProfilePhoto(path);
      Get.snackbar('Photo Updated! 📸', 'Profile photo changed successfully',
          backgroundColor: AppColor.primaryColor,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          borderRadius: 16);
    } catch (e) {
      Get.snackbar('Upload Failed', 'Could not upload photo. Try again.',
          backgroundColor: Colors.red, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
      setState(() => _pickedImage = null);
    } finally {
      setState(() => _isUploadingPhoto = false);
    }
  }

  void _showImageSourceSheet() {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('Change Profile Photo',
                style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  color: AppColor.primaryColor,
                  onTap: () {
                    Get.back();
                    _pickImage(ImageSource.camera);
                  },
                ),
                _SourceOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  color: Colors.purple,
                  onTap: () {
                    Get.back();
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Edit Profile',
            style: AppTypography.h3
                .copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColor.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ─── Profile Photo ───────────────────────────
            GestureDetector(
              onTap: _showImageSourceSheet,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 12,
                            offset: Offset(0, 4))
                      ],
                    ),
                    child: Stack(
                      children: [
                        Obx(() {
                          final user = profileController.user.value;
                          return CircleAvatar(
                            radius: 64,
                            backgroundColor: AppColor.primaryColor.withOpacity(0.1),
                            backgroundImage: _pickedImage != null
                                ? FileImage(_pickedImage!) as ImageProvider
                                : (user.image.startsWith('http')
                                    ? NetworkImage(user.image)
                                    : null),
                            child: (_pickedImage == null &&
                                    !user.image.startsWith('http'))
                                ? const Icon(Icons.person_rounded,
                                    size: 65, color: AppColor.primaryColor)
                                : null,
                          );
                        }),
                        if (_isUploadingPhoto)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Camera icon badge
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColor.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2))
                      ],
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Phone (read-only badge)
            Obx(() => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone_iphone_rounded,
                          size: 16, color: AppColor.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        profileController.user.value.phone,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColor.textColor.withOpacity(0.5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 24),

            // Name field
            _buildTextField(
              controller: nameController,
              label: 'Full Name',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 16),

            // Email field
            _buildTextField(
              controller: emailController,
              label: 'Email Address',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),

            // Address (read-only)
            Obx(() {
              final addr = profileController.user.value.address;
              if (addr.isEmpty || addr == 'No Address Set') {
                return const SizedBox.shrink();
              }
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColor.primaryColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: AppColor.primaryColor.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: AppColor.primaryColor, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        addr,
                        style: AppTypography.caption
                            .copyWith(color: AppColor.textColor.withOpacity(0.7)),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 40),

            // Save button
            Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: profileController.isLoading.value
                        ? null
                        : () async {
                            final name = nameController.text.trim();
                            final email = emailController.text.trim();
                            if (name.isEmpty) {
                              Get.snackbar('Error', 'Name cannot be empty',
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                  snackPosition: SnackPosition.BOTTOM);
                              return;
                            }
                            try {
                              await profileController.updateProfile(name, email);
                              Get.back();
                              Get.snackbar('Saved ✅',
                                  'Profile updated successfully!',
                                  backgroundColor: AppColor.primaryColor,
                                  colorText: Colors.white,
                                  borderRadius: 16,
                                  snackPosition: SnackPosition.BOTTOM);
                            } catch (e) {
                              Get.snackbar('Error',
                                  'Failed to update. Please try again.',
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                  snackPosition: SnackPosition.BOTTOM);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.btnColor,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                    child: profileController.isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black54))
                        : Text('Save Changes',
                            style: AppTypography.buttonLarge
                                .copyWith(fontWeight: FontWeight.bold)),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
            color: AppColor.textColor, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              TextStyle(color: AppColor.textColor.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: AppColor.primaryColor),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: AppTypography.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600, color: AppColor.textColor)),
        ],
      ),
    );
  }
}
