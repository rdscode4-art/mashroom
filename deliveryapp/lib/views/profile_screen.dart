import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../core/controllers/auth_controller.dart';
import '../core/controllers/delivery_controller.dart';
import '../core/theme/app_theme.dart';
import '../core/services/api_service.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AuthController _auth;
  bool _isLoading = false;
  File? _selectedPhoto;

  @override
  void initState() {
    super.initState();
    _auth = Get.find<AuthController>();
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );
      if (picked != null) {
        setState(() {
          _selectedPhoto = File(picked.path);
          _isLoading = true;
        });

        final partner = _auth.partner.value;
        if (partner != null) {
          final res = await ApiService.updateProfile(
            name: partner.name,
            email: partner.email,
            vehicleType: partner.vehicleType,
            vehicleNumber: partner.vehicleNumber,
            profileImagePath: _selectedPhoto!.path,
          );
          if (res['success'] == true) {
            Get.snackbar(
              'Photo Updated 📸',
              'Your profile photo has been updated.',
              backgroundColor: AppTheme.primary,
              colorText: Colors.white,
            );
            await _auth.refreshProfile();
          }
        }
      }
    } catch (e) {
      Get.snackbar(
        'Upload Failed',
        e.toString().replaceFirst('Exception: ', ''),
        backgroundColor: AppTheme.danger,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _selectedPhoto = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dc = Get.isRegistered<DeliveryController>()
        ? Get.find<DeliveryController>()
        : Get.put(DeliveryController());

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text(
          'Partner Account',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
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
          child: Column(
            children: [
              // 1. Profile Avatar & Name Header
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primary,
                              width: 3,
                            ),
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
                                          partner.profileImage.startsWith(
                                                'http',
                                              )
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
                        if (_isLoading)
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black38,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: GestureDetector(
                            onTap: _pickAndUploadPhoto,
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
                    const SizedBox(height: 16),
                    Text(
                      partner.name,
                      style: TextStyle(
                        color: AppTheme.textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      partner.phone,
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    _buildKycStatusBadge(
                      partner.kycStatus,
                      partner.kycRejectionReason,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Stats row
              Row(
                children: [
                  Expanded(
                    child: _buildMiniStatCard(
                      'Today Deliveries',
                      '${dc.todayDeliveries.value}',
                      Icons.today_rounded,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildMiniStatCard(
                      'Total Earnings',
                      '₹${dc.totalEarnings.value.toStringAsFixed(0)}',
                      Icons.currency_rupee_rounded,
                      Colors.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 3. KYC / License info
              _buildDetailCard(
                title: 'Account & KYC Details',
                children: [
                  _buildDetailRow(
                    Icons.badge_outlined,
                    'Driving License (DL) Number',
                    partner.dlNumber.isEmpty
                        ? 'Not Provided'
                        : partner.dlNumber,
                  ),
                  _buildDetailRow(
                    Icons.credit_card_outlined,
                    'Aadhar Number',
                    partner.aadharNumber.isEmpty
                        ? 'Not Provided'
                        : partner.aadharNumber,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. Vehicle config
              _buildDetailCard(
                title: 'Vehicle Information',
                children: [
                  _buildDetailRow(
                    Icons.directions_bike_rounded,
                    'Vehicle Category',
                    partner.vehicleType.toUpperCase(),
                  ),
                  _buildDetailRow(
                    Icons.pin_outlined,
                    'License Plate / Number',
                    partner.vehicleNumber.isEmpty
                        ? 'Not entered'
                        : partner.vehicleNumber,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 5. App Actions Menu
              _buildMenuCard([
                _buildMenuItem(
                  Icons.person_outline_rounded,
                  'Edit Profile Details',
                  'Update name, photo and vehicle plate info',
                  () => Get.to(() => const EditProfileScreen()),
                ),
                _buildMenuItem(
                  Icons.help_outline_rounded,
                  'Help & Partner Support',
                  'Submit queries, view history, dial helpline',
                  () => Get.toNamed('/support'),
                ),
                _buildMenuItem(
                  Icons.logout_rounded,
                  'Logout Account',
                  'Sign out of your partner session safely',
                  _showLogoutDialog,
                  isDanger: true,
                ),
              ]),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildMiniStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildKycStatusBadge(String status, String reason) {
    Color bg;
    Color fg;
    String label = status.toUpperCase();
    IconData icon;

    switch (status) {
      case 'approved':
        bg = Colors.green.withValues(alpha: 0.12);
        fg = Colors.green;
        icon = Icons.verified_rounded;
        break;
      case 'rejected':
        bg = Colors.red.withValues(alpha: 0.12);
        fg = Colors.red;
        icon = Icons.error_rounded;
        break;
      case 'submitted':
        bg = Colors.blue.withValues(alpha: 0.12);
        fg = Colors.blue;
        icon = Icons.hourglass_top_rounded;
        break;
      default:
        bg = Colors.orange.withValues(alpha: 0.12);
        fg = Colors.orange;
        icon = Icons.warning_amber_rounded;
        label = 'KYC NOT SUBMITTED';
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: fg.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: fg, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        if (status == 'rejected' && reason.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Reason: $reason',
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildDetailCard({
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

  Widget _buildDetailRow(IconData icon, String title, String val) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                val,
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children:
            children
                .expand(
                  (w) => [w, const Divider(height: 1, color: AppTheme.border)],
                )
                .toList()
              ..removeLast(),
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isDanger = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDanger
              ? AppTheme.danger.withValues(alpha: 0.12)
              : AppTheme.primary.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isDanger ? AppTheme.danger : AppTheme.primary,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDanger ? AppTheme.danger : AppTheme.textColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppTheme.textMuted,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: Text('Logout', style: TextStyle(color: AppTheme.textColor)),
        content: Text(
          'Are you sure you want to logout from your delivery partner account?',
          style: TextStyle(color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _auth.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
