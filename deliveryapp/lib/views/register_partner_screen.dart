import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../core/models/partner_model.dart';
import '../core/services/api_service.dart';
import '../core/theme/app_theme.dart';

class RegisterPartnerScreen extends StatefulWidget {
  const RegisterPartnerScreen({super.key});

  @override
  State<RegisterPartnerScreen> createState() => _RegisterPartnerScreenState();
}

class _RegisterPartnerScreenState extends State<RegisterPartnerScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _vehicleNumCtrl = TextEditingController();
  final _aadharCtrl = TextEditingController();
  final _dlCtrl = TextEditingController();
  final _picker = ImagePicker();

  String _vehicleType = 'bike';
  XFile? _aadharFront;
  XFile? _aadharBack;
  XFile? _dlImage;
  bool _profileCreated = false;
  DeliveryPartner? _existingPartner;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is DeliveryPartner) {
      _existingPartner = args;
      _profileCreated = true;
      _nameCtrl.text = args.name;
      _phoneCtrl.text = args.phone;
      _vehicleType = args.vehicleType;
      _vehicleNumCtrl.text = args.vehicleNumber;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _vehicleNumCtrl.dispose();
    _aadharCtrl.dispose();
    _dlCtrl.dispose();
    super.dispose();
  }

  Future<void> _createProfile() async {
    if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
      _snack('Required', 'Please fill all required profile fields', Colors.orange);
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await ApiService.registerPartner(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        vehicleType: _vehicleType,
        vehicleNumber: _vehicleNumCtrl.text.trim(),
      );
      if (res['success'] == true) {
        setState(() => _profileCreated = true);
        _snack('Profile Created', 'Submit KYC documents for admin approval.', Colors.green);
      } else {
        throw Exception(res['message']);
      }
    } catch (e) {
      _snack('Error', e.toString().replaceFirst('Exception: ', ''), Colors.redAccent);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickImage(String field) async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    setState(() {
      if (field == 'front') _aadharFront = file;
      if (field == 'back') _aadharBack = file;
      if (field == 'dl') _dlImage = file;
    });
  }

  Future<void> _submitKyc() async {
    final aadhar = _aadharCtrl.text.replaceAll(RegExp(r'\s+'), '');
    if (aadhar.length != 12 ||
        _dlCtrl.text.trim().isEmpty ||
        _aadharFront == null ||
        _aadharBack == null ||
        _dlImage == null) {
      _snack('KYC Required', 'Enter Aadhar, DL number and upload all 3 document images.', Colors.orange);
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await ApiService.submitKyc(
        aadharNumber: aadhar,
        dlNumber: _dlCtrl.text.trim(),
        aadharFrontPath: _aadharFront!.path,
        aadharBackPath: _aadharBack!.path,
        dlImagePath: _dlImage!.path,
      );
      if (res['success'] == true) {
        _snack('KYC Submitted', 'Admin will verify your request before your ID is activated.', Colors.green);
        setState(() {
          _existingPartner = DeliveryPartner(
            id: _existingPartner?.id ?? '',
            name: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            vehicleType: _vehicleType,
            vehicleNumber: _vehicleNumCtrl.text.trim(),
            kycStatus: 'submitted',
          );
        });
      } else {
        throw Exception(res['message']);
      }
    } catch (e) {
      _snack('Error', e.toString().replaceFirst('Exception: ', ''), Colors.redAccent);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _snack(String title, String message, Color color) {
    Get.snackbar(title, message, backgroundColor: color, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_profileCreated ? 'Submit KYC' : 'Complete Your Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(_profileCreated ? Icons.verified_user_rounded : Icons.person_add_rounded, color: AppTheme.primary, size: 44),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _profileCreated ? 'Upload documents for admin approval' : 'Set up your delivery profile',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
          const SizedBox(height: 32),
          if (_existingPartner?.kycStatus == 'submitted') ...[
            _statusCard('KYC submitted', 'Your request is waiting for admin approval. Your driver ID will activate after approval.', Icons.hourglass_top_rounded, Colors.orange),
          ] else if (_existingPartner?.kycStatus == 'rejected') ...[
            _statusCard('KYC rejected', _existingPartner?.kycRejectionReason.isNotEmpty == true ? _existingPartner!.kycRejectionReason : 'Please upload corrected documents.', Icons.error_rounded, Colors.redAccent),
            const SizedBox(height: 20),
            ..._kycFields(),
          ] else if (!_profileCreated) ..._profileFields() else ..._kycFields(),
          const SizedBox(height: 32),
          if (_existingPartner?.kycStatus != 'submitted')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : (_profileCreated ? _submitKyc : _createProfile),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        _profileCreated ? 'Submit KYC for Approval' : 'Create Profile & Continue to KYC',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
            ),
        ]),
      ),
    );
  }

  List<Widget> _profileFields() => [
        _field(_nameCtrl, 'Full Name *', 'e.g. Ramesh Kumar', Icons.person_rounded),
        const SizedBox(height: 16),
        _field(_phoneCtrl, 'Phone Number *', 'e.g. 9876543210', Icons.phone_rounded, type: TextInputType.phone),
        const SizedBox(height: 16),
        Text('Vehicle Type *', style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['bike', 'scooter', 'cycle', 'other'].map((t) {
            final selected = _vehicleType == t;
            return ChoiceChip(
              label: Text(t[0].toUpperCase() + t.substring(1)),
              selected: selected,
              onSelected: (_) => setState(() => _vehicleType = t),
              selectedColor: AppTheme.primary.withValues(alpha: 0.2),
              labelStyle: TextStyle(color: selected ? AppTheme.primary : AppTheme.textMuted, fontWeight: selected ? FontWeight.bold : FontWeight.normal),
              side: BorderSide(color: selected ? AppTheme.primary : AppTheme.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _field(_vehicleNumCtrl, 'Vehicle Number (Optional)', 'e.g. OD-01-AB-1234', Icons.two_wheeler_rounded),
      ];

  List<Widget> _kycFields() => [
        _field(_aadharCtrl, 'Aadhar Number *', '12-digit Aadhar number', Icons.badge_rounded, type: TextInputType.number),
        const SizedBox(height: 16),
        _field(_dlCtrl, 'Driving Licence Number *', 'e.g. OD0120230001234', Icons.credit_card_rounded),
        const SizedBox(height: 18),
        _imageButton('Aadhar Front Image *', _aadharFront, () => _pickImage('front')),
        const SizedBox(height: 12),
        _imageButton('Aadhar Back Image *', _aadharBack, () => _pickImage('back')),
        const SizedBox(height: 12),
        _imageButton('Driving Licence Image *', _dlImage, () => _pickImage('dl')),
      ];

  Widget _field(TextEditingController ctrl, String label, String hint, IconData icon, {TextInputType type = TextInputType.text}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      TextField(
        controller: ctrl,
        keyboardType: type,
        style: TextStyle(color: AppTheme.textColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.textMuted),
          prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
          filled: true,
          fillColor: AppTheme.card,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 1.8)),
        ),
      ),
    ]);
  }

  Widget _imageButton(String label, XFile? file, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: file == null ? AppTheme.border : AppTheme.primary),
        ),
        child: Row(children: [
          Icon(file == null ? Icons.upload_file_rounded : Icons.check_circle_rounded, color: file == null ? AppTheme.textMuted : AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(file?.name ?? 'Tap to choose image', style: TextStyle(color: AppTheme.textMuted, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _statusCard(String title, String message, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 38),
        const SizedBox(height: 12),
        Text(title, style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        Text(message, style: TextStyle(color: AppTheme.textMuted, fontSize: 13), textAlign: TextAlign.center),
      ]),
    );
  }
}
